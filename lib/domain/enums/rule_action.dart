/// Rule actions available in Network Cloak Firewall Engine.
/// Ordered by UI label for display purposes.
enum RuleAction {
  allow,
  block,
  ask,
  temporaryAllow,
  temporaryBlock,
  allowLanOnly,
  allowInternetOnly,
  blockBackground,
  restrict,
  screenOnOnly,
  scheduled,
}

extension RuleActionX on RuleAction {
  String get label {
    switch (this) {
      case RuleAction.allow:
        return 'Allow';
      case RuleAction.block:
        return 'Block';
      case RuleAction.ask:
        return 'Ask';
      case RuleAction.temporaryAllow:
        return 'Allow for...';
      case RuleAction.temporaryBlock:
        return 'Block for...';
      case RuleAction.allowLanOnly:
        return 'LAN only';
      case RuleAction.allowInternetOnly:
        return 'Internet only';
      case RuleAction.blockBackground:
        return 'Foreground only';
      case RuleAction.restrict:
        return 'Restrict...';
      case RuleAction.screenOnOnly:
        return 'Screen-on only';
      case RuleAction.scheduled:
        return 'Scheduled';
    }
  }

  bool get isBlocking =>
      this == RuleAction.block ||
      this == RuleAction.temporaryBlock ||
      this == RuleAction.blockBackground;

  bool get isTemporary =>
      this == RuleAction.temporaryAllow || this == RuleAction.temporaryBlock;
}
