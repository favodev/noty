import 'package:flutter_test/flutter_test.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

void main() {
  group('NotificationItem', () {
    test('creates with required fields', () {
      final item = NotificationItem(
        id: 'test-1',
        appPackage: 'com.whatsapp',
        appName: 'WhatsApp',
        title: 'New message',
        body: 'Hello from test',
        receivedAt: DateTime(2024, 1, 1, 12, 0),
        isUnread: true,
      );

      expect(item.id, 'test-1');
      expect(item.appPackage, 'com.whatsapp');
      expect(item.appName, 'WhatsApp');
      expect(item.title, 'New message');
      expect(item.body, 'Hello from test');
      expect(item.isUnread, true);
    });

    group('matchesQuery', () {
      test('returns true for empty query', () {
        final item = _createItem(appName: 'WhatsApp', title: 'Hello');
        expect(item.matchesQuery(''), true);
        expect(item.matchesQuery('   '), true);
      });

      test('matches appName case insensitive', () {
        final item = _createItem(appName: 'WhatsApp');
        expect(item.matchesQuery('whatsapp'), true);
        expect(item.matchesQuery('WHATSAPP'), true);
        expect(item.matchesQuery(' telegram'), false);
      });

      test('matches title case insensitive', () {
        final item = _createItem(title: 'New Message');
        expect(item.matchesQuery('new message'), true);
        expect(item.matchesQuery('NEW'), true);
        expect(item.matchesQuery('old'), false);
      });

      test('matches body case insensitive', () {
        final item = _createItem(body: 'Hello world');
        expect(item.matchesQuery('hello'), true);
        expect(item.matchesQuery('WORLD'), true);
        expect(item.matchesQuery('foo'), false);
      });
    });

    test('serializes to and from JSON', () {
      final item = _createItem();
      final restored = NotificationItem.fromJson(item.toJson());

      expect(restored.id, item.id);
      expect(restored.appPackage, item.appPackage);
      expect(restored.appName, item.appName);
      expect(restored.title, item.title);
      expect(restored.body, item.body);
      expect(restored.receivedAt, item.receivedAt);
      expect(restored.isUnread, item.isUnread);
    });
  });
}

NotificationItem _createItem({
  String id = 'test',
  String appPackage = 'dev.test.app',
  String appName = 'TestApp',
  String title = 'Test Title',
  String body = 'Test body',
  bool isUnread = false,
}) {
  return NotificationItem(
    id: id,
    appPackage: appPackage,
    appName: appName,
    title: title,
    body: body,
    receivedAt: DateTime(2024, 1, 1),
    isUnread: isUnread,
  );
}
