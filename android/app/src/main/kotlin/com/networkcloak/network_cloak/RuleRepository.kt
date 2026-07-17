package com.networkcloak.network_cloak

import android.content.Context
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

// ── Data classes ──────────────────────────────────────────────────────────────

/**
 * A rule with a finite active window. Evaluated at P2 (highest non-lockdown tier).
 * Expired rules are skipped in evaluate() and cleaned up by WorkManager.
 *
 * Session rules are intentionally in-memory only (Map<String,String>).
 * They are defined as "active for the duration of one VPN session"; a process
 * death (crash or OOM kill) ends the session — no crash-recovery logic needed.
 */
data class TemporaryRule(
    val id: String,
    val appId: String,
    val action: String,
    val startAt: Long,         // epoch ms
    val endAt: Long,           // epoch ms; rule is skipped if now > endAt
    val previousRuleId: String?,
) {
    companion object {
        fun from(rule: Map<String, Any?>): TemporaryRule? {
            val id    = rule["id"]    as? String ?: return null
            val appId = rule["appId"] as? String ?: return null
            return TemporaryRule(
                id             = id,
                appId          = appId,
                action         = rule["action"] as? String ?: "ask",
                startAt        = (rule["startAt"] as? Long)  ?: System.currentTimeMillis(),
                endAt          = (rule["endAt"]   as? Long)  ?: Long.MAX_VALUE,
                previousRuleId = rule["previousRuleId"] as? String,
            )
        }
    }
}

/** Parsed conditions attached to a global rule. All fields are optional (null = wildcard). */
data class RuleConditions(
    val networkType: String?,  // "wifi" | "cellular" | "any"
    val trustLevel: String?,   // "trusted" | "public" | "unknown" | "hostile"
    val hourStart: Int?,       // 0-23
    val hourEnd: Int?,         // 0-23; handles overnight if hourStart > hourEnd
)

/** A global rule with its parsed conditions and action. */
data class RuleWithConditions(
    val id: String,
    val action: String,
    val conditions: RuleConditions?,
) {
    companion object {
        fun from(rule: Map<String, Any?>): RuleWithConditions {
            val condJson = rule["conditionsJson"] as? String
            val cond = condJson?.let { parseConditions(it) }
            return RuleWithConditions(
                id         = rule["id"] as? String ?: "",
                action     = rule["action"] as? String ?: "ask",
                conditions = cond,
            )
        }

        /**
         * Parses rule conditions from JSON.
         * Note: This uses flat regex-based string extraction which is 100% portable on pure JVMs,
         * but assumes a flat, non-nested JSON schema. If nested conditions or logical operators
         * are introduced in the future, this must be migrated to a fully compliant JSON parser.
         */
        private fun parseConditions(json: String): RuleConditions? {
            val trimmed = json.trim()
            if (trimmed == "{}" || trimmed.isEmpty()) return null
            return try {
                val netType = extractStringField(trimmed, "networkType")
                val trust   = extractStringField(trimmed, "trustLevel")
                val start   = extractIntField(trimmed, "hourStart")
                val end     = extractIntField(trimmed, "hourEnd")

                if (netType == null && trust == null && start == null && end == null) {
                    return null
                }
                RuleConditions(
                    networkType = netType,
                    trustLevel  = trust,
                    hourStart   = start,
                    hourEnd     = end
                )
            } catch (_: Exception) { null }
        }

        private fun extractStringField(json: String, key: String): String? {
            val pattern = """"$key"\s*:\s*"([^"]*)"""".toRegex()
            val match = pattern.find(json)
            return match?.groupValues?.getOrNull(1)?.takeIf { it.isNotEmpty() }
        }

        private fun extractIntField(json: String, key: String): Int? {
            val pattern = """"$key"\s*:\s*(\d+)""".toRegex()
            val match = pattern.find(json)
            return match?.groupValues?.getOrNull(1)?.toIntOrNull()
        }
    }
}

/**
 * Runtime context passed into evaluate() so conditionsMatch() can check
 * network-type and time-of-day predicates on global rules.
 */
data class RuleContext(
    val networkType: String,   // "wifi" | "cellular" | "unknown"
    val trustLevel: String,    // "trusted" | "public" | "unknown" | "hostile"
    val currentHour: Int,      // 0-23 (local time)
)

// ── RuleRepository ────────────────────────────────────────────────────────────

