import 'dart:convert';
import '../../entities/firewall_rule.dart';
import '../../entities/temporary_rule.dart';
import '../../enums/network_trust_level.dart';
import '../../enums/protection_mode.dart';
import '../../enums/rule_action.dart';
import '../../enums/rule_priority.dart';

/// Input context for a single connection event.
class RuleEvaluationContext {
  const RuleEvaluationContext({
    required this.appId,
    required this.destIp,
    required this.destPort,
    required this.protocol,
    required this.isBackground,
    required this.isScreenOn,
    required this.networkTrust,
    required this.activeMode,
  });

  final String appId;
  final String destIp;
  final int destPort;
  final String protocol;
  final bool isBackground;
  final bool isScreenOn;
  final NetworkTrustLevel networkTrust;
  final ProtectionMode activeMode;
}

/// Result returned by the rule evaluation pipeline.
class RuleEvaluationResult {
  const RuleEvaluationResult({
    required this.action,
    required this.matchedPriority,
    this.matchedRuleId,
    required this.plainReason,
  });

  final RuleAction action;
  final RulePriority matchedPriority;
  final String? matchedRuleId;
  final String plainReason; // beginner-friendly explanation

  bool get isAllowed => !action.isBlocking;
}

/// ─────────────────────────────────────────────────────────────
/// Core deterministic rule evaluation pipeline.
///
/// Evaluation order matches the 7-priority hierarchy:
///   P1 → Emergency Lockdown
///   P2 → Temporary Rules   (in-memory cache)
///   P3 → Session Rules     (in-memory cache)
///   P4 → Manual App Rules  (from repository)
///   P5 → Profile Rules     (from repository)
///   P6 → Global Rules      (from repository)
///   P7 → Default Behaviour (from settings)
///
/// Steps 1-11 MUST complete in <5ms average on the hot path.
/// ─────────────────────────────────────────────────────────────
class EvaluateRuleUseCase {
  EvaluateRuleUseCase({
    required this.lockdownActive,
    required this.lockdownAllowlist,
    required this.temporaryRules,
    required this.sessionRules,
    required this.manualRules,
    required this.profileRules,
    required this.globalRules,
    required this.defaultAction,
  });

  // ── Input state (provided fresh per call from Notifiers) ───
  final bool lockdownActive;
  final List<String> lockdownAllowlist; // package IDs exempt from lockdown
  final List<TemporaryRuleEntity> temporaryRules; // in-memory, pre-filtered
  final List<SessionRuleEntity> sessionRules;     // in-memory
  final List<FirewallRule> manualRules;
  final List<FirewallRule> profileRules;
  final List<FirewallRule> globalRules;
  final RuleAction defaultAction;

