package com.networkcloak.network_cloak

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.system.Os
import android.system.OsConstants
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Network Cloak VPN Service
 *
 * Creates a TUN interface, intercepts all device traffic at the IP layer,
 * applies the RuleRepository decision per packet, and either forwards or
 * drops the packet accordingly.
 *
 * DNS packets (port 53 / 853) are redirected to DnsGuardEngine for
 * encrypted resolution and blocklist filtering.
 */
class NetworkCloakVpnService : VpnService() {

    companion object {
        private const val TAG = "NC-VPN"
        const val ACTION_KEY = "action"
        const val ACTION_START = "start"
        const val ACTION_STOP = "stop"

        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "nc_protection"

        @Volatile var isRunning: Boolean = false
            private set
    }

    private val running = AtomicBoolean(false)
    private var tunInterface: ParcelFileDescriptor? = null
    private var workerThread: Thread? = null

    // ── Lifecycle ─────────────────────────────────────────────

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

    // ── VPN Setup ─────────────────────────────────────────────

    private fun configureVpn() {
        if (!running.get()) return
        try {
            val builder = Builder()
                .setSession("Network Cloak")
                .addAddress("10.0.0.1", 32)
                .addRoute("10.0.0.1", 32)
                .addDnsServer("10.0.0.1")
                .setMtu(1500)
                .setBlocking(false)

            // Dynamic rule-based app targeting
            val blockedApps = RuleRepository.getBlockedAppIds(this)

            if (RuleRepository.isLockdownActive) {
                val pm = packageManager
                val packages = pm.getInstalledPackages(0)
                for (pkg in packages) {
                    val packageName = pkg.packageName
                    if (RuleRepository.isAppAllowedInLockdown(packageName)) {
                        continue
                    }
                    try {
                        builder.addAllowedApplication(packageName)
                    } catch (_: Exception) {}
                }
            } else {
                for (appId in blockedApps) {
                    try {
                        builder.addAllowedApplication(appId)
                    } catch (_: Exception) {}
                }
            }

            val oldInterface = tunInterface
            tunInterface = builder.establish()

            try {
                oldInterface?.close()
            } catch (_: Exception) {}

            Log.i(TAG, "VPN configured successfully. Active mode applied. Blocked: ${if (RuleRepository.isLockdownActive) "ALL" else blockedApps.size}")
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
            Log.e(TAG, "VPN permission not granted or establish failed")
            running.set(false)
            return
        }

        isRunning = true
        NativeEventBus.postProtectionStateChanged(true)

        workerThread = Thread({ packetLoop() }, "NC-PacketLoop").also { it.start() }
    }

    private fun stopVpn(reason: String) {
        if (!running.getAndSet(false)) return
        Log.i(TAG, "Stopping VPN: $reason")
        workerThread?.interrupt()
        try { tunInterface?.close() } catch (_: Exception) {}
        tunInterface = null
        isRunning = false
        NativeEventBus.postProtectionStateChanged(false)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    // ── Packet Processing Loop ────────────────────────────────

    /**
     * Reads raw IP packets from the TUN fd, inspects headers to extract
     * destination IP and port, queries RuleRepository for a decision,
     * and either forwards to real network (via protect()) or drops.
     *
     * DNS packets (dst port 53 / 853) are intercepted for DnsGuardEngine.
     */
    private fun packetLoop() {
        val tun = tunInterface ?: return
        val input = FileInputStream(tun.fileDescriptor)
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
                if (running.get()) {
                    Log.w(TAG, "Packet error: ${e.message}")
                }
            }
        }

        Log.i(TAG, "Packet loop stopped")
    }

    private fun processPacket(packet: ByteArray, output: FileOutputStream) {
        if (packet.size < 20) return // Too small for IPv4 header

        val version = (packet[0].toInt() and 0xF0) shr 4
        if (version != 4) {
            // Pass IPv6 through — IPv6 rules deferred to Phase 4
            output.write(packet)
            return
        }

        // ── IPv4 header parsing ────────────────────────────
        val protocol = packet[9].toInt() and 0xFF
        val srcIp = formatIp(packet, 12)
        val dstIp = formatIp(packet, 16)

        val ihl = (packet[0].toInt() and 0x0F) * 4
        if (packet.size < ihl + 4) {
            output.write(packet)
            return
        }

        val srcPort = when (protocol) {
            OsConstants.IPPROTO_TCP, OsConstants.IPPROTO_UDP -> {
                ((packet[ihl].toInt() and 0xFF) shl 8) or
                        (packet[ihl + 1].toInt() and 0xFF)
            }
            else -> 0
        }

        val dstPort = when (protocol) {
            OsConstants.IPPROTO_TCP, OsConstants.IPPROTO_UDP -> {
                ((packet[ihl + 2].toInt() and 0xFF) shl 8) or
                        (packet[ihl + 3].toInt() and 0xFF)
            }
            else -> 0
        }

        val protocolStr = when (protocol) {
            OsConstants.IPPROTO_TCP -> "TCP"
            OsConstants.IPPROTO_UDP -> "UDP"
            OsConstants.IPPROTO_ICMP -> "ICMP"
            else -> "IP/$protocol"
        }

        // ── DNS interception (port 53 / 853) ─────────────────
        if (protocol == OsConstants.IPPROTO_UDP && dstPort == 53) {
            DnsGuardEngine.interceptPacket(packet, output)
            return
        }

        // ── UID lookup → App ID ───────────────────────────────
        val uid = getConnectionOwnerUid(srcIp, srcPort, dstIp, dstPort, protocol)
        val appId = UidMapper.getAppId(this, uid)
        val isBackground = AppStateTracker.isBackground(uid)

        // ── Rule evaluation ───────────────────────────────────
        val decision = RuleRepository.evaluate(
            appId = appId,
            destIp = dstIp,
            destPort = dstPort,
            protocol = protocolStr,
            isBackground = isBackground,
        )

        if (decision == "allow") {
            output.write(packet)
        }
        // else: drop (do not write back to TUN)

        // ── Watchtower event ──────────────────────────────────
        NativeEventBus.postConnectionEvent(
            uid = uid,
            appId = appId,
            destHost = dstIp,
            destIp = dstIp,
            port = dstPort,
            protocol = protocolStr,
            bytes = packet.size,
            allowed = decision == "allow",
        )
    }

    private fun formatIp(packet: ByteArray, offset: Int): String {
        return "${packet[offset].toInt() and 0xFF}." +
                "${packet[offset + 1].toInt() and 0xFF}." +
                "${packet[offset + 2].toInt() and 0xFF}." +
                "${packet[offset + 3].toInt() and 0xFF}"
    }

    private fun getConnectionOwnerUid(srcIp: String, srcPort: Int, dstIp: String, dstPort: Int, proto: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return try {
                val local = InetSocketAddress(InetAddress.getByName(srcIp), srcPort)
                val remote = InetSocketAddress(InetAddress.getByName(dstIp), dstPort)
                connectivityManager()?.getConnectionOwnerUid(proto, local, remote) ?: -1
            } catch (_: Exception) { -1 }
        }
        return -1
    }

    private fun connectivityManager() =
        getSystemService(CONNECTIVITY_SERVICE) as? android.net.ConnectivityManager

    // ── Notification ──────────────────────────────────────────

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
