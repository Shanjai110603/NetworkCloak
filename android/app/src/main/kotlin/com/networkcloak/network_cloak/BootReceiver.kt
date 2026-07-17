package com.networkcloak.network_cloak

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Boot Receiver — auto-restarts the VPN if it was active before shutdown.
 *
 * The receiver is declared with android:exported="false" in the manifest.
 * BOOT_COMPLETED is a protected system broadcast; Android delivers it to
 * receivers regardless of the exported flag, so false reduces attack surface
 * without any functional cost.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastMode = prefs.getString(KEY_LAST_MODE, null) ?: return

        when (lastMode) {
            "FULL" -> {
                val serviceIntent = Intent(context, NetworkCloakVpnService::class.java)
                    .putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_START)
                context.startForegroundService(serviceIntent)
            }
            "QUICK_BLOCK" -> {
                val serviceIntent = Intent(context, NetworkCloakVpnService::class.java)
                    .putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_START_QUICK_BLOCK)
                context.startForegroundService(serviceIntent)
            }
        }
    }

    companion object {
        const val PREFS_NAME = "nc_prefs"
        const val KEY_LAST_MODE = "last_vpn_mode"
    }
}
