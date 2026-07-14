import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/enums/network_trust_level.dart';
import '../../../domain/enums/protection_mode.dart';
import '../../../domain/entities/alert.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protectionAsync = ref.watch(protectionStateProvider);
    final networkAsync = ref.watch(networkStatusProvider);
    final mode = ref.watch(activeModeProvider);
    final List<Alert> alerts = ref.watch(alertsProvider);
    final lockdown = ref.watch(lockdownProvider);

    final protectionMode = protectionAsync.valueOrNull ?? 'off';
    final network = networkAsync.valueOrNull;

    return Scaffold(
      backgroundColor: NcColors.bg,
      body: Stack(
        children: [
          // Background radial gradient
          Positioned(
            top: -100,
            left: -100,
            child: _GlowCircle(
              color: protectionMode == 'full'
                  ? NcColors.protected.withValues(alpha: 0.12)
                  : protectionMode == 'quickBlockOnly'
                      ? NcColors.partial.withValues(alpha: 0.12)
                      : NcColors.unprotected.withValues(alpha: 0.10),
              size: 400,
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Network Cloak',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: NcColors.primary,
                                      fontWeight: FontWeight.w800,
                                    )),
                            const SizedBox(height: 2),
                            Text(
                              _networkLabel(network, mode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ],
                        ),
                        _AlertBadge(
                          count: alerts
                              .where((a) => a.isUnread)
                              .length,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Shield Status ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => ref.read(protectionToggleProvider.notifier).toggle(),
                        child: _ShieldWidget(
                          mode: protectionMode,
                          trust: network?.trustLevel ?? NetworkTrustLevel.unknown,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Mode Switcher ──────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ProtectionMode.values
                          .map((m) => Padding(
                                padding:
                                    const EdgeInsets.only(right: 8),
                                child: _ModeChip(
                                  mode: m,
                                  isSelected: m == mode,
                                  onTap: () => ref
                                      .read(activeModeProvider.notifier)
                                      .setMode(m),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Live Pulse ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LivePulseCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Quick Block ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _QuickBlockCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Alerts ────────────────────────────────
                if (alerts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent Alerts',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium),
                          const SizedBox(height: 10),
                          ...alerts
                              .take(3)
                              .cast<Alert>()
                              .map((a) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: _AlertTile(alert: a),
                                  )),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // ── Lockdown FAB ──────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _LockdownButton(isActive: lockdown),
          ),
        ],
      ),
    );
  }

  String _networkLabel(dynamic network, ProtectionMode mode) {
    if (network == null) return 'Scanning network...';
    final name = network.displayName ?? 'Unknown';
    return '$name · ${mode.displayName}';
  }
}

// ── Shield Widget ──────────────────────────────────────────────

class _ShieldWidget extends StatefulWidget {
  const _ShieldWidget({required this.mode, required this.trust});
  final String mode;
  final NetworkTrustLevel trust;

  @override
  State<_ShieldWidget> createState() => _ShieldWidgetState();
}

class _ShieldWidgetState extends State<_ShieldWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _shieldColor {
    if (widget.trust == NetworkTrustLevel.hostile) {
      return NcColors.hostile;
    }
    if (widget.mode == 'off') {
      return NcColors.unprotected;
    }
    if (widget.mode == 'quickBlockOnly') {
      return NcColors.partial;
    }
    if (widget.trust == NetworkTrustLevel.unknown ||
        widget.trust == NetworkTrustLevel.publicWifi) {
      return NcColors.partial;
    }
    return NcColors.protected;
  }

  String get _statusLabel {
    if (widget.trust == NetworkTrustLevel.hostile) {
      return 'Threat Detected';
    }
    if (widget.mode == 'off') {
      return 'Protection Off';
    }
    if (widget.mode == 'quickBlockOnly') {
      return 'Quick Block Active';
    }
    if (widget.trust == NetworkTrustLevel.publicWifi) {
      return 'Shield Active';
    }
    if (widget.trust == NetworkTrustLevel.unknown) {
      return 'Partial Protection';
    }
    return 'Protected';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _shieldColor.withValues(alpha: 0.1),
              border: Border.all(
                color: _shieldColor.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _shieldColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              widget.mode != 'off' ? Icons.shield : Icons.shield_outlined,
              size: 80,
              color: _shieldColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _statusLabel,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: _shieldColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.trust.plainLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Mode Chip ─────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });
  final ProtectionMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? NcColors.primary.withValues(alpha: 0.15)
              : NcColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? NcColors.primary : NcColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mode.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              mode.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? NcColors.primary
                        : NcColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Pulse Card ───────────────────────────────────────────

class _LivePulseCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(liveConnectionsProvider);
    final connections = connectionsAsync.valueOrNull ?? [];

    return Container(
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
              Text('Live Traffic',
                  style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NcColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NcColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulseDot(),
                    const SizedBox(width: 6),
                    Text(
                      '${connections.length} active',
                      style: const TextStyle(
                          color: NcColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (connections.isEmpty)
            const Center(
              child: Text(
                'No active connections',
                style: TextStyle(color: NcColors.textMuted),
              ),
            )
          else
            ...connections.take(3).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _LiveConnectionRow(conn: c),
                )),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NcColors.primary
              .withValues(alpha: 0.4 + (_ctrl.value * 0.6)),
        ),
      ),
    );
  }
}

class _LiveConnectionRow extends StatelessWidget {
  const _LiveConnectionRow({required this.conn});
  final dynamic conn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.swap_horiz, size: 14, color: NcColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            conn.appId,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '→ ${conn.dest}',
          style: const TextStyle(color: NcColors.textMuted, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Alert Badge ───────────────────────────────────────────────

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: NcColors.textPrimary,
          onPressed: () => context.push('/alerts'),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: NcColors.unprotected,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Alert Tile ────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final Alert alert;

  Color _severityColor(String s) {
    switch (s) {
      case 'critical':
        return NcColors.unprotected;
      case 'warning':
        return NcColors.partial;
      default:
        return NcColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(alert.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lockdown Button ───────────────────────────────────────────

class _LockdownButton extends ConsumerWidget {
  const _LockdownButton({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (isActive) {
          ref.read(lockdownProvider.notifier).deactivate();
        } else {
          _confirmLockdown(context, ref);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isActive
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD50000), Color(0xFFFF1744)]),
          color: isActive ? NcColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: NcColors.unprotected.withValues(alpha: 0.5))
              : null,
          boxShadow: isActive
              ? []
              : [
                  BoxShadow(
                    color: NcColors.unprotected.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.lock_open_outlined : Icons.lock_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              isActive ? 'Deactivate Lockdown' : '🔒  Lockdown Mode',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLockdown(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: NcColors.surface,
        title: const Text('Activate Lockdown?',
            style: TextStyle(color: NcColors.textPrimary)),
        content: const Text(
          'Lockdown blocks all apps immediately. '
          'Only phone calls and emergency services will be allowed.',
          style: TextStyle(color: NcColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: NcColors.unprotected),
            onPressed: () {
              Navigator.pop(c);
              ref.read(lockdownProvider.notifier).activate();
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
}

// ── Glow Circle (background decoration) ──────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _QuickBlockCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickBlockState = ref.watch(quickBlockProvider);
    final count = quickBlockState.apps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NcColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NcColors.chipBlock.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, color: NcColors.chipBlock, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Block',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quickBlockState.masterEnabled
                      ? 'Active: $count apps blocked'
                      : '$count apps configured',
                  style: const TextStyle(
                    fontSize: 13,
                    color: NcColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/quick-block'),
            child: const Text('Manage', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
