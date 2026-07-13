
/// Security / heuristic anomaly alert shown on the Home screen.
class Alert {
  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    this.appId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String type; // 'evil_twin' | 'anomaly' | 'first_connection' | etc.
  final String severity; // 'info' | 'warning' | 'critical'
  final String title; // Always plain language
  final String body;
  final String? appId;
  final String status; // 'unread' | 'read' | 'dismissed'
  final DateTime createdAt;

  bool get isUnread => status == 'unread';

  Alert markRead() => Alert(
        id: id,
        type: type,
        severity: severity,
        title: title,
        body: body,
        appId: appId,
        status: 'read',
        createdAt: createdAt,
      );
}
