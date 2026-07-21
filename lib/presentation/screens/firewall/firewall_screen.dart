import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/firewall_rule.dart';
import '../../../domain/enums/rule_action.dart';

class FirewallScreen extends ConsumerStatefulWidget {
  const FirewallScreen({super.key});

  @override
  ConsumerState<FirewallScreen> createState() => _FirewallScreenState();
}

class _FirewallScreenState extends ConsumerState<FirewallScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();

  static const _filters = ['All', 'Blocked', 'Allowed', 'Ask', 'System'];

  void _showBulkActions(BuildContext context, List<FirewallRule> filteredRules) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Bulk Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NcColors.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.check, color: NcColors.chipAllow),
                  title: const Text('Allow All Filtered'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    for (final r in filteredRules) {
                      if (r.appId != null) {
                        await ref
                            .read(firewallRulesProvider.notifier)
                            .updateRuleAction(r.appId!, RuleAction.allow, profileId: r.profileId);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: NcColors.chipBlock),
                  title: const Text('Block All Filtered'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    for (final r in filteredRules) {
                      if (r.appId != null) {
                        await ref
                            .read(firewallRulesProvider.notifier)
                            .updateRuleAction(r.appId!, RuleAction.block, profileId: r.profileId);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: NcColors.chipAsk),
                  title: const Text('Reset All Filtered to Ask'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    for (final r in filteredRules) {
                      if (r.appId != null) {
                        await ref
                            .read(firewallRulesProvider.notifier)
                            .updateRuleAction(r.appId!, RuleAction.ask, profileId: r.profileId);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(firewallRulesProvider);

    List<FirewallRule> filtered = [];
    if (rulesAsync.hasValue) {
      final rules = rulesAsync.value!.cast<FirewallRule>();
      final query = _searchCtrl.text.toLowerCase();
      filtered = rules.where((r) {
        if (query.isNotEmpty &&
            !(r.appId?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
        if (_filter == 'Blocked' && !r.action.isBlocking) {
          return false;
        }
        if (_filter == 'Allowed' && r.action != RuleAction.allow) {
          return false;
        }
        if (_filter == 'Ask' && r.action != RuleAction.ask) {
          return false;
        }
        final isSystem = r.isSystemApp;
        if (_filter == 'System' && !isSystem) {
          return false;
        }
        return true;
      }).toList();
    }

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Firewall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: filtered.isNotEmpty ? () => _showBulkActions(context, filtered) : null,
            tooltip: 'Bulk Actions',
          )
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search, color: NcColors.textMuted),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: _filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: NcColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: NcColors.primary,
                          side: BorderSide(
                            color: _filter == f
                                ? NcColors.primary
                                : NcColors.border,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // App list
          Expanded(
            child: rulesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load rules: $e',
                    style:
                        TextStyle(color: NcColors.textSecondary)),
              ),
              data: (rulesData) {

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security_outlined,
                            size: 48, color: NcColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No apps match the current filter',
                            style:
                                TextStyle(color: NcColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          'Start protection to load installed apps, or change the filter.',
                          style: TextStyle(
                              color: NcColors.textMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final rule = filtered[i];
                    return _AppRuleTile(
                      appId: rule.appId ?? 'Unknown App',
                      action: rule.action,
                      profileId: rule.profileId ?? 'default',
                      displayName: rule.displayName,
                      iconBytes: rule.iconBytes,
                      riskLevel: rule.riskLevel,
                      riskScore: rule.riskScore,
                      riskReasons: rule.riskReasons,
                      onAllow: () => ref
                          .read(firewallRulesProvider.notifier)
                          .updateRuleAction(rule.appId ?? '', RuleAction.allow, profileId: rule.profileId),
                      onBlock: () => ref
                          .read(firewallRulesProvider.notifier)
                          .updateRuleAction(rule.appId ?? '', RuleAction.block, profileId: rule.profileId),
                      onAsk: () => ref
                          .read(firewallRulesProvider.notifier)
                          .updateRuleAction(rule.appId ?? '', RuleAction.ask, profileId: rule.profileId),
                      onProfileChanged: (newProfile) {
                        ref.read(firewallRulesProvider.notifier).updateRuleAction(
                              rule.appId ?? '',
                              rule.action,
                              profileId: newProfile,
                            );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRuleTile extends StatelessWidget {
  const _AppRuleTile({
    required this.appId,
    required this.action,
    required this.profileId,
    required this.onAllow,
    required this.onBlock,
    required this.onAsk,
    required this.onProfileChanged,
    this.displayName,
    this.iconBytes,
    this.riskLevel,
    this.riskScore,
    this.riskReasons,
  });

  final String appId;
  final RuleAction action;
  final String profileId;
  final VoidCallback onAllow;
  final VoidCallback onBlock;
  final VoidCallback onAsk;
  final ValueChanged<String?> onProfileChanged;
  final String? displayName;
  final List<int>? iconBytes;
  final String? riskLevel;
  final int? riskScore;
  final List<String>? riskReasons;

  @override
  Widget build(BuildContext context) {
    // Resolve the label — prefer displayName, fall back to package name
    final label = (displayName?.isNotEmpty == true) ? displayName! : appId;
    // Derive a short package suffix for the subtitle (e.g. "com.example.app" -> "example.app")
    final parts = appId.split('.');
    final subtitle = parts.length > 2 ? parts.skip(1).join('.') : appId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section: Icon, Name/Package, Action state badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NcColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: iconBytes != null && iconBytes!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          Uint8List.fromList(iconBytes!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.apps_outlined,
                            color: NcColors.textMuted,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(Icons.apps_outlined,
                        color: NcColors.textMuted, size: 24),
              ),
              const SizedBox(width: 14),
              // App Info (Name, Package Name)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (riskLevel != null) ...[
                          const SizedBox(width: 8),
                          _RiskBadge(
                            level: riskLevel!,
                            score: riskScore ?? 0,
                            reasons: riskReasons ?? [],
                            appName: label,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: NcColors.textMuted,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Current Action Status Indicator Badge
              _ActionBadge(action: action),
            ],
          ),
          
          const SizedBox(height: 12),
          Divider(height: 1, color: NcColors.border),
          const SizedBox(height: 12),
          
          // Bottom section: Network statuses, Profile dropdown, and Action controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Statuses & Mode
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode dropdown selector
                    Row(
                      children: [
                        Icon(Icons.layers_outlined, size: 14, color: NcColors.textMuted),
                        const SizedBox(width: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: profileId,
                            isDense: true,
                            dropdownColor: NcColors.surface,
                            style: const TextStyle(
                              color: NcColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: NcColors.primary, size: 16),
                            onChanged: onProfileChanged,
                            items: const [
                              DropdownMenuItem(value: 'default', child: Text('All Modes')),
                              DropdownMenuItem(value: 'home', child: Text('Home')),
                              DropdownMenuItem(value: 'work', child: Text('Work')),
                              DropdownMenuItem(value: 'publicWifi', child: Text('Public Wi-Fi')),
                              DropdownMenuItem(value: 'travel', child: Text('Travel')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Network Status indicator chips
                    Row(
                      children: [
                        _StatusChip(label: 'Wi-Fi', action: action),
                        const SizedBox(width: 4),
                        _StatusChip(label: 'Cell', action: action),
                        const SizedBox(width: 4),
                        _StatusChip(label: 'LAN', action: action),
                        const SizedBox(width: 4),
                        _StatusChip(label: 'BG', action: action),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Action buttons (Allow, Block, Ask)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuickBtn(
                    icon: Icons.check,
                    color: NcColors.chipAllow,
                    tooltip: 'Allow',
                    onTap: onAllow,
                    isSelected: action == RuleAction.allow,
                  ),
                  const SizedBox(width: 6),
                  _QuickBtn(
                    icon: Icons.block,
                    color: NcColors.chipBlock,
                    tooltip: 'Block',
                    onTap: onBlock,
                    isSelected: action == RuleAction.block || action == RuleAction.temporaryBlock,
                  ),
                  const SizedBox(width: 6),
                  _QuickBtn(
                    icon: Icons.help_outline,
                    color: NcColors.chipAsk,
                    tooltip: 'Ask',
                    onTap: onAsk,
                    isSelected: action == RuleAction.ask,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});
  final RuleAction action;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    
    switch (action) {
      case RuleAction.allow:
        label = 'Allowed';
        color = NcColors.chipAllow;
        break;
      case RuleAction.block:
      case RuleAction.temporaryBlock:
        label = 'Blocked';
        color = NcColors.chipBlock;
        break;
      case RuleAction.ask:
        label = 'Ask';
        color = NcColors.chipAsk;
        break;
      default:
        label = 'Allowed';
        color = NcColors.chipAllow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.action});
  final String label; // 'Wi-Fi' | 'Cell' | 'LAN' | 'BG'
  final RuleAction action;

  /// Resolves the effective allow/block state for this specific context.
  bool _isAllowed() {
    switch (label) {
      case 'Wi-Fi':
        // On Wi-Fi (assumed not LAN), allowLanOnly blocks internet traffic.
        switch (action) {
          case RuleAction.block:
          case RuleAction.temporaryBlock:
            return false;
          case RuleAction.allowLanOnly:
            return false; // internet traffic on Wi-Fi is blocked by this rule
          case RuleAction.screenOnOnly:
            return false; // can't tell without runtime context — show blocked
          case RuleAction.ask:
            return false; // fails closed
          default:
            return true;
        }
      case 'Cell':
        // On cellular there is no LAN — allowLanOnly effectively blocks all.
        switch (action) {
          case RuleAction.block:
          case RuleAction.temporaryBlock:
          case RuleAction.allowLanOnly:
            return false;
          case RuleAction.ask:
            return false;
          default:
            return true;
        }
      case 'LAN':
        // LAN access: allowInternetOnly blocks LAN destinations.
        switch (action) {
          case RuleAction.block:
          case RuleAction.temporaryBlock:
          case RuleAction.allowInternetOnly:
            return false;
          case RuleAction.ask:
            return false;
          default:
            return true;
        }
      case 'BG':
        // Background: blockBackground and screenOnOnly both restrict background.
        switch (action) {
          case RuleAction.block:
          case RuleAction.temporaryBlock:
          case RuleAction.blockBackground:
          case RuleAction.screenOnOnly:
            return false;
          case RuleAction.ask:
            return false;
          default:
            return true;
        }
      default:
        return action != RuleAction.block &&
            action != RuleAction.temporaryBlock &&
            action != RuleAction.ask;
    }
  }

  Color get _color {
    if (!_isAllowed()) return NcColors.chipBlock;
    if (action == RuleAction.ask) return NcColors.chipAsk;
    return NcColors.chipAllow;
  }

  String get _statusLabel => _isAllowed() ? '✓' : '✗';

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label $_statusLabel',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  const _QuickBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    required this.isSelected,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : color,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.level,
    required this.score,
    required this.reasons,
    required this.appName,
  });
  final String level;
  final int score;
  final List<String> reasons;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final String label;

    switch (level.toLowerCase()) {
      case 'high':
        badgeColor = Colors.redAccent;
        label = 'High Risk ($score)';
        break;
      case 'medium':
        badgeColor = Colors.orangeAccent;
        label = 'Medium Risk ($score)';
        break;
      default:
        badgeColor = Colors.greenAccent;
        label = 'Safe';
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showReasonsDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: badgeColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showReasonsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NcColors.surface,
        title: Text(
          '$appName Risk Profile',
          style: const TextStyle(color: NcColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Score: $score/100 ($level)',
              style: TextStyle(
                color: level == 'high' ? Colors.redAccent : Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Identified indicators (LibreAV/MobSF heuristics):',
              style: TextStyle(color: NcColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (reasons.isEmpty)
              Text(
                '• No critical permissions or debug flags detected.',
                style: TextStyle(color: NcColors.textMuted, fontSize: 12),
              )
            else
              ...reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $r',
                      style: TextStyle(color: NcColors.textSecondary, fontSize: 12),
                    ),
                  )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: NcColors.primary)),
          ),
        ],
      ),
    );
  }
}
