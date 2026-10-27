import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> abrirModuloAdmin(WidgetTester tester, int indice) async {
  await tester.tap(find.byType(DrawerButton));
  await tester.pumpAndSettle();
  final modulo = find.byKey(ValueKey('admin-modulo-$indice'));
  await tester.ensureVisible(modulo);
  await tester.pumpAndSettle();
  expect(modulo.hitTestable(), findsOneWidget);
  await tester.tap(modulo);
  await tester.pumpAndSettle();
}
