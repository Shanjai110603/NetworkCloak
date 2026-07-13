import '../enums/dns_protocol.dart';

/// DNS provider configuration.
class DnsProfile {
  const DnsProfile({
    required this.id,
    required this.name,
    required this.provider,
    required this.protocol,
    required this.endpoint,
    required this.enabledCategories,
  });

  final String id;
  final String name;
  final String provider; // 'cloudflare', 'quad9', 'google', 'custom', etc.
  final DnsProtocol protocol;
  final String endpoint;
  final List<String> enabledCategories;

  static const defaultProfile = DnsProfile(
    id: 'default_cloudflare',
    name: 'Cloudflare (Private)',
    provider: 'cloudflare',
    protocol: DnsProtocol.doh,
    endpoint: 'https://cloudflare-dns.com/dns-query',
    enabledCategories: ['advertising', 'analytics', 'telemetry', 'tracking',
      'malware', 'phishing', 'cryptomining', 'ransomware'],
  );
}

/// An individual DNS blocklist category entry.
class DnsBlocklist {
  const DnsBlocklist({
    required this.id,
    required this.name,
    required this.category,
    required this.enabled,
    required this.url,
    this.checksum,
    required this.updatedAt,
    this.domainCount,
  });

  final String id;
  final String name;
  final String category;
  final bool enabled;
  final String url;
  final String? checksum;
  final DateTime updatedAt;
  final int? domainCount;

  DnsBlocklist copyWith({bool? enabled}) {
    return DnsBlocklist(
      id: id,
      name: name,
      category: category,
      enabled: enabled ?? this.enabled,
      url: url,
      checksum: checksum,
      updatedAt: updatedAt,
      domainCount: domainCount,
    );
  }
}
