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
  Future<void> updateRules(List<Map<String, dynamic>> serializedRules);
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
  Future<void> updateRules(List<Map<String, dynamic>> rules) async {
    await _method.invokeMethod('updateRules', {'rules': rules});
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
}
