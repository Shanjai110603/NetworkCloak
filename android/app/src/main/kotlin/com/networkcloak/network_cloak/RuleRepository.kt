package com.networkcloak.network_cloak

import android.content.Context
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/**
 * In-memory rule cache and enforcement logic.
 *
 * All operations are thread-safe (called from both the VPN packet
 * processing thread and the Flutter method channel thread).
 */
object RuleRepository {

    // ── Lockdown state ───────────────────────────────────────
    @Volatile var isLockdownActive: Boolean = false
        private set

    private val lockdownAllowlist = CopyOnWriteArrayList<String>()

    // ── Rule caches (app_id → action string) ─────────────────
    private val manualRules = ConcurrentHashMap<String, String>()
    private val profileRules = ConcurrentHashMap<String, String>()
    private val globalRules = CopyOnWriteArrayList<Map<String, Any?>>()

    // ── Default action ────────────────────────────────────────
    @Volatile private var defaultAction: String = "ask"

    // ── API called from PlatformChannelHandler ────────────────

    fun updateRules(rules: List<Map<String, Any?>>) {
        manualRules.clear()
        profileRules.clear()
        globalRules.clear()

        for (rule in rules) {
            val appId = rule["appId"] as? String
            val action = rule["action"] as? String ?: "ask"
            val isGlobal = rule["isGlobal"] as? Boolean ?: false
            val priority = (rule["priority"] as? Int) ?: 7

            when {
                isGlobal -> globalRules.add(rule)
                appId != null && priority <= 4 -> manualRules[appId] = action
                appId != null -> profileRules[appId] = action
            }
        }
    }

    fun activateLockdown(allowlist: List<String>) {
        lockdownAllowlist.clear()
        lockdownAllowlist.addAll(allowlist)
        isLockdownActive = true
        NativeEventBus.postAlert(
            alertType = "lockdown_activated",
            severity = "warning",
            title = "Lockdown Active",
            message = "All connections are blocked except phone calls.",
        )
    }

    fun deactivateLockdown() {
        isLockdownActive = false
        lockdownAllowlist.clear()
    }

    fun isAppAllowedInLockdown(appId: String): Boolean {
        if (appId == "com.networkcloak.network_cloak") return true
        return lockdownAllowlist.contains(appId)
    }

    fun getBlockedAppIds(context: Context): List<String> {
        val blocked = mutableListOf<String>()
        val pm = context.packageManager
        val packages = pm.getInstalledPackages(0)
        
        for (pkg in packages) {
            val appId = pkg.packageName
            if (appId == "com.networkcloak.network_cloak") continue
            
            val action = evaluate(
                appId = appId,
                destIp = "",
                destPort = 0,
                protocol = "TCP",
                isBackground = false
            )
            if (action == "block") {
                blocked.add(appId)
            }
        }
        return blocked
    }

    // ── Core evaluation (called from VPN packet loop, <2µs target) ──

    /**
     * Returns "allow" or "block" for a given packet.
     * Follows the 7-priority hierarchy.
     */
    fun evaluate(
        appId: String,
        destIp: String,
        destPort: Int,
        protocol: String,
        isBackground: Boolean,
    ): String {
        // P1: Lockdown
        if (isLockdownActive) {
            return if (lockdownAllowlist.contains(appId)) "allow" else "block"
        }

        // P4: Manual app rules
        manualRules[appId]?.let { action ->
            return resolveAction(action, isBackground, destIp)
        }

        // P5: Profile rules
        profileRules[appId]?.let { action ->
            return resolveAction(action, isBackground, destIp)
        }

        // P6: Global rules
        for (rule in globalRules) {
            val action = rule["action"] as? String ?: continue
            return resolveAction(action, isBackground, destIp)
        }

        // P7: Default
        return if (defaultAction == "ask") "allow" else defaultAction
    }

    private fun resolveAction(action: String, isBackground: Boolean, destIp: String): String {
        return when (action) {
            "block", "temporaryBlock" -> "block"
            "allow", "temporaryAllow" -> "allow"
            "blockBackground" -> if (isBackground) "block" else "allow"
            "allowLanOnly" -> if (isLanAddress(destIp)) "allow" else "block"
            "allowInternetOnly" -> if (!isLanAddress(destIp)) "allow" else "block"
            "ask" -> "allow"  // Fail open during ask; popup handled by Watchtower
            else -> "allow"
        }
    }

    private fun isLanAddress(ip: String): Boolean {
        return ip.startsWith("192.168.") ||
                ip.startsWith("10.") ||
                (ip.startsWith("172.") && run {
                    val second = ip.split(".").getOrNull(1)?.toIntOrNull() ?: 0
                    second in 16..31
                })
    }
}
