
/// A single DNS resolution log entry.
class DnsLogEntry {
  const DnsLogEntry({
    required this.id,
    required this.domain,
    required this.action,
    this.category,
    this.latencyMs,
    this.appId,
    this.countryCode,
    required this.timestamp,
  });

  final int id;
  final String domain;
  final String action; // 'allowed' | 'blocked'
  final String? category; // blocklist category that matched
  final int? latencyMs;
  final String? appId;
  final String? countryCode;
  final DateTime timestamp;

  bool get wasBlocked => action == 'blocked';
}
