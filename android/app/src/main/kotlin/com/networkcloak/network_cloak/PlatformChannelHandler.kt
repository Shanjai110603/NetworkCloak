package com.networkcloak.network_cloak

import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Bridges Flutter ↔ Android via two channels:
 *   com.networkcloak/commands  (MethodChannel)  — control commands from Flutter
 *   com.networkcloak/events    (EventChannel)   — async events to Flutter
 */
object PlatformChannelHandler {

    private const val METHOD_CHANNEL = "com.networkcloak/commands"
    private const val EVENT_CHANNEL  = "com.networkcloak/events"

    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    fun register(context: Context, binaryMessenger: BinaryMessenger) {
        // ── Method channel ───────────────────────────────────
        MethodChannel(binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            handleMethod(context, call, result)
        }

        // ── Event channel ────────────────────────────────────
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
                val intent = Intent(context, NetworkCloakVpnService::class.java)
                    .putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_START)
                context.startService(intent)
                result.success(null)
            }
            "stopFirewall" -> {
                val reason = call.argument<String>("reason") ?: "User stopped"
                val intent = Intent(context, NetworkCloakVpnService::class.java)
                    .putExtra(NetworkCloakVpnService.ACTION_KEY, NetworkCloakVpnService.ACTION_STOP)
                    .putExtra("reason", reason)
                context.startService(intent)
                result.success(null)
            }
            "updateRules" -> {
                @Suppress("UNCHECKED_CAST")
                val rules = call.argument<List<Map<String, Any?>>>("rules") ?: emptyList()
                RuleRepository.updateRules(rules)
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
            else -> result.notImplemented()
        }
    }

    private fun refreshVpnService(context: Context) {
        if (NetworkCloakVpnService.isRunning) {
            val intent = Intent(context, NetworkCloakVpnService::class.java)
                .putExtra(NetworkCloakVpnService.ACTION_KEY, "refresh")
            context.startService(intent)
        }
    }

    /** Called from native code to push an event to Flutter. */
    fun pushEvent(event: Map<String, Any?>) {
        scope.launch { eventSink?.success(event) }
    }
}
