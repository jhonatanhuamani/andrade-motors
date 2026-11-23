import 'dart:async';

import 'package:andrade_motors/data/catalogo_state.dart';
import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:andrade_motors/main.dart';
import 'package:andrade_motors/screens/catalogo_screen.dart';
import 'package:andrade_motors/screens/producto_detalle_screen.dart';
import 'package:andrade_motors/widgets/producto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_admin_auth.dart';

void main() {
  testWidgets(
    'Web y móvil aplican cambios remotos sin reconstruir la aplicación',
    (tester) async {
      final stream =
          StreamController<Map<String, Map<String, dynamic>>>.broadcast();
      final webAuth = FakeAdminAuth();
      final movilAuth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
      final base = demo.productos.first;
      final sku = base.sku;
      const nuevoSku = 'TEST-NUEVO';
      final ancho = ValueNotifier(1200.0);
      addTearDown(ancho.dispose);
      addTearDown(stream.close);
      addTearDown(webAuth.dispose);
      addTearDown(movilAuth.dispose);

      Widget app(FakeAdminAuth auth, {bool web = false}) => AndradeMotorsApp(
        escaparateWeb: web,
        catalogoEnVivo: true,
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cambios: (admin) => stream.stream.map(
            (filas) => {
              for (final fila in filas.entries)
                if (admin || fila.value['activo'] == true) fila.key: fila.value,
            },
          ),
        ),
      );

      tester.view.physicalSize = const Size(1580, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final webApp = app(webAuth, web: true);
      final movilApp = app(movilAuth);
      const webKey = Key('web');
      const movilKey = Key('movil');

      Widget viewport(Key key, double width, Widget app) => SizedBox(
        key: key,
        width: width,
        child: MediaQuery(
          data: MediaQueryData(size: Size(width, 860)),
          child: app,
        ),
      );

      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: ancho,
          builder: (_, width, _) => Row(
            textDirection: TextDirection.ltr,
            children: [
              viewport(webKey, width, webApp),
              viewport(movilKey, 360, movilApp),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder en(Key key, Finder finder, {bool skipOffstage = true}) =>
          find.descendant(
            of: find.byKey(key, skipOffstage: skipOffstage),
            matching: finder,
            skipOffstage: skipOffstage,
          );
      await tester.tap(en(webKey, find.text('Ver productos')));
      await tester.tap(en(movilKey, find.text('Catálogo')));
      await tester.pumpAndSettle();
      expect(en(webKey, find.text('48 productos')), findsOneWidget);

      Map<String, dynamic> documento(String id, {bool activo = true}) => {
        ...ProductosRepository.haciaDocumento(base),
        'sku': id,
        'nombre': 'Producto sincronizado',
        'descripcion': 'Descripción actualizada',
        'precio': 125.0,
        'stock': 7,
        'activo': activo,
      };
      stream.add({sku: documento(sku)});
      await tester.pumpAndSettle();

      Finder tarjeta(Key key) => en(key, find.byType(ProductoCard));
      expect(tester.widget<ProductoCard>(tarjeta(webKey)).producto.precio, 125);
      expect(tester.widget<ProductoCard>(tarjeta(movilKey)).producto.stock, 7);
      final webCard = tarjeta(webKey);
      Finder accion(Finder target) =>
          find.descendant(of: webCard, matching: target);
      await tester.ensureVisible(accion(find.byTooltip('Guardar favorito')));
      await tester.tap(accion(find.byTooltip('Guardar favorito')));
      await tester.ensureVisible(accion(find.text('Agregar')));
      await tester.tap(accion(find.text('Agregar')));
      await tester.drag(
        en(webKey, find.byType(ListView)).first,
        const Offset(0, -325),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(accion(find.text('Ver producto')));
      await tester.tap(accion(find.text('Ver producto')));
      await tester.pumpAndSettle();

      stream.add({
        sku: {...documento(sku), 'precio': 131.0, 'stock': 4},
      });
      await tester.pumpAndSettle();
      final detalle = tester.widget<ProductoDetalleScreen>(
        en(webKey, find.byType(ProductoDetalleScreen)),
      );
      expect(detalle.producto.precio, 131);
      expect(tester.widget<ProductoCard>(tarjeta(movilKey)).producto.stock, 4);

      stream.add({sku: documento(sku, activo: false)});
      await tester.pumpAndSettle();
      expect(
        en(webKey, find.text('Este producto ya no está disponible.')),
        findsOneWidget,
      );
      expect(tarjeta(movilKey), findsNothing);

      await tester.tap(en(webKey, find.byType(BackButton)));
      await tester.pumpAndSettle();
      stream.add({sku: documento(sku), nuevoSku: documento(nuevoSku)});
      await tester.pumpAndSettle();
      expect(en(webKey, find.text('2 productos')), findsOneWidget);
      final cards = tester.widgetList<ProductoCard>(tarjeta(webKey));
      expect(
        cards.firstWhere((card) => card.producto.sku == sku).favorito,
        isTrue,
      );

      for (final width in [1000.0, 720.0, 375.0]) {
        ancho.value = width;
        await tester.pumpAndSettle();
        expect(en(webKey, find.byType(CatalogoScreen)), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('El panel recibe activos e inactivos y el cliente conserva un vacío confirmado', () async {
    final filas =
        StreamController<Map<String, Map<String, dynamic>>>.broadcast();
    ProductosRepository repositorio() => ProductosRepository(
      cambios: (admin) => filas.stream.map(
        (docs) => {
          for (final doc in docs.entries)
            if (admin || doc.value['activo'] == true) doc.key: doc.value,
        },
      ),
    );
    final admin = CatalogoState(repositorio(), enVivo: true);
    final cliente = CatalogoState(repositorio(), enVivo: true);
    addTearDown(filas.close);
    addTearDown(admin.dispose);
    addTearDown(cliente.dispose);
    admin.observar(admin: true, cuenta: 'admin');
    cliente.observar(admin: false);
    await Future<void>.delayed(Duration.zero);
    final base = demo.productos.first;
    final campos = ProductosRepository.haciaDocumento(base);
    final cambios = {
      base.sku: {...campos, 'precio': 301.0, 'stock': 9},
    };
    final adminActualizado = Completer<void>();
    final clienteActualizado = Completer<void>();
    admin.addListener(() {
      if (!adminActualizado.isCompleted) adminActualizado.complete();
    });
    cliente.addListener(() {
      if (!clienteActualizado.isCompleted) clienteActualizado.complete();
    });
    filas.add(cambios);
    await Future.wait([adminActualizado.future, clienteActualizado.future]);
    expect(admin.productos.single.precio, 301);
    expect(cliente.productos.single.stock, 9);

    final desactivado = Completer<void>();
    cliente.addListener(() {
      if (!desactivado.isCompleted && cliente.productos.isEmpty) {
        desactivado.complete();
      }
    });
    filas.add({
      base.sku: {...cambios[base.sku]!, 'activo': false},
    });
    await desactivado.future;
    expect(cliente.usaRespaldo, isFalse);
    expect(admin.productos.single.activo, isFalse);
  });
}
