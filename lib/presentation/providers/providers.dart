// Drift-generated classes have the same names as domain entities.
// We import the database and hide its generated row types, using
// domain entities throughout the app instead.
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';

import '../../data/database/app_database.dart'
    hide Alert, FirewallRule, LiveConnection, DnsProfile, TrustedNetwork;
import '../../domain/entities/alert.dart';
import '../../domain/entities/application_info.dart';
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
// Installed Apps Provider
// ─────────────────────────────────────────────────────────────

/// Fetches the full list of installed apps from the Android PackageManager
/// via the platform channel. Cached for the lifetime of the provider;
/// invalidate by calling ref.invalidate(installedAppsProvider).
///
/// On non-Android platforms (Windows dev, unit tests) returns an empty list.
final installedAppsProvider = FutureProvider<List<ApplicationInfo>>((ref) async {
  try {
    final bridge = ref.read(platformBridgeProvider);
    final raw = await bridge.getInstalledApps();
    return raw.map((m) {
      final iconB64 = m['iconBase64'] as String?;
      final Uint8List? iconBytes = iconB64 != null && iconB64.isNotEmpty
          ? base64Decode(iconB64)
          : null;
      return ApplicationInfo(
        id: m['packageName'] as String,
        packageName: m['packageName'] as String,
        displayName: (m['displayName'] as String?)?.isNotEmpty == true
            ? m['displayName'] as String
            : m['packageName'] as String,
        version: m['version'] as String?,
        isSystem: m['isSystem'] as bool? ?? false,
        firstSeen: DateTime.now(),
        iconBytes: iconBytes,
        riskLevel: m['riskLevel'] as String?,
        riskScore: m['riskScore'] as int?,
        riskReasons: m['riskReasons'] != null
            ? List<String>.from(m['riskReasons'] as List)
            : null,
      );
    }).toList();
  } catch (e) {
    debugPrint('[NC] installedAppsProvider error: $e');
    return [];
  }
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
      // ── Fetch DB rules and installed apps in parallel ──────────────
      final dbRulesFuture = _db.select(_db.firewallRules).get();
      final installedFuture = _ref.read(platformBridgeProvider).getInstalledApps();

      final results = await Future.wait([dbRulesFuture, installedFuture]);
      final rows = results[0] as List;
      final rawApps = results[1] as List<Map<String, dynamic>>;

      // ── Build a lookup of existing rules by package name ───────────
      final existingRulesByAppId = <String, dynamic>{};
      for (final row in rows) {
        final r = row as dynamic;
        if (r.appId != null) {
          existingRulesByAppId[r.appId as String] = r;
        }
      }

      // ── Merge: every installed app gets a FirewallRule ─────────────
      // Apps with an existing DB rule use that action.
      // Apps without a rule get a virtual 'ask' row (not persisted to DB).
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final merged = <FirewallRule>[];

      // 1. Collect installed apps (real device apps take precedence)
      final seenPackages = <String>{};
      for (final app in rawApps) {
        final pkg = app['packageName'] as String? ?? '';
        if (pkg.isEmpty) continue;
        seenPackages.add(pkg);

        final existing = existingRulesByAppId[pkg];
        if (existing != null) {
          merged.add(FirewallRule(
            id: existing.id as String,
            appId: existing.appId as String?,
            action: RuleAction.values.firstWhere(
              (a) => a.name == existing.action,
              orElse: () => RuleAction.ask,
            ),
            priority: RulePriority.values.firstWhere(
              (p) => p.value == existing.priority,
              orElse: () => RulePriority.defaultBehavior,
            ),
            conditionsJson: existing.conditionsJson as String,
            profileId: existing.profileId as String?,
            isGlobal: existing.isGlobal as bool,
            createdAt: DateTime.fromMillisecondsSinceEpoch(existing.createdAt as int),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(existing.updatedAt as int),
            displayName: (app['displayName'] as String?)?.isNotEmpty == true
                ? app['displayName'] as String
                : pkg,
            iconBytes: _decodeIcon(app['iconBase64'] as String?),
            isSystemApp: app['isSystem'] as bool? ?? false,
            riskLevel: app['riskLevel'] as String?,
            riskScore: app['riskScore'] as int?,
            riskReasons: app['riskReasons'] != null
                ? List<String>.from(app['riskReasons'] as List)
                : null,
          ));
        } else {
          // Virtual rule — shown in UI but not yet persisted
          merged.add(FirewallRule(
            id: 'virtual_$pkg',
            appId: pkg,
            action: RuleAction.ask,
            priority: RulePriority.defaultBehavior,
            conditionsJson: '{}',
            profileId: 'default',
            isGlobal: false,
            createdAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
            displayName: (app['displayName'] as String?)?.isNotEmpty == true
                ? app['displayName'] as String
                : pkg,
            iconBytes: _decodeIcon(app['iconBase64'] as String?),
            isSystemApp: app['isSystem'] as bool? ?? false,
            riskLevel: app['riskLevel'] as String?,
            riskScore: app['riskScore'] as int?,
            riskReasons: app['riskReasons'] != null
                ? List<String>.from(app['riskReasons'] as List)
                : null,
          ));
        }
      }

      // 2. Add any DB rules for packages NOT in the installed list
      //    (e.g. rules for recently uninstalled apps — keep them visible)
      for (final row in rows) {
        final r = row as dynamic;
        final pkg = r.appId as String?;
        if (pkg == null || seenPackages.contains(pkg)) continue;
        merged.add(FirewallRule(
          id: r.id as String,
          appId: pkg,
          action: RuleAction.values.firstWhere(
            (a) => a.name == r.action,
            orElse: () => RuleAction.ask,
          ),
          priority: RulePriority.values.firstWhere(
            (p) => p.value == r.priority,
            orElse: () => RulePriority.defaultBehavior,
          ),
          conditionsJson: r.conditionsJson as String,
          profileId: r.profileId as String?,
          isGlobal: r.isGlobal as bool,
          createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt as int),
        ));
      }

      // ── Sort: user apps first, then by display name ────────────────
      merged.sort((a, b) {
        final aSystem = a.isSystemApp ? 1 : 0;
        final bSystem = b.isSystemApp ? 1 : 0;
        if (aSystem != bSystem) return aSystem.compareTo(bSystem);
        return (a.displayName ?? a.appId ?? '')
            .toLowerCase()
            .compareTo((b.displayName ?? b.appId ?? '').toLowerCase());
      });

      state = AsyncValue.data(merged);
      await syncRulesToNative();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  static List<int>? _decodeIcon(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
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
          // Include createdAt so native can apply newest-wins tiebreaker
          'createdAt': rule.createdAt.millisecondsSinceEpoch,
        });
      }

      // ── Deterministic ordering: mirrors EvaluateRuleUseCase tie-breaking ──
      // Within the same priority tier: blocking rules first, then newest first.
      // This ensures RuleRepository.evaluate() on Android/Windows sees the
      // correct winner at the head of each tier without needing to re-sort.
      serialized.sort((a, b) {
        final int pa = a['priority'] as int;
        final int pb = b['priority'] as int;
        if (pa != pb) return pa.compareTo(pb); // lower value = higher priority

        final bool aBlocks = _isBlockingAction(a['action'] as String);
        final bool bBlocks = _isBlockingAction(b['action'] as String);
        if (aBlocks != bBlocks) return aBlocks ? -1 : 1; // blocking first

        final int aTs = a['createdAt'] as int;
        final int bTs = b['createdAt'] as int;
        return bTs.compareTo(aTs); // newest first
      });

      final blockLan = activeMode == ProtectionMode.publicWifi ||
          activeMode == ProtectionMode.travel ||
          activeMode == ProtectionMode.lockdown;

      await _bridge.updateRules(serialized, blockLan: blockLan);
    } catch (e, st) {
      // Previously silently ignored — now logged so issues are visible
      debugPrint('[NC] syncRulesToNative failed: $e\n$st');
    }
  }

  static bool _isBlockingAction(String action) =>
      action == 'block' || action == 'temporaryBlock' || action == 'blockBackground';
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

  Future<void> selectProvider(String name, String endpoint, {String? doHHostname}) async {
    // If endpoint is already a full https:// URL (e.g. from the custom dialog),
    // use it directly. Otherwise derive the DoH URL from the IP literal.
    final String doHUrl;
    final String resolvedHostname;
    if (endpoint.startsWith('https://') || endpoint.startsWith('http://')) {
      doHUrl = endpoint;
      resolvedHostname = doHHostname ?? _resolverHostname(name);
    } else if (endpoint == 'system') {
      // System default — let the OS handle DNS (no DoH interception)
      doHUrl = '';
      resolvedHostname = '';
    } else {
      // IP-literal endpoint from the preset list (e.g. '1.1.1.1')
      doHUrl = 'https://$endpoint/dns-query';
      resolvedHostname = doHHostname ?? _resolverHostname(name);
    }

    state = DnsProfile(
      id: 'active_dns',
      name: name,
      provider: name.toLowerCase(),
      protocol: DnsProtocol.doh,
      endpoint: doHUrl.isNotEmpty ? doHUrl : endpoint,
      enabledCategories: state.enabledCategories,
    );

    if (doHUrl.isNotEmpty) {
      await _ref.read(platformBridgeProvider).setDnsProfile({
        'doHUrl': doHUrl,
        'doHHostname': resolvedHostname,
      });
    }
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

final securityRiskIndicatorsProvider = StateNotifierProvider<SecurityRiskIndicatorsNotifier, bool>((ref) {
  return SecurityRiskIndicatorsNotifier(ref);
});

class SecurityRiskIndicatorsNotifier extends StateNotifier<bool> {
  SecurityRiskIndicatorsNotifier(this._ref) : super(true) {
    _init();
  }
  final Ref _ref;
  Future<void> _init() async {
    final val = await _ref.read(platformBridgeProvider).getSecurityRiskIndicatorsEnabled();
    state = val;
  }
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _ref.read(platformBridgeProvider).setSecurityRiskIndicatorsEnabled(enabled);
    _ref.invalidate(installedAppsProvider);
    _ref.read(firewallRulesProvider.notifier).refresh();
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
    final wasEmpty = state.apps.isEmpty;
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
      final currentMode = _ref.read(protectionStateProvider).valueOrNull ?? 'off';
      if (wasEmpty && apps.isNotEmpty && currentMode == 'off') {
        await _ref.read(platformBridgeProvider).startQuickBlock();
      }
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

// ─────────────────────────────────────────────────────────────
// Watchtower — Throughput Monitor
// ─────────────────────────────────────────────────────────────

class ThroughputState {
  ThroughputState({
    required this.speedHistory,
    required this.currentSpeed,
    required this.peakSpeed,
    required this.totalBytes,
  });

  final List<double> speedHistory; // Rolling history in KB/s
  final double currentSpeed;       // Current speed in B/s
  final double peakSpeed;          // Peak speed in B/s
  final int totalBytes;            // Accumulated total bytes

  ThroughputState copyWith({
    List<double>? speedHistory,
    double? currentSpeed,
    double? peakSpeed,
    int? totalBytes,
  }) {
    return ThroughputState(
      speedHistory: speedHistory ?? this.speedHistory,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      peakSpeed: peakSpeed ?? this.peakSpeed,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}

final throughputProvider = StateNotifierProvider<ThroughputNotifier, ThroughputState>((ref) {
  return ThroughputNotifier(ref);
});

class ThroughputNotifier extends StateNotifier<ThroughputState> {
  ThroughputNotifier(this._ref)
      : super(ThroughputState(
          speedHistory: List.filled(15, 0.0),
          currentSpeed: 0.0,
          peakSpeed: 0.0,
          totalBytes: 0,
        )) {
    _startListening();
  }

  final Ref _ref;
  StreamSubscription? _sub;
  Timer? _timer;
  int _bytesAccumulatedInSecond = 0;
  int _totalBytesAccumulated = 0;

  void _startListening() {
    final bridge = _ref.read(platformBridgeProvider);
    _sub = bridge.connectionEvents.listen((e) {
      final int bytes = e['bytes'] as int? ?? 0;
      // Filter out 'dns' or UID=-1 if desired, but here we track total aggregate throughput
      _bytesAccumulatedInSecond += bytes;
      _totalBytesAccumulated += bytes;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final double speed = _bytesAccumulatedInSecond.toDouble(); // bytes per second
      _bytesAccumulatedInSecond = 0;

      final double peak = speed > state.peakSpeed ? speed : state.peakSpeed;
      final List<double> history = List<double>.from(state.speedHistory);
      if (history.isNotEmpty) {
        history.removeAt(0);
      }
      history.add(speed / 1024.0); // Convert to KB/s for history graph

      state = ThroughputState(
        speedHistory: history,
        currentSpeed: speed,
        peakSpeed: peak,
        totalBytes: _totalBytesAccumulated,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// Theme Mode & Cloak Engine Settings
// ─────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.dark) {
    _init();
  }
  final Ref _ref;

  Future<void> _init() async {
    final enabled = await _ref.read(platformBridgeProvider).getThemeLightEnabled();
    state = enabled ? ThemeMode.light : ThemeMode.dark;
    NcColors.updateColors(state);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    NcColors.updateColors(mode);
    await _ref.read(platformBridgeProvider).setThemeLightEnabled(mode == ThemeMode.light);
  }
}

final cloakEnabledProvider = StateNotifierProvider<CloakEnabledNotifier, bool>((ref) {
  return CloakEnabledNotifier(ref);
});

class CloakEnabledNotifier extends StateNotifier<bool> {
  CloakEnabledNotifier(this._ref) : super(false) {
    _init();
  }
  final Ref _ref;

  Future<void> _init() async {
    final enabled = await _ref.read(platformBridgeProvider).getCloakEnabled();
    state = enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _ref.read(platformBridgeProvider).setCloakEnabled(enabled);
  }
}




