import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
// Platform Channel Identifiers
// ─────────────────────────────────────────────────────────────
const _kCommandChannel = 'com.networkcloak/commands';
const _kEventChannel = 'com.networkcloak/events';

// ─────────────────────────────────────────────────────────────
// PAL: Firewall Platform Interface
// ─────────────────────────────────────────────────────────────
abstract class FirewallPlatform {
  Future<void> startFirewall();
  Future<void> stopFirewall(String reason);
  Future<void> updateRules(List<Map<String, dynamic>> serializedRules, {bool blockLan = false});
  Future<void> activateLockdown(List<String> allowlist);
  Future<void> deactivateLockdown(String reason);
  Future<Map<String, dynamic>> getStatus();
}

// ─────────────────────────────────────────────────────────────
// PAL: VPN Platform Interface
// ─────────────────────────────────────────────────────────────
abstract class VpnPlatform {
  Future<void> startVpn();
  Future<void> stopVpn();
  Stream<bool> get connectionStateStream;
}

// ─────────────────────────────────────────────────────────────
// PAL: DNS Platform Interface
// ─────────────────────────────────────────────────────────────
abstract class DnsPlatform {
  Future<void> setDnsProfile(Map<String, dynamic> profile);
  Future<void> updateBlocklists(List<Map<String, dynamic>> lists);
}

// ─────────────────────────────────────────────────────────────
// PAL: Network Info Platform Interface
// ─────────────────────────────────────────────────────────────
abstract class NetworkInfoPlatform {
  Future<Map<String, dynamic>> getCurrentNetworkInfo();
  Stream<Map<String, dynamic>> get networkChanges;
}

