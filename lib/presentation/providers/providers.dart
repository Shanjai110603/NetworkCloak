// Drift-generated classes have the same names as domain entities.
// We import the database and hide its generated row types, using
// domain entities throughout the app instead.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart'
    hide Alert, FirewallRule, LiveConnection, DnsProfile, TrustedNetwork;
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

final protectionStateProvider = StreamProvider<String>((ref) {
  final bridge = ref.watch(platformBridgeProvider);
  return bridge.protectionModeChanges;
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

      final autoSwitch = _ref.read(autoSwitchEnabledProvider);
      if (!autoSwitch) return; // Guard auto-switch (Item 7)

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
        
        // Only start/refresh VPN if full protection is already active
        final currentMode = _ref.read(protectionStateProvider).valueOrNull ?? 'off';
        if (currentMode == 'full') {
          await _ref.read(platformBridgeProvider).startFirewall();
        }
      }
    });
  }

  Future<void> setMode(ProtectionMode mode) async {
    state = mode;
    await _ref.read(firewallRulesProvider.notifier).syncRulesToNative();
    
    // Only start/refresh VPN if full protection is already active
    final currentMode = _ref.read(protectionStateProvider).valueOrNull ?? 'off';
    if (currentMode == 'full') {
      await _ref.read(platformBridgeProvider).startFirewall();
    }
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

  Future<void> updateRuleAction(String appId, RuleAction action, {String? profileId}) async {
    final query = _db.select(_db.firewallRules)
      ..where((t) => t.appId.equals(appId));
    if (profileId != null) {
      query.where((t) => t.profileId.equals(profileId));
    }
    final existing = await query.getSingleOrNull();

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
        profileId: Value(profileId ?? 'default'),
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
          'conditionsJson': rule.conditionsJson,
        });
      }

      final blockLan = activeMode == ProtectionMode.publicWifi ||
          activeMode == ProtectionMode.travel ||
          activeMode == ProtectionMode.lockdown;

      await _bridge.updateRules(serialized, blockLan: blockLan);
    } catch (e, st) {
      // Previously silently ignored — now logged so issues are visible
      debugPrint('[NC] syncRulesToNative failed: $e\n$st');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Watchtower — Live Connections
// ─────────────────────────────────────────────────────────────

final liveConnectionsProvider = StreamProvider<List<LiveConnection>>((ref) async* {
  final bridge = ref.watch(platformBridgeProvider);
  // Start with empty state — no mock data
  final list = <LiveConnection>[];
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
    // No mock data — show empty state until real alerts arrive
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

  Future<void> markRead(String id) async {
    state = state
        .map((a) => a.id == id ? a.markRead() : a)
        .toList();
    await (_db.update(_db.alerts)..where((t) => t.id.equals(id)))
        .write(const AlertsCompanion(status: Value('read')));
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
    // Map display name/endpoint to DoH URL + hostname
    // Endpoint should be an IP literal; derive doHHostname from provider name
    final doHUrl = 'https://$endpoint/dns-query';
    final doHHostname = _resolverHostname(name);
    state = DnsProfile(
      id: 'active_dns',
      name: name,
      provider: name.toLowerCase(),
      protocol: DnsProtocol.doh,
      endpoint: endpoint,
      enabledCategories: state.enabledCategories,
    );
    await _ref.read(platformBridgeProvider).setDnsProfile({
      'doHUrl': doHUrl,
      'doHHostname': doHHostname,
    });
  }

  static String _resolverHostname(String providerName) {
    final lower = providerName.toLowerCase();
    if (lower.contains('cloudflare')) return 'cloudflare-dns.com';
    if (lower.contains('google'))     return 'dns.google';
    if (lower.contains('quad9'))      return 'dns.quad9.net';
    if (lower.contains('nextdns'))    return 'dns.nextdns.io';
    return 'cloudflare-dns.com'; // safe default
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
  // No mock data — return empty list when DB is empty
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
  return rows;
});

final notificationsEnabledProvider = StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
  return NotificationsEnabledNotifier(ref);
});

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  NotificationsEnabledNotifier(this._ref) : super(true) {
    _init();
  }
  final Ref _ref;
  Future<void> _init() async {
    final val = await _ref.read(platformBridgeProvider).getAlertNotificationsEnabled();
    state = val;
  }
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _ref.read(platformBridgeProvider).setAlertNotificationsEnabled(enabled);
  }
}

final retentionDaysProvider = StateNotifierProvider<RetentionDaysNotifier, int>((ref) {
  return RetentionDaysNotifier(ref);
});

class RetentionDaysNotifier extends StateNotifier<int> {
  RetentionDaysNotifier(this._ref) : super(30) {
    _init();
  }
  final Ref _ref;
  Future<void> _init() async {
    final val = await _ref.read(platformBridgeProvider).getRetentionDays();
    state = val;
  }
  Future<void> setDays(int days) async {
    state = days;
    await _ref.read(platformBridgeProvider).setRetentionDays(days);
  }
}

final autoSwitchEnabledProvider = StateNotifierProvider<AutoSwitchEnabledNotifier, bool>((ref) {
  return AutoSwitchEnabledNotifier();
});