/**
 * In-memory rule cache and enforcement logic.
 *
 * Implements the 7-priority hierarchy from SDES Volume II §2:
 *
 *   P1  Lockdown     — isLockdownActive flag; never stored as a rule bucket,
 *                      never subject to expiry logic
 *   P2  Temporary    — TemporaryRule list with startAt/endAt; expired entries skipped
 *   P3  Session      — in-memory Map cleared when VPN stops or process dies
 *   P4  Manual       — per-app rules set explicitly by the user
 *   P5  Profile      — rules belonging to the active Shield profile
 *   P6  Global       — condition-bearing rules evaluated across all apps
 *   P7  Default      — falls through to defaultAction
 *
 * All operations are thread-safe (called from both the VPN packet-processing
 * thread and the Flutter method-channel thread).
 */
object RuleRepository {

    private const val TAG = "NC-Rules"

    // ── P0: Quick Block (unconditional per-app kill switch) ───
    private val quickBlockedApps = java.util.concurrent.ConcurrentHashMap.newKeySet<String>()

    // ── P1: Lockdown ──────────────────────────────────────────────
    @Volatile var isLockdownActive: Boolean = false
        private set

    // ── Cloak Engine ──────────────────────────────────────────────
    @Volatile var cloakEnabled: Boolean = false

    private val lockdownAllowlist = CopyOnWriteArrayList<String>()

    // ── P2: Temporary rules ───────────────────────────────────────
    private val temporaryRules = CopyOnWriteArrayList<TemporaryRule>()

    // ── P3: Session rules (in-memory; cleared on VPN stop / process death) ──
    private val sessionRules = ConcurrentHashMap<String, String>()

    // ── P4 & P5: Manual and profile rules ────────────────────────
    private val manualRules  = ConcurrentHashMap<String, String>()
    private val profileRules = ConcurrentHashMap<String, String>()

    // ── P6: Global rules with conditions ─────────────────────────
    private val globalRules = CopyOnWriteArrayList<RuleWithConditions>()

    // ── P7: Default action ────────────────────────────────────────
    @Volatile private var defaultAction: String = "ask"

    // ── Blocked-app cache (invalidated on updateRules) ────────────
    @Volatile private var cachedBlockedApps: List<String>? = null

    // ── P1.5: Global LAN block (Public Wi-Fi / Travel modes) ────
    // Wins unconditionally over per-app allowLanOnly (D4) — on untrusted
    // networks, LAN devices ARE the threat model.
    @Volatile var blockLanTraffic: Boolean = false

    // ── Last-known network context (updated by ConnectivityMonitor via Platform) ──
    @Volatile var lastKnownContext: RuleContext = RuleContext(
        networkType = "unknown",
        trustLevel  = "unknown",
        currentHour = 0,
    )

    // ── API — called from PlatformChannelHandler ──────────────────

    /**
     * Replaces all rule buckets with the provided list.
     *
     * Priority routing:
     *   isGlobal=true          → globalRules  (P6)
     *   priority == 2          → temporaryRules (P2)
     *   priority == 3          → sessionRules   (P3)
     *   priority == 4          → manualRules    (P4)
     *   priority == 5          → profileRules   (P5)
     *   priority == 1 (Lockdown) is never sent as a rule object — use
     *     activateLockdown() instead.
     *
     * Malformed rules (isGlobal + explicit priority, out-of-range priority,
     * or priority==1 in a rule object) are rejected with a logged error.
     */
    fun updateRules(rules: List<Map<String, Any?>>) {
        temporaryRules.clear()
        sessionRules.clear()
        manualRules.clear()
        profileRules.clear()
        globalRules.clear()
        cachedBlockedApps = null  // invalidate cache

        for (rule in rules) {
            val id       = rule["id"]       as? String  ?: "<unknown>"
            val appId    = rule["appId"]    as? String
            val action   = rule["action"]   as? String  ?: "ask"
            val isGlobal = rule["isGlobal"] as? Boolean ?: false
            val priority = (rule["priority"] as? Int)

            // ── Validation ────────────────────────────────────────
            // P1 (Lockdown) must never arrive as a rule object
            if (!isGlobal && priority == 1) {
                Log.e(TAG, "Rule $id: priority=1 (Lockdown) must be set via activateLockdown() — rejected")
                continue
            }
            // isGlobal=true combined with any explicit priority tier is ambiguous
            if (isGlobal && priority != null && priority in 1..5) {
                Log.e(TAG, "Rule $id: isGlobal=true with priority=$priority is ambiguous — rejected")
                continue
            }
            // Non-global rules must have a priority in the defined range 2–5
            if (!isGlobal && (priority == null || priority !in 2..5)) {
                Log.e(TAG, "Rule $id: non-global rule has invalid priority=$priority — rejected")
                continue
            }

            // ── Bucket routing ────────────────────────────────────
            when {
                isGlobal      -> globalRules.add(RuleWithConditions.from(rule))
                priority == 2 -> TemporaryRule.from(rule)?.let { temporaryRules.add(it) }
                priority == 3 -> if (appId != null) sessionRules[appId] = action
                priority == 4 -> if (appId != null) manualRules[appId]  = action
                priority == 5 -> if (appId != null) profileRules[appId] = action
            }
        }

        Log.i(TAG, "Rules updated — temp=${temporaryRules.size} session=${sessionRules.size} " +
              "manual=${manualRules.size} profile=${profileRules.size} global=${globalRules.size}")
    }

