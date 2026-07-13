/// Installed application info resolved from the native package manager.
class ApplicationInfo {
  const ApplicationInfo({
    required this.id,
    required this.packageName,
    required this.displayName,
    this.version,
    required this.firstSeen,
    this.iconBytes,
    this.isSystem = false,
  });

  final String id;
  final String packageName;
  final String displayName;
  final String? version;
  final DateTime firstSeen;
  final List<int>? iconBytes; // PNG bytes from PackageManager
  final bool isSystem;
}

/// Per-app bandwidth & connection statistics for a given period.
class AppStatistics {
  const AppStatistics({
    required this.appId,
    required this.connections,
    required this.blocked,
    required this.bytesSent,
    required this.bytesRecv,
    required this.statDate,
  });

  final String appId;
  final int connections;
  final int blocked;
  final int bytesSent;
  final int bytesRecv;
  final String statDate; // YYYY-MM-DD

  int get totalBytes => bytesSent + bytesRecv;

  double get blockRate =>
      connections == 0 ? 0 : blocked / connections;
}
