import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsSyncResult {
  const NotificationsSyncResult({
    required this.syncedIds,
    required this.failed,
  });

  final List<String> syncedIds;
  final List<NotificationSyncFailure> failed;
}

class NotificationSyncFailure {
  const NotificationSyncFailure({
    required this.notificationId,
    required this.message,
  });

  final String notificationId;
  final String message;
}

class SupabaseNotificationsSync {
  Future<NotificationsSyncResult> sync(List<NotificationItem> items) async {
    if (items.isEmpty) {
      return const NotificationsSyncResult(
        syncedIds: <String>[],
        failed: <NotificationSyncFailure>[],
      );
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return NotificationsSyncResult(
        syncedIds: const <String>[],
        failed: items
            .map(
              (item) => NotificationSyncFailure(
                notificationId: item.id,
                message: 'no authenticated user',
              ),
            )
            .toList(growable: false),
      );
    }

    try {
      final rows = items
          .map((item) => _toSupabaseRow(item, userId))
          .toList(growable: false);

      await Supabase.instance.client
          .from('notifications')
          .upsert(rows, onConflict: 'id');

      return NotificationsSyncResult(
        syncedIds: items.map((item) => item.id).toList(growable: false),
        failed: const <NotificationSyncFailure>[],
      );
    } catch (error) {
      final message = _normalizeError(error);

      return NotificationsSyncResult(
        syncedIds: const <String>[],
        failed: items
            .map(
              (item) => NotificationSyncFailure(
                notificationId: item.id,
                message: message,
              ),
            )
            .toList(growable: false),
      );
    }
  }

  Map<String, Object?> _toSupabaseRow(NotificationItem item, String userId) {
    return <String, Object?>{
      'id': item.id,
      'app_name': item.appName,
      'title': item.title,
      'body': item.body,
      'received_at': item.receivedAt.toUtc().toIso8601String(),
      'is_unread': item.isUnread,
      'user_id': userId,
    };
  }

  String _normalizeError(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return 'sync failed';
    }
    if (raw.length > 220) {
      return '${raw.substring(0, 220)}...';
    }
    return raw;
  }
}