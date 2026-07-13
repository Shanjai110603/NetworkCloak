import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

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
    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Watchtower'),
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
}

// ── Live Tab ─────────────────────────────────────────────────

class _LiveTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(liveConnectionsProvider);
    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: NcColors.textSecondary)),
      ),
      data: (connections) {
        if (connections.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monitor_heart_outlined,
                    size: 48, color: NcColors.textMuted),
                SizedBox(height: 12),
                Text('No active connections',
                    style: TextStyle(color: NcColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final c = connections[i];
            return _LiveConnectionCard(
              appId: c.appId,
              dest: c.dest,
              protocol: c.protocol,
              bytes: c.bytes,
              duration: c.duration,
            );
          },
        );
      },
    );
  }
}

class _LiveConnectionCard extends StatelessWidget {
  const _LiveConnectionCard({
    required this.appId,
    required this.dest,
    required this.protocol,
    required this.bytes,
    required this.duration,
  });
  final String appId;
  final String dest;
  final String protocol;
  final int bytes;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NcColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NcColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apps_outlined,
                color: NcColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appId,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '→ $dest',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
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
                  color: NcColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  protocol,
                  style: const TextStyle(
                      color: NcColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatBytes(bytes),
                style: const TextStyle(
                    color: NcColors.primary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBytes(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}

// ── History Tab ───────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(connectionHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading history: $e',
            style: const TextStyle(color: NcColors.textSecondary)),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Text(
              'No connection history recorded yet.',
              style: TextStyle(color: NcColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final r = records[i];
            final isBlocked = r.wasBlocked;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NcColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NcColors.border),
              ),
              child: Row(
                children: [
                  Text(r.countryFlag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.appId,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '→ ${r.destHost}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? NcColors.unprotected.withValues(alpha: 0.15)
                              : NcColors.protected.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isBlocked ? 'BLOCKED' : 'ALLOWED',
                          style: TextStyle(
                            color: isBlocked ? NcColors.unprotected : NcColors.protected,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(r.bytes ?? 0),
                        style: const TextStyle(color: NcColors.textSecondary, fontSize: 12),
                      ),
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

  String _formatBytes(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}

// ── Bandwidth Tab ─────────────────────────────────────────────

class _BandwidthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(applicationStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading stats: $e',
            style: const TextStyle(color: NcColors.textSecondary)),
      ),
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(
            child: Text(
              'No bandwidth stats available yet.',
              style: TextStyle(color: NcColors.textSecondary),
            ),
          );
        }

        // Sort by total bytes descending
        final sorted = List.from(stats)
          ..sort((a, b) => (b.bytesSent + b.bytesRecv).compareTo(a.bytesSent + a.bytesRecv));

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
                        child: Text(
                          s.appId,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatBytes(totalBytes),
                        style: const TextStyle(
                          color: NcColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📤 Sent: ${_formatBytes(s.bytesSent)}',
                        style: const TextStyle(color: NcColors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '📥 Recv: ${_formatBytes(s.bytesRecv)}',
                        style: const TextStyle(color: NcColors.textSecondary, fontSize: 12),
                      ),
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

  String _formatBytes(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}
