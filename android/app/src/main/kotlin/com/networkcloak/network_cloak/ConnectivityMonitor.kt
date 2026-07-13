package com.networkcloak.network_cloak

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.telephony.TelephonyManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Monitors connectivity changes and classifies each network event
 * into a trust level using the 10-signal hierarchy.
 */
object ConnectivityMonitor {

    private var registered = false

    fun start(context: Context) {
        if (registered) return
        registered = true

        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        cm.registerNetworkCallback(request, object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                CoroutineScope(Dispatchers.IO).launch {
                    val info = getCurrentNetworkInfo(context)
                    NativeEventBus.postNetworkChanged(
                        trustLevel = info["trustLevel"] as? String ?: "unknown",
                        ssid       = info["ssid"] as? String,
                        bssid      = info["bssid"] as? String,
                        authType   = info["authType"] as? String,
                        isRoaming  = info["isRoaming"] as? Boolean ?: false,
                        hasCaptivePortal = info["hasCaptivePortal"] as? Boolean ?: false,
                        isCellular = info["isCellular"] as? Boolean ?: false,
                    )
                }
            }

            override fun onLost(network: Network) {
                NativeEventBus.postNetworkChanged(
                    trustLevel = "unknown",
                    ssid = null,
                    bssid = null,
                    authType = null,
                    isRoaming = false,
                    hasCaptivePortal = false,
                    isCellular = false,
                )
            }
        })
    }

    /**
     * Returns a Map with all 10 network classification signals.
     * Safe to call from any thread.
     */
    fun getCurrentNetworkInfo(context: Context): Map<String, Any?> {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = cm.activeNetwork
        val caps = cm.getNetworkCapabilities(activeNetwork)

        val isCellular = caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ?: false
        val isWifi     = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ?: false

        var ssid: String? = null
        var bssid: String? = null
        var authType: String? = null
        var isRoaming = false

        if (isCellular) {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            isRoaming = tm.isNetworkRoaming
        }

        if (isWifi) {
            @Suppress("DEPRECATION")
            val wm = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = try {
                @Suppress("DEPRECATION")
                wm.connectionInfo
            } catch (_: Exception) { null }

            ssid = wifiInfo?.ssid?.trim('"')
            bssid = wifiInfo?.bssid
            authType = detectAuthType()
        }

        val hasCaptivePortal = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL) ?: false
        val trustLevel = classifyTrust(
            isCellular = isCellular,
            ssid = ssid,
            bssid = bssid,
            authType = authType,
            isRoaming = isRoaming,
            hasCaptivePortal = hasCaptivePortal,
        )

        return mapOf(
            "trustLevel"       to trustLevel,
            "ssid"             to ssid,
            "bssid"            to bssid,
            "authType"         to authType,
            "isRoaming"        to isRoaming,
            "hasCaptivePortal" to hasCaptivePortal,
            "isCellular"       to isCellular,
        )
    }

    private fun classifyTrust(
        isCellular: Boolean,
        ssid: String?,
        bssid: String?,
        authType: String?,
        isRoaming: Boolean,
        hasCaptivePortal: Boolean,
    ): String {
        if (isCellular) return "trusted"
        if (authType == null || authType == "open") return "public"
        if (authType.contains("WEP", ignoreCase = true)) return "public"
        if (authType.contains("TKIP", ignoreCase = true)) return "public"
        if (hasCaptivePortal) return "unknown"
        if (isRoaming) return "unknown"
        return "unknown"  // Unknown until user explicitly trusts it
    }

    private fun detectAuthType(): String? {
        // On Android 10+ we can't easily get security type without location permission.
        // Return null to trigger "unknown" classification — safe default.
        return null
    }
}
