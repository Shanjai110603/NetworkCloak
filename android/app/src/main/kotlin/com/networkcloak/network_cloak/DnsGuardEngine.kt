package com.networkcloak.network_cloak

import android.util.Log
import java.io.ByteArrayOutputStream
import java.lang.ref.WeakReference
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetSocketAddress
import java.net.Socket
import java.security.cert.X509Certificate
import java.util.concurrent.ConcurrentHashMap
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory

/**
 * DNS Guard Engine
 *
 * Intercepts raw DNS UDP packets from the TUN interface, checks the
 * queried domain against the in-memory blocklist, and either:
 *   - Returns a well-formed NXDOMAIN response immediately (blocked), or
 *   - Forwards the query to the encrypted DoH upstream resolver (allowed)
 *
 * DoH security guarantees:
 *   - Endpoint must be an IP literal (e.g. "https://1.1.1.1/dns-query") to
 *     avoid the DNS-bootstrap chicken-and-egg problem.
 *   - The TLS certificate is verified against doHHostname ("cloudflare-dns.com")
 *     using a pinned HostnameVerifier — NEVER skipped.
 *   - The underlying socket is protect()ed via the VPN service reference
 *     before the TLS handshake, preventing the DoH traffic from looping
 *     back through the TUN interface.
 *
 * Blocklist: HashSet for O(1) lookups.
 */
object DnsGuardEngine {
    private const val TAG = "NC-DNS"

    // ── Upstream resolver ─────────────────────────────────────────
    // Must be an IP-literal URL to avoid bootstrapping DNS to resolve the resolver.
    @Volatile private var doHUrl      = "https://1.1.1.1/dns-query"
    @Volatile private var doHHostname = "cloudflare-dns.com"   // cert validation hostname

    // Map of known resolver IPs → (doHUrl, doHHostname) for legacy profile migration
    private val KNOWN_DOH_MAP = mapOf(
        "1.1.1.1"           to Pair("https://1.1.1.1/dns-query",           "cloudflare-dns.com"),
        "1.0.0.1"           to Pair("https://1.0.0.1/dns-query",           "cloudflare-dns.com"),
        "8.8.8.8"           to Pair("https://8.8.8.8/dns-query",           "dns.google"),
        "8.8.4.4"           to Pair("https://8.8.4.4/dns-query",           "dns.google"),
        "9.9.9.9"           to Pair("https://9.9.9.9/dns-query",           "dns.quad9.net"),
        "149.112.112.112"   to Pair("https://149.112.112.112/dns-query",   "dns.quad9.net"),
    )

    // ── VPN service lifecycle (WeakReference to prevent leak across restarts) ──
    private var vpnRef: WeakReference<NetworkCloakVpnService>? = null

    val isAttached: Boolean get() = vpnRef != null

    /**
     * Called from NetworkCloakVpnService.startVpn().
     * Must be called before any DNS packet is processed so protect() is available.
     */
    fun attach(svc: NetworkCloakVpnService) {
        vpnRef = WeakReference(svc)
        Log.d(TAG, "Attached to VPN service")
    }

    /**
     * Called from NetworkCloakVpnService.stopVpn().
     * Clears the reference so we never call protect() on a dead service instance.
     */
    fun detach() {
        vpnRef = null
        Log.d(TAG, "Detached from VPN service")
    }

    // ── In-memory domain blocklist ────────────────────────────────
    private val blocklist = ConcurrentHashMap.newKeySet<String>()

    // ── Stats for Watchtower ──────────────────────────────────────
    @Volatile var totalQueries: Long   = 0
    @Volatile var blockedQueries: Long = 0

    // ── API ───────────────────────────────────────────────────────

