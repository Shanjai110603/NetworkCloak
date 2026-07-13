import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class DnsGuardScreen extends StatelessWidget {
  const DnsGuardScreen({super.key});

  static const _providers = [
    ('Cloudflare', '🛡️', 'DoH · 1.1.1.1', true),
    ('Quad9', '🔒', 'DoH · 9.9.9.9', false),
    ('Google', '🌐', 'DoH · 8.8.8.8', false),
    ('AdGuard', '🛡️', 'DoH · 94.140.14.14', false),
    ('System Default', '⚙️', 'OS resolver', false),
    ('Custom', '✏️', 'User-defined', false),
  ];

  static const _categories = [
    ('Advertising', true, Icons.ads_click),
    ('Analytics', true, Icons.analytics_outlined),
    ('Telemetry', true, Icons.sensors_outlined),
    ('Tracking', true, Icons.track_changes_outlined),
    ('Malware', true, Icons.bug_report_outlined),
    ('Phishing', true, Icons.phishing_outlined),
    ('Cryptomining', true, Icons.currency_bitcoin),
    ('Ransomware', true, Icons.security_outlined),
    ('Adult Content', false, Icons.no_adult_content),
    ('Social Media', false, Icons.people_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('DNS Guard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider section
          Text('DNS Provider',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...(_providers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DnsProviderTile(
                  name: p.$1,
                  emoji: p.$2,
                  subtitle: p.$3,
                  isSelected: p.$4,
                ),
              ))),

          const SizedBox(height: 24),

          // Blocklist categories
          Text('Blocklist Categories',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Always active: Malware, Phishing, Cryptomining, Ransomware.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NcColors.border),
            ),
            child: Column(
              children: _categories
                  .asMap()
                  .entries
                  .map((e) => _BlocklistRow(
                        name: e.value.$1,
                        isOn: e.value.$2,
                        icon: e.value.$3,
                        isAlwaysOn: e.key >= 4 && e.key <= 7,
                        isLast: e.key == _categories.length - 1,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Config string
          Text('DNS Config String',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NcColors.border),
            ),
            child: Column(
              children: [
                const Text(
                  'NC-DNS-v1:eyJwcm92aWRlciI6ImNsb3VkZmxhcmUi...',
                  style: TextStyle(
                    color: NcColors.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: const Text('Copy'),
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NcColors.primary,
                          side: const BorderSide(color: NcColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.input_outlined, size: 16),
                        label: const Text('Import'),
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NcColors.textSecondary,
                          side: const BorderSide(color: NcColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _DnsProviderTile extends StatelessWidget {
  const _DnsProviderTile({
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.isSelected,
  });
  final String name, emoji, subtitle;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? NcColors.primary.withValues(alpha: 0.08)
            : NcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? NcColors.primary : NcColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle,
                color: NcColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _BlocklistRow extends StatefulWidget {
  const _BlocklistRow({
    required this.name,
    required this.isOn,
    required this.icon,
    required this.isAlwaysOn,
    required this.isLast,
  });
  final String name;
  final bool isOn;
  final IconData icon;
  final bool isAlwaysOn;
  final bool isLast;

  @override
  State<_BlocklistRow> createState() => _BlocklistRowState();
}

class _BlocklistRowState extends State<_BlocklistRow> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.isOn;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(widget.icon,
              color: _enabled ? NcColors.primary : NcColors.textMuted,
              size: 20),
          title: Text(widget.name,
              style: Theme.of(context).textTheme.bodyLarge),
          trailing: widget.isAlwaysOn
              ? const Chip(
                  label: Text('Always on',
                      style: TextStyle(fontSize: 10, color: NcColors.primary)),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: NcColors.primary),
                  padding: EdgeInsets.zero,
                )
              : Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
        ),
        if (!widget.isLast)
          const Divider(
              height: 0, indent: 16, endIndent: 16, color: NcColors.border),
      ],
    );
  }
}
