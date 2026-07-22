package com.networkcloak.network_cloak

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.net.VpnService
import android.util.Base64
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

/**
 * Bridges Flutter ? Android via two channels:
 *   com.networkcloak/commands  (MethodChannel)  � control commands from Flutter
 *   com.networkcloak/events    (EventChannel)   � async events to Flutter
 */
object PlatformChannelHandler {

    private const val METHOD_CHANNEL = "com.networkcloak/commands"
    private const val EVENT_CHANNEL  = "com.networkcloak/events"

    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    fun register(context: Context, binaryMessenger: BinaryMessenger) {
        // -- Method channel -----------------------------------
        MethodChannel(binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handleMethod(context, call, result)
        }

        // -- Event channel ------------------------------------
        EventChannel(binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Start forwarding native events to Flutter
                    NativeEventBus.register { event -> eventSink?.success(event) }
                }
                override fun onCancel(arguments: Any?) {
                    NativeEventBus.unregister()
                    eventSink = null
                }
            }
        )
    }

    private fun handleMethod(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startFirewall" -> {
                val activity = context as? android.app.Activity
                
                // 1. Request POST_NOTIFICATIONS at runtime on Android 13+ (API 33+)
                if (android.os.Build.VERSION.SDK_INT >= 33 &&
                    context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
                ) {
                    activity?.requestPermissions(
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                        1002
                    )
                }

                // 2. Prepare VpnService dialog if not already authorized
                val vpnIntent = VpnService.prepare(context)
                if (vpnIntent != null) {
                    activity?.startActivityForResult(vpnIntent, 1003)
                    result.success(false) // Not started yet, waiting for result callback in MainActivity
                } else {
                    val intent = Intent(context, NetworkCloakVpnService::class.java).apply {
                        putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_START)
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        context.startForegroundService(intent)
                    } else {
                        context.startService(intent)
                    }
                    result.success(true)
                }
            }
            "stopFirewall" -> {
                val reason = call.argument<String>("reason") ?: "User stopped"
                val intent = Intent(context, NetworkCloakVpnService::class.java)
                    .putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_STOP)
                    .putExtra("reason", reason)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                result.success(null)
            }
            "updateRules" -> {
                @Suppress("UNCHECKED_CAST")
                val rules = call.argument<List<Map<String, Any?>>>("rules") ?: emptyList()
                RuleRepository.updateRules(rules)
                // Read blockLan flag from the call and apply it (D4)
                val blockLan = call.argument<Boolean>("blockLan") ?: false
                RuleRepository.blockLanTraffic = blockLan
                // Update lastKnownContext so conditionsMatch() stays current
                updateRuleContext(context)
                refreshVpnService(context)
                result.success(null)
            }
            "activateLockdown" -> {
                @Suppress("UNCHECKED_CAST")
                val allowlist = call.argument<List<String>>("allowlist") ?: emptyList()
                RuleRepository.activateLockdown(allowlist)
                refreshVpnService(context)
                result.success(null)
            }
            "deactivateLockdown" -> {
                RuleRepository.deactivateLockdown()
                refreshVpnService(context)
                result.success(null)
            }
            "getNetworkInfo" -> {
                scope.launch {
                    val info = ConnectivityMonitor.getCurrentNetworkInfo(context)
                    result.success(info)
                }
            }
            "getStatus" -> {
                result.success(mapOf(
                    "isRunning" to NetworkCloakVpnService.isRunning,
                    "mode"      to NetworkCloakVpnService.currentMode.toEventString(),
                    "isLockdown" to RuleRepository.isLockdownActive,
                ))
            }
            "setDnsProfile" -> {
                val profile = call.arguments<Map<String, Any?>>() ?: emptyMap()
                DnsGuardEngine.setProfile(profile)
                result.success(null)
            }
            "updateBlocklists" -> {
                @Suppress("UNCHECKED_CAST")
                val lists = call.argument<List<Map<String, Any?>>>("lists") ?: emptyList()
                DnsGuardEngine.updateBlocklists(lists)
                result.success(null)
            }
            "updateQuickBlock" -> {
                @Suppress("UNCHECKED_CAST")
                val apps = call.argument<List<String>>("apps") ?: emptyList()
                RuleRepository.updateQuickBlockList(apps)
                // If VPN is running, refresh config
                refreshVpnService(context)
                result.success(null)
            }
            "startQuickBlock" -> {
                // If full protection is already running, just update the list
                if (NetworkCloakVpnService.currentMode == NetworkCloakVpnService.VpnMode.FULL) {
                    result.success(true)
                    return
                }
                // Start VPN in Quick Block mode
                val vpnIntent = VpnService.prepare(context)
                if (vpnIntent != null) {
                    val activity = context as? android.app.Activity
                    activity?.startActivityForResult(vpnIntent, 1003)
                    result.success(false)
                } else {
                    val intent = Intent(context, NetworkCloakVpnService::class.java).apply {
                        putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_START_QUICK_BLOCK)
                    }
                    context.startService(intent)
                    result.success(true)
                }
            }
            "setAlertNotificationsEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean("alertNotificationsEnabled", enabled)
                    .apply()
                result.success(null)
            }
            "getAlertNotificationsEnabled" -> {
                val enabled = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .getBoolean("alertNotificationsEnabled", true)
                result.success(enabled)
            }
            "setRetentionDays" -> {
                val days = call.argument<Int>("days") ?: 30
                context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .edit()
                    .putInt("retentionDays", days)
                    .apply()
                result.success(null)
            }
            "getRetentionDays" -> {
                val days = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .getInt("retentionDays", 30)
                result.success(days)
            }
            "setSecurityRiskIndicatorsEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean("showSecurityRiskIndicators", enabled)
                    .apply()
                result.success(null)
            }
            "getSecurityRiskIndicatorsEnabled" -> {
                val enabled = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .getBoolean("showSecurityRiskIndicators", true)
                result.success(enabled)
            }
            "setDebugLoggingEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean("debugLoggingEnabled", enabled)
                    .apply()
                result.success(null)
            }
            "getDebugLoggingEnabled" -> {
                val enabled = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .getBoolean("debugLoggingEnabled", false)
                result.success(enabled)
            }
            "setCloakEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean("cloakEnabled", enabled)
                    .apply()
                RuleRepository.cloakEnabled = enabled
                refreshVpnService(context)
                result.success(null)
            }
            "getCloakEnabled" -> {
                val enabled = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .getBoolean("cloakEnabled", false)
                RuleRepository.cloakEnabled = enabled
                result.success(enabled)
            }
            "setThemeLightEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean("themeLightEnabled", enabled)
                    .apply()
                result.success(null)
            }
            "getThemeLightEnabled" -> {
                val enabled = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                    .getBoolean("themeLightEnabled", false)
                result.success(enabled)
            }
            "getInstalledApps" -> {
                // Runs on IO � PackageManager is blocking.
                // Returns ALL installed apps (user + relevant system) with:
                //   packageName, displayName, version, isSystem, iconBase64 (PNG),
                //   and (if showSecurityRiskIndicators == true): riskScore, riskLevel, riskReasons.
                scope.launch(Dispatchers.IO) {
                    try {
                        val pm = context.packageManager
                        val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                            PackageManager.GET_META_DATA
                        } else {
                            PackageManager.GET_META_DATA
                        }
                        val apps = pm.getInstalledApplications(flags)

                        val prefs = context.getSharedPreferences("nc_settings", Context.MODE_PRIVATE)
                        val showRisk = prefs.getBoolean("showSecurityRiskIndicators", true)

                        val list = mutableListOf<Map<String, Any?>>()
                        for (app in apps) {
                            // Skip our own package to avoid recursive rules
                            if (app.packageName == context.packageName) continue

                            val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                            // Try to get icon as base64 PNG; null if it fails
                            val iconBase64 = try {
                                val drawable = pm.getApplicationIcon(app.packageName)
                                drawableToPngBase64(drawable)
                            } catch (_: Exception) { null }

                            val versionName = try {
                                pm.getPackageInfo(app.packageName, 0).versionName
                            } catch (_: Exception) { null }

                            val appMap = mutableMapOf<String, Any?>(
                                "packageName"  to app.packageName,
                                "displayName"  to (pm.getApplicationLabel(app).toString()),
                                "version"      to versionName,
                                "isSystem"     to isSystem,
                                "iconBase64"   to iconBase64
                            )

                            // Evaluate security risks only if enabled via feature flag
                            if (showRisk) {
                                val report = AppRiskHeuristics.evaluate(context, app)
                                appMap["riskScore"] = report.score
                                appMap["riskLevel"] = report.level
                                appMap["riskReasons"] = report.reasons
                            }

                            list.add(appMap)
                        }

                        // Sort: user apps first, then alphabetically by displayName
                        val sorted = list.sortedWith(
                            compareBy<Map<String, Any?>> { it["isSystem"] as? Boolean == true }
                                .thenBy { (it["displayName"] as? String)?.lowercase() ?: "" }
                        )

                        withContext(Dispatchers.Main) {
                            result.success(sorted)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("GET_APPS_FAILED", e.message, null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun updateRuleContext(context: Context) {
        scope.launch(kotlinx.coroutines.Dispatchers.IO) {
            try {
                val info = ConnectivityMonitor.getCurrentNetworkInfo(context)
                val hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
                val netType = when {
                    info["isCellular"] as? Boolean == true -> "cellular"
                    info["ssid"] != null                  -> "wifi"
                    else                                   -> "unknown"
                }
                RuleRepository.lastKnownContext = RuleContext(
                    networkType = netType,
                    trustLevel  = info["trustLevel"] as? String ?: "unknown",
                    currentHour = hour,
                )
            } catch (_: Exception) { }
        }
    }

    private fun refreshVpnService(context: Context) {
        if (NetworkCloakVpnService.isRunning) {
            val intent = Intent(context, NetworkCloakVpnService::class.java)
                .putExtra(NetworkCloakVpnService.ACTION_KEY, "refresh")
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    /** Converts any Drawable to a base64-encoded PNG byte string for the platform channel. */
    private fun drawableToPngBase64(drawable: android.graphics.drawable.Drawable): String {
        val size = 96 // 96�96 px is sufficient for list tiles
        val bmp = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        } else {
            val bmp2 = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp2)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp2
        }
        val baos = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, baos)
        return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
    }

    /** Called from native code to push an event to Flutter. */
    fun pushEvent(event: Map<String, Any?>) {
        scope.launch { eventSink?.success(event) }
    }
}