    /**
     * Configure the DoH upstream resolver.
     *
     * Accepts new-format keys (doHUrl, doHHostname) or legacy keys (endpoint, port).
     * Legacy profiles are migrated to DoH at read time using KNOWN_DOH_MAP;
     * if the old endpoint is not in the map, we fall back to Cloudflare and post
     * a user-visible alert so the user knows to re-configure.
     */
    fun setProfile(profile: Map<String, Any?>) {
        if (profile.containsKey("doHUrl")) {
            doHUrl      = profile["doHUrl"]      as? String ?: doHUrl
            doHHostname = profile["doHHostname"] as? String ?: doHHostname
            Log.i(TAG, "DoH profile set: $doHUrl (hostname=$doHHostname)")
        } else {
            // Legacy format: endpoint + port (plain UDP era)
            val oldEndpoint = profile["endpoint"] as? String
            val mapped = KNOWN_DOH_MAP[oldEndpoint]

            if (mapped != null) {
                doHUrl      = mapped.first
                doHHostname = mapped.second
                Log.i(TAG, "Legacy DNS profile migrated to DoH: $doHUrl")
            } else {
                // Unknown endpoint — fall back to Cloudflare and notify user
                doHUrl      = "https://1.1.1.1/dns-query"
                doHHostname = "cloudflare-dns.com"
                Log.w(TAG, "Unknown legacy DNS endpoint '$oldEndpoint' — migrated to Cloudflare DoH")
                NativeEventBus.postAlert(
                    alertType = "dns_profile_migrated",
                    severity  = "info",
                    title     = "DNS encryption upgraded",
                    message   = "Your DNS settings were upgraded to encrypted DNS (DoH). " +
                                "If you used a custom resolver, please re-configure in DNS Guard settings.",
                )
                vpnRef?.get()?.let { ctx ->
                    NativeEventBus.postSystemNotification(
                        context = ctx,
                        title = "DNS encryption upgraded",
                        body = "Your DNS settings were upgraded to encrypted DNS (DoH).",
                        severity = "warning"
                    )
                }
            }
        }
    }

    fun updateBlocklists(lists: List<Map<String, Any?>>) {
        blocklist.clear()
        for (list in lists) {
            @Suppress("UNCHECKED_CAST")
            val domains = list["domains"] as? List<String> ?: continue
            blocklist.addAll(domains)
        }
        Log.i(TAG, "Blocklist updated: ${blocklist.size} domains")
    }

    fun addDomain(domain: String)    = blocklist.add(domain.lowercase().trimEnd('.'))
    fun removeDomain(domain: String) = blocklist.remove(domain.lowercase().trimEnd('.'))
    fun isBlocked(domain: String): Boolean =
        blocklist.contains(domain.lowercase().trimEnd('.'))

    // ── Packet Interception ───────────────────────────────────────

    /**
     * Called by NetworkCloakVpnService for every UDP packet to port 53.
     *
     * Parses the DNS question, checks blocklist, and either:
     *   - Writes a well-formed NXDOMAIN response back to the TUN (blocked), or
     *   - Forwards the query to the DoH upstream and writes the response back.
     *
     * Failing silently (not writing anything back) would cause the app to wait
     * for a timeout instead of receiving an instant refusal — that was bug #7.
     */
    fun interceptPacket(packet: ByteArray, tunWriter: (ByteArray) -> Unit) {
        try {
            val ihl = (packet[0].toInt() and 0x0F) * 4
            val udpPayloadOffset = ihl + 8  // UDP header is 8 bytes

            if (packet.size <= udpPayloadOffset) return

            val dnsPayload = packet.copyOfRange(udpPayloadOffset, packet.size)
            val domain = parseDnsQuery(dnsPayload) ?: run {
                // Unparseable DNS query — forward as-is to upstream
                forwardDnsQuery(dnsPayload, tunWriter, packet, ihl)
                return
            }

            totalQueries++

            if (isBlocked(domain)) {
                blockedQueries++
                Log.d(TAG, "BLOCKED: $domain")

                NativeEventBus.postConnectionEvent(
                    uid = -1, appId = "dns", destHost = domain, destIp = "dns",
                    port = 53, protocol = "DNS", bytes = packet.size, allowed = false,
                )

                // Write a proper NXDOMAIN response — not silence.
                // Silence would make the app wait for a timeout (bug #7).
                val nxPacket = buildNxdomainPacket(packet, ihl, dnsPayload)
                tunWriter(nxPacket)
                return
            }

            // Allowed domain — forward via DoH
            forwardDnsQuery(dnsPayload, tunWriter, packet, ihl)

        } catch (e: Exception) {
            Log.w(TAG, "DNS interception error: ${e.message}")
            tunWriter(packet)  // fail open on unexpected error
        }
    }

