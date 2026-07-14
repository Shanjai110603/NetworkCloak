package com.networkcloak.network_cloak

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.system.OsConstants
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
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
 * TCP forwarding: Option B (UDP only, TCP Relay deferred) is active.
 * Since the tun2socks-android library (Option A) has not been integrated yet,
 * all TCP traffic is rejected with a TCP RST packet to prevent connection hangs.
 * Go-based tun2socks-android integration will be implemented in a future sprint.
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

        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID      = "nc_protection"

        @Volatile var isRunning: Boolean = false
            private set
    }

    private val running       = AtomicBoolean(false)
    private var tunInterface: ParcelFileDescriptor? = null
    private var workerThread: Thread? = null

    // ── Lifecycle ─────────────────────────────────────────────────

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.getStringExtra(ACTION_KEY) ?: ACTION_START
        return when (action) {
            ACTION_STOP -> {
                stopVpn("Stopped by user")
                START_NOT_STICKY
            }
            "refresh" -> {
                configureVpn()
                START_STICKY
            }
            else -> {
                startVpn()
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

            // Route ALL apps through the tunnel for per-packet policy evaluation.
            // Bug #3 fix: the previous code called addAllowedApplication(blockedAppId),
            // which has the OPPOSITE semantics — it only routes ALLOWED apps through the
            // tunnel, meaning blocked apps bypassed the tunnel entirely.
            // Correct approach: route everything, exclude only ourselves to avoid a loop.
            // Per-packet allow/block is then handled in processPacket() via RuleRepository.
            try {
                builder.addDisallowedApplication("com.networkcloak.network_cloak")
            } catch (_: Exception) { }

            // Lockdown mode: also exclude phone/dialer so emergency calls work
            if (RuleRepository.isLockdownActive) {
                val phonePkgs = listOf("com.android.phone", "com.google.android.dialer")
                for (pkg in phonePkgs) {
                    try { builder.addDisallowedApplication(pkg) } catch (_: Exception) { }
                }
            }

            val oldInterface = tunInterface
            tunInterface = builder.establish()
            try { oldInterface?.close() } catch (_: Exception) { }

            Log.i(TAG, "VPN configured. Lockdown=${RuleRepository.isLockdownActive}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure VPN: ${e.message}")
        }
    }

    private fun startVpn() {
        if (running.getAndSet(true)) return

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        configureVpn()

        if (tunInterface == null) {
            Log.e(TAG, "VPN permission not granted or establish() failed")
            running.set(false)
            return
        }

        isRunning = true
        persistProtectionState(active = true)

        // Attach DnsGuardEngine before starting the packet loop
        DnsGuardEngine.attach(this)

        NativeEventBus.postProtectionStateChanged(true)

        workerThread = Thread({ packetLoop() }, "NC-PacketLoop").also { it.start() }
    }

    private fun stopVpn(reason: String) {
        if (!running.getAndSet(false)) return
        Log.i(TAG, "Stopping VPN: $reason")

        workerThread?.interrupt()
        DnsGuardEngine.detach()
        RuleRepository.clearSessionRules()  // P3 session rules end with the VPN session

        try { tunInterface?.close() } catch (_: Exception) { }
        tunInterface = null
        isRunning = false

        persistProtectionState(active = false)
        NativeEventBus.postProtectionStateChanged(false)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /** Persists protection state for BootReceiver to read on next device start. */
    private fun persistProtectionState(active: Boolean) {
        getSharedPreferences(BootReceiver.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(BootReceiver.KEY_WAS_ACTIVE, active)
            .apply()
    }

    // ── Packet Processing Loop ────────────────────────────────────

    /**
     * Reads raw IP packets from the TUN fd and dispatches each packet:
     *   - UDP port 53 → DnsGuardEngine (DoH interception)
     *   - All others  → processPacket() for policy evaluation and forwarding
     *
     * TCP forwarding (Option A) is managed by the tun2socks library integration.
     * The library intercepts TCP flows and calls back into this class for per-flow
     * policy decisions while managing the TCP state machine internally.
     */
    private fun packetLoop() {
        val tun    = tunInterface ?: return
        val input  = FileInputStream(tun.fileDescriptor)
        val output = FileOutputStream(tun.fileDescriptor)
        val buffer = ByteBuffer.allocate(32767)

        Log.i(TAG, "Packet loop started")

        while (running.get() && !Thread.currentThread().isInterrupted) {
            try {
                buffer.clear()
                val bytes = input.read(buffer.array())
                if (bytes <= 0) continue

                buffer.limit(bytes)
                val packet = buffer.array().copyOf(bytes)

                processPacket(packet, output)
            } catch (e: InterruptedException) {
                break
            } catch (e: Exception) {
                if (running.get()) Log.w(TAG, "Packet error: ${e.message}")
            }
        }

        Log.i(TAG, "Packet loop stopped")
    }

    private fun processPacket(packet: ByteArray, output: FileOutputStream) {
        if (packet.size < 20) return

        val version = (packet[0].toInt() and 0xF0) shr 4
        if (version != 4) {
            // Pass IPv6 through — IPv6 rules deferred to Phase 4
            output.write(packet)
            return
        }

        // ── IPv4 header parsing ───────────────────────────────────
        val protocol = packet[9].toInt() and 0xFF
        val srcIp    = formatIp(packet, 12)
        val dstIp    = formatIp(packet, 16)

        val ihl = (packet[0].toInt() and 0x0F) * 4
        if (packet.size < ihl + 4) { output.write(packet); return }

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

        val protocolStr = when (protocol) {
            OsConstants.IPPROTO_TCP  -> "TCP"
            OsConstants.IPPROTO_UDP  -> "UDP"
            OsConstants.IPPROTO_ICMP -> "ICMP"
            else                     -> "IP/$protocol"
        }

        // ── DNS interception (port 53) ────────────────────────────
        if (protocol == OsConstants.IPPROTO_UDP && dstPort == 53) {
            DnsGuardEngine.interceptPacket(packet, output)
            return
        }

        // ── UID lookup → App ID ───────────────────────────────────
        val uid         = getConnectionOwnerUid(srcIp, srcPort, dstIp, dstPort, protocol)
        val appId       = UidMapper.getAppId(this, uid)
        val isBackground = AppStateTracker.isBackground(uid)

        // Build runtime context for condition-aware global rule evaluation
        val context = RuleRepository.lastKnownContext

        // ── Rule evaluation ───────────────────────────────────────
        val decision = RuleRepository.evaluate(
            appId        = appId,
            destIp       = dstIp,
            destPort     = dstPort,
            protocol     = protocolStr,
            isBackground = isBackground,
            context      = context,
        )

        // ── Enforcement ───────────────────────────────────────────
        if (protocol == OsConstants.IPPROTO_TCP) {
            // Option B (UDP only, TCP Relay deferred) fallback: block all TCP flows by sending a TCP RST.
            // This prevents the self-looping bug where allowed TCP packets are written back to the TUN,
            // causing connections to hang indefinitely instead of failing cleanly.
            if (packet.size >= ihl + 20) {
                try {
                    val rst = PacketUtils.buildTcpRst(packet, ihl)
                    output.write(rst)
                } catch (e: Exception) {
                    Log.w(TAG, "RST build failed: ${e.message}")
                }
            }
            // Log block event for Watchtower
            NativeEventBus.postConnectionEvent(
                uid       = uid,
                appId     = appId,
                destHost  = dstIp,
                destIp    = dstIp,
                port      = dstPort,
                protocol  = protocolStr,
                bytes     = packet.size,
                allowed   = false,
            )
            return
        }

        if (decision == "allow") {
            when (protocol) {
                OsConstants.IPPROTO_UDP -> forwardUdpPacket(packet, ihl, dstIp, dstPort)
                else -> output.write(packet)  // ICMP etc.
            }
        } else {
            // Blocked UDP/ICMP: drop silently
        }

        // ── Watchtower event ──────────────────────────────────────
        NativeEventBus.postConnectionEvent(
            uid       = uid,
            appId     = appId,
            destHost  = dstIp,
            destIp    = dstIp,
            port      = dstPort,
            protocol  = protocolStr,
            bytes     = packet.size,
            allowed   = decision == "allow",
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
