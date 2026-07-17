import '../enums/rule_action.dart';
import '../enums/rule_priority.dart';

/// Immutable domain entity representing a single firewall rule.
///
/// The three optional fields ([displayName], [iconBytes], [isSystemApp])
/// are populated at load time from the native PackageManager via the merge
/// step in FirewallRulesNotifier._load(). They are transient UI-only fields
/// and are NEVER written to the Drift database.
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
    // Transient UI fields — populated from PackageManager, not persisted
    this.displayName,
    this.iconBytes,
    this.isSystemApp = false,
    this.riskLevel,
    this.riskScore,
    this.riskReasons,
  });

  final String id;
  final String? appId;
  final RuleAction action;
  final RulePriority priority;
  final String conditionsJson;
  final String? profileId;
  final bool isGlobal;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Human-readable app name from PackageManager (e.g. "Google Chrome").
  final String? displayName;

  /// PNG icon bytes from PackageManager, base64-decoded.
  final List<int>? iconBytes;

  /// True if this app has the Android FLAG_SYSTEM flag set.
  final bool isSystemApp;

  /// Computed security risk category level ("low", "medium", "high").
  final String? riskLevel;

  /// Computed security risk rating score (0 to 100).
  final int? riskScore;

  /// Human-readable reasons identifying dangerous permissions/flags.
  final List<String>? riskReasons;

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
    String? displayName,
    List<int>? iconBytes,
    bool? isSystemApp,
    String? riskLevel,
    int? riskScore,
    List<String>? riskReasons,
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
      displayName: displayName ?? this.displayName,
      iconBytes: iconBytes ?? this.iconBytes,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      riskReasons: riskReasons ?? this.riskReasons,
    );
  }

  @override
  String toString() =>
      'FirewallRule(id: $id, app: ${displayName ?? appId}, action: ${action.label}, priority: ${priority.value}, risk: $riskLevel ($riskScore))';
}
