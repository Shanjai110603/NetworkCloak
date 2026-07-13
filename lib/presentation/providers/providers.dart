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
  ModeNotifier(this._ref) : super(ProtectionMode.home);
  final Ref _ref;

  Future<void> setMode(ProtectionMode mode) async {
    state = mode;
    await _ref.read(firewallRulesProvider.notifier).syncRulesToNative();
    await _ref.read(platformBridgeProvider).startFirewall();
  }
}

// ─────────────────────────────────────────────────────────────
// Network Status
// ─────────────────────────────────────────────────────────────

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final bridge = ref.watch(platformBridgeProvider);
  return bridge.networkChanges.map((e) => NetworkStatus(
        trustLevel: _parseTrust(e['trustLevel'] as String? ?? 'unknown'),
        ssid: e['ssid'] as String?,
        bssid: e['bssid'] as String?,
        authType: e['authType'] as String?,
        isRoaming: e['isRoaming'] as bool? ?? false,
        isCellular: e['isCellular'] as bool? ?? false,
      ));
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
      final rows = await _db.select(_db.firewallRules).get();
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

      await _bridge.updateRules(serialized);
    } catch (e) {
      // Ignore
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Watchtower — Live Connections
// ─────────────────────────────────────────────────────────────

final liveConnectionsProvider = StreamProvider<List<LiveConnection>>((ref) {
  final bridge = ref.watch(platformBridgeProvider);
  final list = <LiveConnection>[];
  return bridge.connectionEvents.map((e) {
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
    return List<LiveConnection>.from(list);
  });
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
  }

  final AppDatabase _db;
  final PlatformChannelBridge _bridge;

  Future<void> _loadFromDb() async {
    final rows = await _db.select(_db.alerts).get();
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
            createdAt: alert.createdAt.millisecondsSinceEpoch,
          ));
    });
  }

  void markRead(String id) {
    state = state
        .map((a) => a.id == id ? a.markRead() : a)
        .toList();
  }
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
