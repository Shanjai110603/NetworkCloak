import 'package:flutter_test/flutter_test.dart';
import 'package:network_cloak/domain/entities/application_info.dart';
import 'package:network_cloak/domain/entities/firewall_rule.dart';
import 'package:network_cloak/domain/enums/rule_action.dart';
import 'package:network_cloak/domain/enums/rule_priority.dart';

void main() {
  group('Security Risk Indicators Model Tests', () {
    test('ApplicationInfo constructs with security risk fields correctly', () {
      final app = ApplicationInfo(
        id: 'com.dangerous.app',
        packageName: 'com.dangerous.app',
        displayName: 'Dangerous App',
        firstSeen: DateTime.now(),
        riskLevel: 'high',
        riskScore: 75,
        riskReasons: const [
          'Requests background location access',
          'Application has debuggable flag enabled'
        ],
      );

      expect(app.riskLevel, equals('high'));
      expect(app.riskScore, equals(75));
      expect(app.riskReasons?.length, equals(2));
      expect(app.riskReasons?.first, contains('background location'));
    });

    test('FirewallRule constructs and formats risk string correctly', () {
      final rule = FirewallRule(
        id: 'rule_1',
        appId: 'com.dangerous.app',
        action: RuleAction.block,
        priority: RulePriority.manualApp,
        conditionsJson: '{}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        riskLevel: 'high',
        riskScore: 75,
        riskReasons: const ['Sample reason'],
      );

      expect(rule.riskLevel, equals('high'));
      expect(rule.riskScore, equals(75));
      expect(rule.riskReasons, isNotNull);
      expect(rule.toString(), contains('risk: high (75)'));
    });

    test('FirewallRule copyWith duplicates risk parameters correctly', () {
      final rule = FirewallRule(
        id: 'rule_1',
        appId: 'com.dangerous.app',
        action: RuleAction.block,
        priority: RulePriority.manualApp,
        conditionsJson: '{}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        riskLevel: 'medium',
        riskScore: 35,
        riskReasons: const ['Reason A'],
      );

      final copied = rule.copyWith(
        riskLevel: 'low',
        riskScore: 10,
        riskReasons: const ['Reason B'],
      );

      expect(copied.riskLevel, equals('low'));
      expect(copied.riskScore, equals(10));
      expect(copied.riskReasons?.first, equals('Reason B'));
    });
  });
}