    // ── DNS Query Parsing ─────────────────────────────────────────

    /** Parses the first QNAME from a raw DNS message. Returns "example.com" or null. */
    private fun parseDnsQuery(dns: ByteArray): String? {
        if (dns.size < 12) return null
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

    // ── DoH Forwarding ────────────────────────────────────────────

    /**
     * Forwards a DNS query to the configured DoH upstream using HTTPS POST
     * (RFC 8484 — DNS over HTTPS).
     *
     * Security properties:
     *  1. The TCP socket is protect()ed before the TLS handshake — the socket
     *     bypasses the TUN interface even though we're inside the VPN service.
     *     (Belt-and-suspenders: addDisallowedApplication already excludes our UID
     *     from the tunnel, but we keep protect() in case that changes.)
     *  2. The endpoint is an IP literal ("https://1.1.1.1/...") to avoid a
     *     DNS bootstrap loop when resolving the resolver's hostname.
     *  3. The TLS certificate is verified against doHHostname ("cloudflare-dns.com"),
     *     not the IP literal — the default verifier would fail on an IP, so we
     *     supply a custom verifier that checks against the expected hostname.
     *     IMPORTANT: this verifier is NOT unconditional — it uses the platform's
     *     default verifier logic against the pinned hostname.  Returning true
     *     unconditionally would silently disable MITM protection, recreating the
     *     exact vulnerability that DoH was added to fix.
     */
    private fun forwardDnsQuery(
        dnsPayload: ByteArray,
        tunWriter: (ByteArray) -> Unit,
        originalPacket: ByteArray,
        ihl: Int,
    ) {
        try {
            val svc = vpnRef?.get()

            // ── Build a protected raw socket ──────────────────────
            val rawSocket = Socket()
            svc?.protect(rawSocket)  // protect() BEFORE connect (belt-and-suspenders)
            
            // Set 5-second read/SO timeout (prevents read stalling the packet loop thread)
            rawSocket.soTimeout = 5_000

            // Parse IP + port from doHUrl: "https://<ip>/path"
            val url = java.net.URL(doHUrl)
            val host = url.host   // IP literal e.g. "1.1.1.1"
            val port = if (url.port > 0) url.port else 443

            rawSocket.connect(InetSocketAddress(host, port), 5_000)

            // Upgrade to TLS using the platform's default SSL context
            val sslContext = SSLContext.getDefault()
            val sslSocket = sslContext.socketFactory.createSocket(
                rawSocket, host, port, true
            ) as SSLSocket
            sslSocket.startHandshake()

            // Belt-and-suspenders: set SO_TIMEOUT on the SSL socket too.
            // rawSocket.soTimeout (line 245) may not reliably propagate through
            // the SSLSocket wrapper on all JVM implementations.
            sslSocket.soTimeout = 5_000

            // Verify cert against the pinned hostname — not the IP literal.
            // Never skip: unconditional "return true" would allow MITM.
            val defaultVerifier = HttpsURLConnection.getDefaultHostnameVerifier()
            val session = sslSocket.session
            val certValid = defaultVerifier.verify(doHHostname, session)
            if (!certValid) {
                Log.e(TAG, "DoH cert validation failed for hostname $doHHostname — aborting query")
                sslSocket.close()
                return
            }

            // ── POST DNS query (RFC 8484 wire format) ─────────────
            val path = if (url.path.isNotEmpty()) url.path else "/dns-query"
            val requestLine = "POST $path HTTP/1.1\r\n"
            val headers = "Host: $doHHostname\r\n" +
                          "Content-Type: application/dns-message\r\n" +
                          "Accept: application/dns-message\r\n" +
                          "Content-Length: ${dnsPayload.size}\r\n" +
                          "Connection: close\r\n\r\n"
            val out = sslSocket.outputStream
            out.write(requestLine.toByteArray(Charsets.US_ASCII))
            out.write(headers.toByteArray(Charsets.US_ASCII))
            out.write(dnsPayload)
            out.flush()

            // ── Read HTTP response headers & body ─────────────────
            val dnsResponse = readHttpDnsResponse(sslSocket.inputStream)
            sslSocket.close()

            if (dnsResponse == null) {
                Log.w(TAG, "DoH response parse or non-200 status")
                return
            }

            // Reconstruct IP+UDP packet for the TUN interface
            val responsePacket = buildDnsResponsePacket(originalPacket, ihl, dnsResponse)
            tunWriter(responsePacket)

        } catch (e: Exception) {
            Log.w(TAG, "DoH forward failed: ${e.message}")
        }
    }

    /**
     * Reads a DoH HTTP/1.1 response from the SSL socket input stream.
     * Parses the HTTP status line (must be 200 OK), headers (Content-Length / Transfer-Encoding),
     * and reads the body payload immediately without waiting for socket EOF.
     */
    private fun readHttpDnsResponse(input: java.io.InputStream): ByteArray? {
        val headerStream = ByteArrayOutputStream()
        var b: Int
        var prev3 = 0
        var prev2 = 0
        var prev1 = 0

        // Read header section byte-by-byte until \r\n\r\n
        while (input.read().also { b = it } != -1) {
            headerStream.write(b)
            if (prev3 == '\r'.code && prev2 == '\n'.code && prev1 == '\r'.code && b == '\n'.code) {
                break
            }
            prev3 = prev2
            prev2 = prev1
            prev1 = b
        }

        val headerBytes = headerStream.toByteArray()
        if (headerBytes.isEmpty()) return null

        val headerText = String(headerBytes, Charsets.ISO_8859_1)
        val lines = headerText.split("\r\n")
        if (lines.isEmpty()) return null

        // Verify status line e.g. "HTTP/1.1 200 OK"
        val statusLine = lines[0]
        if (!statusLine.contains(" 200 ")) {
            Log.w(TAG, "DoH HTTP response status non-200: $statusLine")
            return null
        }

        // Parse headers
        var contentLength = -1
        var isChunked = false
        for (i in 1 until lines.size) {
            val line = lines[i]
            val colonIdx = line.indexOf(':')
            if (colonIdx > 0) {
                val key = line.substring(0, colonIdx).trim().lowercase()
                val value = line.substring(colonIdx + 1).trim()
                if (key == "content-length") {
                    contentLength = value.toIntOrNull() ?: -1
                } else if (key == "transfer-encoding" && value.lowercase().contains("chunked")) {
                    isChunked = true
                }
            }
        }

        // Read payload body based on headers
        return when {
            contentLength >= 0 -> {
                val body = ByteArray(contentLength)
                var totalRead = 0
                while (totalRead < contentLength) {
                    val read = input.read(body, totalRead, contentLength - totalRead)
                    if (read == -1) break
                    totalRead += read
                }
                if (totalRead == contentLength) body else null
            }
            isChunked -> {
                readChunkedBody(input)
            }
            else -> {
                // Fallback if no length header: read until EOF or timeout
                val bodyStream = ByteArrayOutputStream()
                val buf = ByteArray(1024)
                var len: Int
                try {
                    while (input.read(buf).also { len = it } != -1) {
                        bodyStream.write(buf, 0, len)
                    }
                } catch (_: Exception) {}
                bodyStream.toByteArray().takeIf { it.isNotEmpty() }
            }
        }
    }

    /** Un-chunks HTTP chunked encoding stream data. */
    private fun readChunkedBody(input: java.io.InputStream): ByteArray? {
        val out = ByteArrayOutputStream()
        val reader = java.io.BufferedReader(java.io.InputStreamReader(input, Charsets.ISO_8859_1))
        while (true) {
            val hexLine = reader.readLine() ?: break
            val chunkSize = hexLine.trim().split(";")[0].toIntOrNull(16) ?: break
            if (chunkSize == 0) break

            var remaining = chunkSize
            val buf = ByteArray(1024)
            while (remaining > 0) {
                val readLen = Math.min(remaining, buf.size)
                val bytesRead = input.read(buf, 0, readLen)
                if (bytesRead == -1) break
                out.write(buf, 0, bytesRead)
                remaining -= bytesRead
            }
            // Read trailing CRLF after chunk
            input.read()
            input.read()
        }
        return out.toByteArray().takeIf { it.isNotEmpty() }
    }

    // ── Packet Construction ───────────────────────────────────────

    /**
     * Builds an NXDOMAIN (RCODE=3) DNS response for a blocked domain.
     *
     * Copies the question section verbatim and sets:
     *   QR=1 (response), OPCODE=0, AA=0, TC=0, RD=1, RA=1, RCODE=3
     *
     * This gives the requesting app an instant authoritative refusal
     * rather than a multi-second timeout (bug #7 fix).
     */
    private fun buildNxdomainPacket(
        originalPacket: ByteArray,
        ihl: Int,
        dnsQuery: ByteArray,
    ): ByteArray {
        if (dnsQuery.size < 12) return originalPacket

        // Build DNS NXDOMAIN payload based on the original query
        val nxDns = dnsQuery.copyOf()
        // Flags: QR=1, OPCODE=0, AA=0, TC=0, RD=1, RA=1, Z=0, RCODE=3
        // Original query flags are at bytes 2-3; we override:
        nxDns[2] = 0x81.toByte()  // QR=1 AA=0 TC=0 RD=1
        nxDns[3] = 0x83.toByte()  // RA=1 Z=0 RCODE=3 (NXDOMAIN)
        // ANCOUNT, NSCOUNT, ARCOUNT = 0 (already 0 in a query, no change needed)

        return buildDnsResponsePacket(originalPacket, ihl, nxDns)
    }

    /**
     * Wraps a DNS payload in an IP+UDP response packet suitable for writing
     * back into the TUN file descriptor.
     *
     * Swaps src/dst IP addresses and ports (we're responding from the upstream
     * position), updates the length fields, and computes correct checksums.
     *
     * IPv4 checksum: mandatory per RFC 791.
     * UDP checksum:  left as 0 — valid for IPv4 per RFC 768.
     */
    private fun buildDnsResponsePacket(
        originalPacket: ByteArray,
        ihl: Int,
        dnsPayload: ByteArray,
    ): ByteArray {
        val udpLen = 8 + dnsPayload.size
        val ipLen  = ihl + udpLen
        val out    = ByteArrayOutputStream(ipLen)

        // ── IPv4 header: swap src ↔ dst ───────────────────────────
        val ip = originalPacket.copyOf(ihl)
        val srcIp = ip.copyOfRange(12, 16)
        val dstIp = ip.copyOfRange(16, 20)
        System.arraycopy(dstIp, 0, ip, 12, 4)  // new src = original dst
        System.arraycopy(srcIp, 0, ip, 16, 4)  // new dst = original src
        // Update total length
        ip[2] = ((ipLen shr 8) and 0xFF).toByte()
        ip[3] = (ipLen and 0xFF).toByte()
        // Compute real checksum (bug #8 fix — zero is invalid on TUN write)
        ip[10] = 0; ip[11] = 0
        val ipCk = PacketUtils.ipv4Checksum(ip)
        PacketUtils.writeChecksum(ip, 10, ipCk)

        // ── UDP header: swap src ↔ dst port ──────────────────────
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
        // UDP checksum = 0: valid for IPv4 per RFC 768 (unlike TCP which is mandatory)
        udpHeader[6] = 0; udpHeader[7] = 0

        out.write(ip)
        out.write(udpHeader)
        out.write(dnsPayload)
        return out.toByteArray()
    }
}
