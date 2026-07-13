package com.networkcloak.network_cloak

import android.system.OsConstants
import java.io.ByteArrayOutputStream

/**
 * Shared low-level packet utility functions.
 *
 * Used by both DnsGuardEngine (DNS response / NXDOMAIN packets) and
 * NetworkCloakVpnService (TCP RST packets). Centralised here so that
 * every packet-crafting path uses the same checksum implementation and
 * there is no risk of a future path silently skipping it.
 */
object PacketUtils {

    // ── Checksum ─────────────────────────────────────────────────

    /**
     * RFC 791 IPv4 header checksum.
     *
     * Pass the header bytes with the checksum field (bytes 10–11) already
     * zeroed. The returned value must be written back into bytes 10–11.
     */
    fun ipv4Checksum(header: ByteArray, offset: Int = 0, length: Int = header.size): Int {
        var sum = 0
        var i = offset
        while (i < offset + length - 1) {
            sum += ((header[i].toInt() and 0xFF) shl 8) or (header[i + 1].toInt() and 0xFF)
            i += 2
        }
        if ((length and 1) != 0) {
            sum += (header[offset + length - 1].toInt() and 0xFF) shl 8
        }
        while (sum shr 16 != 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return sum.inv() and 0xFFFF
    }

    /**
     * RFC 793 TCP checksum over the IPv4 pseudo-header + TCP segment.
     *
     * Unlike UDP (RFC 768), TCP checksums are MANDATORY — a value of 0x0000
     * is not valid and will cause the receiving stack to silently discard
     * the segment. This is the same class of failure as the bug #8 zero-
     * checksum that caused DNS response packets to be dropped.
     *
     * @param srcIp      4-byte source IP address
     * @param dstIp      4-byte destination IP address
     * @param tcpSegment full TCP segment (header + data), checksum field zeroed
     */
    fun tcpChecksum(srcIp: ByteArray, dstIp: ByteArray, tcpSegment: ByteArray): Int {
        val pseudoLen = 12 + tcpSegment.size
        val pseudo = ByteArray(pseudoLen)
        System.arraycopy(srcIp, 0, pseudo, 0, 4)
        System.arraycopy(dstIp, 0, pseudo, 4, 4)
        pseudo[8] = 0  // reserved
        pseudo[9] = OsConstants.IPPROTO_TCP.toByte()
        pseudo[10] = ((tcpSegment.size shr 8) and 0xFF).toByte()
        pseudo[11] = (tcpSegment.size and 0xFF).toByte()
        System.arraycopy(tcpSegment, 0, pseudo, 12, tcpSegment.size)
        return ipv4Checksum(pseudo, 0, pseudoLen)
    }

    // ── RST Builder ──────────────────────────────────────────────

    /**
     * Builds a valid TCP RST response for an inbound SYN (or any segment
     * on a connection that cannot be forwarded).
     *
     * RFC 793 §3.4 — for a SYN the RST must have:
     *   SEQ  = 0
     *   ACK  = original_SEQ + 1   (so the peer knows we received the SYN)
     *   Flags = RST | ACK (0x14)
     *
     * An RST with a valid checksum but the wrong SEQ/ACK is silently
     * discarded by the remote TCP stack — same failure class as the original
     * bug #8 zero-checksum packets.
     *
     * @param originalPacket the raw IP packet read from the TUN interface
     * @param ihl            IPv4 header length in bytes (packet[0] & 0x0F) * 4
     */
    fun buildTcpRst(originalPacket: ByteArray, ihl: Int): ByteArray {
        val tcpOff = ihl

        // Original src/dst IPs (we swap them in the RST response)
        val origSrcIp = originalPacket.copyOfRange(12, 16)
        val origDstIp = originalPacket.copyOfRange(16, 20)

        // Ports: RST source port = original dest port, and vice-versa
        val origSrcPort = ((originalPacket[tcpOff].toInt() and 0xFF) shl 8) or
                           (originalPacket[tcpOff + 1].toInt() and 0xFF)
        val origDstPort = ((originalPacket[tcpOff + 2].toInt() and 0xFF) shl 8) or
                           (originalPacket[tcpOff + 3].toInt() and 0xFF)

        // Extract original SEQ from inbound segment (bytes 4–7 of TCP header)
        val origSeq = ((originalPacket[tcpOff + 4].toLong() and 0xFF) shl 24) or
                      ((originalPacket[tcpOff + 5].toLong() and 0xFF) shl 16) or
                      ((originalPacket[tcpOff + 6].toLong() and 0xFF) shl 8)  or
                       (originalPacket[tcpOff + 7].toLong() and 0xFF)
        val ackNum = (origSeq + 1L) and 0xFFFFFFFFL

        // ── TCP segment: 20-byte header, no options, no payload ──
        val tcp = ByteArray(20)
        // Source port = original dest port (we're responding from the remote side)
        tcp[0] = ((origDstPort shr 8) and 0xFF).toByte()
        tcp[1] = (origDstPort and 0xFF).toByte()
        // Dest port = original source port
        tcp[2] = ((origSrcPort shr 8) and 0xFF).toByte()
        tcp[3] = (origSrcPort and 0xFF).toByte()
        // SEQ = 0 (RFC 793 §3.4: "If the incoming segment has an ACK field,
        //          the reset takes its sequence number from the ACK field of
        //          the segment, otherwise the reset has sequence number zero")
        tcp[4] = 0; tcp[5] = 0; tcp[6] = 0; tcp[7] = 0
        // ACK = original SEQ + 1
        tcp[8]  = ((ackNum shr 24) and 0xFF).toByte()
        tcp[9]  = ((ackNum shr 16) and 0xFF).toByte()
        tcp[10] = ((ackNum shr  8) and 0xFF).toByte()
        tcp[11] = (ackNum         and 0xFF).toByte()
        tcp[12] = 0x50  // data offset = 5 (20 bytes), reserved nibble = 0
        tcp[13] = 0x14  // flags: RST (0x04) | ACK (0x10) = 0x14
        tcp[14] = 0; tcp[15] = 0  // window size = 0
        tcp[16] = 0; tcp[17] = 0  // checksum — computed below
        tcp[18] = 0; tcp[19] = 0  // urgent pointer

        // TCP checksum: note argument order — srcIp for the RST is origDstIp
        val tcpCk = tcpChecksum(srcIp = origDstIp, dstIp = origSrcIp, tcpSegment = tcp)
        tcp[16] = ((tcpCk shr 8) and 0xFF).toByte()
        tcp[17] = (tcpCk and 0xFF).toByte()

        // ── IPv4 header — swap src/dst, set correct length & checksum ──
        val ip = originalPacket.copyOf(ihl)
        // Swap: RST comes from origDstIp → origSrcIp
        System.arraycopy(origDstIp, 0, ip, 12, 4)
        System.arraycopy(origSrcIp, 0, ip, 16, 4)
        val ipLen = ihl + 20
        ip[2] = ((ipLen shr 8) and 0xFF).toByte()
        ip[3] = (ipLen and 0xFF).toByte()
        ip[9] = OsConstants.IPPROTO_TCP.toByte()
        // Zero checksum field before computing
        ip[10] = 0; ip[11] = 0
        val ipCk = ipv4Checksum(ip)
        ip[10] = ((ipCk shr 8) and 0xFF).toByte()
        ip[11] = (ipCk and 0xFF).toByte()

        val out = ByteArrayOutputStream(ipLen)
        out.write(ip)
        out.write(tcp)
        return out.toByteArray()
    }

    // ── Helpers ──────────────────────────────────────────────────

    /** Writes a computed checksum into bytes [offset] and [offset+1]. */
    fun writeChecksum(buf: ByteArray, offset: Int, checksum: Int) {
        buf[offset]     = ((checksum shr 8) and 0xFF).toByte()
        buf[offset + 1] = (checksum and 0xFF).toByte()
    }
}
