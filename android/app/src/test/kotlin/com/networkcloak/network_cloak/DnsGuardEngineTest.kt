package com.networkcloak.network_cloak

import android.util.Log
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.slot
import io.mockk.verify
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream

/**
 * Unit tests for DnsGuardEngine — NXDOMAIN response construction,
 * blocked-domain write behaviour, and IPv4 checksum correctness of
 * crafted response packets.
 *
 * DnsGuardEngine is a Kotlin object (singleton), so tests must account
 * for state leakage between test runs. Each test sets up fresh state.
 *
 * Tests 19–21 match Phase J in the implementation plan.
 */
class DnsGuardEngineTest {

    @Before
    fun setup() {
        mockkStatic(Log::class)
        every { Log.i(any<String>(), any<String>()) } returns 0
        every { Log.e(any<String>(), any<String>()) } returns 0
        every { Log.d(any<String>(), any<String>()) } returns 0
        every { Log.w(any<String>(), any<String>()) } returns 0

        // Reset engine blocklists
        DnsGuardEngine.updateBlocklists(emptyList())
    }

    // ── Helper: build a minimal raw DNS query UDP packet ─────────────────────
    //
    // IP header (20 bytes) + UDP header (8 bytes) + DNS payload.
    // Domain: "ads.example.com" → labels: [3]ads[7]example[3]com[0]
    private fun buildDnsPacket(domain: String = "ads.example.com"): ByteArray {
        val labels = domain.split(".")
        val qname = ByteArrayOutputStream().also { buf ->
            for (label in labels) {
                buf.write(label.length)
                buf.write(label.toByteArray(Charsets.US_ASCII))
            }
            buf.write(0)  // root label
        }.toByteArray()

        // DNS payload: 12-byte header + QNAME + QTYPE(1) + QCLASS(1)
        val dnsPayload = ByteArray(12 + qname.size + 4)
        dnsPayload[0] = 0x12; dnsPayload[1] = 0x34  // transaction ID
        // Flags: QR=0 (query), OPCODE=0, RD=1 → 0x0100
        dnsPayload[2] = 0x01; dnsPayload[3] = 0x00
        // QDCOUNT=1
        dnsPayload[4] = 0x00; dnsPayload[5] = 0x01
        System.arraycopy(qname, 0, dnsPayload, 12, qname.size)
        // QTYPE=A(1), QCLASS=IN(1)
        dnsPayload[12 + qname.size]     = 0x00; dnsPayload[12 + qname.size + 1] = 0x01
        dnsPayload[12 + qname.size + 2] = 0x00; dnsPayload[12 + qname.size + 3] = 0x01

        val ihl = 20
        val udpLen = 8 + dnsPayload.size
        val ipLen  = ihl + udpLen
        val packet = ByteArray(ipLen)

        // IP header
        packet[0] = 0x45  // version=4, IHL=5
        packet[2] = ((ipLen shr 8) and 0xFF).toByte()
        packet[3] = (ipLen and 0xFF).toByte()
        packet[9] = 17  // IPPROTO_UDP
        // src: 192.168.1.50
        packet[12] = 192.toByte(); packet[13] = 168.toByte(); packet[14] = 1; packet[15] = 50
        // dst (our fake DNS server): 10.0.0.1
        packet[16] = 10; packet[17] = 0; packet[18] = 0; packet[19] = 1
        // Compute IPv4 checksum
        packet[10] = 0; packet[11] = 0
        val ck = PacketUtils.ipv4Checksum(packet, 0, ihl)
        PacketUtils.writeChecksum(packet, 10, ck)

        // UDP header
        packet[ihl + 0] = 0xD4.toByte(); packet[ihl + 1] = 0x31  // src port: 54321
        packet[ihl + 2] = 0x00;          packet[ihl + 3] = 0x35  // dst port: 53
        packet[ihl + 4] = ((udpLen shr 8) and 0xFF).toByte()
        packet[ihl + 5] = (udpLen and 0xFF).toByte()

        System.arraycopy(dnsPayload, 0, packet, ihl + 8, dnsPayload.size)
        return packet
    }

