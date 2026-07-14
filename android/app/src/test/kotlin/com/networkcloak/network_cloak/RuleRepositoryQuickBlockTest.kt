package com.networkcloak.network_cloak

import android.util.Log
import io.mockk.every
import io.mockk.mockkStatic
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class RuleRepositoryQuickBlockTest {

    @Before
    fun reset() {
        mockkStatic(Log::class)
        every { Log.i(any<String>(), any<String>()) } returns 0
        every { Log.e(any<String>(), any<String>()) } returns 0
        every { Log.d(any<String>(), any<String>()) } returns 0
        every { Log.w(any<String>(), any<String>()) } returns 0

        RuleRepository.updateRules(emptyList())
        RuleRepository.deactivateLockdown()
        RuleRepository.updateQuickBlockList(emptyList())
        RuleRepository.blockLanTraffic = false
    }

    @Test
    fun `quick block blocks app even during lockdown mode`() {
        // App is in lockdown allowlist
        RuleRepository.activateLockdown(listOf("com.example.app"))
        
        // App is also quick blocked
        RuleRepository.updateQuickBlockList(listOf("com.example.app"))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "8.8.8.8",
            destPort = 80,
            protocol = "TCP",
            isBackground = false
        )

        assertEquals("Quick block (P0) must win over lockdown allowlist (P1)", "block", decision)
    }

    @Test
    fun `quick block blocks app even with manual rules`() {
        // manual rule allows com.example.app
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))
        
        RuleRepository.updateQuickBlockList(listOf("com.example.app"))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "8.8.8.8",
            destPort = 80,
            protocol = "TCP",
            isBackground = false
        )

        assertEquals("Quick block (P0) must win over manual allow (P4)", "block", decision)
    }

    @Test
    fun `isQuickBlockEmpty returns correct state`() {
        assertTrue(RuleRepository.isQuickBlockEmpty())

        RuleRepository.updateQuickBlockList(listOf("com.example.app"))
        assertFalse(RuleRepository.isQuickBlockEmpty())

        RuleRepository.updateQuickBlockList(emptyList())
        assertTrue(RuleRepository.isQuickBlockEmpty())
    }
}
