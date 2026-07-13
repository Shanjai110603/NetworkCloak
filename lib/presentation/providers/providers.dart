// Drift-generated classes have the same names as domain entities.
// We import the database and hide its generated row types, using
// domain entities throughout the app instead.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart'
    hide Alert, FirewallRule, LiveConnection, DnsProfile;
import '../../domain/entities/alert.dart';
import '../../domain/entities/connection_record.dart';
import '../../domain/entities/firewall_rule.dart';
import '../../domain/entities/trusted_network.dart';
import '../../domain/enums/network_trust_level.dart';
import '../../domain/enums/protection_mode.dart';
import '../../domain/enums/rule_action.dart';
import '../../domain/enums/rule_priority.dart';
import '../../domain/entities/dns_profile.dart';
import '../../domain/enums/dns_protocol.dart';
import '../../domain/usecases/shield/classify_network_use_case.dart';
import '../../platform/platform_channel_bridge.dart';

// ─────────────────────────────────────────────────────────────
// Infrastructure Providers
// ─────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final platformBridgeProvider = Provider<PlatformChannelBridge>((ref) {
  return PlatformChannelBridge();
});

// ─────────────────────────────────────────────────────────────
// Protection State
// ─────────────────────────────────────────────────────────────

final protectionStateProvider = StreamProvider<bool>((ref) {
  final bridge = ref.watch(platformBridgeProvider);
  return bridge.protectionStateChanges;
});

final activeModeProvider = StateNotifierProvider<ModeNotifier, ProtectionMode>(
  (ref) => ModeNotifier(ref),
);

class ModeNotifier extends StateNotifier<ProtectionMode> {
  ModeNotifier(this._ref) : super(ProtectionMode.home) {
    _listenNetwork();
  }
  final Ref _ref;

  void _listenNetwork() {
    _ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (prev, next) async {
      final status = next.value;
      if (status == null) return;

      final db = _ref.read(databaseProvider);
      final trustedRows = await db.select(db.trustedNetworks).get();
      final trusted = trustedRows.map((r) => TrustedNetwork(
        id: r.id,
        ssid: r.ssid,
        bssid: r.bssid,
        trustLevel: NetworkTrustLevel.values.firstWhere(
          (t) => t.name == r.trustLevel,
          orElse: () => NetworkTrustLevel.trusted,
        ),
        profileId: r.profileId,
      )).toList();

      final input = NetworkClassificationInput(
        ssid: status.ssid,
        bssid: status.bssid,
        authType: status.authType,
        isRoaming: status.isRoaming,
        hasCaptivePortal: false,
        isCellular: status.isCellular,
        trustedNetworks: trusted,
      );

      const classifier = ClassifyNetworkUseCase();
      final result = classifier.classify(input);

      if (result.autoSwitched && result.suggestedMode != state) {
        state = result.suggestedMode;

        if (result.plainAlert != null) {
          final alertId = 'alert_auto_${DateTime.now().millisecondsSinceEpoch}';
          await db.into(db.alerts).insert(AlertsCompanion.insert(
            id: alertId,
            type: 'profile_switch',
            severity: result.trustLevel == NetworkTrustLevel.hostile ? 'critical' : 'info',
            title: 'Shield Protection Active',
            body: result.plainAlert!,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));
          _ref.read(alertsProvider.notifier).refresh();
        }

        await _ref.read(firewallRulesProvider.notifier).syncRulesToNative();
        await _ref.read(platformBridgeProvider).startFirewall();
      }
    });
  }

  Future<void> setMode(ProtectionMode mode) async {
    state = mode;
    await _ref.read(firewallRulesProvider.notifier).syncRulesToNative();
    await _ref.read(platformBridgeProvider).startFirewall();
  }
}

// ─────────────────────────────────────────────────────────────
// Network Status
// ─────────────────────────────────────────────────────────────

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final bridge = ref.watch(platformBridgeProvider);
  
  yield const NetworkStatus(
    trustLevel: NetworkTrustLevel.trusted,
    ssid: 'Ethernet/Wi-Fi',
    bssid: '00:11:22:33:44:55',
    authType: 'WPA2-PSK',
    isRoaming: false,
    isCellular: false,
  );

  await for (final e in bridge.networkChanges) {
    yield NetworkStatus(
      trustLevel: _parseTrust(e['trustLevel'] as String? ?? 'unknown'),
      ssid: e['ssid'] as String?,
      bssid: e['bssid'] as String?,
      authType: e['authType'] as String?,
      isRoaming: e['isRoaming'] as bool? ?? false,
      isCellular: e['isCellular'] as bool? ?? false,
    );
  }
});

NetworkTrustLevel _parseTrust(String raw) {
  switch (raw) {
    case 'trusted':
      return NetworkTrustLevel.trusted;
    case 'public':
      return NetworkTrustLevel.publicWifi;
    case 'hostile':
      return NetworkTrustLevel.hostile;
    default:
      return NetworkTrustLevel.unknown;
  }
}

