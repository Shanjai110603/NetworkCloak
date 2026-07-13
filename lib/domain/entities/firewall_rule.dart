import '../enums/rule_action.dart';
import '../enums/rule_priority.dart';

/// Immutable domain entity representing a single firewall rule.
class FirewallRule {
  const FirewallRule({
    required this.id,
    this.appId,
    required this.action,
    required this.priority,
    required this.conditionsJson,
    this.profileId,
    this.isGlobal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? appId;
  final RuleAction action;
  final RulePriority priority;
  final String conditionsJson; // parsed on demand
  final String? profileId;
  final bool isGlobal;
  final DateTime createdAt;
  final DateTime updatedAt;

  FirewallRule copyWith({
    String? id,
    String? appId,
    RuleAction? action,
    RulePriority? priority,
    String? conditionsJson,
    String? profileId,
    bool? isGlobal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirewallRule(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      conditionsJson: conditionsJson ?? this.conditionsJson,
      profileId: profileId ?? this.profileId,
      isGlobal: isGlobal ?? this.isGlobal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'FirewallRule(id: $id, app: $appId, action: ${action.label}, priority: ${priority.value})';
}
