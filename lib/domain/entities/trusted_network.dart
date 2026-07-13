import '../enums/network_trust_level.dart';

/// A network entry in the user's trust list.
class TrustedNetwork {
  const TrustedNetwork({
    required this.id,
    required this.ssid,
    required this.bssid,
    required this.trustLevel,
    required this.profileId,
  });

  final String id;
  final String ssid;
  final String bssid;
  final NetworkTrustLevel trustLevel;
  final String profileId; // Associated profile to auto-activate
}

/// Live snapshot of the currently connected network.
class NetworkStatus {
  const NetworkStatus({
    required this.trustLevel,
    this.ssid,
    this.bssid,
    this.authType,
    this.isRoaming = false,
    this.hasCaptivePortal = false,
    this.isCellular = false,
  });

  final NetworkTrustLevel trustLevel;
  final String? ssid;
  final String? bssid;
  final String? authType;
  final bool isRoaming;
  final bool hasCaptivePortal;
  final bool isCellular;

  static const disconnected = NetworkStatus(
    trustLevel: NetworkTrustLevel.unknown,
  );

  String get displayName {
    if (isCellular) return 'Mobile Data';
    return ssid ?? 'Unknown Network';
  }
}
