import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

class NativeNotificationsBridge {
  static const MethodChannel _channel = MethodChannel('noty/native_notifications');

  Future<List<NotificationItem>> drainPendingNotifications() async {
    if (!_supportsNativeBridge) {
      return const <NotificationItem>[];
    }

    try {
      final rawItems = await _channel.invokeMethod<List<dynamic>>('drainPendingNotifications');
      final result = <NotificationItem>[];

      for (final raw in rawItems ?? const <dynamic>[]) {
        if (raw is! Map) {
          continue;
        }

        final item = _mapRawToItem(raw.cast<Object?, Object?>());
        if (item != null) {
          result.add(item);
        }
      }

      return result;
    } on MissingPluginException {
      return const <NotificationItem>[];
    } on PlatformException {
      return const <NotificationItem>[];
    }
  }

  Future<bool> isNotificationListenerEnabled() async {
    if (!_supportsNativeBridge) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('isNotificationListenerEnabled') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openNotificationListenerSettings() async {
    if (!_supportsNativeBridge) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('openNotificationListenerSettings');
    } on MissingPluginException {
      // No-op in unsupported targets.
    } on PlatformException {
      // No-op when platform rejects opening settings.
    }
  }

  Future<List<Map<String, String>>> getInstalledApps() async {
    if (!_supportsNativeBridge) {
      return const <Map<String, String>>[];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return const <Map<String, String>>[];
      
      return result.map((dynamic item) {
        final map = item as Map<dynamic, dynamic>;
        return {
          'packageName': map['packageName'].toString(),
          'appName': map['appName'].toString(),
        };
      }).toList();
    } on MissingPluginException {
      return const <Map<String, String>>[];
    } on PlatformException {
      return const <Map<String, String>>[];
    }
  }

  Future<void> updateMonitoredPackages(List<String> packages) async {
    if (!_supportsNativeBridge) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('updateMonitoredPackages', {'packages': packages});
    } on MissingPluginException {
      // No-op in unsupported targets.
    } on PlatformException {
      // No-op.
    }
  }

  Future<List<String>> getMonitoredPackages() async {
    if (!_supportsNativeBridge) {
      return const <String>[];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getMonitoredPackages');
      if (result == null) return const <String>[];
      
      return result.map((dynamic item) => item.toString()).toList();
    } on MissingPluginException {
      return const <String>[];
    } on PlatformException {
      return const <String>[];
    }
  }

  bool get _supportsNativeBridge => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  NotificationItem? _mapRawToItem(Map<Object?, Object?> raw) {
    final title = _asString(raw['title']).trim();
    final body = _asString(raw['body']).trim();

    if (title.isEmpty && body.isEmpty) {
      return null;
    }

    final packageName = _asString(raw['appPackage']);
    final receivedAtEpochMs = _asInt(raw['receivedAtEpochMs']) ?? DateTime.now().millisecondsSinceEpoch;

    return NotificationItem(
      id: _asString(raw['id']).ifEmpty(() => 'native-${DateTime.now().microsecondsSinceEpoch}'),
      appName: _displayNameFromPackage(packageName),
      title: title,
      body: body,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedAtEpochMs),
      isUnread: _asBool(raw['isUnread']) ?? true,
    );
  }

  String _displayNameFromPackage(String packageName) {
    final raw = packageName.trim();
    if (raw.isEmpty) {
      return 'Desconocida';
    }

    final token = raw.split('.').last.replaceAll('_', ' ').trim();
    if (token.isEmpty) {
      return raw;
    }

    return '${token[0].toUpperCase()}${token.substring(1)}';
  }

  String _asString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
    return null;
  }
}

extension _StringFallback on String {
  String ifEmpty(String Function() fallback) {
    if (trim().isEmpty) {
      return fallback();
    }
    return this;
  }
}