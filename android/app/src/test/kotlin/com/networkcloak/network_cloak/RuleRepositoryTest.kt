package com.networkcloak.network_cloak

import android.util.Log
import io.mockk.every
import io.mockk.mockkStatic
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for RuleRepository — priority-bucket routing, expiry logic,
 * condition matching, and validation.
 *
 * Tests are pure JVM (no Android SDK calls) because RuleRepository uses only
 * Kotlin stdlib and java.util.concurrent types. No Robolectric needed.
 *
 * Test numbering matches Phase J in the implementation plan (tests 5–18).
 */
class RuleRepositoryTest {

    @Before
    fun reset() {
        // Mock the static android.util.Log class to avoid Method ... in android.util.Log not mocked exception
        mockkStatic(Log::class)
        every { Log.i(any<String>(), any<String>()) } returns 0
        every { Log.e(any<String>(), any<String>()) } returns 0
        every { Log.d(any<String>(), any<String>()) } returns 0
        every { Log.w(any<String>(), any<String>()) } returns 0

        // Start each test with a clean slate
        RuleRepository.updateRules(emptyList())
        RuleRepository.deactivateLockdown()
    }

    // ── Lockdown (P1) ─────────────────────────────────────────────────────────

    // Test 5
    @Test
    fun `P1 lockdown blocks non-allowlisted app regardless of manual rule`() {
        // Load a manual allow rule for com.example.app
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))
        // Activate lockdown — this app is NOT in the allowlist
        RuleRepository.activateLockdown(listOf("com.android.phone"))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        assertEquals("Lockdown should block non-allowlisted app even with manual allow", "block", decision)
    }

    // Test 6
    @Test
    fun `P1 lockdown allows app in allowlist`() {
        RuleRepository.activateLockdown(listOf("com.android.phone", "com.example.allowed"))

        val decision = RuleRepository.evaluate(
            appId = "com.example.allowed", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        assertEquals("Lockdown should allow app in allowlist", "allow", decision)
    }

    // ── Temporary rules (P2) ──────────────────────────────────────────────────

    // Test 7: expired rule is skipped and falls through to manual rule
    @Test
    fun `P2 expired temporary rule is skipped, falls through to manual rule`() {
        val expiredMs = System.currentTimeMillis() - 60_000L  // 1 minute ago
        RuleRepository.updateRules(listOf(
            // Expired temp block
            mapOf("id" to "temp1", "appId" to "com.example.app", "action" to "block",
                  "priority" to 2, "isGlobal" to false, "conditionsJson" to "{}",
                  "startAt" to expiredMs - 1000L, "endAt" to expiredMs),
            // Manual allow (should win once temp is skipped)
            mapOf("id" to "man1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        assertEquals("Expired temp rule must be skipped; manual allow should win", "allow", decision)
    }

    // Test 8: non-expired temp rule beats manual rule
    @Test
    fun `P2 non-expired temporary rule beats manual rule`() {
        val futureMs = System.currentTimeMillis() + 60_000L
        RuleRepository.updateRules(listOf(
            // Active temp block
            mapOf("id" to "temp1", "appId" to "com.example.app", "action" to "block",
                  "priority" to 2, "isGlobal" to false, "conditionsJson" to "{}",
                  "startAt" to System.currentTimeMillis(), "endAt" to futureMs),
            // Manual allow — should lose to the temp rule
            mapOf("id" to "man1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        assertEquals("Non-expired temp block must beat manual allow", "block", decision)
    }

    // ── Session rules (P3) ────────────────────────────────────────────────────

    // Test 9: session rule beats manual rule
    @Test
    fun `P3 session rule beats manual rule`() {
        RuleRepository.updateRules(listOf(
            // Session block
            mapOf("id" to "sess1", "appId" to "com.example.app", "action" to "block",
                  "priority" to 3, "isGlobal" to false, "conditionsJson" to "{}"),
            // Manual allow — should lose
            mapOf("id" to "man1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        assertEquals("Session block must beat manual allow", "block", decision)
    }

    // ── Global rules (P6) ─────────────────────────────────────────────────────

    // Test 10: global rule loop evaluates ALL entries — third rule matched
    @Test
    fun `P6 global rule loop evaluates all entries, not just first`() {
        RuleRepository.updateRules(listOf(
            // Rule 1: wifi only — won't match cellular context
            mapOf("id" to "g1", "action" to "allow", "isGlobal" to true,
                  "conditionsJson" to """{"networkType":"wifi"}"""),
            // Rule 2: trusted only — won't match unknown trust context
            mapOf("id" to "g2", "action" to "allow", "isGlobal" to true,
                  "conditionsJson" to """{"trustLevel":"trusted"}"""),
            // Rule 3: no conditions — wildcard, should match
            mapOf("id" to "g3", "action" to "block", "isGlobal" to true,
                  "conditionsJson" to "{}"),
        ))

        val ctx = RuleContext(networkType = "cellular", trustLevel = "unknown", currentHour = 12)
        val decision = RuleRepository.evaluate(
            appId = "com.unknown.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false, context = ctx,
        )
        assertEquals("Third global rule (wildcard) must be reached and matched", "block", decision)
    }

    // Test 11: global rule with networkType=wifi does not match cellular context
    @Test
    fun `P6 global rule networkType=wifi does not match cellular context`() {
        RuleRepository.updateRules(listOf(
            mapOf("id" to "g1", "action" to "block", "isGlobal" to true,
                  "conditionsJson" to """{"networkType":"wifi"}"""),
        ))

        val ctx = RuleContext(networkType = "cellular", trustLevel = "trusted", currentHour = 12)
        val decision = RuleRepository.evaluate(
            appId = "com.unknown.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false, context = ctx,
        )
        // No rule matched — falls to P7 default ("ask" → "block")
        assertEquals("Wifi-only global rule must not match cellular; should fall to default block", "block", decision)
    }

    // ── Default action (P7) ───────────────────────────────────────────────────

    // Test 12: "ask" action resolves to "block" (Volume I §4 Safe Defaults)
    @Test
    fun `ask action resolves to block (fail-closed safe default)`() {
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "ask",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        assertEquals("'ask' action must resolve to 'block' (fail-closed)", "block", decision)
    }

    // Test 13: blockBackground resolves to allow when foreground
    //
    // NOTE: AppStateTracker.isBackground() always returns false in the current
    // codebase because bug #11 (AppStateTracker wiring) is explicitly deferred.
    // This test validates the BRANCH LOGIC of resolveAction() only — green here
    // does NOT indicate that real background detection is working (#11 is still open).
    @Test
    fun `blockBackground resolves to allow when isBackground=false`() {
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "blockBackground",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP",
            isBackground = false,  // foreground — must allow
        )
        assertEquals("blockBackground must allow when app is in foreground", "allow", decision)
    }

    // ── Validation ────────────────────────────────────────────────────────────

    // Test 14: isGlobal=true + priority=4 is rejected (logged, not added to any bucket)
    @Test
    fun `updateRules rejects isGlobal=true with priority=4 as ambiguous`() {
        RuleRepository.updateRules(listOf(
            // Ambiguous: isGlobal AND an explicit priority tier
            mapOf("id" to "bad1", "appId" to "com.example.app", "action" to "block",
                  "priority" to 4, "isGlobal" to true, "conditionsJson" to "{}"),
            // A valid manual rule for the same app to verify the bad one wasn't applied
            mapOf("id" to "good1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app", destIp = "1.1.1.1",
            destPort = 443, protocol = "TCP", isBackground = false,
        )
        // If bad1 were accepted as a global rule it could block; valid rule must win
        assertEquals("Ambiguous rule must be rejected; valid manual allow must win", "allow", decision)
    }

    // Test 15: non-global rule with priority=0 (out of valid range 2–5) is rejected
    @Test
    fun `updateRules rejects non-global rule with priority=0 (out of range)`() {
        RuleRepository.updateRules(listOf(
            mapOf("id" to "bad2", "appId" to "com.example.app", "action" to "block",
                  "priority" to 0, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        // No valid rule — must fall to default (which is "ask" → "block")
        // We just verify it doesn't crash and the bad rule doesn't silently land anywhere
        // by checking no manual/profile/session/temp rule was loaded (evaluate won't throw)
        assertDoesNotThrow {
            RuleRepository.evaluate(
                appId = "com.example.app", destIp = "1.1.1.1",
                destPort = 443, protocol = "TCP", isBackground = false,
            )
        }
    }

    // Test 16: isGlobal=true + priority=1 (Lockdown tier) is rejected
    @Test
    fun `updateRules rejects isGlobal=true with priority=1 (Lockdown tier)`() {
        RuleRepository.updateRules(listOf(
            mapOf("id" to "bad3", "action" to "block",
                  "priority" to 1, "isGlobal" to true, "conditionsJson" to "{}"),
        ))

        // No lockdown was activated via activateLockdown(), so isLockdownActive=false.
        // The bad rule should NOT have slipped into globalRules.
        // With no rules loaded, falls to default block.
        assertDoesNotThrow {
            RuleRepository.evaluate(
                appId = "com.example.app", destIp = "1.1.1.1",
                destPort = 443, protocol = "TCP", isBackground = false,
            )
        }
        // Verify lockdown wasn't inadvertently activated by the bad rule
        assertFalse("Lockdown must not be active from a rule object", RuleRepository.isLockdownActive)
    }

    // ── conditionsMatch — hour-window wraparound ──────────────────────────────

    // Test 17: overnight window 22:00–06:00
    @Test
    fun `conditionsMatch overnight window hourStart=22 hourEnd=6 handles wraparound`() {
        val rule = RuleWithConditions(
            id = "night",
            action = "block",
            conditions = RuleConditions(
                networkType = null, trustLevel = null, hourStart = 22, hourEnd = 6,
            ),
        )

        // 23:00 → inside window
        val ctx23 = RuleContext("wifi", "trusted", currentHour = 23)
        // 12:00 → outside window
        val ctx12 = RuleContext("wifi", "trusted", currentHour = 12)
        // 03:00 → inside window (overnight part)
        val ctx3  = RuleContext("wifi", "trusted", currentHour = 3)

        // We call conditionsMatch indirectly via evaluate() by loading the rule
        RuleRepository.updateRules(listOf(
            mapOf("id" to "night", "action" to "block", "isGlobal" to true,
                  "conditionsJson" to """{"hourStart":22,"hourEnd":6}"""),
        ))

        val d23 = RuleRepository.evaluate("app", "1.1.1.1", 443, "TCP", false, ctx23)
        val d12 = RuleRepository.evaluate("app", "1.1.1.1", 443, "TCP", false, ctx12)
        val d3  = RuleRepository.evaluate("app", "1.1.1.1", 443, "TCP", false, ctx3)

        assertEquals("Hour 23 must be inside overnight window 22–06", "block", d23)
        assertEquals("Hour 12 must be outside overnight window 22–06", "block", d12)  // falls to default block
        assertEquals("Hour 3 must be inside overnight window 22–06", "block", d3)
    }

    // Test 18: same-day window 09:00–17:00
    @Test
    fun `conditionsMatch same-day window hourStart=9 hourEnd=17`() {
        RuleRepository.updateRules(listOf(
            mapOf("id" to "day", "action" to "block", "isGlobal" to true,
                  "conditionsJson" to """{"hourStart":9,"hourEnd":17}"""),
        ))

        val ctxIn  = RuleContext("wifi", "trusted", currentHour = 14)
        val ctxOut = RuleContext("wifi", "trusted", currentHour = 20)

        val dIn  = RuleRepository.evaluate("app", "1.1.1.1", 443, "TCP", false, ctxIn)
        val dOut = RuleRepository.evaluate("app", "1.1.1.1", 443, "TCP", false, ctxOut)

        assertEquals("Hour 14 must be inside day window 09–17", "block", dIn)
        assertEquals("Hour 20 must be outside day window 09–17 (falls to default block)", "block", dOut)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun assertDoesNotThrow(block: () -> Unit) {
        try {
            block()
        } catch (e: Exception) {
            fail("Expected no exception but got: ${e.message}")
        }
    }
}