    private var contextRef: java.lang.ref.WeakReference<Context>? = null

    fun attachContext(context: Context) {
        contextRef = java.lang.ref.WeakReference(context.applicationContext)
    }

    // ── Lockdown API ──────────────────────────────────────────────

    fun activateLockdown(allowlist: List<String>) {
        lockdownAllowlist.clear()
        lockdownAllowlist.addAll(allowlist)
        isLockdownActive = true
        NativeEventBus.postAlert(
            alertType = "lockdown_activated",
            severity  = "warning",
            title     = "Lockdown Active",
            message   = "All connections are blocked except phone calls.",
        )
        contextRef?.get()?.let { ctx ->
            NativeEventBus.postSystemNotification(
                context = ctx,
                title = "Lockdown Active",
                body = "All connections are blocked except phone calls.",
                severity = "warning"
            )
        }
    }

    fun deactivateLockdown() {
        isLockdownActive = false
        lockdownAllowlist.clear()
    }

    fun isAppAllowedInLockdown(appId: String): Boolean {
        if (appId == "com.networkcloak.network_cloak") return true
        return lockdownAllowlist.contains(appId)
    }

    // ── Session rules API ─────────────────────────────────────────

    /** Clears P3 session rules. Called from NetworkCloakVpnService.stopVpn(). */
    fun clearSessionRules() {
        sessionRules.clear()
    }

    // ── Quick Block API ───────────────────────────────────────────

    /**
     * Replaces the quick-block app set (P0). Invalidates the blocked-app
     * cache so getBlockedAppIds() returns fresh results (D3).
     */
    fun updateQuickBlockList(apps: List<String>) {
        quickBlockedApps.clear()
        quickBlockedApps.addAll(apps)
        cachedBlockedApps = null  // D3: invalidate cache
        Log.i(TAG, "Quick Block list updated: ${quickBlockedApps.size} apps")
    }

    fun isQuickBlockEmpty(): Boolean = quickBlockedApps.isEmpty()

    // ── Blocked-app list (used by VPN builder, cached) ────────────

    /**
     * Returns package IDs whose current effective action is "block".
     * Result is cached and invalidated whenever updateRules() is called.
     * This prevents a full O(packages × rules) scan on every configureVpn() call.
     */
    fun getBlockedAppIds(context: Context): List<String> {
        cachedBlockedApps?.let { return it }

        val blocked = mutableListOf<String>()
        val pm = context.packageManager
        val packages = pm.getInstalledPackages(0)

        for (pkg in packages) {
            val appId = pkg.packageName
            if (appId == "com.networkcloak.network_cloak") continue
            val action = evaluate(appId = appId, destIp = "", destPort = 0,
                                  protocol = "TCP", isBackground = false)
            if (action == "block") blocked.add(appId)
        }

        cachedBlockedApps = blocked
        return blocked
    }

    // ── Core evaluation ───────────────────────────────────────────