    // ── Test 19: NXDOMAIN response has RCODE=3 ────────────────────────────────
    @Test
    fun `buildNxdomainPacket response has RCODE=3 in DNS flags`() {
        DnsGuardEngine.updateBlocklists(listOf(
            mapOf("domains" to listOf("ads.example.com")),
        ))

        val packet = buildDnsPacket("ads.example.com")
        val captured = ByteArrayOutputStream()
        // Wrap in a FileOutputStream-like capture — we use a spy approach with a buffer
        val outputBuffer = ByteArrayOutputStream()

        // We drive interceptPacket via a custom FileOutputStream that writes to our buffer
        val tempFile = java.io.File.createTempFile("dns_test_19", ".tmp").apply { deleteOnExit() }
        val fakeOutput = object : FileOutputStream(tempFile) {
            override fun write(b: ByteArray) { outputBuffer.write(b) }
            override fun write(b: ByteArray, off: Int, len: Int) { outputBuffer.write(b, off, len) }
        }

        DnsGuardEngine.interceptPacket(packet, fakeOutput)

        val response = outputBuffer.toByteArray()
        assertTrue("NXDOMAIN response must not be empty", response.isNotEmpty())

        // DNS payload starts at IP header (20) + UDP header (8) = offset 28
        val ihl = (packet[0].toInt() and 0x0F) * 4
        val dnsOffset = ihl + 8

        assertTrue("Response must be large enough to contain DNS header",
            response.size >= dnsOffset + 12)

        // DNS flags byte 3 (offset dnsOffset+3): lower nibble = RCODE
        val flagsByte3 = response[dnsOffset + 3].toInt() and 0xFF
        val rcode = flagsByte3 and 0x0F
        assertEquals("NXDOMAIN response must have RCODE=3", 3, rcode)
    }

    // ── Test 20: Blocked domain causes output.write() to be called (not silence) ─
    @Test
    fun `blocked domain causes exactly one write to TUN output, not silence`() {
        DnsGuardEngine.updateBlocklists(listOf(
            mapOf("domains" to listOf("tracker.evil.com")),
        ))

        val packet = buildDnsPacket("tracker.evil.com")
        var writeCount = 0
        val tempFile = java.io.File.createTempFile("dns_test_20", ".tmp").apply { deleteOnExit() }
        val fakeOutput = object : FileOutputStream(tempFile) {
            override fun write(b: ByteArray) { writeCount++ }
            override fun write(b: ByteArray, off: Int, len: Int) { writeCount++ }
        }

        DnsGuardEngine.interceptPacket(packet, fakeOutput)

        assertEquals(
            "Blocked domain must result in exactly one write (NXDOMAIN) — not silence",
            1, writeCount,
        )
    }

    // ── Test 21: IPv4 checksum of NXDOMAIN response self-verifies ────────────
    @Test
    fun `NXDOMAIN response packet IPv4 checksum self-verifies to 0x0000`() {
        DnsGuardEngine.updateBlocklists(listOf(
            mapOf("domains" to listOf("blocked.test")),
        ))

        val packet = buildDnsPacket("blocked.test")
        val outputBuffer = ByteArrayOutputStream()
        val tempFile = java.io.File.createTempFile("dns_test_21", ".tmp").apply { deleteOnExit() }
        val fakeOutput = object : FileOutputStream(tempFile) {
            override fun write(b: ByteArray) { outputBuffer.write(b) }
            override fun write(b: ByteArray, off: Int, len: Int) { outputBuffer.write(b, off, len) }
        }

        DnsGuardEngine.interceptPacket(packet, fakeOutput)

        val response = outputBuffer.toByteArray()
        assertTrue("Response must not be empty for checksum test", response.isNotEmpty())

        val ihl = (response[0].toInt() and 0x0F) * 4
        assertTrue("Response must contain a full IP header", response.size >= ihl)

        // Re-compute checksum over the response IP header — must self-verify to 0x0000
        val ipHeader = response.copyOf(ihl)
        val verify = PacketUtils.ipv4Checksum(ipHeader)
        assertEquals(
            "NXDOMAIN response IPv4 checksum must self-verify to 0x0000 (bug #8 regression guard)",
            0x0000, verify,
        )
    }
}