class AutoSwitchEnabledNotifier extends StateNotifier<bool> {
  AutoSwitchEnabledNotifier() : super(true);
  void setEnabled(bool val) => state = val;
}

final roamingAutoBlockProvider = StateNotifierProvider<RoamingAutoBlockNotifier, bool>((ref) {
  return RoamingAutoBlockNotifier();
});

class RoamingAutoBlockNotifier extends StateNotifier<bool> {
  RoamingAutoBlockNotifier() : super(true);
  void setEnabled(bool val) => state = val;
}

class QuickBlockState {
  const QuickBlockState({required this.apps, required this.masterEnabled});
  final Set<String> apps;
  final bool masterEnabled;

  QuickBlockState copyWith({Set<String>? apps, bool? masterEnabled}) {
    return QuickBlockState(
      apps: apps ?? this.apps,
      masterEnabled: masterEnabled ?? this.masterEnabled,
    );
  }
}

final quickBlockProvider = StateNotifierProvider<QuickBlockNotifier, QuickBlockState>((ref) {
  return QuickBlockNotifier(ref);
});

class QuickBlockNotifier extends StateNotifier<QuickBlockState> {
  QuickBlockNotifier(this._ref) : super(const QuickBlockState(apps: {}, masterEnabled: false)) {
    _init();
  }
  final Ref _ref;

  Future<void> _init() async {
    final db = _ref.read(databaseProvider);
    final enabledSetting = await (db.select(db.settings)
          ..where((t) => t.category.equals('quick_block') & t.key.equals('enabled')))
        .getSingleOrNull();
    final appsSetting = await (db.select(db.settings)
          ..where((t) => t.category.equals('quick_block') & t.key.equals('apps')))
        .getSingleOrNull();

    final enabled = enabledSetting?.value == 'true';
    final apps = appsSetting?.value.split(',').where((s) => s.isNotEmpty).toSet() ?? {};

    state = QuickBlockState(apps: apps, masterEnabled: enabled);
  }

  Future<void> toggle(String appId) async {
    final apps = Set<String>.from(state.apps);
    if (apps.contains(appId)) {
      apps.remove(appId);
    } else {
      apps.add(appId);
    }
    state = state.copyWith(apps: apps);

    final db = _ref.read(databaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      category: const Value('quick_block'),
      key: const Value('apps'),
      value: Value(apps.join(',')),
      valueType: const Value('string'),
      updatedAt: Value(now),
    ));

    if (state.masterEnabled) {
      await _ref.read(platformBridgeProvider).updateQuickBlock(apps.toList());
    }

    if (apps.isEmpty && state.masterEnabled) {
      final currentMode = _ref.read(protectionStateProvider).valueOrNull ?? 'off';
      if (currentMode == 'quickBlockOnly') {
        await _ref.read(platformBridgeProvider).stopFirewall('No apps quick-blocked');
      }
    }
  }

  Future<void> setMasterEnabled(bool enabled) async {
    state = state.copyWith(masterEnabled: enabled);

    final db = _ref.read(databaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion(
      category: const Value('quick_block'),
      key: const Value('enabled'),
      value: Value(enabled.toString()),
      valueType: const Value('bool'),
      updatedAt: Value(now),
    ));

    final bridge = _ref.read(platformBridgeProvider);
    if (enabled) {
      await bridge.updateQuickBlock(state.apps.toList());
      if (state.apps.isNotEmpty) {
        await bridge.startQuickBlock();
      }
    } else {
      await bridge.updateQuickBlock([]);
      final currentMode = _ref.read(protectionStateProvider).valueOrNull ?? 'off';
      if (currentMode == 'quickBlockOnly') {
        await bridge.stopFirewall('Quick Block disabled');
      }
    }
  }
}

final protectionToggleProvider = StateNotifierProvider<ProtectionToggleNotifier, bool>((ref) {
  return ProtectionToggleNotifier(ref);
});

class ProtectionToggleNotifier extends StateNotifier<bool> {
  ProtectionToggleNotifier(this._ref) : super(false) {
    _ref.listen<AsyncValue<String>>(protectionStateProvider, (prev, next) {
      final mode = next.value;
      if (mode != null) {
        state = (mode == 'full');
      }
    });
  }
  final Ref _ref;

  Future<void> toggle() async {
    final bridge = _ref.read(platformBridgeProvider);
    final rulesNotifier = _ref.read(firewallRulesProvider.notifier);
    if (state) {
      await bridge.stopFirewall('User disabled');
      state = false;
    } else {
      await rulesNotifier.syncRulesToNative();
      await bridge.startFirewall();
      state = true;
    }
  }
}

final trustedNetworksProvider = StreamProvider<List<TrustedNetwork>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.trustedNetworks).watch().map((rows) => rows.map((r) => TrustedNetwork(
        id: r.id,
        ssid: r.ssid,
        bssid: r.bssid,
        trustLevel: NetworkTrustLevel.values.firstWhere(
          (t) => t.name == r.trustLevel,
          orElse: () => NetworkTrustLevel.trusted,
        ),
        profileId: r.profileId,
      )).toList());
});