    /**
     * Returns "allow" or "block" for a given packet.
     * Follows the 7-priority hierarchy. Target latency: <2µs.
     *
     * @param context optional runtime context for global-rule condition matching.
     *                Defaults to lastKnownContext if not provided.
     */
    fun evaluate(
        appId: String,
        destIp: String,
        destPort: Int,
        protocol: String,
        isBackground: Boolean,
        context: RuleContext = lastKnownContext,
    ): String {

        // P0: Quick Block — unconditional per-app kill switch.
        // Above even Lockdown because the user explicitly wants this app dead.
        if (quickBlockedApps.contains(appId)) {
            return "block"
        }

        // P1: Lockdown — unconditional, never expires
        if (isLockdownActive) {
            return if (lockdownAllowlist.contains(appId)) "allow" else "block"
        }

        // Cloak Engine: Block LAN discovery/multicast if enabled
        if (cloakEnabled) {
            // Block local discovery / multicast ports:
            // 5353 (mDNS), 5355 (LLMNR), 137/138/139 (NetBIOS), 445 (SMB), 1900 (SSDP/UPnP)
            if (destPort == 5353 || destPort == 5355 || destPort == 137 || destPort == 138 || destPort == 139 || destPort == 445 || destPort == 1900) {
                return "block"
            }
            // Block IP multicast (224.0.0.0/4) or broadcast 255.255.255.255
            if (destIp.isNotEmpty()) {
                val parts = destIp.split(".")
                if (parts.size >= 4) {
                    val firstOctet = parts[0].toIntOrNull()
                    if (firstOctet != null && firstOctet in 224..239) {
                        return "block"
                    }
                }
                if (destIp == "255.255.255.255") {
                    return "block"
                }
            }
        }

        // P1.5: Global LAN block (Public Wi-Fi / Travel / Lockdown modes).
        // Wins unconditionally over per-app allowLanOnly (D4) — on untrusted
        // networks, LAN devices ARE the threat model. User can override by
        // switching to Home mode where blockLan is not set.
        if (blockLanTraffic && isLanAddress(destIp)) {
            return "block"
        }

        // P2: Temporary rules (skip expired entries)
        val nowMs = System.currentTimeMillis()
        for (rule in temporaryRules) {
            if (rule.appId != appId) continue
            if (nowMs > rule.endAt) continue   // expired — skip
            return resolveAction(rule.action, isBackground, destIp)
        }

        // P3: Session rules
        sessionRules[appId]?.let { return resolveAction(it, isBackground, destIp) }

        // P4: Manual rules
        manualRules[appId]?.let { return resolveAction(it, isBackground, destIp) }

        // P5: Profile rules
        profileRules[appId]?.let { return resolveAction(it, isBackground, destIp) }

        // P6: Global rules — evaluate ALL entries, match on conditions
        for (rule in globalRules) {
            if (conditionsMatch(rule, context)) {
                return resolveAction(rule.action, isBackground, destIp)
            }
            // no match → continue to next global rule
        }

        // P7: Default
        return if (defaultAction == "ask") "block" else defaultAction
    }

    // ── Condition matching ────────────────────────────────────────

    /**
     * Returns true if all conditions on the global rule match the current context.
     * Missing/null condition fields are treated as wildcards (match-all).
     *
     * Hour-window wraparound is handled correctly:
     *   - Same-day window (hourStart ≤ hourEnd):  h in [start, end]
     *   - Overnight window (hourStart > hourEnd): h >= start OR h < end
     *     e.g. hourStart=22, hourEnd=6 covers 22:00–23:59 and 00:00–05:59
     */
    private fun conditionsMatch(rule: RuleWithConditions, ctx: RuleContext): Boolean {
        val c = rule.conditions ?: return true   // no conditions → wildcard

        c.networkType?.let { if (it != "any" && it != ctx.networkType) return false }
        c.trustLevel?.let  { if (it != ctx.trustLevel)                 return false }

        val hs = c.hourStart
        val he = c.hourEnd
        if (hs != null && he != null) {
            val h = ctx.currentHour
            val inWindow = if (hs <= he) h in hs..he else h >= hs || h < he
            if (!inWindow) return false
        }

        return true
    }

    // ── Action resolution ─────────────────────────────────────────

    private fun resolveAction(action: String, isBackground: Boolean, destIp: String): String {
        return when (action) {
            "block", "temporaryBlock"    -> "block"
            "allow", "temporaryAllow"    -> "allow"
            "blockBackground"            -> if (isBackground) "block" else "allow"
            "allowLanOnly"               -> if (isLanAddress(destIp)) "allow" else "block"
            "allowInternetOnly"          -> if (!isLanAddress(destIp)) "allow" else "block"
            // "ask" fails closed per Volume I §4 Safe Defaults.
            // The UI popup is handled by Watchtower; until the user answers,
            // the packet is blocked — the previous "fail open" behaviour was
            // a security defect (audit bug #10).
            "ask"                        -> "block"
            else                         -> "allow"
        }
    }

    internal fun isLanAddress(ip: String): Boolean {
        if (ip.isEmpty()) return false
        return ip.startsWith("192.168.") ||
               ip.startsWith("10.") ||
               (ip.startsWith("172.") && run {
                   val second = ip.split(".").getOrNull(1)?.toIntOrNull() ?: 0
                   second in 16..31
               })
    }
}
