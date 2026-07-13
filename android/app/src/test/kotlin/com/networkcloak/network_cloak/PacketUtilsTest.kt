package com.networkcloak.network_cloak

import android.system.OsConstants
import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for PacketUtils — checksum correctness and RST packet field values.
 *
 * Tests validate:
 *  1. ipv4Checksum() against a known-good ICMP echo-request header
 *  2. Self-verification property: re-computing over a complete header yields 0x0000
 *  3. tcpChecksum() against a known-good SYN segment
 *  4. buildTcpRst() SEQ/ACK field correctness per RFC 793 §3.4
 *     and checksum self-verification
 */
class PacketUtilsTest {

    // ── Test 1: IPv4 checksum against known-good header ──────────────────────
    //
    // Standard ICMP echo request to 8.8.8.8 from 192.168.1.1.
    // Header (20 bytes, checksum field zeroed):
    //   45 00 00 1c 00 01 00 00 40 01 00 00 c0 a8 01 01 08 08 08 08
    //
    // Expected checksum from Wireshark / RFC-compliant reference: 0xA927
    // (verified manually: one's complement sum of 16-bit words, then inverted)
    @Test
    fun `ipv4Checksum produces correct value for known ICMP header`() {
        val header = byteArrayOf(
            0x45, 0x00, 0x00, 0x1c,  // version+IHL, DSCP, total length
            0x00, 0x01, 0x00, 0x00,  // identification, flags+frag offset
            0x40, 0x01, 0x00, 0x00,  // TTL=64, proto=ICMP(1), checksum=0 (zeroed)
            0xc0.toByte(), 0xa8.toByte(), 0x01, 0x01,  // src: 192.168.1.1
            0x08, 0x08, 0x08, 0x08,  // dst: 8.8.8.8
        )

        val result = PacketUtils.ipv4Checksum(header)
        // Expected: 0xA927 — calculated from one's complement sum
        assertEquals("IPv4 checksum mismatch for known-good ICMP header", 0xA927, result)
    }

    // ── Test 2: Self-verification property ───────────────────────────────────
    //
    // RFC 791: If you include the checksum field in the sum and the packet is
    // valid, the result is 0xFFFF; equivalently, the one's complement of
    // re-summing yields 0x0000.
    // We write the computed checksum back into the header, re-run the function,
    // and expect the one's complement of 0xFFFF = 0x0000.
    @Test
    fun `ipv4Checksum self-verifies to 0x0000 when checksum field is set`() {
        val header = byteArrayOf(
            0x45, 0x00, 0x00, 0x1c,
            0x00, 0x01, 0x00, 0x00,
            0x40, 0x01, 0x00, 0x00,  // checksum zeroed
            0xc0.toByte(), 0xa8.toByte(), 0x01, 0x01,
            0x08, 0x08, 0x08, 0x08,
        )
        // First pass: compute and write the checksum
        val ck = PacketUtils.ipv4Checksum(header)
        PacketUtils.writeChecksum(header, 10, ck)

        // Second pass: re-compute over the complete header (checksum field now set)
        val verify = PacketUtils.ipv4Checksum(header)
        assertEquals("Re-computing checksum over complete header should yield 0x0000", 0x0000, verify)
    }

    // ── Test 3: TCP checksum against known-good SYN ──────────────────────────
    //
    // Minimal SYN from 10.0.0.1:12345 to 1.1.1.1:443.
    // TCP segment (20 bytes, no options, no data), checksum field zeroed:
    //   Flags: SYN (0x02)
    // Expected checksum computed via pseudo-header + segment.
    // We compute independently and verify self-check property.
    @Test
    fun `tcpChecksum self-verifies to 0x0000 when checksum field is set`() {
        val srcIp = byteArrayOf(10, 0, 0, 1)
        val dstIp = byteArrayOf(1, 1, 1, 1)

        val tcp = ByteArray(20)
        // src port = 12345 = 0x3039
        tcp[0] = 0x30; tcp[1] = 0x39
        // dst port = 443 = 0x01BB
        tcp[2] = 0x01; tcp[3] = 0xBB.toByte()
        // SEQ = 0x00000001
        tcp[4] = 0; tcp[5] = 0; tcp[6] = 0; tcp[7] = 1
        // ACK = 0
        tcp[8] = 0; tcp[9] = 0; tcp[10] = 0; tcp[11] = 0
        tcp[12] = 0x50  // data offset = 5
        tcp[13] = 0x02  // SYN
        tcp[14] = 0xFF.toByte(); tcp[15] = 0xFF.toByte()  // window
        tcp[16] = 0; tcp[17] = 0  // checksum zeroed
        tcp[18] = 0; tcp[19] = 0  // urgent

        val ck = PacketUtils.tcpChecksum(srcIp, dstIp, tcp)
        PacketUtils.writeChecksum(tcp, 16, ck)

        // Re-compute: build pseudo-header with the now-set checksum field
        val verify = PacketUtils.tcpChecksum(srcIp, dstIp, tcp)
        assertEquals("Re-computing TCP checksum over complete segment should yield 0x0000", 0x0000, verify)
    }

