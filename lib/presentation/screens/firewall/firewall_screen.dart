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

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(firewallRulesProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Firewall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {},
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
                final rules = rulesData.cast<FirewallRule>();
                final query = _searchCtrl.text.toLowerCase();
                final filtered = rules.where((r) {
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
                  return true;
                }).toList();

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
                      onAllow: () => ref
                          .read(firewallRulesProvider.notifier)
                          .updateRuleAction(rule.appId ?? '', RuleAction.allow),
                      onBlock: () => ref
                          .read(firewallRulesProvider.notifier)
                          .updateRuleAction(rule.appId ?? '', RuleAction.block),
                      onAsk: () => ref
                          .read(firewallRulesProvider.notifier)
                          .updateRuleAction(rule.appId ?? '', RuleAction.ask),
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
    required this.onAllow,
    required this.onBlock,
    required this.onAsk,
  });

  final String appId;
  final RuleAction action;
  final VoidCallback onAllow;
  final VoidCallback onBlock;
  final VoidCallback onAsk;

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
          // Name + chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appId,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                // Status chips
                Wrap(
                  spacing: 4,
                  children: [
                    _StatusChip(label: 'Wi-Fi', action: action),
                    _StatusChip(label: 'Cell', action: action),
                    _StatusChip(label: 'BG', action: action),
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
