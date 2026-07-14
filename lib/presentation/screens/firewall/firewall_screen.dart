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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        final isSystem = r.appId == 'system_process' ||
            (r.appId?.startsWith('com.android.') ?? false) ||
            (r.appId?.startsWith('android.') ?? false);
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
              decoration: const InputDecoration(
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
                        const TextStyle(color: NcColors.textSecondary)),
              ),
              data: (rulesData) {

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.security_outlined,
                            size: 48, color: NcColors.textMuted),
                        SizedBox(height: 12),
                        Text('No rules yet',
                            style:
                                TextStyle(color: NcColors.textSecondary)),
                        SizedBox(height: 4),
                        Text(
                          'Apps appear here when they request internet access.',
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
  });

  final String appId;
  final RuleAction action;
  final String profileId;
  final VoidCallback onAllow;
  final VoidCallback onBlock;
  final VoidCallback onAsk;
  final ValueChanged<String?> onProfileChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NcColors.border),
      ),
      child: Row(
        children: [
          // App icon placeholder
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NcColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apps_outlined,
                color: NcColors.textMuted, size: 22),
          ),
          const SizedBox(width: 12),
          // Name + chips + profile dropdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appId,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Profile/Mode dropdown
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
                    const SizedBox(width: 8),
                    // Status chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StatusChip(label: 'Wi-Fi', action: action),
                            const SizedBox(width: 4),
                            _StatusChip(label: 'Cell', action: action),
                            const SizedBox(width: 4),
                            _StatusChip(label: 'BG', action: action),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Quick-action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickBtn(
                  icon: Icons.check,
                  color: NcColors.chipAllow,
                  tooltip: 'Allow',
                  onTap: onAllow),
              const SizedBox(width: 4),
              _QuickBtn(
                  icon: Icons.block,
                  color: NcColors.chipBlock,
                  tooltip: 'Block',
                  onTap: onBlock),
              const SizedBox(width: 4),
              _QuickBtn(
                  icon: Icons.help_outline,
                  color: NcColors.chipAsk,
                  tooltip: 'Ask',
                  onTap: onAsk),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.action});
  final String label;
  final RuleAction action;

  Color get _color {
    if (action == RuleAction.block || action == RuleAction.temporaryBlock) {
      return NcColors.chipBlock;
    }
    if (action == RuleAction.ask) return NcColors.chipAsk;
    return NcColors.chipAllow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: ${action.label}',
        style: TextStyle(
          color: _color,
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
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