// ─────────────────────────────────────────────────────────────
// Concrete: MethodChannel + EventChannel bridge implementation
// ─────────────────────────────────────────────────────────────
class PlatformChannelBridge
    implements FirewallPlatform, DnsPlatform, NetworkInfoPlatform {
  static const _method = MethodChannel(_kCommandChannel);
  static const _event = EventChannel(_kEventChannel);

  // Lazily broadcast the native EventChannel as a stream
  static Stream<dynamic>? _eventStream;
  static Stream<dynamic> get _events {
    _eventStream ??= _event.receiveBroadcastStream();
    return _eventStream!;
  }

  // ── FirewallPlatform ───────────────────────────────────────

  @override
  Future<void> startFirewall() async {
    await _method.invokeMethod('startFirewall');
  }

  @override
  Future<void> stopFirewall(String reason) async {
    await _method.invokeMethod('stopFirewall', {'reason': reason});
  }

  @override
  Future<void> updateRules(List<Map<String, dynamic>> rules, {bool blockLan = false}) async {
    await _method.invokeMethod('updateRules', {
      'rules': rules,
      'blockLan': blockLan,
    });
  }

  @override
  Future<void> activateLockdown(List<String> allowlist) async {
    await _method.invokeMethod('activateLockdown', {'allowlist': allowlist});
  }

  @override
  Future<void> deactivateLockdown(String reason) async {
    await _method.invokeMethod('deactivateLockdown', {'reason': reason});
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    final result = await _method.invokeMethod<Map>('getStatus');
    return Map<String, dynamic>.from(result ?? {});
  }

  // ── DnsPlatform ───────────────────────────────────────────

  @override
  Future<void> setDnsProfile(Map<String, dynamic> profile) async {
    await _method.invokeMethod('setDnsProfile', profile);
  }

  @override
  Future<void> updateBlocklists(List<Map<String, dynamic>> lists) async {
    await _method.invokeMethod('updateBlocklists', {'lists': lists});
  }

  // ── NetworkInfoPlatform ───────────────────────────────────

  @override
  Future<Map<String, dynamic>> getCurrentNetworkInfo() async {
    final result = await _method.invokeMethod<Map>('getNetworkInfo');
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Stream<Map<String, dynamic>> get networkChanges {
    return _events
        .where((e) => (e as Map?)?['type'] == 'NetworkChanged')
        .map((e) => Map<String, dynamic>.from(e as Map));
  }

  // ── Event stream helpers (for Riverpod StreamProviders) ───

  /// Live connection events from the VPN engine.
  Stream<Map<String, dynamic>> get connectionEvents {
    return _events
        .where((e) => (e as Map?)?['type'] == 'ConnectionEvent')
        .map((e) => Map<String, dynamic>.from(e as Map));
  }

  /// VPN protection state changes (connected / disconnected).
  Stream<bool> get protectionStateChanges {
    return _events
        .where((e) => (e as Map?)?['type'] == 'ProtectionStateChanged')
        .map((e) => (e as Map)['isActive'] as bool? ?? false);
  }

  /// VPN protection mode changes ("off", "quickBlockOnly", "full").
  Stream<String> get protectionModeChanges {
    return _events
        .where((e) => (e as Map?)?['type'] == 'ProtectionStateChanged')
        .map((e) => (e as Map)['mode'] as String? ?? 'off');
  }

  /// Alerts fired from the native heuristic analysis engine.
  Stream<Map<String, dynamic>> get alertStream {
    return _events
        .where((e) => (e as Map?)?['type'] == 'AlertFired')
        .map((e) => Map<String, dynamic>.from(e as Map));
  }

  /// Temporary rule expiry notifications from WorkManager.
  Stream<Map<String, dynamic>> get tempRuleExpiredStream {
    return _events
        .where((e) => (e as Map?)?['type'] == 'TempRuleExpired')
        .map((e) => Map<String, dynamic>.from(e as Map));
  }

  // ── Quick Block & Settings ───────────────────────────────

  Future<void> updateQuickBlock(List<String> apps) async {
    await _method.invokeMethod('updateQuickBlock', {'apps': apps});
  }

  Future<bool> startQuickBlock() async {
    final result = await _method.invokeMethod<bool>('startQuickBlock');
    return result ?? false;
  }

  Future<void> setAlertNotificationsEnabled(bool enabled) async {
    await _method.invokeMethod('setAlertNotificationsEnabled', {'enabled': enabled});
  }

  Future<bool> getAlertNotificationsEnabled() async {
    final result = await _method.invokeMethod<bool>('getAlertNotificationsEnabled');
    return result ?? true;
  }

  Future<void> setRetentionDays(int days) async {
    await _method.invokeMethod('setRetentionDays', {'days': days});
  }

  Future<int> getRetentionDays() async {
    final result = await _method.invokeMethod<int>('getRetentionDays');
    return result ?? 30;
  }

  Future<void> setSecurityRiskIndicatorsEnabled(bool enabled) async {
    await _method.invokeMethod('setSecurityRiskIndicatorsEnabled', {'enabled': enabled});
  }

  Future<bool> getSecurityRiskIndicatorsEnabled() async {
    final result = await _method.invokeMethod<bool>('getSecurityRiskIndicatorsEnabled');
    return result ?? true;
  }

  Future<void> setCloakEnabled(bool enabled) async {
    await _method.invokeMethod('setCloakEnabled', {'enabled': enabled});
  }

  Future<bool> getCloakEnabled() async {
    final result = await _method.invokeMethod<bool>('getCloakEnabled');
    return result ?? false;
  }

  Future<void> setThemeLightEnabled(bool enabled) async {
    await _method.invokeMethod('setThemeLightEnabled', {'enabled': enabled});
  }

  Future<bool> getThemeLightEnabled() async {
    final result = await _method.invokeMethod<bool>('getThemeLightEnabled');
    return result ?? false;
  }

  /// Fetches all installed apps from the Android PackageManager.
  ///
  /// Returns a list of raw maps with keys:
  ///   packageName, displayName, version, isSystem, iconBase64
  ///
  /// Call this once at Firewall screen load time; cache the result
  /// in [installedAppsProvider] so repeated navigations don't re-query.
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    final result = await _method.invokeMethod<List>('getInstalledApps');
    if (result == null) return [];
    return result
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
