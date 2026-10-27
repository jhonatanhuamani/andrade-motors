import 'package:andrade_motors/auth/admin_session.dart';
import 'package:andrade_motors/auth/auth_router.dart';
import 'package:andrade_motors/auth/session_scope.dart';
import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:andrade_motors/main.dart';
import 'package:andrade_motors/screens/admin/admin_modules.dart';
import 'package:andrade_motors/screens/admin/admin_shell.dart';
import 'package:andrade_motors/screens/admin_login_screen.dart';
import 'package:andrade_motors/screens/catalogo_screen.dart';
import 'package:andrade_motors/screens/cliente/cliente_shell.dart';
import 'package:andrade_motors/screens/home_screen.dart';
import 'package:andrade_motors/screens/inventario_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/admin_navigation.dart';
import 'support/fake_admin_auth.dart';

void main() {
  Future<void> montar(WidgetTester tester, FakeAdminAuth auth) async {
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(
          cargar: () async => {
            for (final p in demo.productos.reversed)
              p.sku: ProductosRepository.haciaDocumento(p),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('El login inicial no construye ninguna interfaz sin sesión', (
    tester,
  ) async {
    await montar(tester, FakeAdminAuth());
    expect(find.byType(AdminLoginScreen), findsOneWidget);
    expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
    expect(find.byType(ClienteShell, skipOffstage: false), findsNothing);
  });

  testWidgets(
    'Cliente restaurado conserva catálogo y navegación sin inventario',
    (tester) async {
      await montar(tester, FakeAdminAuth(cuenta: FakeCuentaAdmin(false)));
      expect(find.byType(ClienteShell), findsOneWidget);
      expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
      expect(find.byType(InventarioScreen, skipOffstage: false), findsNothing);
      final catalogo = tester
          .widget<AuthRouter>(find.byType(AuthRouter))
          .catalogo;
      expect(catalogo.usaRespaldo, isFalse);
      expect(
        catalogo.productos.map(ProductosRepository.haciaDocumento),
        demo.productos.map(ProductosRepository.haciaDocumento),
      );
      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CatalogoScreen>(find.byType(CatalogoScreen)).productos,
        hasLength(8),
      );
      expect(find.text('8 productos'), findsOneWidget);
    },
  );

  testWidgets('Cliente no accede a ninguna ruta administrativa directa', (
    tester,
  ) async {
    await montar(tester, FakeAdminAuth(cuenta: FakeCuentaAdmin(false)));
    final cliente = tester.element(find.byType(ClienteShell));
    for (final ruta in [
      '/admin',
      '/admin/productos',
      '/admin/servicios',
      '/admin/inventario',
      '/admin/usuarios',
      '/admin/reservas',
      '/admin/pedidos',
      '/admin/configuracion',
    ]) {
      Navigator.of(cliente).pushNamed<void>(ruta);
      await tester.pumpAndSettle();
      expect(find.textContaining('Acceso denegado'), findsOneWidget);
      expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
      expect(find.byType(InventarioScreen, skipOffstage: false), findsNothing);
      Navigator.of(cliente).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'AdminOnly también rechaza la construcción directa para clientes',
    (tester) async {
      final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
      final session = AdminSession(auth);
      await tester.pumpWidget(
        SessionScope(
          session: session,
          child: const MaterialApp(
            home: Scaffold(body: AdminOnly(child: Text('Contenido protegido'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Contenido protegido'), findsNothing);
      expect(find.textContaining('Acceso denegado'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      await auth.dispose();
    },
  );

  testWidgets(
    'Administrador tiene ocho módulos independientes y datos pendientes claros',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await montar(tester, FakeAdminAuth(cuenta: FakeCuentaAdmin(true)));
      expect(find.byType(AdminDashboard), findsOneWidget);
      expect(find.byType(ClienteShell, skipOffstage: false), findsNothing);
      for (var i = 1; i < AdminShell.modulos.length; i++) {
        await abrirModuloAdmin(tester, i);
        expect(tester.takeException(), isNull);
      }
      await abrirModuloAdmin(tester, 1);
      expect(
        tester.widget<AdminProducts>(find.byType(AdminProducts)).productos,
        hasLength(8),
      );
      final agregar = find.widgetWithText(FilledButton, 'Agregar producto');
      expect(tester.widget<FilledButton>(agregar).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Actualizar el token conserva favoritos y carrito de la sesión cliente',
    (tester) async {
      await montar(tester, FakeAdminAuth(cuenta: FakeCuentaAdmin(false)));
      final inicio = tester.widget<HomeScreen>(find.byType(HomeScreen));
      inicio.onFavorito(inicio.productos.first);
      inicio.onAgregar(inicio.productos.first);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ClienteShell));
      await SessionScope.of(context).comprobar();
      await tester.pumpAndSettle();
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).favoritos,
        contains(inicio.productos.first.sku),
      );
      await tester.tap(find.byTooltip('Ver carrito'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 uds.'), findsOneWidget);
    },
  );

  testWidgets(
    'Cerrar sesión cliente vuelve al login y retira sus páginas de la pila',
    (tester) async {
      final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
      await montar(tester, auth);
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('cuenta@example.test'), findsOneWidget);
      final salir = find.widgetWithText(TextButton, 'Cerrar sesión');
      await tester.ensureVisible(salir);
      await tester.pumpAndSettle();
      expect(salir.hitTestable(), findsOneWidget);
      await tester.tap(salir);
      await tester.pumpAndSettle();
      expect(auth.cuentaActual, isNull);
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.byType(ClienteShell, skipOffstage: false), findsNothing);
      expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
    },
  );
}
