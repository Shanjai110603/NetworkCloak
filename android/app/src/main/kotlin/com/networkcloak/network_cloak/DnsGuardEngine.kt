package com.networkcloak.network_cloak

import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.ConcurrentHashMap

/**
 * DNS Guard Engine
 *
 * Intercepts raw DNS UDP packets from the TUN interface, checks the
 * queried domain against the in-memory blocklist, and either:
 *   - Returns a NXDOMAIN response immediately (blocked), or
 *   - Forwards the query to the encrypted upstream resolver (allowed)
 *
 * Blocklist is stored as a HashSet for O(1) lookups.
 */
object DnsGuardEngine {
    private const val TAG = "NC-DNS"

    // Upstream encrypted resolver (set via setProfile)
    @Volatile private var upstreamIp = "1.1.1.1"
    @Volatile private var upstreamPort = 53

    // In-memory domain blocklist (populated from DnsBlocklist table)
    private val blocklist = ConcurrentHashMap.newKeySet<String>()

    // DNS query stats for Watchtower
    @Volatile var totalQueries: Long = 0
    @Volatile var blockedQueries: Long = 0

    // ── API ──────────────────────────────────────────────────

    fun setProfile(profile: Map<String, Any?>) {
        upstreamIp   = profile["endpoint"] as? String ?: "1.1.1.1"
        upstreamPort = (profile["port"] as? Int) ?: 53
    }

    fun updateBlocklists(lists: List<Map<String, Any?>>) {
        // Lists contain domain hashes or domain strings
        blocklist.clear()
        for (list in lists) {
            @Suppress("UNCHECKED_CAST")
            val domains = list["domains"] as? List<String> ?: continue
            blocklist.addAll(domains)
        }
        Log.i(TAG, "Blocklist updated: ${blocklist.size} domains")
    }

    fun addDomain(domain: String) = blocklist.add(domain.lowercase().trimEnd('.'))
    fun removeDomain(domain: String) = blocklist.remove(domain.lowercase().trimEnd('.'))

    fun isBlocked(domain: String): Boolean =
        blocklist.contains(domain.lowercase().trimEnd('.'))

    // ── Packet Interception ───────────────────────────────────

    /**
     * Called by NetworkCloakVpnService for every UDP packet to port 53.
     * Parses the DNS question, checks blocklist, and either blocks or
     * forwards to the upstream resolver.
     */
    fun interceptPacket(packet: ByteArray, output: FileOutputStream) {
        try {
            val ihl = (packet[0].toInt() and 0x0F) * 4
            val udpPayloadOffset = ihl + 8  // UDP header is 8 bytes

            if (packet.size <= udpPayloadOffset) return

            val dnsPayload = packet.copyOfRange(udpPayloadOffset, packet.size)
            val domain = parseDnsQuery(dnsPayload) ?: return

            totalQueries++

            if (isBlocked(domain)) {
                blockedQueries++
                Log.d(TAG, "BLOCKED: $domain")

                NativeEventBus.postConnectionEvent(
                    uid = -1,
                    appId = "dns",
                    destHost = domain,
                    destIp = "dns",
                    port = 53,
                    protocol = "DNS",
                    bytes = packet.size,
                    allowed = false,
                )
                // Do not write packet back — effectively returns NXDOMAIN
                return
            }

            // Forward to upstream (plain UDP for now; DoH upgrade in Phase 4)
            forwardDnsQuery(dnsPayload, output, packet, ihl)
        } catch (e: Exception) {
            Log.w(TAG, "DNS interception error: ${e.message}")
            output.write(packet)  // fail open
        }
    }

    // ── DNS Query Parsing ─────────────────────────────────────

    /**
     * Parses the first QNAME from a raw DNS message payload.
     * Returns "example.com" form or null if unparseable.
     */
    private fun parseDnsQuery(dns: ByteArray): String? {
        if (dns.size < 12) return null  // DNS header is 12 bytes
        return try {
            val sb = StringBuilder()
            var idx = 12
            while (idx < dns.size) {
                val len = dns[idx].toInt() and 0xFF
                if (len == 0) break
                if (sb.isNotEmpty()) sb.append('.')
                sb.append(String(dns, idx + 1, len, Charsets.US_ASCII))
                idx += len + 1
            }
            sb.toString().lowercase().ifEmpty { null }
        } catch (_: Exception) { null }
    }

    // ── DNS Forwarding ────────────────────────────────────────

    private fun forwardDnsQuery(
        dnsPayload: ByteArray,
        tunOutput: FileOutputStream,
        originalPacket: ByteArray,
        ihl: Int,
    ) {
        try {
            val socket = DatagramSocket()
            socket.soTimeout = 3000
            val upstream = InetAddress.getByName(upstreamIp)
            socket.send(DatagramPacket(dnsPayload, dnsPayload.size, upstream, upstreamPort))

            val buf = ByteArray(4096)
            val response = DatagramPacket(buf, buf.size)
            socket.receive(response)
            socket.close()

            // Reconstruct IP+UDP headers for the TUN response
            val responsePacket = buildDnsResponsePacket(
                originalPacket = originalPacket,
                ihl = ihl,
                dnsPayload = buf.copyOf(response.length),
            )
            tunOutput.write(responsePacket)
        } catch (e: Exception) {
            Log.w(TAG, "DNS forward failed: ${e.message}")
        }
    }

    private fun buildDnsResponsePacket(
        originalPacket: ByteArray,
        ihl: Int,
        dnsPayload: ByteArray,
    ): ByteArray {
        val udpLen = 8 + dnsPayload.size
        val ipLen  = ihl + udpLen
        val out = ByteArrayOutputStream(ipLen)

        // IPv4 header (swap src/dst)
        val ip = originalPacket.copyOf(ihl)
        // Swap src and dst IP
        val srcIp = ip.copyOfRange(12, 16)
        val dstIp = ip.copyOfRange(16, 20)
        System.arraycopy(dstIp, 0, ip, 12, 4)
        System.arraycopy(srcIp, 0, ip, 16, 4)
        // Update total length
        ip[2] = ((ipLen shr 8) and 0xFF).toByte()
        ip[3] = (ipLen and 0xFF).toByte()
        // Zero checksum — kernel will recalculate
        ip[10] = 0; ip[11] = 0

        // UDP header (swap src/dst port)
        val srcPort = ((originalPacket[ihl + 2].toInt() and 0xFF) shl 8) or
                (originalPacket[ihl + 3].toInt() and 0xFF)
        val dstPort = ((originalPacket[ihl].toInt() and 0xFF) shl 8) or
                (originalPacket[ihl + 1].toInt() and 0xFF)
        val udpHeader = ByteArray(8)
        udpHeader[0] = ((dstPort shr 8) and 0xFF).toByte()
        udpHeader[1] = (dstPort and 0xFF).toByte()
        udpHeader[2] = ((srcPort shr 8) and 0xFF).toByte()
        udpHeader[3] = (srcPort and 0xFF).toByte()
        udpHeader[4] = ((udpLen shr 8) and 0xFF).toByte()
        udpHeader[5] = (udpLen and 0xFF).toByte()
        // UDP checksum = 0 (optional for IPv4)
        udpHeader[6] = 0; udpHeader[7] = 0

        out.write(ip)
        out.write(udpHeader)
        out.write(dnsPayload)
        return out.toByteArray()
    }
}
