package com.networkcloak.network_cloak

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformChannelHandler.register(
            context = this,
            binaryMessenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }
}
