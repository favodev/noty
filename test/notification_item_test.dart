import 'package:flutter_test/flutter_test.dart';
import 'package:noty/features/feed/domain/notification_item.dart';

void main() {
  group('NotificationItem', () {
    test('creates with required fields', () {
      final item = NotificationItem(
        id: 'test-1',
        appName: 'WhatsApp',
        title: 'New message',
        body: 'Hello from test',
        receivedAt: DateTime(2024, 1, 1, 12, 0),
        isUnread: true,
      );

      expect(item.id, 'test-1');
      expect(item.appName, 'WhatsApp');
      expect(item.title, 'New message');
      expect(item.body, 'Hello from test');
      expect(item.isUnread, true);
      expect(item.syncState, NotificationSyncState.pending);
    });

    test('needsSync returns true when pending', () {
      final item = _createItem(syncState: NotificationSyncState.pending);
      expect(item.needsSync, true);
    });

    test('needsSync returns true when error', () {
      final item = _createItem(syncState: NotificationSyncState.error);
      expect(item.needsSync, true);
    });

    test('needsSync returns false when synced', () {
      final item = _createItem(syncState: NotificationSyncState.synced);
      expect(item.needsSync, false);
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
  });

  group('NotificationSyncState', () {
    test('has correct values', () {
      expect(NotificationSyncState.pending, 'pending');
      expect(NotificationSyncState.synced, 'synced');
      expect(NotificationSyncState.error, 'error');
    });
  });
}

NotificationItem _createItem({
  String id = 'test',
  String appName = 'TestApp',
  String title = 'Test Title',
  String body = 'Test body',
  bool isUnread = false,
  String syncState = NotificationSyncState.pending,
}) {
  return NotificationItem(
    id: id,
    appName: appName,
    title: title,
    body: body,
    receivedAt: DateTime(2024, 1, 1),
    isUnread: isUnread,
    syncState: syncState,
  );
}