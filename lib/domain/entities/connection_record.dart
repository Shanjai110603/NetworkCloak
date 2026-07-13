import '../enums/rule_action.dart';

/// A historical connection event logged by the firewall engine.
class ConnectionRecord {
  const ConnectionRecord({
    required this.id,
    required this.appId,
    required this.destHost,
    this.destIp,
    this.port,
    this.protocol,
    this.ruleId,
    required this.action,
    this.bytes,
    this.countryCode,
    required this.timestamp,
  });

  final int id;
  final String appId;
  final String destHost;
  final String? destIp;
  final int? port;
  final String? protocol;
  final String? ruleId;
  final RuleAction action;
  final int? bytes;
  final String? countryCode;
  final DateTime timestamp;

  bool get wasBlocked => action.isBlocking;

  /// Country flag emoji derived from ISO 3166-1 alpha-2 country code.
  String get countryFlag {
    if (countryCode == null || countryCode!.length != 2) return '🌐';
    const base = 0x1F1E6 - 0x41;
    final chars = countryCode!.toUpperCase().codeUnits;
    return String.fromCharCode(base + chars[0]) +
        String.fromCharCode(base + chars[1]);
  }
}

/// A live (currently active) connection from the VPN engine.
class LiveConnection {
  const LiveConnection({
    required this.id,
    required this.appId,
    required this.dest,
    required this.protocol,
    required this.startedAt,
    required this.bytes,
  });

  final String id;
  final String appId;
  final String dest;
  final String protocol;
  final DateTime startedAt;
  final int bytes;

  Duration get duration => DateTime.now().difference(startedAt);
}