  /// Evaluate a connection event against the full priority hierarchy.
  RuleEvaluationResult evaluate(RuleEvaluationContext ctx) {
    // ── P1: Emergency Lockdown ─────────────────────────────
    if (lockdownActive) {
      if (lockdownAllowlist.contains(ctx.appId)) {
        return const RuleEvaluationResult(
          action: RuleAction.allow,
          matchedPriority: RulePriority.emergencyLockdown,
          plainReason: 'Lockdown is active. This app is on your allowed list.',
        );
      }
      return const RuleEvaluationResult(
        action: RuleAction.block,
        matchedPriority: RulePriority.emergencyLockdown,
        plainReason: 'Lockdown is active. All other rules are currently overridden.',
      );
    }

    // ── P2: Temporary Rules ────────────────────────────────
    final activeTemp = temporaryRules
        .where((tmp) => tmp.appId == ctx.appId && !tmp.isExpired)
        .toList()
      ..sort((a, b) {
        final aBlocks = a.action.isBlocking ? 1 : 0;
        final bBlocks = b.action.isBlocking ? 1 : 0;
        if (aBlocks != bBlocks) {
          return bBlocks.compareTo(aBlocks);
        }
        return b.startAt.compareTo(a.startAt);
      });

    for (final tmp in activeTemp) {
      if (_conditionsMatch(tmp.conditionsJson, ctx)) {
        return RuleEvaluationResult(
          action: tmp.action,
          matchedPriority: RulePriority.temporary,
          matchedRuleId: tmp.id,
          plainReason: _temporaryReason(tmp.action, tmp.endAt),
        );
      }
    }

    // ── P3: Session Rules ──────────────────────────────────
    final activeSession = sessionRules
        .where((sr) => sr.appId == ctx.appId)
        .toList()
      ..sort((a, b) {
        final aBlocks = a.action.isBlocking ? 1 : 0;
        final bBlocks = b.action.isBlocking ? 1 : 0;
        return bBlocks.compareTo(aBlocks);
      });

    for (final sr in activeSession) {
      return RuleEvaluationResult(
        action: sr.action,
        matchedPriority: RulePriority.session,
        matchedRuleId: sr.id,
        plainReason: _actionReason(sr.action),
      );
    }

    // ── P4: Manual App Rules ───────────────────────────────
    final appManual = manualRules
        .where((r) => r.appId == ctx.appId)
        .toList()
      ..sort((a, b) {
        final aBlocks = a.action.isBlocking ? 1 : 0;
        final bBlocks = b.action.isBlocking ? 1 : 0;
        if (aBlocks != bBlocks) {
          return bBlocks.compareTo(aBlocks);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    for (final rule in appManual) {
      if (_conditionsMatch(rule.conditionsJson, ctx)) {
        final resolved = _applyConditions(rule.action, ctx);
        return RuleEvaluationResult(
          action: resolved,
          matchedPriority: RulePriority.manualApp,
          matchedRuleId: rule.id,
          plainReason: _actionReason(resolved),
        );
      }
    }

    // ── P5: Profile Rules ──────────────────────────────────
    final activeProfile = profileRules
        .where((rule) => rule.appId == null || rule.appId == ctx.appId)
        .toList()
      ..sort((a, b) {
        final aBlocks = a.action.isBlocking ? 1 : 0;
        final bBlocks = b.action.isBlocking ? 1 : 0;
        if (aBlocks != bBlocks) {
          return bBlocks.compareTo(aBlocks);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    for (final rule in activeProfile) {
      if (_conditionsMatch(rule.conditionsJson, ctx)) {
        return RuleEvaluationResult(
          action: rule.action,
          matchedPriority: RulePriority.profile,
          matchedRuleId: rule.id,
          plainReason: _actionReason(rule.action),
        );
      }
    }

    // ── P6: Global Rules ───────────────────────────────────
    final activeGlobal = globalRules.toList()
      ..sort((a, b) {
        final aBlocks = a.action.isBlocking ? 1 : 0;
        final bBlocks = b.action.isBlocking ? 1 : 0;
        if (aBlocks != bBlocks) {
          return bBlocks.compareTo(aBlocks);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    for (final rule in activeGlobal) {
      if (_conditionsMatch(rule.conditionsJson, ctx)) {
        return RuleEvaluationResult(
          action: rule.action,
          matchedPriority: RulePriority.global,
          matchedRuleId: rule.id,
          plainReason: _actionReason(rule.action),
        );
      }
    }

    // ── P7: Default Behaviour ──────────────────────────────
    return RuleEvaluationResult(
      action: defaultAction,
      matchedPriority: RulePriority.defaultBehavior,
      plainReason: _actionReason(defaultAction),
    );
  }

  // ── Condition helpers ──────────────────────────────────────

  bool _conditionsMatch(String? conditionsJson, RuleEvaluationContext ctx) {
    if (conditionsJson == null || conditionsJson.isEmpty || conditionsJson == '{}') {
      return true;
    }
    try {
      final cond = jsonDecode(conditionsJson) as Map<String, dynamic>;

      // Screen-on-only rule
      if (cond['screen_on_only'] == true && !ctx.isScreenOn) return false;

      // Background block rule
      if (cond['block_background'] == true && ctx.isBackground) return false;

      // Network type condition
      if (cond['network_type'] != null) {
        final required = cond['network_type'] as String;
        if (!_networkTypeMatches(required, ctx.networkTrust)) return false;
      }

      // LAN destination check
      if (cond['lan_only'] == true && !_isLanAddress(ctx.destIp)) return false;
      if (cond['internet_only'] == true && _isLanAddress(ctx.destIp)) return false;

      return true;
    } catch (_) {
      return true; // Fail open on unparseable conditions
    }
  }

  RuleAction _applyConditions(RuleAction base, RuleEvaluationContext ctx) {
    switch (base) {
      // Block Background: block when app is backgrounded, allow in foreground
      case RuleAction.blockBackground:
        return ctx.isBackground ? RuleAction.block : RuleAction.allow;

      // LAN only: allow only if destination is a private/LAN address
      case RuleAction.allowLanOnly:
        return _isLanAddress(ctx.destIp) ? RuleAction.allow : RuleAction.block;

      // Internet only: allow only if destination is NOT a private/LAN address
      case RuleAction.allowInternetOnly:
        return !_isLanAddress(ctx.destIp) ? RuleAction.allow : RuleAction.block;

      // Screen-on only: block when screen is off
      case RuleAction.screenOnOnly:
        return ctx.isScreenOn ? RuleAction.allow : RuleAction.block;

      default:
        return base;
    }
  }

  bool _networkTypeMatches(String required, NetworkTrustLevel trust) {
    switch (required) {
      case 'trusted':
        return trust == NetworkTrustLevel.trusted;
      case 'public':
        return trust == NetworkTrustLevel.publicWifi;
      case 'unknown':
        return trust == NetworkTrustLevel.unknown;
      case 'hostile':
        return trust == NetworkTrustLevel.hostile;
      default:
        return true;
    }
  }

  bool _isLanAddress(String ip) {
    return ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(ip);
  }

  String _actionReason(RuleAction action) {
    switch (action) {
      case RuleAction.allow:
        return 'This app is allowed to connect.';
      case RuleAction.block:
        return 'This app is blocked from connecting.';
      case RuleAction.ask:
        return 'Waiting for your permission.';
      case RuleAction.allowLanOnly:
        return 'This app can only access your local network.';
      case RuleAction.allowInternetOnly:
        return 'This app can only access the internet, not your local network.';
      case RuleAction.blockBackground:
        return 'This app can only connect while you\'re using it.';
      case RuleAction.screenOnOnly:
        return 'This app can only connect while your screen is on.';
      default:
        return 'Rule applied.';
    }
  }

  String _temporaryReason(RuleAction action, DateTime endAt) {
    final diff = endAt.difference(DateTime.now());
    final mins = diff.inMinutes;
    final label = action.isBlocking ? 'blocked' : 'allowed';
    if (mins < 1) return 'Temporarily $label for less than a minute.';
    return 'Temporarily $label for $mins more minute${mins == 1 ? '' : 's'}.';
  }
}
