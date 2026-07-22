package com.networkcloak.network_cloak

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.pm.ServiceInfo
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.system.OsConstants
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Network Cloak VPN Service
 *
 * Creates a TUN interface that captures all device traffic at the IP layer,
 * applies the RuleRepository decision per packet, and either:
 *   - Allows:  forwards the packet to the real internet via a protected socket
 *   - Blocks:  drops the packet (TCP gets a RST for fast-fail UX)
 *
 * DNS packets (UDP port 53) are intercepted by DnsGuardEngine for encrypted
 * DoH resolution and blocklist filtering.
 *
 * TCP forwarding: Option B is active — all TCP traffic is rejected with a
 * TCP RST packet (correct checksums + SEQ/ACK per RFC 793 §3.4). This
 * prevents the self-loop bug where writing a TCP packet back to the TUN fd
 * causes it to re-enter the tunnel and hang indefinitely. TCP relay requires
 * building tun2socks from source (Go + gomobile bind → .aar); there is no
 * Maven dependency for this — it must be done in a future sprint.
 *
 * Threading (D1): UDP/DNS forwarding runs on a bounded 4-thread coroutine
 * pool. All writes to the TUN fd go through a single-writer channel to
 * prevent interleaved/corrupted writes from concurrent threads.
 *
 * Note: android:process=":vpn" has been removed from AndroidManifest.xml so
 * this service runs in the same process as MainActivity, making all object
 * singletons (RuleRepository, NativeEventBus, DnsGuardEngine) genuinely shared.
 */
class NetworkCloakVpnService : VpnService() {

    companion object {
        private const val TAG = "NC-VPN"
        const val ACTION_KEY   = "action"
        const val ACTION_START = "start"
        const val ACTION_STOP  = "stop"
        const val ACTION_START_QUICK_BLOCK = "start_quick_block"

        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID      = "nc_protection"

        /** Tri-state VPN mode (D2): OFF, QUICK_BLOCK, or FULL */
        @Volatile var currentMode: VpnMode = VpnMode.OFF

        /** Backward compat convenience */
        val isRunning: Boolean get() = currentMode != VpnMode.OFF
    }

    /** Tri-state mode for distinguishing Quick Block from full protection (D2) */
    enum class VpnMode {
        OFF,
        QUICK_BLOCK,
        FULL;

        fun toEventString(): String = when (this) {
            OFF -> "off"
            QUICK_BLOCK -> "quickBlockOnly"
            FULL -> "full"
        }
    }

    val running       = AtomicBoolean(false)
    private var tunInterface: ParcelFileDescriptor? = null
    private var workerThread: Thread? = null

    // ── Coroutine infrastructure (D1) ─────────────────────────────
    private val ioDispatcher = Executors.newFixedThreadPool(4).asCoroutineDispatcher()
    private val scope = CoroutineScope(SupervisorJob() + ioDispatcher)
    // Single-writer channel: all threads send packets here; one writer drains to TUN
    private val tunWriteChannel = Channel<ByteArray>(capacity = 256)

