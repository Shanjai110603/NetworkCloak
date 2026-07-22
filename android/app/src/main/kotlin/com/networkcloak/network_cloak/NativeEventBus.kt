package com.networkcloak.network_cloak

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * In-process event bus from native components → PlatformChannelHandler.
 * Native services (VPN, ConnectivityMonitor, WatchtowerEngine) call
 * [post] to push typed events to Flutter.
 *
 * Also provides system notification posting for real Android-tray alerts (D5).
 */
object NativeEventBus {
    private const val TAG = "NC-EventBus"
    private const val ALERTS_CHANNEL_ID = "nc_alerts"
    private var nextNotificationId = 5000

    private var listener: ((Map<String, Any?>) -> Unit)? = null

    // Buffer for connection events (D1) to prevent EventChannel flooding
    private val connectionEventBuffer = java.util.Collections.synchronizedList(mutableListOf<Map<String, Any?>>())

    init {
        // Always-on 500ms ticker: flushes connection events when non-empty.
        // Overhead is negligible (<0.01% CPU) when buffer is empty because flushConnectionEvents()
        // immediately returns if connectionEventBuffer.isEmpty().
        CoroutineScope(Dispatchers.Default).launch {
            while (true) {
                delay(500)
                flushConnectionEvents()
            }
        }
    }

    private fun flushConnectionEvents() {
        val batch = synchronized(connectionEventBuffer) {
            if (connectionEventBuffer.isEmpty()) return
            val copy = ArrayList(connectionEventBuffer)
            connectionEventBuffer.clear()
            copy
        }
        post(mapOf(
            "type" to "ConnectionEventsBatch",
            "events" to batch
        ))
    }

    fun register(onEvent: (Map<String, Any?>) -> Unit) {
        listener = onEvent
    }

    fun unregister() {
        listener = null
    }

    /** Post a typed event. Always safe to call from any thread. */
    fun post(event: Map<String, Any?>) {
        listener?.invoke(event)
    }

    // ── Notification Channel Setup ────────────────────────────

    /**
     * Creates the nc_alerts notification channel for real system-tray alerts.
     * Must be called before postSystemNotification(). Safe to call multiple times.
     */
    fun createAlertsChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALERTS_CHANNEL_ID,
                "Security Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for security events, anomalies, and blocked threats"
                enableVibration(true)
                setShowBadge(true)
            }
            context.getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    // ── Typed helpers ────────────────────────────────────────

    fun postConnectionEvent(
        uid: Int,
        appId: String,
        destHost: String,
        destIp: String,
        port: Int,
        protocol: String,
        bytes: Int,
        allowed: Boolean,
    ) {
        synchronized(connectionEventBuffer) {
            if (connectionEventBuffer.size >= 500) {
                connectionEventBuffer.removeAt(0)
            }
            connectionEventBuffer.add(mapOf(
                "uid"       to uid,
                "appId"     to appId,
                "destHost"  to destHost,
                "destIp"    to destIp,
                "port"      to port,
                "protocol"  to protocol,
                "bytes"     to bytes,
                "allowed"   to allowed,
                "timestamp" to System.currentTimeMillis(),
            ))
        }
    }

    fun postNetworkChanged(
        trustLevel: String,
        ssid: String?,
        bssid: String?,
        authType: String?,
        isRoaming: Boolean,
        hasCaptivePortal: Boolean,
        isCellular: Boolean,
    ) {
        post(mapOf(
            "type"             to "NetworkChanged",
            "trustLevel"       to trustLevel,
            "ssid"             to ssid,
            "bssid"            to bssid,
            "authType"         to authType,
            "isRoaming"        to isRoaming,
            "hasCaptivePortal" to hasCaptivePortal,
            "isCellular"       to isCellular,
            "timestamp"        to System.currentTimeMillis(),
        ))
    }

    /**
     * Posts protection state change with tri-state VPN mode (D2).
     * @param mode one of "off", "quickBlockOnly", "full"
     */
    fun postProtectionStateChanged(mode: String) {
        post(mapOf(
            "type"     to "ProtectionStateChanged",
            "mode"     to mode,
            // Backward compat: isActive is true for any non-off mode
            "isActive" to (mode != "off"),
        ))
    }

    fun postAlert(
        alertType: String,
        severity: String,
        title: String,
        message: String,
        appId: String? = null,
    ) {
        post(mapOf(
            "type"      to "AlertFired",
            "alertType" to alertType,
            "severity"  to severity,
            "title"     to title,
            "message"   to message,
            "appId"     to appId,
            "timestamp" to System.currentTimeMillis(),
        ))
    }

    /**
     * Posts a real Android system notification to the nc_alerts channel (D5).
     * Only posts if alertNotificationsEnabled is true in SharedPreferences.
     * Call createAlertsChannel() once before using this.
     */
    fun postSystemNotification(
        context: Context,
        title: String,
        body: String,
        severity: String,
    ) {
        val prefs = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("alertNotificationsEnabled", true)) {
            Log.d(TAG, "System notification suppressed (user disabled)")
            return
        }

        val icon = when (severity) {
            "critical" -> android.R.drawable.ic_dialog_alert
            "warning"  -> android.R.drawable.ic_dialog_info
            else       -> android.R.drawable.ic_dialog_info
        }
        val priority = when (severity) {
            "critical" -> NotificationCompat.PRIORITY_HIGH
            "warning"  -> NotificationCompat.PRIORITY_DEFAULT
            else       -> NotificationCompat.PRIORITY_LOW
        }

        val notification = NotificationCompat.Builder(context, ALERTS_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(icon)
            .setPriority(priority)
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(nextNotificationId++, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification permission not granted: ${e.message}")
        }
    }

    fun postTempRuleExpired(ruleId: String, appId: String) {
        post(mapOf(
            "type"      to "TempRuleExpired",
            "ruleId"    to ruleId,
            "appId"     to appId,
            "timestamp" to System.currentTimeMillis(),
        ))
    }
}
