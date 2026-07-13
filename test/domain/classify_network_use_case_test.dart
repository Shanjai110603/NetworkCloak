import 'package:flutter_test/flutter_test.dart';
import 'package:network_cloak/domain/entities/trusted_network.dart';
import 'package:network_cloak/domain/enums/network_trust_level.dart';
import 'package:network_cloak/domain/enums/protection_mode.dart';
import 'package:network_cloak/domain/usecases/shield/classify_network_use_case.dart';

void main() {
  const classifier = ClassifyNetworkUseCase();

  NetworkClassificationInput input({
    String? ssid,
    String? bssid,
    String? authType,
    bool isRoaming = false,
    bool hasCaptivePortal = false,
    bool isCellular = false,
    List<TrustedNetwork> trustedNetworks = const [],
  }) {
    return NetworkClassificationInput(
      ssid: ssid,
      bssid: bssid,
      authType: authType,
      isRoaming: isRoaming,
      hasCaptivePortal: hasCaptivePortal,
      isCellular: isCellular,
      trustedNetworks: trustedNetworks,
    );
  }

  group('ClassifyNetworkUseCase', () {
    test('cellular → trusted, Home mode', () {
      final result = classifier.classify(input(isCellular: true));
      expect(result.trustLevel, equals(NetworkTrustLevel.trusted));
      expect(result.suggestedMode, equals(ProtectionMode.home));
    });

    test('cellular + roaming → trusted, Travel mode', () {
      final result = classifier.classify(input(isCellular: true, isRoaming: true));
      expect(result.trustLevel, equals(NetworkTrustLevel.trusted));
      expect(result.suggestedMode, equals(ProtectionMode.travel));
      expect(result.plainAlert, isNotNull);
    });

    test('open Wi-Fi → public trust, PublicWifi mode', () {
      final result = classifier.classify(input(ssid: 'CoffeeShop', authType: 'open'));
      expect(result.trustLevel, equals(NetworkTrustLevel.publicWifi));
      expect(result.suggestedMode, equals(ProtectionMode.publicWifi));
    });

    test('WEP network → public trust', () {
      final result = classifier.classify(input(ssid: 'Hotel', authType: 'WEP'));
      expect(result.trustLevel, equals(NetworkTrustLevel.publicWifi));
    });

    test('captive portal → unknown trust', () {
      final result = classifier.classify(input(
        ssid: 'Airport',
        authType: 'WPA2',
        hasCaptivePortal: true,
      ));
      expect(result.trustLevel, equals(NetworkTrustLevel.unknown));
    });

    test('known SSID + matching BSSID → trusted', () {
      const trusted = TrustedNetwork(
        id: 't1',
        ssid: 'HomeNetwork',
        bssid: 'AA:BB:CC:DD:EE:FF',
        trustLevel: NetworkTrustLevel.trusted,
        profileId: 'home',
      );
      final result = classifier.classify(input(
        ssid: 'HomeNetwork',
        bssid: 'AA:BB:CC:DD:EE:FF',
        authType: 'WPA2',
        trustedNetworks: [trusted],
      ));
      expect(result.trustLevel, equals(NetworkTrustLevel.trusted));
      expect(result.matchedNetwork, isNotNull);
    });

    test('known SSID but different BSSID → hostile (evil twin)', () {
      const trusted = TrustedNetwork(
        id: 't2',
        ssid: 'HomeNetwork',
        bssid: 'AA:BB:CC:DD:EE:FF',
        trustLevel: NetworkTrustLevel.trusted,
        profileId: 'home',
      );
      final result = classifier.classify(input(
        ssid: 'HomeNetwork',
        bssid: '11:22:33:44:55:66',  // Different BSSID!
        authType: 'WPA2',
        trustedNetworks: [trusted],
      ));
      expect(result.trustLevel, equals(NetworkTrustLevel.hostile));
      expect(result.suggestedMode, equals(ProtectionMode.lockdown));
      expect(result.plainAlert, contains('Warning'));
    });
  });
}
