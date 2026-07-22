import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/enums/rule_action.dart';

class WatchtowerScreen extends ConsumerStatefulWidget {
  const WatchtowerScreen({super.key});

  @override
  ConsumerState<WatchtowerScreen> createState() => _WatchtowerScreenState();
}

class _WatchtowerScreenState extends ConsumerState<WatchtowerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final throughput = ref.watch(throughputProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Watchtower'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: NcColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NcColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: NcColors.protected,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _fmtSpeedHeader(throughput.currentSpeed),
                    style: const TextStyle(
                      color: NcColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: NcColors.primary,
          labelColor: NcColors.primary,
          unselectedLabelColor: NcColors.textSecondary,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'History'),
            Tab(text: 'Bandwidth'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LiveTab(),
          _HistoryTab(),
          _BandwidthTab(),
        ],
      ),
    );
  }

  String _fmtSpeedHeader(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    final kb = bytesPerSec / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB/s';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB/s';
  }
}

// ------------------- Live Tab --------------------------------

class _LiveTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(liveConnectionsProvider);
    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: TextStyle(color: NcColors.textSecondary)),
      ),
      data: (connections) {
        final totalCount = 1 + (connections.isEmpty ? 1 : connections.length);

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: totalCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return const _RealTimeTrafficDashboard();
            }

            if (connections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_heart_outlined,
                          size: 40, color: NcColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No active connections monitored',
                          style: TextStyle(color: NcColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            final c = connections[i - 1];
            return _ConnectionCard(
              appId: c.appId,
              destHost: c.dest,
              destIp: c.dest,
              protocol: c.protocol,
              bytes: c.bytes,
              allowed: c.allowed,
              onTap: () => _showConnectionDetails(
                context: ctx,
                ref: ref,
                appId: c.appId,
                destHost: c.dest,
                destIp: c.dest,
                protocol: c.protocol,
                bytes: c.bytes,
                allowed: c.allowed,
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------- History Tab -----------------------------

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(connectionHistoryProvider);
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading history: $e',
            style: TextStyle(color: NcColors.textSecondary)),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Text('No connection history recorded yet.',
                style: TextStyle(color: NcColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final r = records[i];
            return _ConnectionCard(
              appId: r.appId,
              destHost: r.destHost,
              destIp: r.destIp ?? r.destHost,
              protocol: r.protocol ?? 'TCP',
              bytes: r.bytes ?? 0,
              allowed: !r.wasBlocked,
              countryFlag: r.countryFlag,
              port: r.port,
              onTap: () => _showConnectionDetails(
                context: ctx,
                ref: ref,
                appId: r.appId,
                destHost: r.destHost,
                destIp: r.destIp ?? r.destHost,
                protocol: r.protocol ?? 'TCP',
                bytes: r.bytes ?? 0,
                allowed: !r.wasBlocked,
                countryFlag: r.countryFlag,
                port: r.port,
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------- Bandwidth Tab ---------------------------

class _BandwidthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(applicationStatsProvider);
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading stats: $e',
            style: TextStyle(color: NcColors.textSecondary)),
      ),
      data: (stats) {
        if (stats.isEmpty) {
          return Center(
            child: Text('No bandwidth stats available yet.',
                style: TextStyle(color: NcColors.textSecondary)),
          );
        }
        final sorted = List.from(stats)
          ..sort((a, b) =>
              (b.bytesSent + b.bytesRecv).compareTo(a.bytesSent + a.bytesRecv));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final s = sorted[i];
            final totalBytes = s.bytesSent + s.bytesRecv;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NcColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NcColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(s.appId,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(_fmt(totalBytes),
                          style: const TextStyle(
                              color: NcColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('?? Sent: ${_fmt(s.bytesSent)}',
                          style: TextStyle(
                              color: NcColors.textSecondary, fontSize: 12)),
                      Text('?? Recv: ${_fmt(s.bytesRecv)}',
                          style: TextStyle(
                              color: NcColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}

// ------------------- Shared Connection Card -------------------

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.appId,
    required this.destHost,
    required this.destIp,
    required this.protocol,
    required this.bytes,
    required this.allowed,
    required this.onTap,
    this.countryFlag,
    this.port,
  });

  final String appId;
  final String destHost;
  final String destIp;
  final String protocol;
  final int bytes;
  final bool allowed;
  final VoidCallback onTap;
  final String? countryFlag;
  final int? port;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        allowed ? NcColors.protected : NcColors.unprotected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NcColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NcColors.border),
        ),
        child: Row(
          children: [
            Text(countryFlag ?? '??',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appId,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('? $destHost',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    allowed ? 'ALLOWED' : 'BLOCKED',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_fmt(bytes),
                    style: TextStyle(
                        color: NcColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: NcColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}

// ------------------- Connection Details Sheet -----------------

void _showConnectionDetails({
  required BuildContext context,
  required WidgetRef ref,
  required String appId,
  required String destHost,
  required String destIp,
  required String protocol,
  required int bytes,
  required bool allowed,
  String? countryFlag,
  int? port,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConnectionDetailsSheet(
      appId: appId,
      destHost: destHost,
      destIp: destIp,
      port: port,
      protocol: protocol,
      bytes: bytes,
      allowed: allowed,
      countryFlag: countryFlag,
      parentRef: ref,
    ),
  );
}

class _ConnectionDetailsSheet extends ConsumerStatefulWidget {
  const _ConnectionDetailsSheet({
    required this.appId,
    required this.destHost,
    required this.destIp,
    required this.protocol,
    required this.bytes,
    required this.allowed,
    required this.parentRef,
    this.port,
    this.countryFlag,
  });

  final String appId;
  final String destHost;
  final String destIp;
  final int? port;
  final String protocol;
  final int bytes;
  final bool allowed;
  final String? countryFlag;
  final WidgetRef parentRef;

  @override
  ConsumerState<_ConnectionDetailsSheet> createState() =>
      _ConnectionDetailsSheetState();
}

class _ConnectionDetailsSheetState
    extends ConsumerState<_ConnectionDetailsSheet> {
  bool _loading = false;
  String? _rdapResult;
  String? _rdapError;

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
  }

  Future<void> _lookupRdap() async {
    final ip = widget.destIp;
    // Skip private / loopback / unresolvable addresses
    final isPrivate = ip.startsWith('192.168.') ||
        ip.startsWith('10.') ||
        ip.startsWith('172.') ||
        ip == 'dns' ||
        ip.isEmpty ||
        ip == '?';

    if (isPrivate) {
      setState(() {
        _rdapError =
            'Private or unresolvable address — no RDAP data available.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _rdapResult = null;
      _rdapError = null;
    });

    try {
      final uri = Uri.parse('https://rdap.arin.net/registry/ip/$ip');
      final resp = await http.get(
        uri,
        headers: {'Accept': 'application/rdap+json'},
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final name = data['name'] as String? ?? 'Unknown Network';
        final handle = data['handle'] as String? ?? '';
        final country = data['country'] as String? ?? '';

        String org = '';
        final entities = data['entities'] as List<dynamic>?;
        if (entities != null) {
          for (final entity in entities) {
            final roles = (entity['roles'] as List<dynamic>?) ?? [];
            if (roles.contains('registrant') || roles.contains('iana')) {
              final vcardArray = entity['vcardArray'] as List<dynamic>?;
              if (vcardArray != null && vcardArray.length > 1) {
                final props = vcardArray[1] as List<dynamic>;
                for (final prop in props) {
                  final pList = prop as List<dynamic>;
                  if (pList.isNotEmpty && pList[0] == 'fn') {
                    org = pList.last?.toString() ?? '';
                    break;
                  }
                }
              }
              if (org.isNotEmpty) break;
            }
          }
        }

        setState(() {
          _loading = false;
          _rdapResult = [
            if (org.isNotEmpty) 'Organisation: $org',
            'Network: $name',
            if (handle.isNotEmpty) 'Handle: $handle',
            if (country.isNotEmpty) 'Country: $country',
          ].join('\n');
        });
      } else if (resp.statusCode == 404) {
        setState(() {
          _loading = false;
          _rdapError = 'No RDAP record found for $ip.';
        });
      } else {
        setState(() {
          _loading = false;
          _rdapError = 'RDAP lookup failed (HTTP ${resp.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _rdapError = 'Lookup error: ${e.toString()}';
      });
    }
  }

  Future<void> _setRule(RuleAction action) async {
    await widget.parentRef
        .read(firewallRulesProvider.notifier)
        .updateRuleAction(widget.appId, action);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.appId} set to: ${action.label}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        widget.allowed ? NcColors.protected : NcColors.unprotected;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: NcColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: NcColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NcColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.apps_outlined,
                        color: NcColors.textMuted, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.appId,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: NcColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(widget.destHost,
                            style: TextStyle(
                                color: NcColors.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.allowed ? 'ALLOWED' : 'BLOCKED',
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: NcColors.border),

            // Scrollable body
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // -- Metadata -----------------------------------
                  _InfoRow(label: 'IP', value: widget.destIp),
                  _InfoRow(label: 'Protocol', value: widget.protocol),
                  if (widget.port != null)
                    _InfoRow(
                        label: 'Port', value: widget.port.toString()),
                  _InfoRow(
                      label: 'Transferred', value: _fmt(widget.bytes)),
                  if (widget.countryFlag != null)
                    _InfoRow(label: 'Origin', value: widget.countryFlag!),

                  const SizedBox(height: 20),

                  // -- RDAP / WhoIs -------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Destination RDAP Info',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: NcColors.textPrimary),
                      ),
                      if (_loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NcColors.primary),
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(Icons.search, size: 16),
                          label: Text(
                              _rdapResult == null ? 'Lookup' : 'Refresh'),
                          style: TextButton.styleFrom(
                              foregroundColor: NcColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8)),
                          onPressed: _lookupRdap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NcColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: NcColors.border),
                      ),
                      child: Text(
                        _rdapError ??
                            _rdapResult ??
                            'Tap "Lookup" to query ARIN RDAP for network ownership info.',
                        style: TextStyle(
                          color: _rdapError != null
                              ? NcColors.textMuted
                              : (_rdapResult != null
                                  ? NcColors.textSecondary
                                  : NcColors.textMuted),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -- Quick Rule Actions --------------------------
                  Text(
                    'Rule Action',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NcColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Allow',
                          icon: Icons.check_circle_outline,
                          color: NcColors.chipAllow,
                          onTap: () => _setRule(RuleAction.allow),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Ask',
                          icon: Icons.help_outline,
                          color: NcColors.chipAsk,
                          onTap: () => _setRule(RuleAction.ask),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Block',
                          icon: Icons.block,
                          color: NcColors.chipBlock,
                          onTap: () => _setRule(RuleAction.block),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // -- Bulk Block ----------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shield_outlined, size: 16),
                      label:
                          const Text('Block All Traffic from This App'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NcColors.unprotected,
                        side: const BorderSide(
                            color: NcColors.unprotected),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _setRule(RuleAction.block),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Shared Widgets ---------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: TextStyle(
                    color: NcColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: NcColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RealTimeTrafficDashboard extends ConsumerWidget {
  const _RealTimeTrafficDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final throughput = ref.watch(throughputProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: NcColors.protected,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE NETWORK SPEED',
                        style: TextStyle(
                          color: NcColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtSpeed(throughput.currentSpeed),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: NcColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '▼ ${_fmtSpeed(throughput.rxSpeed)}',
                        style: const TextStyle(
                          color: NcColors.protected,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '▲ ${_fmtSpeed(throughput.txSpeed)}',
                        style: const TextStyle(
                          color: NcColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Peak: ${_fmtSpeed(throughput.peakSpeed)}',
                    style: TextStyle(
                      color: NcColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${_fmtBytes(throughput.totalBytes)}',
                    style: TextStyle(
                      color: NcColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _ThroughputChartPainter(throughput.speedHistory),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    final kb = bytesPerSec / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB/s';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}

class _ThroughputChartPainter extends CustomPainter {
  _ThroughputChartPainter(this.history);
  final List<double> history;

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = NcColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final maxVal = history.reduce((curr, next) => curr > next ? curr : next);
    // Dynamic scale height matching peaks, default to 10 KB/s scale
    final double scale = maxVal < 10.0 ? 10.0 : maxVal;

    final points = <Offset>[];
    final double stepX = size.width / (history.length - 1);

    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      // Invert Y coordinate since Canvas 0,0 is top-left
      final double normVal = history[i] / scale;
      final double y = size.height - (normVal * size.height * 0.85); // leaves 15% top padding
      points.add(Offset(x, y));
    }

    // 1. Draw subtle gridlines
    final gridPaint = Paint()
      ..color = NcColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    
    // Draw 3 horizontal gridlines
    for (int i = 1; i <= 3; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    // 2. Build smooth cubic bezier path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = p0.dx + (p1.dx - p0.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 3. Draw gradient fill underneath the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    paintFill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        NcColors.primary.withValues(alpha: 0.15),
        NcColors.primary.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, paintFill);

    // 4. Draw the primary glowing path line
    // Layer 1: soft bloom/glow shadow under the line
    final shadowPaint = Paint()
      ..color = NcColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..isAntiAlias = true;
    canvas.drawPath(path, shadowPaint);

    // Layer 2: crisp core foreground line
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _ThroughputChartPainter oldDelegate) =>
      oldDelegate.history != history;
}
