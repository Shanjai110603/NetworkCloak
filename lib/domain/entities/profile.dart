import '../enums/protection_mode.dart';
import '../enums/rule_action.dart';

/// A user-created protection profile (Home, Work, Custom, etc.)
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.mode,
    required this.isSystem,
    required this.isActive,
    required this.configJson,
    required this.createdAt,
  });

  final String id;
  final String name;
  final ProtectionMode mode;
  final bool isSystem;
  final bool isActive;
  final String configJson;
  final DateTime createdAt;

  Profile copyWith({
    String? name,
    bool? isActive,
    String? configJson,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      mode: mode,
      isSystem: isSystem,
      isActive: isActive ?? this.isActive,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt,
    );
  }
}

/// Default rule to apply when no manual rule matches.
class DefaultPolicy {
  const DefaultPolicy({
    required this.action,
    required this.applyToNewApps,
  });

  final RuleAction action;
  final bool applyToNewApps;

  static const safe = DefaultPolicy(
    action: RuleAction.ask,
    applyToNewApps: true,
  );
}
