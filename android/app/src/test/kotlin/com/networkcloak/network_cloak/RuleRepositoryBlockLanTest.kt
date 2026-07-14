package com.networkcloak.network_cloak

import android.util.Log
import io.mockk.every
import io.mockk.mockkStatic
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class RuleRepositoryBlockLanTest {

    @Before
    fun reset() {
        mockkStatic(Log::class)
        every { Log.i(any<String>(), any<String>()) } returns 0
        every { Log.e(any<String>(), any<String>()) } returns 0
        every { Log.d(any<String>(), any<String>()) } returns 0
        every { Log.w(any<String>(), any<String>()) } returns 0

        RuleRepository.updateRules(emptyList())
        RuleRepository.deactivateLockdown()
        RuleRepository.blockLanTraffic = false
    }

    @Test
    fun `blockLan block wins over manual app rule allowLanOnly`() {
        // blockLan is set (e.g. Public Wi-Fi or Travel mode)
        RuleRepository.blockLanTraffic = true

        // User explicitly configured allowLanOnly for com.example.app (P4 manual rule)
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "allowLanOnly",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        // Evaluate connection to a LAN IP
        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "192.168.1.50",
            destPort = 80,
            protocol = "TCP",
            isBackground = false
        )

        // blockLan (P1.5) must win over allowLanOnly manual rule (P4)
        assertEquals("Global blockLan should win over app allowLanOnly", "block", decision)
    }

    @Test
    fun `blockLan does not block internet traffic`() {
        RuleRepository.blockLanTraffic = true

        // P4 manual rule: allow com.example.app
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "8.8.8.8", // internet IP
            destPort = 80,
            protocol = "TCP",
            isBackground = false
        )

        assertEquals("blockLan should not affect internet IP for allowed app", "allow", decision)
    }
}
