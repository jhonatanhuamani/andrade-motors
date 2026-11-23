import 'package:andrade_motors/auth/session_scope.dart';
import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/favoritos_state.dart';
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:andrade_motors/main.dart';
import 'package:andrade_motors/screens/catalogo_screen.dart';
import 'package:andrade_motors/screens/favoritos_screen.dart';
import 'package:andrade_motors/screens/producto_detalle_screen.dart';
import 'package:andrade_motors/widgets/producto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/fake_admin_auth.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'Los SKU guardados son únicos y cada UID conserva su selección',
    () async {
      final primera = FavoritosState();
      primera.cambiarCliente('uno');
      primera.alternar('SKU-1');
      primera.alternar('SKU-2');
      primera.alternar('SKU-2');
      primera.cambiarCliente('dos');
      expect(primera.skus, isEmpty);
      primera.alternar('SKU-3');
      primera.dispose();

      final restaurada = FavoritosState();
      restaurada.cambiarCliente('uno');
      await Future<void>.delayed(Duration.zero);
      expect(restaurada.skus, {'SKU-1'});
      restaurada.cambiarCliente('dos');
      await Future<void>.delayed(Duration.zero);
      expect(restaurada.skus, {'SKU-3'});
      restaurada.dispose();
    },
  );

  for (final web in [false, true]) {
    testWidgets('Catálogo, detalle y Perfil comparten favoritos (web: $web)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = web
          ? const Size(1200, 900)
          : const Size(410, 850);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAdminAuth(
        cuenta: FakeCuentaAdmin(false),
        adminAlEntrar: false,
      );
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        AndradeMotorsApp(
          escaparateWeb: web,
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
      final perfil = web ? find.byTooltip('Perfil') : find.text('Perfil');
      final catalogo = web
          ? find.widgetWithText(TextButton, 'Productos')
          : find.text('Catálogo');
      await tester.tap(catalogo.hitTestable().first);
      await tester.pumpAndSettle();
      final tarjeta = find.byType(ProductoCard).first;
      final p = tester.widget<ProductoCard>(tarjeta).producto;
      final corazon = find.descendant(
        of: tarjeta,
        matching: find.byTooltip('Guardar favorito'),
      );
      await tester.ensureVisible(corazon);
      await tester.pumpAndSettle();
      await tester.tap(corazon);
      await tester.pumpAndSettle();
      expect(tester.widget<ProductoCard>(tarjeta).favorito, isTrue);
      expect(
        await SharedPreferencesAsync().getStringList('favoritos.cuenta-prueba'),
        [p.sku],
      );

      await tester.tap(perfil.hitTestable());
      await tester.pumpAndSettle();
      final tile = find.text('Mis favoritos');
      final sesion = SessionScope.of(tester.element(tile));
      await sesion.cerrarSesion();
      await tester.pumpAndSettle();
      expect(tile, findsNothing);
      await sesion.iniciarSesion('cuenta@example.test', 'prueba');
      await tester.pumpAndSettle();
      if (tile.evaluate().isEmpty) {
        await tester.tap(perfil.hitTestable());
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(FavoritosScreen), findsOneWidget);
      expect(find.text(p.nombre), findsOneWidget);
      expect(find.text(p.precioTexto), findsOneWidget);
      expect(find.text('Stock: ${p.stock} uds.'), findsOneWidget);
      await tester.tap(find.text('Ver producto'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductoDetalleScreen), findsOneWidget);
      expect(find.byTooltip('Quitar favorito'), findsOneWidget);
      await tester.tap(find.byTooltip('Quitar favorito'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Guardar favorito'), findsOneWidget);
      await tester.tap(find.byTooltip('Guardar favorito'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(ProductoDetalleScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pumpAndSettle();
      expect(find.text(p.nombre), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(catalogo.hitTestable().first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<CatalogoScreen>(find.byType(CatalogoScreen)).favoritos,
        isEmpty,
      );
    });
  }
}
