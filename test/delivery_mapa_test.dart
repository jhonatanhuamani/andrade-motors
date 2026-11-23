import 'package:andrade_motors/auth/admin_session.dart';
import 'package:andrade_motors/auth/session_scope.dart';
import 'package:andrade_motors/data/delivery_state.dart';
import 'package:andrade_motors/models/delivery_pedido.dart';
import 'package:andrade_motors/screens/delivery_mapa_pedido_screen.dart';
import 'package:andrade_motors/screens/delivery_seguimiento_screen.dart';
import 'package:andrade_motors/screens/delivery_ubicacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'support/fake_admin_auth.dart';

const _item = DeliveryItem(
  sku: 'QA',
  nombre: 'Producto de prueba',
  cantidad: 1,
  precioUnitario: 25,
);

void main() {
  testWidgets(
    'El GPS mueve el marcador y cotiza sin reemplazar la selección manual',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const servicio = MethodChannel('flutter.baseflow.com/geolocator');
      const actualizaciones = MethodChannel(
        'flutter.baseflow.com/geolocator_updates',
      );
      final messenger = tester.binding.defaultBinaryMessenger;
      final eventos = <String>[];
      messenger.setMockMethodCallHandler(
        servicio,
        (call) async => switch (call.method) {
          'isLocationServiceEnabled' => true,
          'checkPermission' => LocationPermission.whileInUse.index,
          _ => throw StateError(call.method),
        },
      );
      messenger.setMockMethodCallHandler(actualizaciones, (call) async {
        eventos.add(call.method);
        if (call.method == 'listen') {
          expect(call.arguments['distanceFilter'], 5);
          expect(call.arguments['accuracy'], LocationAccuracy.high.index);
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(servicio, null);
        messenger.setMockMethodCallHandler(actualizaciones, null);
      });

      await tester.pumpWidget(
        const MaterialApp(home: DeliveryUbicacionScreen(items: [_item])),
      );
      await tester.pump();
      expect(eventos, isEmpty);
      final mapa = find.byType(FlutterMap);
      final botones = find.byTooltip('Acercar mapa');
      expect(mapa, findsOneWidget);
      expect(botones, findsOneWidget);
      final controlador = tester.widget<FlutterMap>(mapa).mapController!;

      Future<void> pulsar(String texto) async {
        final control = find.text(texto);
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        await tester.tap(control);
        await tester.pump();
      }

      Future<void> enviar(double latitud) async {
        await messenger.handlePlatformMessage(
          actualizaciones.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'latitude': latitud,
            'longitude': -75.2049,
            'accuracy': 4.0,
            'timestamp': DateTime(2026).millisecondsSinceEpoch,
          }),
          null,
        );
        await tester.pump();
        await tester.pump();
      }

      await pulsar('Usar mi ubicación actual');
      expect(eventos, ['listen']);
      await enviar(-12.058);
      expect(find.text('ORIGEN: GPS'), findsOneWidget);
      expect(find.text('Costo estimado de delivery: S/ 5.00'), findsWidgets);
      expect(controlador.camera.center.latitude, closeTo(-12.058, .00001));
      await messenger.handlePlatformMessage(
        actualizaciones.name,
        const StandardMethodCodec().encodeErrorEnvelope(
          code: 'LOCATION_UPDATE_FAILURE',
        ),
        null,
      );
      await tester.pump();
      expect(find.textContaining('perdió señal temporalmente'), findsOneWidget);
      expect(find.text('Latitud: -12.058000'), findsOneWidget);
      expect(eventos, ['listen']);
      await enviar(-12.027);
      expect(find.textContaining('perdió señal temporalmente'), findsNothing);
      expect(find.text('Latitud: -12.027000'), findsOneWidget);
      expect(find.text('Costo estimado de delivery: S/ 8.00'), findsWidgets);

      tester.widget<FlutterMap>(mapa).options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(-11.99, -75.2049),
      );
      await tester.pump();
      await enviar(-12.057);
      expect(find.text('Ubicación seleccionada manualmente'), findsOneWidget);
      expect(find.text('Latitud: -11.990000'), findsOneWidget);
      expect(find.text('Costo estimado de delivery: S/ 12.00'), findsWidgets);
      expect(controlador.camera.center.latitude, closeTo(-11.99, .00001));
      await pulsar('Usar nuevamente mi ubicación GPS');
      expect(find.text('Latitud: -12.057000'), findsOneWidget);

      await pulsar('Modo simulación');
      final latitud = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Latitud',
      );
      await tester.ensureVisible(latitud);
      await tester.enterText(latitud, '-11.95');
      await pulsar('Aplicar ubicación simulada');
      expect(find.text('ORIGEN: SIMULACIÓN'), findsOneWidget);
      expect(
        find.text('Costo estimado de delivery: Consultar disponibilidad'),
        findsWidgets,
      );
      expect(controlador.camera.center.latitude, closeTo(-11.95, .00001));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(eventos, ['listen', 'cancel']);
    },
  );

  testWidgets(
    'Ver ubicación presenta el punto guardado y el mapa administrativo es de solo lectura',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(true));
      final sesion = AdminSession(auth);
      final delivery = DeliveryState();
      addTearDown(auth.dispose);
      try {
        final pedido = delivery.confirmar(
          clienteId: 'cliente-prueba',
          cliente: 'Cliente de prueba',
          items: [_item],
          costoDelivery: 5,
          ubicacion: DeliveryUbicacion(
            latitud: -12.058,
            longitud: -75.2049,
            actualizada: DateTime(2026),
            origen: DeliveryOrigen.manual,
          ),
          direccion: 'Dirección de prueba',
          referencia: 'Referencia de prueba',
          distanciaKm: .79,
        );
        await tester.pumpWidget(
          SessionScope(
            session: sesion,
            child: DeliveryScope(
              delivery: delivery,
              child: MaterialApp(
                home: DeliverySeguimientoScreen(
                  pedidoId: pedido.id,
                  administrar: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver ubicación'));
        await tester.pumpAndSettle();
        expect(find.byType(DeliveryMapaPedidoScreen), findsOneWidget);
        final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
        expect(mapa.options.onTap, isNull);
        final markers = mapa.children.whereType<MarkerLayer>().single.markers;
        expect(markers, hasLength(2));
        expect(markers[1].point, const LatLng(-12.058, -75.2049));
        expect(find.text('Dirección: Dirección de prueba'), findsOneWidget);
        expect(find.text('Referencia: Referencia de prueba'), findsOneWidget);
        expect(find.text('Distancia aproximada: 0.79 km'), findsOneWidget);
        await tester.tap(find.byTooltip('Centrar en el cliente'));
        await tester.pump();
        expect(
          mapa.mapController!.camera.center.latitude,
          closeTo(-12.058, .00001),
        );
        expect(delivery.buscar(pedido.id)!.ubicacion, same(pedido.ubicacion));
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        sesion.dispose();
        delivery.dispose();
      }
    },
  );
}
