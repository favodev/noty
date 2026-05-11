import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noty/app/noty_app.dart';

void main() {
  testWidgets('Noty shell renders and navigates to local settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NotyApp(enableLocalPersistence: false));
    await tester.pumpAndSettle();

    expect(find.text('Historial reciente'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
    expect(find.text('Exportar e importar'), findsOneWidget);
    expect(find.text('Acceso a notificaciones'), findsNothing);
    expect(find.textContaining('Supabase'), findsNothing);
  });
}
