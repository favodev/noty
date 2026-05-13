import 'package:noty/features/feed/data/local_notifications_repository.dart';
import 'package:noty/features/feed/data/mock_notifications.dart';
import 'package:noty/features/feed/data/native_notifications_bridge.dart';
import 'package:noty/features/feed/data/notification_archive_service.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

class NotyShellLoadResult {
  const NotyShellLoadResult({
    required this.notifications,
    required this.listenerEnabled,
    this.errorMessage,
  });

  final List<NotificationItem> notifications;
  final bool listenerEnabled;
  final String? errorMessage;
}

class NotyShellService {
  NotyShellService({
    LocalNotificationsRepository? repository,
    NativeNotificationsBridge? nativeBridge,
    NotificationArchiveService? archiveService,
  })  : _repository = repository ?? LocalNotificationsRepository(),
        _nativeBridge = nativeBridge ?? NativeNotificationsBridge(),
        _archiveService = archiveService ?? NotificationArchiveService();

  final LocalNotificationsRepository _repository;
  final NativeNotificationsBridge _nativeBridge;
  final NotificationArchiveService _archiveService;

  Future<void> dispose() => _repository.dispose();

  Future<NotyShellLoadResult> loadNotifications({
    required bool enableLocalPersistence,
  }) async {
    if (!enableLocalPersistence) {
      return NotyShellLoadResult(
        notifications: buildMockNotifications(),
        listenerEnabled: false,
      );
    }

    try {
      await _repository.initialize();

      final listenerEnabled = await _nativeBridge.isNotificationListenerEnabled();
      final nativeNotifications = await _nativeBridge.drainPendingNotifications();

      for (final item in nativeNotifications) {
        await _repository.upsert(item);
      }

      final notifications = await _repository.getAll();

      return NotyShellLoadResult(
        notifications: notifications,
        listenerEnabled: listenerEnabled,
      );
    } catch (_) {
      return const NotyShellLoadResult(
        notifications: <NotificationItem>[],
        listenerEnabled: false,
        errorMessage: 'No pudimos cargar notificaciones locales.',
      );
    }
  }

  Future<void> openNotificationListenerSettings() async {
    await _nativeBridge.openNotificationListenerSettings();
  }

  Future<List<Map<String, String>>> getInstalledApps() async {
    return _nativeBridge.getInstalledApps();
  }

  Future<List<String>> getMonitoredPackages() async {
    return _nativeBridge.getMonitoredPackages();
  }

  Future<void> updateMonitoredPackages(List<String> packages) async {
    await _nativeBridge.updateMonitoredPackages(packages);
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteItem(id);
  }

  Future<void> markNotificationAsRead(String id) async {
    await _repository.markAsRead(id);
  }

  Future<void> clearLocalHistory() async {
    await _repository.deleteAll();
  }

  Future<String> exportHistory() async {
    final notifications = await _repository.getAll();
    return _archiveService.exportAndShare(notifications);
  }

  Future<int?> importHistory() async {
    final result = await _archiveService.pickAndImport();
    if (result == null) {
      return null;
    }

    await _repository.importMany(result.items);
    return result.count;
  }
}
