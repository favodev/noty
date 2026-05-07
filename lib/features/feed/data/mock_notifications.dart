import 'package:noty/features/feed/domain/notification_item.dart';

List<NotificationItem> buildMockNotifications() {
  final now = DateTime.now();

  return <NotificationItem>[
    NotificationItem(
      id: 'n-001',
      appName: 'WhatsApp',
      title: 'Mensaje eliminado',
      body: 'Este mensaje fue eliminado',
      receivedAt: now.subtract(const Duration(minutes: 6)),
      isUnread: true,
    ),
    NotificationItem(
      id: 'n-002',
      appName: 'Gmail',
      title: 'Build failed en CI',
      body: 'Pipeline main-android falló en step test',
      receivedAt: now.subtract(const Duration(minutes: 21)),
      isUnread: true,
    ),
    NotificationItem(
      id: 'n-003',
      appName: 'Instagram',
      title: 'Nuevo mensaje',
      body: 'sofia.v te envio un mensaje',
      receivedAt: now.subtract(const Duration(hours: 2, minutes: 10)),
      isUnread: false,
    ),
    NotificationItem(
      id: 'n-004',
      appName: 'Slack',
      title: 'Reminder',
      body: 'Daily standup en 10 minutos',
      receivedAt: now.subtract(const Duration(hours: 3, minutes: 48)),
      isUnread: false,
    ),
    NotificationItem(
      id: 'n-005',
      appName: 'Banco',
      title: 'Consumo detectado',
      body: 'Compra en tienda online por ARS 12.000',
      receivedAt: now.subtract(const Duration(hours: 7, minutes: 12)),
      isUnread: true,
    ),
    NotificationItem(
      id: 'n-006',
      appName: 'Google Calendar',
      title: 'Evento proximamente',
      body: 'Review de arquitectura en 30 minutos',
      receivedAt: now.subtract(const Duration(days: 1, hours: 1)),
      isUnread: false,
    ),
  ];
}