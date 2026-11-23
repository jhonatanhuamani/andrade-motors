import 'dart:async';

import 'package:andrade_motors/auth/admin_session.dart';
import 'package:andrade_motors/auth/session_scope.dart';
import 'package:andrade_motors/data/delivery_fcm.dart';
import 'package:andrade_motors/data/delivery_state.dart';
import 'package:andrade_motors/models/delivery_aviso.dart';
import 'package:andrade_motors/models/delivery_pedido.dart';
import 'package:andrade_motors/screens/delivery_pedidos_screen.dart';
import 'package:andrade_motors/screens/delivery_seguimiento_screen.dart';
import 'package:andrade_motors/widgets/delivery_push_host.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_admin_auth.dart';

DeliveryPedido _pedido(DeliveryState estado, {String? clienteId}) =>
    estado.confirmar(
      clienteId: clienteId,
      cliente: 'Cliente de prueba',
      items: const [
        DeliveryItem(
          sku: 'QA',
          nombre: 'Producto',
          cantidad: 1,
          precioUnitario: 25,
        ),
      ],
      costoDelivery: 5,
      ubicacion: DeliveryUbicacion(
        latitud: -12,
        longitud: -75,
        actualizada: DateTime(2026),
        origen: DeliveryOrigen.manual,
      ),
      direccion: 'Dirección de prueba',
      referencia: '',
      distanciaKm: 1,
    );

RemoteMessage _mensaje(String pedidoId, {String clienteId = 'cuenta-prueba'}) =>
    RemoteMessage(
      messageId: 'mensaje-$pedidoId',
      data: {
        'tipo': DeliveryAviso.tipo,
        'pedidoId': pedidoId,
        'clienteId': clienteId,
        'estado': DeliveryEstado.preparando.codigo,
      },
    );

class _Canal implements DeliveryCanalPush {
  final mensajes = StreamController<RemoteMessage>.broadcast();
  final aperturas = StreamController<RemoteMessage>.broadcast();
  final tokens = StreamController<String>.broadcast();
  final solicitudes = <bool>[];
  String? token = 'token-de-prueba';
  RemoteMessage? inicial;
  int borrados = 0;

  @override
  Stream<RemoteMessage> get enPrimerPlano => mensajes.stream;

  @override
  Stream<RemoteMessage> get alAbrir => aperturas.stream;

  @override
  Stream<String> get tokensRenovados => tokens.stream;

  @override
  Future<RemoteMessage?> mensajeInicial() async => inicial;

  @override
  Future<String?> obtenerToken({required bool pedirPermiso}) async {
    solicitudes.add(pedirPermiso);
    return token;
  }

  @override
  Future<void> borrarToken() async => borrados++;

  Future<void> cerrar() async {
    await Future.wait([mensajes.close(), aperturas.close(), tokens.close()]);
  }
}

