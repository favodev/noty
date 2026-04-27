import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noty/app/noty_app.dart';

void main() {
  testWidgets('Noty shell renders and navigates to settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NotyApp(enableLocalPersistence: false));
    await tester.pumpAndSettle();

    expect(find.text('Historial reciente'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Acceso a notificaciones'), findsOneWidget);
  });
}
