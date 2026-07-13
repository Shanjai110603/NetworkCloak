import '../../entities/trusted_network.dart';
import '../../enums/network_trust_level.dart';
import '../../enums/protection_mode.dart';

/// Input signals from ConnectivityMonitor / WifiAnalyzer.
class NetworkClassificationInput {
  const NetworkClassificationInput({
    this.ssid,
    this.bssid,
    this.authType,
    required this.isRoaming,
    required this.hasCaptivePortal,
    required this.isCellular,
    required this.trustedNetworks,
  });

  final String? ssid;
  final String? bssid;
  final String? authType; // 'open' | 'WEP' | 'WPA-TKIP' | 'WPA2' | etc.
  final bool isRoaming;
  final bool hasCaptivePortal;
  final bool isCellular;
  final List<TrustedNetwork> trustedNetworks;
}

/// Result of network classification.
class NetworkClassificationResult {
  const NetworkClassificationResult({
    required this.trustLevel,
    required this.suggestedMode,
    this.matchedNetwork,
    required this.plainAlert,
    required this.autoSwitched,
  });

  final NetworkTrustLevel trustLevel;
  final ProtectionMode suggestedMode;
  final TrustedNetwork? matchedNetwork;
  final String? plainAlert; // Non-null means user should see a notification
  final bool autoSwitched;
}

/// ─────────────────────────────────────────────────────────────
/// Shield Engine: evaluates all 10 classification signals and
/// returns the trust level + suggested protection mode.
/// ─────────────────────────────────────────────────────────────
class ClassifyNetworkUseCase {
  const ClassifyNetworkUseCase();

  NetworkClassificationResult classify(NetworkClassificationInput input) {
    // Signal 10: Cellular — always trusted
    if (input.isCellular) {
      final mode = input.isRoaming
          ? ProtectionMode.travel
          : ProtectionMode.home;
      final alert = input.isRoaming
          ? "You're roaming. Travel mode activated to protect your data."
          : null;
      return NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.trusted,
        suggestedMode: mode,
        plainAlert: alert,
        autoSwitched: true,
      );
    }

    // Signals 1 & 2: Check trusted network list
    final matched = _findTrusted(input);
    if (matched != null) {
      // Signal 3: BSSID mismatch → evil twin
      if (input.bssid != null && input.bssid != matched.bssid) {
        return NetworkClassificationResult(
          trustLevel: NetworkTrustLevel.hostile,
          suggestedMode: ProtectionMode.lockdown,
          matchedNetwork: matched,
          plainAlert:
              'Warning: This Wi-Fi looks different from the one you trusted before. Tap to review.',
          autoSwitched: true,
        );
      }
      // Known good trusted network
      return NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.trusted,
        suggestedMode: ProtectionMode.home,
        matchedNetwork: matched,
        plainAlert: null,
        autoSwitched: true,
      );
    }

    // Signal 4: Open network
    if (input.authType == 'open' || input.authType == null) {
      return const NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.publicWifi,
        suggestedMode: ProtectionMode.publicWifi,
        plainAlert:
            'Connected to an open Wi-Fi network. Public Wi-Fi mode activated.',
        autoSwitched: true,
      );
    }

    // Signal 5: WEP — old and insecure
    if (input.authType == 'WEP') {
      return const NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.publicWifi,
        suggestedMode: ProtectionMode.publicWifi,
        plainAlert:
            'This network uses weak encryption (WEP). Public Wi-Fi mode activated.',
        autoSwitched: true,
      );
    }

    // Signal 6: WPA-TKIP — outdated
    if (input.authType?.contains('TKIP') == true) {
      return const NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.publicWifi,
        suggestedMode: ProtectionMode.publicWifi,
        plainAlert:
            'This network uses outdated encryption. Public Wi-Fi mode activated.',
        autoSwitched: true,
      );
    }

    // Signal 7: Captive portal
    if (input.hasCaptivePortal) {
      return const NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.unknown,
        suggestedMode: ProtectionMode.publicWifi,
        plainAlert:
            'This network requires a login page. Protection enabled.',
        autoSwitched: true,
      );
    }

    // Signal 8: Roaming
    if (input.isRoaming) {
      return const NetworkClassificationResult(
        trustLevel: NetworkTrustLevel.unknown,
        suggestedMode: ProtectionMode.travel,
        plainAlert:
            "You're roaming. Travel mode activated to protect your data.",
        autoSwitched: true,
      );
    }

    // Signal 9: Encrypted but unknown network
    return const NetworkClassificationResult(
      trustLevel: NetworkTrustLevel.unknown,
      suggestedMode: ProtectionMode.publicWifi,
      plainAlert:
          'Connected to an unfamiliar network. Protection enabled.',
      autoSwitched: true,
    );
  }

  TrustedNetwork? _findTrusted(NetworkClassificationInput input) {
    if (input.ssid == null) return null;
    try {
      return input.trustedNetworks.firstWhere(
        (n) => n.ssid == input.ssid,
      );
    } catch (_) {
      return null;
    }
  }
}
