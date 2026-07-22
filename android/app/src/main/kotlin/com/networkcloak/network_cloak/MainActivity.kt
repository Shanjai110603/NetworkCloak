package com.networkcloak.network_cloak

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Main Android Activity for Network Cloak.
 *
 * Handles Flutter engine initialization, platform channel registration,
 * and VpnService permission dialog result callbacks.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformChannelHandler.register(
            context = this,
            binaryMessenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    /**
     * Called when the system VPN permission dialog finishes.
     * Starts NetworkCloakVpnService safely as a foreground service on Android 8.0+.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1003 && resultCode == RESULT_OK) {
            // User approved the VPN permission dialog — start the foreground service!
            val intent = Intent(this, NetworkCloakVpnService::class.java).apply {
                putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_START)
            }
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }
}
