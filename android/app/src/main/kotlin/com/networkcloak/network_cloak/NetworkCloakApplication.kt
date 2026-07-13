package com.networkcloak.network_cloak

import android.app.Application

/**
 * Custom Application class.
 *
 * Starts ConnectivityMonitor here rather than in MainActivity so that
 * network-change callbacks keep firing when the Activity is destroyed
 * while the VPN foreground service continues running — the normal
 * usage pattern once the user backgrounds the app.
 *
 * Starting from MainActivity.configureFlutterEngine() would tie the
 * network callback to Activity lifecycle and could cause double-
 * registration on engine caching / re-attachment.
 */
class NetworkCloakApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ConnectivityMonitor.start(this)
    }
}