    // ── Test 4: buildTcpRst SEQ/ACK fields per RFC 793 §3.4 ─────────────────
    //
    // Given a SYN packet with SEQ=1000 (0x000003E8), the RST must have:
    //   RST.SEQ  = 0
    //   RST.ACK  = 1001 (0x000003E9)
    //   RST.flags = RST | ACK = 0x14
    // And the IPv4 and TCP checksums must both self-verify.
    @Test
    fun `buildTcpRst produces correct SEQ=0, ACK=origSeq+1, flags=RST+ACK`() {
        val ihl = 20
        // Minimal valid IPv4 + TCP SYN packet (40 bytes)
        val syn = ByteArray(40)
        // IP header
        syn[0] = 0x45  // version=4, IHL=5
        syn[2] = 0; syn[3] = 40  // total length = 40
        syn[9] = OsConstants.IPPROTO_TCP.toByte()
        // src IP: 192.168.1.100
        syn[12] = 192.toByte(); syn[13] = 168.toByte(); syn[14] = 1; syn[15] = 100
        // dst IP: 93.184.216.34 (example.com)
        syn[16] = 93; syn[17] = 184.toByte(); syn[18] = 216.toByte(); syn[19] = 34
        // TCP header starts at offset 20
        // src port: 54321 = 0xD431
        syn[20] = 0xD4.toByte(); syn[21] = 0x31
        // dst port: 80 = 0x0050
        syn[22] = 0x00; syn[23] = 0x50
        // SEQ = 1000 = 0x000003E8
        syn[24] = 0x00; syn[25] = 0x00; syn[26] = 0x03; syn[27] = 0xE8.toByte()
        // ACK = 0
        syn[28] = 0; syn[29] = 0; syn[30] = 0; syn[31] = 0
        syn[32] = 0x50  // data offset
        syn[33] = 0x02  // SYN flag
        syn[34] = 0xFF.toByte(); syn[35] = 0xFF.toByte()  // window

        val rst = PacketUtils.buildTcpRst(syn, ihl)

        // RST is ihl(20) + tcp(20) = 40 bytes
        assertEquals("RST packet must be 40 bytes", 40, rst.size)

        val tcpOff = ihl
        // SEQ must be 0
        val seq = ((rst[tcpOff + 4].toInt() and 0xFF) shl 24) or
                  ((rst[tcpOff + 5].toInt() and 0xFF) shl 16) or
                  ((rst[tcpOff + 6].toInt() and 0xFF) shl 8)  or
                   (rst[tcpOff + 7].toInt() and 0xFF)
        assertEquals("RST SEQ must be 0", 0, seq)

        // ACK must be origSeq + 1 = 1001
        val ack = ((rst[tcpOff + 8].toLong() and 0xFF) shl 24) or
                  ((rst[tcpOff + 9].toLong() and 0xFF) shl 16) or
                  ((rst[tcpOff + 10].toLong() and 0xFF) shl 8) or
                   (rst[tcpOff + 11].toLong() and 0xFF)
        assertEquals("RST ACK must be origSeq+1 = 1001", 1001L, ack)

        // Flags must be RST | ACK = 0x14
        val flags = rst[tcpOff + 13].toInt() and 0xFF
        assertEquals("RST flags must be RST|ACK (0x14)", 0x14, flags)

        // TCP checksum must self-verify
        val rstSrcIp = rst.copyOfRange(12, 16)
        val rstDstIp = rst.copyOfRange(16, 20)
        val tcpSeg   = rst.copyOfRange(tcpOff, rst.size)
        val tcpVerify = PacketUtils.tcpChecksum(rstSrcIp, rstDstIp, tcpSeg)
        assertEquals("RST TCP checksum must self-verify to 0x0000", 0x0000, tcpVerify)

        // IPv4 checksum must self-verify
        val ipHeader = rst.copyOf(ihl)
        val ipVerify = PacketUtils.ipv4Checksum(ipHeader)
        assertEquals("RST IPv4 checksum must self-verify to 0x0000", 0x0000, ipVerify)
    }
}
