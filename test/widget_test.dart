import 'dart:async';

import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:andrade_motors/screens/home_screen.dart';
import 'package:andrade_motors/screens/catalogo_screen.dart';
import 'package:andrade_motors/screens/inventario_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:andrade_motors/main.dart';
import 'package:andrade_motors/screens/reserva_screen.dart';
import 'package:andrade_motors/screens/servicios_screen.dart';
import 'package:andrade_motors/widgets/servicio_card.dart';

import 'support/fake_admin_auth.dart';

import 'package:andrade_motors/auth/auth_router.dart';

void main() {
  late FakeAdminAuth auth;
  setUp(() {
    auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
  });
  tearDown(() async {
    await auth.dispose();
  });

  testWidgets(
    'Una carga as?ncrona comparte productos y conserva carrito por SKU',
    (tester) async {
      final carga = Completer<Map<String, Map<String, dynamic>>>();
      var consultas = 0;
      await tester.pumpWidget(
        AndradeMotorsApp(
          adminAuthService: auth,
          productosRepository: ProductosRepository(
            cargar: () {
              consultas++;
              return carga.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final antes = tester.widget<HomeScreen>(find.byType(HomeScreen));
      antes.onAgregar(antes.productos.first);
      final documentos = {
        for (final p in demo.productos.reversed)
          p.sku: ProductosRepository.haciaDocumento(p),
      };
      // Cambiar un campo solo en la prueba fuerza una instancia distinta.
      documentos[demo.productos.first.sku]!['descripcion'] = 'Prueba remota';
      carga.complete(documentos);
      await tester.pumpAndSettle();
      final inicio = tester.widget<HomeScreen>(find.byType(HomeScreen));
      final catalogo = tester.widget<CatalogoScreen>(
        find.byType(CatalogoScreen, skipOffstage: false),
      );
      final compartido = tester
          .widget<AuthRouter>(find.byType(AuthRouter))
          .catalogo;
      expect(consultas, 2);
      expect(identical(inicio.productos, catalogo.productos), isTrue);
      expect(identical(inicio.productos, compartido.productos), isTrue);
      expect(find.byType(InventarioScreen, skipOffstage: false), findsNothing);
      expect(
        inicio.productos.map((p) => p.sku),
        demo.productos.map((p) => p.sku),
      );
      expect(inicio.productos.first.descripcion, 'Prueba remota');
      inicio.onAgregar(inicio.productos.first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ver carrito'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quitar del carrito'), findsOneWidget);
      expect(find.textContaining('2 uds.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('La carga puede terminar despu?s de desmontar MotorShell', (
    tester,
  ) async {
    final carga = Completer<Map<String, Map<String, dynamic>>>();
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(cargar: () => carga.future),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    carga.complete({});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile navigation, search and detail work', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cargar: () async => {
            for (final p in demo.productos)
              p.sku: ProductosRepository.haciaDocumento(p),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ANDRADE MOTORS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'HJC');
    await tester.pumpAndSettle();
    expect(find.text('1 productos'), findsOneWidget);
    await tester.ensureVisible(find.text('Casco HJC RPHA 11').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casco HJC RPHA 11').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byIcon(Icons.add_circle_outline), 300);
    await tester.ensureVisible(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_circle_outline).hitTestable(), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Agregar al carrito'), 200);
    await tester.ensureVisible(find.text('Agregar al carrito'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar al carrito').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Agregar al carrito'));
    await tester.pumpAndSettle();
    expect(find.textContaining('agregado al carrito local'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('All tabs fit a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cargar: () async => {
            for (final p in demo.productos)
              p.sku: ProductosRepository.haciaDocumento(p),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final icon in [
      Icons.grid_view_outlined,
      Icons.build_outlined,
      Icons.calendar_month_outlined,
      Icons.person_outline,
    ]) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Service selection opens the reservation form', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cargar: () async => {
            for (final p in demo.productos)
              p.sku: ProductosRepository.haciaDocumento(p),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.build_outlined).last);
    await tester.pumpAndSettle();
    final servicioCard = find.byWidgetPredicate(
      (widget) =>
          widget is ServicioCard &&
          widget.servicio.nombre == 'Cambio de aceite',
    );
    expect(servicioCard, findsOneWidget);
    final reservar = find.descendant(
      of: servicioCard,
      matching: find.widgetWithText(FilledButton, 'Reservar'),
    );
    expect(reservar, findsOneWidget);
    final serviciosScrollable = find.descendant(
      of: find.byType(ServiciosScreen),
      matching: find.byType(Scrollable),
    );
    expect(serviciosScrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      reservar,
      250,
      scrollable: serviciosScrollable,
    );
    await tester.ensureVisible(reservar);
    await tester.pumpAndSettle();
    expect(reservar.hitTestable(), findsOneWidget);
    await tester.tap(reservar);
    await tester.pumpAndSettle();
    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, 'Cambio de aceite');
    final confirmarReserva = find.descendant(
      of: find.byType(ReservaScreen),
      matching: find.widgetWithText(FilledButton, 'Confirmar reserva'),
    );
    expect(confirmarReserva, findsOneWidget);
    // The dropdown also contains a Scrollable; select the outer form ListView.
    final reservaScrollable = find
        .descendant(
          of: find.descendant(
            of: find.byType(ReservaScreen),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(reservaScrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      confirmarReserva,
      300,
      scrollable: reservaScrollable,
    );
    await tester.ensureVisible(confirmarReserva);
    await tester.pumpAndSettle();
    expect(confirmarReserva.hitTestable(), findsOneWidget);
    await tester.tap(confirmarReserva);
    await tester.pumpAndSettle();
    expect(find.text('Completa este campo'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adding inventory updates the local dashboard', (tester) async {
    await auth.dispose();
    auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(true));
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cargar: () async => {
            for (final p in demo.productos)
              p.sku: ProductosRepository.haciaDocumento(p),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DrawerButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-modulo-3')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Agregar producto'), 200);
    await tester.tap(find.text('Agregar producto'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'Filtro de aceite');
    await tester.enterText(fields.at(1), '45');
    await tester.enterText(fields.at(2), '3');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final total = '${demo.productos.length + 1}';
    final bajo = '${demo.productos.where((p) => p.stock <= 5).length + 1}';
    await tester.scrollUntilVisible(find.text(total), -250);
    expect(find.text(total), findsOneWidget);
    expect(find.text(bajo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desktop uses navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cargar: () async => {
            for (final p in demo.productos)
              p.sku: ProductosRepository.haciaDocumento(p),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
