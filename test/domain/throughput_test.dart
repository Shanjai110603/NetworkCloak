import 'package:flutter_test/flutter_test.dart';
import 'package:network_cloak/presentation/providers/providers.dart';

void main() {
  group('ThroughputState Unit Tests', () {
    test('constructs with initial rolling state correctly', () {
      final initial = ThroughputState(
        speedHistory: List.filled(15, 0.0),
        currentSpeed: 0.0,
        peakSpeed: 0.0,
        totalBytes: 0,
      );

      expect(initial.speedHistory.length, equals(15));
      expect(initial.speedHistory.every((val) => val == 0.0), isTrue);
      expect(initial.currentSpeed, equals(0.0));
      expect(initial.peakSpeed, equals(0.0));
      expect(initial.totalBytes, equals(0));
    });

    test('copyWith updates specific properties correctly', () {
      final initial = ThroughputState(
        speedHistory: List.filled(15, 0.0),
        currentSpeed: 0.0,
        peakSpeed: 0.0,
        totalBytes: 0,
      );

      final updated = initial.copyWith(
        currentSpeed: 1024.0,
        peakSpeed: 2048.0,
        totalBytes: 50000,
      );

      expect(updated.speedHistory.length, equals(15));
      expect(updated.currentSpeed, equals(1024.0));
      expect(updated.peakSpeed, equals(2048.0));
      expect(updated.totalBytes, equals(50000));
    });
  });
}