    // ── Lifecycle ─────────────────────────────────────────────────

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.getStringExtra(ACTION_KEY) ?: ACTION_START
        if (action != ACTION_STOP) {
            createNotificationChannel()
            NativeEventBus.createAlertsChannel(this)
            try {
                if (Build.VERSION.SDK_INT >= 34) {
                    startForeground(
                        NOTIFICATION_ID,
                        buildNotification(),
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                } else {
                    startForeground(NOTIFICATION_ID, buildNotification())
                }
            } catch (e: Exception) {
                Log.w(TAG, "startForeground call failed: ${e.message}")
            }
        }
        return when (action) {
            ACTION_STOP -> {
                stopVpn("Stopped by user")
                START_NOT_STICKY
            }
            "refresh" -> {
                configureVpn()
                START_STICKY
            }
            ACTION_START_QUICK_BLOCK -> {
                startVpn(VpnMode.QUICK_BLOCK)
                START_STICKY
            }
            else -> {
                startVpn(VpnMode.FULL)
                START_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopVpn("Service destroyed")
        super.onDestroy()
    }

    override fun onRevoke() {
        stopVpn("Permission revoked")
    }

    // ── VPN Setup ─────────────────────────────────────────────────

    private fun configureVpn() {
        if (!running.get()) return
        try {
            val builder = Builder()
                .setSession("Network Cloak")
                .addAddress("10.0.0.1", 32)
                .addRoute("0.0.0.0", 0)          // capture all IPv4 traffic
                .addDnsServer("10.0.0.1")
                .setMtu(1500)
                .setBlocking(false)

            try {
                builder.addAddress("2001:db8:1::1", 64)
                builder.addRoute("::", 0)
                builder.addDnsServer("2001:db8:1::1")
            } catch (e: Exception) {
                Log.w(TAG, "IPv6 setup skipped/not supported: ${e.message}")
            }

            // ── Per-app TCP & UDP blocking strategy ──────────────────────────
            //
            // Without a TCP proxy (tun2socks .aar), we cannot forward TCP
            // through the TUN interface — writing an allowed TCP packet back to
            // the TUN fd causes it to re-enter the tunnel in a loop.
            //
            // The correct approach is to route ONLY BLOCKED apps through the TUN:
            //   • Blocked apps enter TUN → their TCP gets RST'd, UDP/ICMP dropped,
            //     IPv6 dropped, and DNS queries returned as NXDOMAIN.
            //   • Allowed apps bypass the TUN entirely → OS handles their TCP/UDP
            //     natively over IPv4 & IPv6, ensuring zero lag and normal app launch.
            //
            // We use addAllowedApplication() to whitelist ONLY the blocked apps
            // into the tunnel (VPN builder semantics: addAllowedApplication means
            // ONLY those apps go through the VPN; everything else bypasses it).

            if (RuleRepository.isLockdownActive) {
                // Lockdown: route ALL apps into tunnel; exclude only emergency/VPN itself
                val excluded = buildList {
                    add("com.networkcloak.network_cloak")
                    addAll(listOf("com.android.phone", "com.google.android.dialer"))
                    addAll(RuleRepository.getLockdownAllowlist())
                }
                for (pkg in excluded) {
                    try { builder.addDisallowedApplication(pkg) } catch (_: Exception) { }
                }
                Log.i(TAG, "VPN configured in LOCKDOWN mode. Excluded: ${excluded.size} packages")
            } else {
                // Normal mode: route ONLY blocked apps through the TUN.
                // Allowed/unset apps bypass the TUN and use the real OS stack.
                val blockedApps = RuleRepository.getBlockedAppIds(this)
                if (blockedApps.isEmpty()) {
                    // No apps currently blocked — route minimal control traffic through TUN
                    try { builder.addAllowedApplication("com.networkcloak.network_cloak") } catch (_: Exception) { }
                    Log.i(TAG, "VPN configured: 0 blocked apps — TUN has minimal routing")
                } else {
                    // Route blocked apps + ourselves through TUN.
                    try { builder.addAllowedApplication("com.networkcloak.network_cloak") } catch (_: Exception) { }
                    for (pkg in blockedApps) {
                        try { builder.addAllowedApplication(pkg) } catch (e: Exception) {
                            Log.w(TAG, "Could not add $pkg to TUN: ${e.message}")
                        }
                    }
                    Log.i(TAG, "VPN configured: ${blockedApps.size} blocked apps routed through TUN")
                }
            }

            val oldInterface = tunInterface
            tunInterface = builder.establish()
            try { oldInterface?.close() } catch (_: Exception) { }

            Log.i(TAG, "VPN interface established. Lockdown=${RuleRepository.isLockdownActive}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure VPN: ${e.message}")
        }
    }

    private fun startVpn(mode: VpnMode = VpnMode.FULL) {
        if (running.get()) {
            if (currentMode == mode) return  // already in the requested mode, nothing to do
            if (currentMode == VpnMode.QUICK_BLOCK && mode == VpnMode.FULL) {
                DnsGuardEngine.attach(this)
                currentMode = VpnMode.FULL
                persistProtectionState(VpnMode.FULL)
                NativeEventBus.postProtectionStateChanged(VpnMode.FULL.toEventString())
                return
            }
            if (currentMode == VpnMode.FULL && mode == VpnMode.QUICK_BLOCK) {
                DnsGuardEngine.detach()
                currentMode = VpnMode.QUICK_BLOCK
                persistProtectionState(VpnMode.QUICK_BLOCK)
                NativeEventBus.postProtectionStateChanged(VpnMode.QUICK_BLOCK.toEventString())
                return
            }
            return
        }
        running.set(true)

        createNotificationChannel()
        NativeEventBus.createAlertsChannel(this)
        startForeground(NOTIFICATION_ID, buildNotification())

        val prefs = getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
        RuleRepository.cloakEnabled = prefs.getBoolean("cloakEnabled", false)

        configureVpn()

        if (tunInterface == null) {
            Log.e(TAG, "VPN permission not granted or establish() failed")
            running.set(false)
            return
        }

        AppStateTracker.startMonitoring(this) {
            configureVpn()
        }
        registerScreenReceiver()

        currentMode = mode
        persistProtectionState(mode)

        if (mode == VpnMode.FULL) {
            DnsGuardEngine.attach(this)
        }

        NativeEventBus.postProtectionStateChanged(mode.toEventString())

        workerThread = Thread({ packetLoop() }, "NC-PacketLoop").also { it.start() }
    }

    private var screenReceiver: android.content.BroadcastReceiver? = null

    private fun registerScreenReceiver() {
        if (screenReceiver != null) return
        val filter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        screenReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        RuleRepository.isScreenOn = true
                        configureVpn()
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        RuleRepository.isScreenOn = false
                        configureVpn()
                    }
                }
            }
        }
        try {
            registerReceiver(screenReceiver, filter)
        } catch (e: Exception) {
            Log.w(TAG, "Screen receiver setup failed: ${e.message}")
        }
    }

    private fun unregisterScreenReceiver() {
        screenReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
            screenReceiver = null
        }
    }

    private fun stopVpn(reason: String) {
        if (!running.getAndSet(false)) return
        Log.i(TAG, "Stopping VPN: $reason")

        workerThread?.interrupt()
        unregisterScreenReceiver()

        scope.coroutineContext.cancelChildren()
        tunWriteChannel.close()

        if (currentMode == VpnMode.FULL) {
            DnsGuardEngine.detach()
        }
        RuleRepository.clearSessionRules()

        try { tunInterface?.close() } catch (_: Exception) { }
        tunInterface = null
        currentMode = VpnMode.OFF

        persistProtectionState(VpnMode.OFF)
        NativeEventBus.postProtectionStateChanged(VpnMode.OFF.toEventString())
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    fun stopQuickBlockIfEmpty() {
        if (currentMode == VpnMode.QUICK_BLOCK && RuleRepository.isQuickBlockEmpty()) {
            stopVpn("Quick Block list empty")
        }
    }

    private fun persistProtectionState(mode: VpnMode) {
        getSharedPreferences(BootReceiver.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(BootReceiver.KEY_LAST_MODE, mode.name)
            .apply()
    }

    // ── Packet Processing Loop ────────────────────────────────────

    private fun packetLoop() {
        val tun    = tunInterface ?: return
        val input  = FileInputStream(tun.fileDescriptor)
        val output = FileOutputStream(tun.fileDescriptor)
        val buffer = ByteBuffer.allocate(32767)

        scope.launch {
            for (packet in tunWriteChannel) {
                try {
                    output.write(packet)
                } catch (e: Exception) {
                    if (running.get()) Log.w(TAG, "TUN write failed: ${e.message}")
                }
            }
        }

        Log.i(TAG, "Packet loop started (mode=${currentMode})")

        while (running.get() && !Thread.currentThread().isInterrupted) {
            try {
                buffer.clear()
                val bytes = input.read(buffer.array())
                if (bytes <= 0) continue

                buffer.limit(bytes)
                val packet = buffer.array().copyOf(bytes)

                processPacket(packet)
            } catch (e: InterruptedException) {
                break
            } catch (e: Exception) {
                if (running.get()) Log.w(TAG, "Packet error: ${e.message}")
            }
        }

        Log.i(TAG, "Packet loop stopped")
    }

    private fun processPacket(packet: ByteArray) {
        if (packet.size < 20) return

        val version = (packet[0].toInt() and 0xF0) shr 4
        if (version != 4 && version != 6) return

        val isIpv6 = (version == 6)
        val ihl = if (isIpv6) 40 else (packet[0].toInt() and 0x0F) * 4
        if (packet.size < ihl + 4) return

        val protocol = if (isIpv6) {
            packet[6].toInt() and 0xFF
        } else {
            packet[9].toInt() and 0xFF
        }

        val srcPort = when (protocol) {
            OsConstants.IPPROTO_TCP, OsConstants.IPPROTO_UDP ->
                ((packet[ihl].toInt() and 0xFF) shl 8) or (packet[ihl + 1].toInt() and 0xFF)
            else -> 0
        }
        val dstPort = when (protocol) {
            OsConstants.IPPROTO_TCP, OsConstants.IPPROTO_UDP ->
                ((packet[ihl + 2].toInt() and 0xFF) shl 8) or (packet[ihl + 3].toInt() and 0xFF)
            else -> 0
        }

        val srcIp = if (isIpv6) "IPv6-src" else formatIp(packet, 12)
        val dstIp = if (isIpv6) "IPv6-dst" else formatIp(packet, 16)

        val protocolStr = when (protocol) {
            OsConstants.IPPROTO_TCP  -> "TCP"
            OsConstants.IPPROTO_UDP  -> "UDP"
            OsConstants.IPPROTO_ICMP, 58 -> "ICMP"
            else                     -> "IP/$protocol"
        }

        val isLockdown = RuleRepository.isLockdownActive

        // UID lookup
        val uid = if (isIpv6) -1 else getConnectionOwnerUid(srcIp, srcPort, dstIp, dstPort, protocol)
        val appId = UidMapper.getAppId(this, uid)

        // Decision logic:
        // In Lockdown mode: Check allowlist.
        // In Normal mode: All packets in TUN belong to blocked apps (since configureVpn only added blocked apps).
        // Exceptions: VPN app itself ("com.networkcloak.network_cloak").
        val decision = if (isLockdown) {
            if (RuleRepository.isAppAllowedInLockdown(appId)) "allow" else "block"
        } else {
            if (appId == "com.networkcloak.network_cloak") "allow" else "block"
        }

        val debugLogEnabled = getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
            .getBoolean("debugLoggingEnabled", false)
        if (debugLogEnabled) {
            Log.d(TAG, "Packet: v=$version, proto=$protocolStr, app=$appId, src=$srcIp:$srcPort, dest=$dstIp:$dstPort, decision=$decision")
        }

        // ── DNS Interception (port 53 UDP) ───────────────────────────
        if (protocol == OsConstants.IPPROTO_UDP && dstPort == 53) {
            if (decision == "allow" && currentMode == VpnMode.FULL) {
                scope.launch {
                    DnsGuardEngine.interceptPacket(packet) { responsePacket ->
                        tunWriteChannel.trySend(responsePacket)
                    }
                }
                return
            } else {
                // Blocked app DNS query -> Return NXDOMAIN immediately for IPv4
                if (!isIpv6 && currentMode == VpnMode.FULL && packet.size > ihl + 8) {
                    val dnsPayload = packet.copyOfRange(ihl + 8, packet.size)
                    val nxPacket = DnsGuardEngine.buildNxdomainPacket(packet, ihl, dnsPayload)
                    tunWriteChannel.trySend(nxPacket)
                }
                return
            }
        }

        // ── Enforcement ──────────────────────────────────────────────
        if (decision == "allow") {
            if (protocol == OsConstants.IPPROTO_UDP && !isIpv6) {
                scope.launch {
                    forwardUdpPacket(packet, ihl, dstIp, dstPort)
                }
            } else if (!isIpv6 && protocol != OsConstants.IPPROTO_TCP) {
                tunWriteChannel.trySend(packet)
            }
        } else {
            // BLOCKED:
            // - IPv4 TCP gets TCP RST
            // - IPv6 TCP & all UDP (QUIC, HTTP3, Game UDP, Ads UDP) are DROPPED!
            if (protocol == OsConstants.IPPROTO_TCP && !isIpv6) {
                if (packet.size >= ihl + 20) {
                    try {
                        val rst = PacketUtils.buildTcpRst(packet, ihl)
                        tunWriteChannel.trySend(rst)
                    } catch (e: Exception) {
                        Log.w(TAG, "RST build failed: ${e.message}")
                    }
                }
            }
            // All UDP / ICMP / IPv6 packets for blocked apps are dropped silently here
        }

        // Post connection event to Watchtower
        NativeEventBus.postConnectionEvent(
            uid       = uid,
            appId     = appId,
            destHost  = dstIp,
            destIp    = dstIp,
            port      = dstPort,
            protocol  = protocolStr,
            bytes     = packet.size,
            allowed   = (decision == "allow"),
        )
    }

    /**
     * Forwards a UDP packet to the real internet via a protected DatagramSocket.
     *
     * protect() is called before send(). This is belt-and-suspenders alongside
     * addDisallowedApplication(): the firewall app's own UID is already excluded
     * from the tunnel at the routing level, but we keep protect() in case that
     * changes or a socket is opened through a different code path.
     */
    private fun forwardUdpPacket(packet: ByteArray, ihl: Int, dstIp: String, dstPort: Int) {
        try {
            val udpPayloadOffset = ihl + 8
            if (packet.size <= udpPayloadOffset) return
            val payload = packet.copyOfRange(udpPayloadOffset, packet.size)

            val socket = DatagramSocket()
            protect(socket)  // belt-and-suspenders (see above)
            val addr    = InetAddress.getByName(dstIp)
            socket.send(DatagramPacket(payload, payload.size, addr, dstPort))
            socket.close()
        } catch (e: Exception) {
            Log.w(TAG, "UDP forward failed: ${e.message}")
        }
    }

    // ── Helpers ───────────────────────────────────────────────────

    private fun formatIp(packet: ByteArray, offset: Int): String =
        "${packet[offset].toInt() and 0xFF}.${packet[offset+1].toInt() and 0xFF}." +
        "${packet[offset+2].toInt() and 0xFF}.${packet[offset+3].toInt() and 0xFF}"

    private fun getConnectionOwnerUid(
        srcIp: String, srcPort: Int, dstIp: String, dstPort: Int, proto: Int
    ): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return try {
                val local  = InetSocketAddress(InetAddress.getByName(srcIp), srcPort)
                val remote = InetSocketAddress(InetAddress.getByName(dstIp), dstPort)
                connectivityManager()?.getConnectionOwnerUid(proto, local, remote) ?: -1
            } catch (_: Exception) { -1 }
        }
        return -1
    }

    private fun connectivityManager() =
        getSystemService(CONNECTIVITY_SERVICE) as? android.net.ConnectivityManager

    // ── Notification ──────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Network Cloak Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when Network Cloak is protecting your connection"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val openIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Network Cloak is protecting you")
            .setContentText("Your connections are being monitored and filtered")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