// ─────────────────────────────────────────────────────────────
// Firewall Providers
// ─────────────────────────────────────────────────────────────

final firewallRulesProvider =
    StateNotifierProvider<FirewallRulesNotifier, AsyncValue<List<FirewallRule>>>(
  (ref) => FirewallRulesNotifier(ref),
);

class FirewallRulesNotifier
    extends StateNotifier<AsyncValue<List<FirewallRule>>> {
  FirewallRulesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  AppDatabase get _db => _ref.read(databaseProvider);
  PlatformChannelBridge get _bridge => _ref.read(platformBridgeProvider);

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      var rows = await _db.select(_db.firewallRules).get();
      if (rows.isEmpty) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final defaultApps = [
          ('com.android.chrome', RuleAction.allow),
          ('com.spotify.music', RuleAction.allow),
          ('com.whatsapp', RuleAction.ask),
          ('com.instagram.android', RuleAction.block),
          ('system_process', RuleAction.allow),
        ];
        for (final app in defaultApps) {
          final newId = 'rule_${nowMs}_${app.$1}';
          await _db.into(_db.firewallRules).insert(FirewallRulesCompanion.insert(
            id: newId,
            appId: Value(app.$1),
            action: app.$2.name,
            priority: RulePriority.manualApp.value,
            conditionsJson: '{}',
            profileId: const Value('default'),
            isGlobal: const Value(false),
            createdAt: nowMs,
            updatedAt: nowMs,
          ));
        }
        rows = await _db.select(_db.firewallRules).get();
      }
      state = AsyncValue.data(rows
          .map((r) => FirewallRule(
                id: r.id,
                appId: r.appId,
                action: RuleAction.values.firstWhere(
                  (a) => a.name == r.action,
                  orElse: () => RuleAction.ask,
                ),
                priority: RulePriority.values.firstWhere(
                  (p) => p.value == r.priority,
                  orElse: () => RulePriority.defaultBehavior,
                ),
                conditionsJson: r.conditionsJson,
                profileId: r.profileId,
                isGlobal: r.isGlobal,
                createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
              ))
          .toList());
      await syncRulesToNative();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> updateRuleAction(String appId, RuleAction action) async {
    final existing = await (_db.select(_db.firewallRules)
          ..where((t) => t.appId.equals(appId)))
        .getSingleOrNull();

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (existing != null) {
      await (_db.update(_db.firewallRules)
            ..where((t) => t.id.equals(existing.id)))
          .write(FirewallRulesCompanion(
        action: Value(action.name),
        updatedAt: Value(nowMs),
      ));
    } else {
      final newId = 'rule_${nowMs}_$appId';
      await _db.into(_db.firewallRules).insert(FirewallRulesCompanion.insert(
        id: newId,
        appId: Value(appId),
        action: action.name,
        priority: RulePriority.manualApp.value,
        conditionsJson: '{}',
        profileId: const Value('default'),
        isGlobal: const Value(false),
        createdAt: nowMs,
        updatedAt: nowMs,
      ));
    }

    await _load();
  }

  Future<void> syncRulesToNative() async {
    try {
      final rules = state.valueOrNull ?? [];
      final activeMode = _ref.read(activeModeProvider);

      final List<Map<String, dynamic>> serialized = [];
      for (final rule in rules) {
        if (rule.profileId != null &&
            rule.profileId != 'default' &&
            rule.profileId != 'global' &&
            rule.profileId != '' &&
            !rule.isGlobal) {
          if (rule.profileId != activeMode.name) {
            continue;
          }
        }

        serialized.add({
          'id': rule.id,
          'appId': rule.appId,
          'action': rule.action.name,
          'priority': rule.priority.value,
          'isGlobal': rule.isGlobal,
        });
      }

      final blockLan = activeMode == ProtectionMode.publicWifi ||
          activeMode == ProtectionMode.travel ||
          activeMode == ProtectionMode.lockdown;

      await _bridge.updateRules(serialized, blockLan: blockLan);
    } catch (e) {
      // Ignore
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Watchtower — Live Connections
// ─────────────────────────────────────────────────────────────

final liveConnectionsProvider = StreamProvider<List<LiveConnection>>((ref) async* {
  final bridge = ref.watch(platformBridgeProvider);
  final list = <LiveConnection>[
    LiveConnection(
      id: 'mock_1',
      appId: 'com.android.chrome',
      dest: 'google.com',
      protocol: 'TCP',
      startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
      bytes: 1024,
    ),
    LiveConnection(
      id: 'mock_2',
      appId: 'com.spotify.music',
      dest: 'spotify.com',
      protocol: 'TCP',
      startedAt: DateTime.now().subtract(const Duration(seconds: 4)),
      bytes: 40960,
    ),
    LiveConnection(
      id: 'mock_3',
      appId: 'com.google.android.youtube',
      dest: 'youtube.com',
      protocol: 'UDP',
      startedAt: DateTime.now().subtract(const Duration(seconds: 2)),
      bytes: 102400,
    ),
  ];
  yield list;

  await for (final e in bridge.connectionEvents) {
    final conn = LiveConnection(
      id: '${e['uid']}_${e['timestamp']}',
      appId: e['appId'] as String? ?? 'unknown',
      dest: e['destHost'] as String? ?? e['destIp'] as String? ?? '?',
      protocol: e['protocol'] as String? ?? 'TCP',
      startedAt: DateTime.fromMillisecondsSinceEpoch(
          e['timestamp'] as int? ?? 0),
      bytes: e['bytes'] as int? ?? 0,
    );
    list.insert(0, conn);
    if (list.length > 200) list.removeLast();
    yield List<LiveConnection>.from(list);
  }
});

// ─────────────────────────────────────────────────────────────
// Alerts
// ─────────────────────────────────────────────────────────────

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<Alert>>(
  (ref) => AlertsNotifier(
    ref.watch(databaseProvider),
    ref.watch(platformBridgeProvider),
  ),
);

class AlertsNotifier extends StateNotifier<List<Alert>> {
  AlertsNotifier(this._db, this._bridge) : super([]) {
    _loadFromDb();
    _listenNative();
    _monitorConnectionAnomalies();
  }

  final AppDatabase _db;
  final PlatformChannelBridge _bridge;

  final _connectionHistory = <String, List<DateTime>>{};
  final _lastAnomalyAlert = <String, DateTime>{};

  Future<void> _loadFromDb() async {
    final rows = await _db.select(_db.alerts).get();
    if (rows.isEmpty) {
      state = [
        Alert(
          id: 'alert_1',
          type: 'port_scan',
          severity: 'warning',
          title: 'Suspicious Port Activity',
          body: 'IP 192.168.1.150 was blocked scanning ports.',
          appId: 'system',
          status: 'unread',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Alert(
          id: 'alert_2',
          type: 'dns_leak',
          severity: 'info',
          title: 'DNS Encryption Active',
          body: 'All DNS queries are now routed securely via Cloudflare DoH.',
          appId: 'dns',
          status: 'read',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    } else {
      state = rows
          .map((r) => Alert(
                id: r.id,
                type: r.type,
                severity: r.severity,
                title: r.title,
                body: r.body,
                appId: r.appId,
                status: r.status,
                createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
              ))
          .toList();
    }
  }

  void _listenNative() {
    _bridge.alertStream.listen((e) async {
      final alert = Alert(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        type: e['alertType'] as String? ?? 'unknown',
        severity: e['severity'] as String? ?? 'warning',
        title: e['title'] as String? ?? 'Security Alert',
        body: e['message'] as String? ?? '',
        appId: e['appId'] as String?,
        status: 'unread',
        createdAt: DateTime.now(),
      );
      state = [alert, ...state];
      await _db.into(_db.alerts).insert(AlertsCompanion.insert(
            id: alert.id,
            type: alert.type,
            severity: alert.severity,
            title: alert.title,
            body: alert.body,
            appId: Value(alert.appId),
            createdAt: alert.createdAt.millisecondsSinceEpoch,
          ));
    });
  }

  void _monitorConnectionAnomalies() {
    _bridge.connectionEvents.listen((e) async {
      final appId = e['appId'] as String? ?? 'unknown';
      if (appId == 'unknown' || appId == 'dns' || appId == 'system') return;

      final now = DateTime.now();
      final times = _connectionHistory.putIfAbsent(appId, () => []);
      times.add(now);

      // Remove connections older than 60 seconds
      times.removeWhere((t) => now.difference(t).inSeconds > 60);

      // Threshold: 40 connections in 60 seconds
      if (times.length > 40) {
        final lastAlert = _lastAnomalyAlert[appId];
        if (lastAlert == null || now.difference(lastAlert).inMinutes >= 2) {
          _lastAnomalyAlert[appId] = now;

          final alert = Alert(
            id: 'anomaly_${now.millisecondsSinceEpoch}_$appId',
            type: 'anomaly',
            severity: 'warning',
            title: 'Unusual Network Activity',
            body: '$appId is connecting to an unusually high number of servers. Tap to review.',
            appId: appId,
            status: 'unread',
            createdAt: now,
          );

          state = [alert, ...state];
          await _db.into(_db.alerts).insert(AlertsCompanion.insert(
                id: alert.id,
                type: alert.type,
                severity: alert.severity,
                title: alert.title,
                body: alert.body,
                appId: Value(alert.appId),
                createdAt: alert.createdAt.millisecondsSinceEpoch,
              ));
        }
      }
    });
  }

  void markRead(String id) {
    state = state
        .map((a) => a.id == id ? a.markRead() : a)
        .toList();
  }

  void refresh() => _loadFromDb();
}

// ─────────────────────────────────────────────────────────────
// Lockdown
// ─────────────────────────────────────────────────────────────

final lockdownProvider = StateNotifierProvider<LockdownNotifier, bool>(
  (ref) => LockdownNotifier(ref.watch(platformBridgeProvider)),
);

class LockdownNotifier extends StateNotifier<bool> {
  LockdownNotifier(this._bridge) : super(false);
  final PlatformChannelBridge _bridge;

  static const _defaultAllowlist = [
    'com.android.phone',
    'com.google.android.dialer',
  ];

  Future<void> activate({List<String>? allowlist}) async {
    await _bridge.activateLockdown(allowlist ?? _defaultAllowlist);
    state = true;
  }

  Future<void> deactivate() async {
    await _bridge.deactivateLockdown('User deactivated lockdown');
    state = false;
  }
}

// ─────────────────────────────────────────────────────────────
// DNS Guard
// ─────────────────────────────────────────────────────────────

final dnsProfileProvider = StateNotifierProvider<DnsProfileNotifier, DnsProfile>((ref) {
  return DnsProfileNotifier(ref);
});

class DnsProfileNotifier extends StateNotifier<DnsProfile> {
  DnsProfileNotifier(this._ref) : super(DnsProfile.defaultProfile);
  final Ref _ref;

  Future<void> selectProvider(String name, String endpoint) async {
    state = DnsProfile(
      id: 'active_dns',
      name: name,
      provider: name.toLowerCase(),
      protocol: DnsProtocol.doh,
      endpoint: endpoint,
      enabledCategories: state.enabledCategories,
    );
    await _ref.read(platformBridgeProvider).setDnsProfile({
      'provider': state.provider,
      'protocol': state.protocol.name,
      'endpoint': state.endpoint,
    });
  }

  Future<void> toggleCategory(String category) async {
    final categories = List<String>.from(state.enabledCategories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    state = DnsProfile(
      id: state.id,
      name: state.name,
      provider: state.provider,
      protocol: state.protocol,
      endpoint: state.endpoint,
      enabledCategories: categories,
    );
    await _ref.read(platformBridgeProvider).updateBlocklists([
      {
        'category': category,
        'domains': [], // Native implementation dynamically updates domains
      }
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Connection History & Stats
// ─────────────────────────────────────────────────────────────

final connectionHistoryProvider = FutureProvider<List<ConnectionRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.connectionHistory).get();
  
  if (rows.isEmpty) {
    return [
      ConnectionRecord(
        id: 1,
        appId: 'com.android.chrome',
        destHost: 'github.com',
        destIp: '140.82.121.4',
        port: 443,
        protocol: 'TCP',
        action: RuleAction.allow,
        bytes: 12540,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ConnectionRecord(
        id: 2,
        appId: 'com.instagram.android',
        destHost: 'instagram.com',
        destIp: '157.240.22.174',
        port: 443,
        protocol: 'TCP',
        action: RuleAction.block,
        bytes: 2540,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      ConnectionRecord(
        id: 3,
        appId: 'com.whatsapp',
        destHost: 'whatsapp.net',
        destIp: '157.240.22.53',
        port: 443,
        protocol: 'TCP',
        action: RuleAction.allow,
        bytes: 840,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  return rows.map((r) => ConnectionRecord(
    id: r.id,
    appId: r.appId,
    destHost: r.destHost,
    destIp: r.destIp ?? '',
    port: r.port ?? 80,
    protocol: r.protocol ?? 'TCP',
    action: RuleAction.values.firstWhere(
      (a) => a.name == r.action,
      orElse: () => RuleAction.allow,
    ),
    bytes: r.bytes ?? 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(r.timestamp),
  )).toList();
});

final applicationStatsProvider = FutureProvider<List<ApplicationStat>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.applicationStats).get();
  
  if (rows.isEmpty) {
    return [
      ApplicationStat(
        id: 'stats_1',
        appId: 'com.android.chrome',
        connections: 124,
        blocked: 4,
        bytesSent: 1542000,
        bytesRecv: 8420000,
        statDate: '2026-07-13',
      ),
      ApplicationStat(
        id: 'stats_2',
        appId: 'com.spotify.music',
        connections: 45,
        blocked: 0,
        bytesSent: 852000,
        bytesRecv: 45200000,
        statDate: '2026-07-13',
      ),
      ApplicationStat(
        id: 'stats_3',
        appId: 'com.google.android.youtube',
        connections: 84,
        blocked: 1,
        bytesSent: 3450000,
        bytesRecv: 120400000,
        statDate: '2026-07-13',
      ),
    ];
  }
  
  return rows;
});