void main() {
  test(
    'Emite un aviso solo por cada transición notificable de un cliente',
    () async {
      final estado = DeliveryState();
      addTearDown(estado.dispose);
      final avisos = <DeliveryAviso>[];
      final sub = estado.avisos.listen(avisos.add);
      addTearDown(sub.cancel);
      final cliente = _pedido(estado, clienteId: 'cuenta-prueba');
      final visitante = _pedido(estado);

      estado.cambiarEstado(visitante.id, DeliveryEstado.preparando);
      for (final nuevo in DeliveryEstado.values) {
        estado.cambiarEstado(cliente.id, nuevo);
        estado.cambiarEstado(cliente.id, nuevo);
      }
      estado.cambiarEstado(cliente.id, DeliveryEstado.pendiente);
      await Future<void>.delayed(Duration.zero);

      expect(avisos.map((a) => a.estado), DeliveryEstado.values.skip(1));
      expect(
        avisos.every(
          (a) => a.pedidoId == cliente.id && a.clienteId == 'cuenta-prueba',
        ),
        isTrue,
      );
      expect(avisos.map((a) => a.mensaje), [
        'Tu pedido está siendo preparado.',
        'Tu pedido ya tiene repartidor asignado.',
        'Tu pedido está en camino.',
        'Tu pedido está cerca de tu ubicación.',
        'Tu pedido fue entregado.',
      ]);
      expect(
        DeliveryAviso.desdeDatos(avisos.first.datos)?.estado,
        DeliveryEstado.preparando,
      );
      expect(estado.buscar(cliente.id)?.estado, DeliveryEstado.pendiente);
    },
  );

  Future<void> montar(
    WidgetTester tester,
    AdminSession sesion,
    DeliveryState delivery,
    _Canal canal,
    List<RegistroDeliveryFcm?> registros,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final mensajero = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      SessionScope(
        session: sesion,
        child: DeliveryScope(
          delivery: delivery,
          child: MaterialApp(
            navigatorKey: navigator,
            scaffoldMessengerKey: mensajero,
            builder: (_, child) => DeliveryPushHost(
              sesion: sesion,
              delivery: delivery,
              canal: canal,
              navigator: navigator,
              mensajero: mensajero,
              alCambiarRegistro: registros.add,
              child: child!,
            ),
            home: const Scaffold(body: Text('Pantalla cliente')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Asocia el token al iniciar, filtra avisos y abre el pedido desde el banner',
    (tester) async {
      final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
      final sesion = AdminSession(auth);
      final delivery = DeliveryState();
      final canal = _Canal();
      final registros = <RegistroDeliveryFcm?>[];
      addTearDown(auth.dispose);
      addTearDown(canal.cerrar);
      try {
        final pedido = _pedido(delivery, clienteId: 'cuenta-prueba');
        await montar(tester, sesion, delivery, canal, registros);
        expect(canal.solicitudes, [true]);
        expect(registros.single, (
          clienteId: 'cuenta-prueba',
          token: 'token-de-prueba',
        ));
        canal.tokens.add('token-renovado');
        await tester.pump();
        expect(registros.last?.token, 'token-renovado');

        canal.mensajes.add(_mensaje(pedido.id, clienteId: 'otra-cuenta'));
        await tester.pumpAndSettle();
        expect(find.text('Ver pedido'), findsNothing);
        canal.mensajes.add(_mensaje(pedido.id));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Tu pedido está siendo preparado.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Ver pedido'));
        await tester.pumpAndSettle();
        expect(find.byType(DeliverySeguimientoScreen), findsOneWidget);

        await sesion.cerrarSesion();
        await tester.pumpAndSettle();
        expect(registros.last, isNull);
        expect(canal.borrados, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        sesion.dispose();
        delivery.dispose();
      }
    },
  );

  testWidgets(
    'Espera el inicio de sesión y abre Mis pedidos si el pedido no está en memoria',
    (tester) async {
      final auth = FakeAdminAuth(adminAlEntrar: false);
      final sesion = AdminSession(auth);
      final delivery = DeliveryState();
      final canal = _Canal()
        ..inicial = _mensaje('DEL-100')
        ..token = null;
      final registros = <RegistroDeliveryFcm?>[];
      addTearDown(auth.dispose);
      addTearDown(canal.cerrar);
      try {
        await montar(tester, sesion, delivery, canal, registros);
        expect(canal.solicitudes, isEmpty);
        expect(find.byType(DeliveryPedidosScreen), findsNothing);

        await sesion.iniciarSesion('cuenta@example.test', 'prueba');
        await tester.pumpAndSettle();
        expect(canal.solicitudes, [true]);
        expect(registros, isEmpty);
        expect(find.byType(DeliveryPedidosScreen), findsOneWidget);

        Navigator.of(tester.element(find.byType(DeliveryPedidosScreen))).pop();
        await tester.pumpAndSettle();
        final pedido = _pedido(delivery, clienteId: 'cuenta-prueba');
        canal.aperturas.add(_mensaje(pedido.id));
        await tester.pumpAndSettle();
        expect(find.byType(DeliverySeguimientoScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        sesion.dispose();
        delivery.dispose();
      }
    },
  );
}
