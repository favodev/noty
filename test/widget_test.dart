import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noty/app/noty_app.dart';

void main() {
  testWidgets('Noty shell navigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NotyApp());

    expect(find.text('Historial reciente'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Buscar en historial'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Sincronizacion'), findsOneWidget);
  });
}
