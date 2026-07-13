package com.networkcloak.network_cloak

/**
 * In-process event bus from native components → PlatformChannelHandler.
 * Native services (VPN, ConnectivityMonitor, WatchtowerEngine) call
 * [post] to push typed events to Flutter.
 */
object NativeEventBus {
    private var listener: ((Map<String, Any?>) -> Unit)? = null

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
        post(mapOf(
            "type"      to "ConnectionEvent",
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

    fun postProtectionStateChanged(isActive: Boolean) {
        post(mapOf(
            "type"     to "ProtectionStateChanged",
            "isActive" to isActive,
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

    fun postTempRuleExpired(ruleId: String, appId: String) {
        post(mapOf(
            "type"      to "TempRuleExpired",
            "ruleId"    to ruleId,
            "appId"     to appId,
            "timestamp" to System.currentTimeMillis(),
        ))
    }
}
