package com.networkcloak.network_cloak

import android.util.Log
import io.mockk.every
import io.mockk.mockkStatic
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class RuleRepositoryCloakTest {

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
        RuleRepository.cloakEnabled = false
    }

    @Test
    fun `cloak blocks mDNS multicast port 5353`() {
        RuleRepository.cloakEnabled = true

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "224.0.0.251",
            destPort = 5353,
            protocol = "UDP",
            isBackground = false
        )

        assertEquals("mDNS should be blocked when cloak is enabled", "block", decision)
    }

    @Test
    fun `cloak blocks multicast IP ranges`() {
        RuleRepository.cloakEnabled = true

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "239.255.255.250", // SSDP/UPnP
            destPort = 1900,
            protocol = "UDP",
            isBackground = false
        )

        assertEquals("Multicast IP should be blocked when cloak is enabled", "block", decision)
    }

    @Test
    fun `cloak blocks local NetBIOS ports`() {
        RuleRepository.cloakEnabled = true

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "192.168.1.100",
            destPort = 445, // SMB
            protocol = "TCP",
            isBackground = false
        )

        assertEquals("SMB port should be blocked when cloak is enabled", "block", decision)
    }

    @Test
    fun `cloak does not block regular HTTP traffic`() {
        RuleRepository.cloakEnabled = true
        
        // Setup manual allow rule
        RuleRepository.updateRules(listOf(
            mapOf("id" to "r1", "appId" to "com.example.app", "action" to "allow",
                  "priority" to 4, "isGlobal" to false, "conditionsJson" to "{}"),
        ))

        val decision = RuleRepository.evaluate(
            appId = "com.example.app",
            destIp = "8.8.8.8",
            destPort = 80,
            protocol = "TCP",
            isBackground = false
        )

        assertEquals("Regular HTTP traffic should be allowed when cloak is enabled", "allow", decision)
    }
}
