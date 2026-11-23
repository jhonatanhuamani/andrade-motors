import 'dart:convert';
import 'dart:io';

import 'package:andrade_motors/auth/admin_session.dart';
import 'package:andrade_motors/auth/session_scope.dart';
import 'package:andrade_motors/data/delivery_comprobante_pdf.dart';
import 'package:andrade_motors/data/delivery_state.dart';
import 'package:andrade_motors/models/delivery_pedido.dart';
import 'package:andrade_motors/screens/delivery_comprobante_screen.dart';
import 'package:andrade_motors/screens/delivery_pedidos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import 'support/fake_admin_auth.dart';

const _cliente = 'cliente@example.test';
const _items = [
  DeliveryItem(
    sku: 'QA-1',
    nombre: 'Filtro de aceite',
    cantidad: 2,
    precioUnitario: 45.5,
  ),
  DeliveryItem(
    sku: 'QA-2',
    nombre: 'Bujía de encendido',
    cantidad: 1,
    precioUnitario: 19,
  ),
];
final _fecha = DateTime(2026, 11, 23, 14, 35);
final _ubicacion = DeliveryUbicacion(
  latitud: -12.0651,
  longitud: -75.2049,
  actualizada: _fecha,
  origen: DeliveryOrigen.manual,
);
const _direccion = 'Avenida de Prueba 123';
const _referencia = 'Portón negro';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Genera un PDF con logo y totales del pedido', () async {
    final pedido = DeliveryPedido(
      id: 'DEL-001',
      clienteId: 'cuenta-prueba',
      cliente: _cliente,
      items: _items,
      costoDelivery: 8,
      ubicacion: _ubicacion,
      direccion: _direccion,
      referencia: _referencia,
      distanciaKm: 4.25,
      createdAt: _fecha,
      estado: DeliveryEstado.enCamino,
    );
    final bytes = await generarComprobanteDelivery(pedido);
    final pdf = latin1.decode(bytes);
    expect(pdf, startsWith('%PDF-'));
    expect(pdf, contains('/Image'));
    expect(pdf.trimRight(), endsWith('%%EOF'));
    expect(pedido.subtotal, 110);
    expect(pedido.total, 118);
    expect(
      nombreComprobanteDelivery(pedido.id),
      'Andrade_Motors_Pedido_DEL-001.pdf',
    );
    expect(
      await generarComprobanteDelivery(
        pedido.conEstado(DeliveryEstado.entregado),
      ),
      isNot(bytes),
    );

    if (const bool.fromEnvironment('GENERAR_COMPROBANTE_PRUEBA')) {
      final carpeta = Directory('build/qa_comprobantes')
        ..createSync(recursive: true);
      File('${carpeta.path}/${nombreComprobanteDelivery(pedido.id)}')
          .writeAsBytesSync(bytes);
    }
  });

  for (final administrar in [false, true]) {
    testWidgets('Abre y comparte el comprobante (administrar: $administrar)', (
      tester,
    ) async {
      final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(administrar));
      final sesion = AdminSession(auth);
      final store = DeliveryState();
      final pedido = store.confirmar(
        clienteId: administrar ? 'otro-cliente' : 'cuenta-prueba',
        cliente: _cliente,
        items: _items,
        costoDelivery: 8,
        ubicacion: _ubicacion,
        direccion: _direccion,
        referencia: _referencia,
        distanciaKm: 4.25,
      );
      const canal = MethodChannel('net.nfet.printing');
      MethodCall? exportacion;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(canal, (call) async {
        switch (call.method) {
          case 'printingInfo':
            return {'canRaster': false, 'canPrint': true, 'canShare': true};
          case 'sharePdf':
            exportacion = call;
            return 1;
        }
        throw StateError(call.method);
      });
      try {
        await tester.pumpWidget(
          SessionScope(
            session: sesion,
            child: DeliveryScope(
              delivery: store,
              child: MaterialApp(
                home: Scaffold(
                  body: DeliveryPedidosScreen(administrar: administrar),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver comprobante'));
        await tester.pump();
        await tester.runAsync(() async {
          await rootBundle.load('assets/images/logo/logo_andrade_motors.png');
        });
        await tester.pumpAndSettle();
        expect(find.byType(DeliveryComprobanteScreen), findsOneWidget);
        expect(find.byType(PdfPreview), findsOneWidget);
        await tester.tap(find.byTooltip('Compartir comprobante'));
        await tester.pumpAndSettle();
        expect(
          exportacion?.arguments['name'],
          nombreComprobanteDelivery(pedido.id),
        );
        expect(
          latin1.decode(exportacion!.arguments['doc'] as Uint8List),
          startsWith('%PDF-'),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        messenger.setMockMethodCallHandler(canal, null);
        sesion.dispose();
        store.dispose();
        await auth.dispose();
      }
    });
  }
}
