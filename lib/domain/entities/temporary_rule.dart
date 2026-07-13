import '../enums/rule_action.dart';

/// A temporary rule that auto-expires at [endAt].
/// On expiry, the engine restores [previousRuleId].
class TemporaryRuleEntity {
  const TemporaryRuleEntity({
    required this.id,
    required this.appId,
    required this.action,
    required this.startAt,
    required this.endAt,
    this.previousRuleId,
    this.conditionsJson,
  });

  final String id;
  final String appId;
  final RuleAction action;
  final DateTime startAt;
  final DateTime endAt;
  final String? previousRuleId;
  final String? conditionsJson;

  bool get isExpired => DateTime.now().isAfter(endAt);
}

/// A session rule — cleared on reboot or network change.
class SessionRuleEntity {
  const SessionRuleEntity({
    required this.id,
    required this.appId,
    required this.action,
    required this.sessionId,
  });

  final String id;
  final String appId;
  final RuleAction action;
  final String sessionId;
}
