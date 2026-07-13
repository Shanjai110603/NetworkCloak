import 'package:flutter_test/flutter_test.dart';
import 'package:network_cloak/domain/entities/firewall_rule.dart';
import 'package:network_cloak/domain/entities/temporary_rule.dart';
import 'package:network_cloak/domain/enums/network_trust_level.dart';
import 'package:network_cloak/domain/enums/protection_mode.dart';
import 'package:network_cloak/domain/enums/rule_action.dart';
import 'package:network_cloak/domain/enums/rule_priority.dart';
import 'package:network_cloak/domain/usecases/firewall/evaluate_rule_use_case.dart';

void main() {
  // ── Shared context factory ─────────────────────────────────
  RuleEvaluationContext ctx({
    String appId = 'com.example.app',
    String destIp = '93.184.216.34',
    int destPort = 443,
    String protocol = 'TCP',
    bool isBackground = false,
    bool isScreenOn = true,
    NetworkTrustLevel networkTrust = NetworkTrustLevel.trusted,
    ProtectionMode activeMode = ProtectionMode.home,
  }) {
    return RuleEvaluationContext(
      appId: appId,
      destIp: destIp,
      destPort: destPort,
      protocol: protocol,
      isBackground: isBackground,
      isScreenOn: isScreenOn,
      networkTrust: networkTrust,
      activeMode: activeMode,
    );
  }

  FirewallRule manualRule({
    required String appId,
    required RuleAction action,
    String conditionsJson = '{}',
    RulePriority priority = RulePriority.manualApp,
  }) {
    return FirewallRule(
      id: 'test_${action.name}',
      appId: appId,
      action: action,
      priority: priority,
      conditionsJson: conditionsJson,
      isGlobal: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  EvaluateRuleUseCase usecase({
    bool lockdownActive = false,
    List<String> lockdownAllowlist = const [],
    List<TemporaryRuleEntity> temporaryRules = const [],
    List<SessionRuleEntity> sessionRules = const [],
    List<FirewallRule> manualRules = const [],
    List<FirewallRule> profileRules = const [],
    List<FirewallRule> globalRules = const [],
    RuleAction defaultAction = RuleAction.ask,
  }) {
    return EvaluateRuleUseCase(
      lockdownActive: lockdownActive,
      lockdownAllowlist: lockdownAllowlist,
      temporaryRules: temporaryRules,
      sessionRules: sessionRules,
      manualRules: manualRules,
      profileRules: profileRules,
      globalRules: globalRules,
      defaultAction: defaultAction,
    );
  }

  // ── P1: Emergency Lockdown ────────────────────────────────
  group('P1 — Lockdown', () {
    test('blocks all apps when lockdown is active', () {
      final uc = usecase(lockdownActive: true);
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.block));
      expect(result.matchedPriority, equals(RulePriority.emergencyLockdown));
    });

    test('allows allowlisted apps during lockdown', () {
      final uc = usecase(
        lockdownActive: true,
        lockdownAllowlist: ['com.android.phone'],
      );
      final result = uc.evaluate(ctx(appId: 'com.android.phone'));
      expect(result.action, equals(RuleAction.allow));
      expect(result.matchedPriority, equals(RulePriority.emergencyLockdown));
    });

    test('blocks non-allowlisted apps during lockdown even with manual allow', () {
      final uc = usecase(
        lockdownActive: true,
        manualRules: [manualRule(appId: 'com.example.app', action: RuleAction.allow)],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.block));
    });
  });

  // ── P2: Temporary Rules ───────────────────────────────────
  group('P2 — Temporary Rules', () {
    test('applies non-expired temporary block', () {
      final tmp = TemporaryRuleEntity(
        id: 'tmp1',
        appId: 'com.example.app',
        action: RuleAction.block,
        startAt: DateTime.now().subtract(const Duration(minutes: 1)),
        endAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      final uc = usecase(temporaryRules: [tmp]);
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.block));
      expect(result.matchedPriority, equals(RulePriority.temporary));
    });

    test('ignores expired temporary rule', () {
      final tmp = TemporaryRuleEntity(
        id: 'tmp2',
        appId: 'com.example.app',
        action: RuleAction.block,
        startAt: DateTime.now().subtract(const Duration(hours: 2)),
        endAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final uc = usecase(temporaryRules: [tmp], defaultAction: RuleAction.allow);
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      // Falls through to default
      expect(result.action, equals(RuleAction.allow));
      expect(result.matchedPriority, equals(RulePriority.defaultBehavior));
    });
  });

  // ── P4: Manual App Rules ──────────────────────────────────
  group('P4 — Manual App Rules', () {
    test('applies manual allow rule for matching app', () {
      final uc = usecase(
        manualRules: [manualRule(appId: 'com.example.app', action: RuleAction.allow)],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.allow));
      expect(result.matchedPriority, equals(RulePriority.manualApp));
    });

    test('applies manual block rule for matching app', () {
      final uc = usecase(
        manualRules: [manualRule(appId: 'com.example.app', action: RuleAction.block)],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.block));
    });

    test('does not apply manual rule for different app', () {
      final uc = usecase(
        manualRules: [manualRule(appId: 'com.other.app', action: RuleAction.block)],
        defaultAction: RuleAction.allow,
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.allow));
      expect(result.matchedPriority, equals(RulePriority.defaultBehavior));
    });
  });

  // ── Condition: blockBackground ────────────────────────────
  group('Condition — blockBackground', () {
    test('blocks app when it is in background with blockBackground rule', () {
      final uc = usecase(
        manualRules: [
          manualRule(appId: 'com.example.app', action: RuleAction.blockBackground)
        ],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app', isBackground: true));
      expect(result.action, equals(RuleAction.block));
    });

    test('allows app when it is in foreground with blockBackground rule', () {
      final uc = usecase(
        manualRules: [
          manualRule(appId: 'com.example.app', action: RuleAction.blockBackground)
        ],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app', isBackground: false));
      expect(result.action, equals(RuleAction.allow));
    });
  });

  // ── Condition: LAN only ───────────────────────────────────
  group('Condition — allowLanOnly', () {
    test('allows LAN destination with allowLanOnly rule', () {
      final uc = usecase(
        manualRules: [
          manualRule(appId: 'com.example.app', action: RuleAction.allowLanOnly)
        ],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app', destIp: '192.168.1.100'));
      expect(result.action, equals(RuleAction.allow));
    });

    test('blocks internet destination with allowLanOnly rule', () {
      final uc = usecase(
        manualRules: [
          manualRule(appId: 'com.example.app', action: RuleAction.allowLanOnly)
        ],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app', destIp: '93.184.216.34'));
      expect(result.action, equals(RuleAction.block));
    });
  });

  // ── P7: Default Behaviour ─────────────────────────────────
  group('P7 — Default Behaviour', () {
    test('uses default action when no rules match', () {
      final uc = usecase(defaultAction: RuleAction.block);
      final result = uc.evaluate(ctx());
      expect(result.action, equals(RuleAction.block));
      expect(result.matchedPriority, equals(RulePriority.defaultBehavior));
    });

    test('plain reason is non-empty', () {
      final uc = usecase(defaultAction: RuleAction.allow);
      final result = uc.evaluate(ctx());
      expect(result.plainReason, isNotEmpty);
    });
  });

  // ── Priority ordering ─────────────────────────────────────
  group('Priority ordering', () {
    test('temporary rule beats manual rule', () {
      final tmp = TemporaryRuleEntity(
        id: 'tmp3',
        appId: 'com.example.app',
        action: RuleAction.block,
        startAt: DateTime.now().subtract(const Duration(minutes: 1)),
        endAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      final uc = usecase(
        temporaryRules: [tmp],
        manualRules: [manualRule(appId: 'com.example.app', action: RuleAction.allow)],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      // P2 must win over P4
      expect(result.matchedPriority, equals(RulePriority.temporary));
      expect(result.action, equals(RuleAction.block));
    });

    test('manual rule beats profile rule', () {
      final uc = usecase(
        manualRules: [manualRule(appId: 'com.example.app', action: RuleAction.block)],
        profileRules: [manualRule(
          appId: 'com.example.app',
          action: RuleAction.allow,
          priority: RulePriority.profile,
        )],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.matchedPriority, equals(RulePriority.manualApp));
      expect(result.action, equals(RuleAction.block));
    });

    test('same priority level: block overrides allow', () {
      final olderBlock = FirewallRule(
        id: 'older_block',
        appId: 'com.example.app',
        action: RuleAction.block,
        priority: RulePriority.manualApp,
        conditionsJson: '{}',
        isGlobal: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final newerAllow = FirewallRule(
        id: 'newer_allow',
        appId: 'com.example.app',
        action: RuleAction.allow,
        priority: RulePriority.manualApp,
        conditionsJson: '{}',
        isGlobal: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final uc = usecase(
        manualRules: [newerAllow, olderBlock],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.action, equals(RuleAction.block));
    });

    test('same priority level and action: newest wins', () {
      final olderAllow = FirewallRule(
        id: 'older_allow',
        appId: 'com.example.app',
        action: RuleAction.allow,
        priority: RulePriority.manualApp,
        conditionsJson: '{}',
        isGlobal: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final newerAllow = FirewallRule(
        id: 'newer_allow',
        appId: 'com.example.app',
        action: RuleAction.allow,
        priority: RulePriority.manualApp,
        conditionsJson: '{}',
        isGlobal: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final uc = usecase(
        manualRules: [olderAllow, newerAllow],
      );
      final result = uc.evaluate(ctx(appId: 'com.example.app'));
      expect(result.matchedRuleId, equals('newer_allow'));
    });
  });
}
