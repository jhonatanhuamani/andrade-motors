import 'package:andrade_motors/screens/presentacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La marca aparece antes de mostrar la pantalla inicial', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const contenido = Key('contenido-inicial');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PresentacionScreen(child: child!),
        home: const Scaffold(key: contenido),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('ANDRADE MOTORS'), findsOneWidget);
    expect(find.text('PASI\u00D3N EN MOVIMIENTO'), findsOneWidget);
    expect(find.byKey(contenido), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 1051));
    expect(find.text('ANDRADE MOTORS'), findsNothing);
    expect(find.byKey(contenido), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
