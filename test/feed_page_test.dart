import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:noty/features/feed/presentation/feed_page.dart';

void main() {
  testWidgets(
    'shows app icon in filter chip even when first app row has no package',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          FeedPage(
            notifications: <NotificationItem>[
              _item(id: 'old', appPackage: '', appName: 'WhatsApp'),
              _item(id: 'new', appPackage: 'com.whatsapp', appName: 'WhatsApp'),
            ],
            appIcons: <String, Uint8List>{
              'com.whatsapp': Uint8List.fromList(_transparentPng),
            },
            isLoading: false,
            isNotificationListenerEnabled: true,
            onOpenNotificationSettings: () {},
            onRefreshRequested: () async {},
            onDeleteNotification: (_) async {},
            onMarkAsRead: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(ChoiceChip, 'WhatsApp'),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('delete and mark-as-read actions call their callbacks', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final calls = <String>[];

    await tester.pumpWidget(
      _wrap(
        FeedPage(
          notifications: <NotificationItem>[_item(id: 'n1', isUnread: true)],
          appIcons: const <String, Uint8List>{},
          isLoading: false,
          isNotificationListenerEnabled: true,
          onOpenNotificationSettings: () {},
          onRefreshRequested: () async {},
          onDeleteNotification: (id) async => calls.add('delete:$id'),
          onMarkAsRead: (id) async => calls.add('read:$id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.mark_email_read_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(calls, <String>['read:n1', 'delete:n1']);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

NotificationItem _item({
  required String id,
  String appPackage = 'dev.test.app',
  String appName = 'Test App',
  bool isUnread = false,
}) {
  return NotificationItem(
    id: id,
    appPackage: appPackage,
    appName: appName,
    title: 'Title',
    body: 'Body',
    receivedAt: DateTime(2026, 1, 1, 12),
    isUnread: isUnread,
  );
}

const List<int> _transparentPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
