class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.appName,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.isUnread,
    this.syncState = NotificationSyncState.pending,
    this.syncAttempts = 0,
    this.syncError,
  });

  final String id;
  final String appName;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isUnread;
  final String syncState;
  final int syncAttempts;
  final String? syncError;

  bool get needsSync =>
      syncState == NotificationSyncState.pending || syncState == NotificationSyncState.error;

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return appName.toLowerCase().contains(normalized) ||
        title.toLowerCase().contains(normalized) ||
        body.toLowerCase().contains(normalized);
  }
}

class NotificationSyncState {
  const NotificationSyncState._();

  static const String pending = 'pending';
  static const String synced = 'synced';
  static const String error = 'error';
}