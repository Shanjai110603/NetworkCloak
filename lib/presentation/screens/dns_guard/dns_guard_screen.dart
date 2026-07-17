import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

class DnsGuardScreen extends ConsumerWidget {
  const DnsGuardScreen({super.key});

  static const _providers = [
    ('Cloudflare', '🛡️', 'DoH · 1.1.1.1', '1.1.1.1'),
    ('Quad9', '🔒', 'DoH · 9.9.9.9', '9.9.9.9'),
    ('Google', '🌐', 'DoH · 8.8.8.8', '8.8.8.8'),
    ('AdGuard', '🛡️', 'DoH · 94.140.14.14', '94.140.14.14'),
    ('System Default', '⚙️', 'OS resolver', 'system'),
    // 'Custom' has a special onTap that opens a configuration dialog
    // instead of calling selectProvider with a placeholder value.
    ('Custom', '✏️', 'User-defined DoH endpoint', '__custom__'),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final dnsProfile = ref.watch(dnsProfileProvider);

    // Dynamically generate the Base64 DNS stamp config string
    final configBytes = utf8.encode(json.encode({
      'provider': dnsProfile.name,
      'endpoint': dnsProfile.endpoint,
      'categories': dnsProfile.enabledCategories,
    }));
    final configString = 'NC-DNS-v1:${base64.encode(configBytes)}';

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
                  isSelected: dnsProfile.name.toLowerCase() == p.$1.toLowerCase(),
                  onTap: () {
                    if (p.$4 == '__custom__') {
                      _showCustomDnsDialog(context, ref);
                    } else {
                      ref
                          .read(dnsProfileProvider.notifier)
                          .selectProvider(p.$1, p.$4);
                    }
                  },
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
                        isOn: dnsProfile.enabledCategories.contains(e.value.$1.toLowerCase()) || (e.key >= 4 && e.key <= 7),
                        icon: e.value.$3,
                        isAlwaysOn: e.key >= 4 && e.key <= 7,
                        isLast: e.key == _categories.length - 1,
                        onChanged: (val) {
                          ref.read(dnsProfileProvider.notifier).toggleCategory(e.value.$1.toLowerCase());
                        },
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
                Text(
                  configString,
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
                        label: const Text('Copy Stamp'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: configString));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('DNS Stamp copied to clipboard!')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NcColors.primary,
                          side: const BorderSide(color: NcColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Import Stamp'),
                        onPressed: () => _showImportDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NcColors.textSecondary,
                          side: BorderSide(color: NcColors.border),
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

  /// Opens a dialog to configure a custom DoH endpoint.
  ///
  /// The DoH URL must be an IP-literal (e.g. https://94.140.14.14/dns-query)
  /// to avoid a DNS bootstrapping loop when the VPN is active. The TLS
  /// hostname is used for certificate validation against the correct name.
  void _showCustomDnsDialog(BuildContext context, WidgetRef ref) {
    final urlCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NcColors.surface,
        title: const Text('Custom DoH Resolver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use an IP-literal URL to avoid DNS bootstrap loops (e.g. https://1.2.3.4/dns-query).',
              style: TextStyle(fontSize: 12, color: NcColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'DoH URL',
                hintText: 'https://1.2.3.4/dns-query',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hostCtrl,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'TLS Certificate Hostname',
                hintText: 'dns.example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The TLS hostname is used for certificate validation — it should match the FQDN of your resolver, not the IP.',
              style: TextStyle(fontSize: 11, color: NcColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: NcColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              final hostname = hostCtrl.text.trim();
              if (url.startsWith('https://') && hostname.isNotEmpty) {
                // selectProvider receives doHUrl + doHHostname via native bridge
                ref.read(dnsProfileProvider.notifier)
                    .selectProvider('Custom', url, doHHostname: hostname);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Custom DoH resolver set: $hostname')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL must start with https:// and hostname must not be empty.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: NcColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NcColors.surface,
        title: const Text('Import DNS Stamp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a valid base64-encoded Network Cloak DNS Stamp (starts with NC-DNS-v1:)',
              style: TextStyle(fontSize: 12, color: NcColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'NC-DNS-v1:...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: NcColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final stamp = controller.text.trim();
              if (stamp.startsWith('NC-DNS-v1:')) {
                try {
                  final encoded = stamp.substring('NC-DNS-v1:'.length);
                  final decoded = utf8.decode(base64.decode(encoded));
                  final Map<String, dynamic> data = json.decode(decoded);
                  final providerName = data['provider'] as String? ?? 'Custom';
                  final endpoint = data['endpoint'] as String? ?? 'system';
                  
                  ref.read(dnsProfileProvider.notifier).selectProvider(providerName, endpoint);
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Imported DNS profile: $providerName successfully!')),
                  );
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid DNS Stamp payload.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid DNS Stamp format.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: NcColors.primary),
            child: const Text('Import'),
          ),
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
    required this.onTap,
  });
  final String name, emoji, subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _BlocklistRow extends StatelessWidget {
  const _BlocklistRow({
    required this.name,
    required this.isOn,
    required this.icon,
    required this.isAlwaysOn,
    required this.isLast,
    required this.onChanged,
  });
  final String name;
  final bool isOn;
  final IconData icon;
  final bool isAlwaysOn;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon,
              color: isOn ? NcColors.primary : NcColors.textMuted,
              size: 20),
          title: Text(name,
              style: Theme.of(context).textTheme.bodyLarge),
          trailing: isAlwaysOn
              ? const Chip(
                  label: Text('Always on',
                      style: TextStyle(fontSize: 10, color: NcColors.primary)),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: NcColors.primary),
                  padding: EdgeInsets.zero,
                )
              : Switch(
                  value: isOn,
                  onChanged: onChanged,
                ),
        ),
        if (!isLast)
          Divider(
              height: 0, indent: 16, endIndent: 16, color: NcColors.border),
      ],
    );
  }
}
