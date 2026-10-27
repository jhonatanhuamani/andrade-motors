import 'dart:async';

import 'package:andrade_motors/auth/admin_auth_service.dart';
import 'package:andrade_motors/auth/admin_session.dart';
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:andrade_motors/main.dart';
import 'package:andrade_motors/screens/admin_login_screen.dart';
import 'package:andrade_motors/screens/admin/admin_shell.dart';
import 'package:andrade_motors/screens/cliente/cliente_shell.dart';
import 'package:andrade_motors/screens/inventario_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_admin_auth.dart';
import 'support/admin_navigation.dart';

class _Token extends Fake implements IdTokenResult {
  _Token(this.claims);
  @override
  final Map<String, dynamic>? claims;
}

class _User extends Fake implements User {
  _User(this.claims);
  final Map<String, dynamic> claims;
  @override
  String get uid => 'cuenta-prueba';
  @override
  String get email => 'cuenta@example.test';
  bool? forzar;
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    forzar = forceRefresh;
    return _Token(claims);
  }
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);
  @override
  final User? currentUser;
}

void main() {
  Future<void> pulsarControlVisible(WidgetTester tester, Finder control) async {
    // Terminar primero cualquier desplazamiento del campo que tenía el foco.
    await tester.pumpAndSettle();
    expect(control, findsOneWidget);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    expect(control.hitTestable(), findsOneWidget);
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  Future<void> montar(WidgetTester tester, FakeAdminAuth auth) async {
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      AndradeMotorsApp(
        adminAuthService: auth,
        productosRepository: ProductosRepository(cargar: () async => {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'El servicio fuerza un token nuevo y exige admin booleano true',
    () async {
      for (final valor in [true, false, 'true', 1, null]) {
        final user = _User({'admin': valor});
        final servicio = FirebaseAdminAuthService(auth: _Auth(user));
        expect(await servicio.cuentaActual!.comprobarAdmin(), valor == true);
        expect(user.forzar, isTrue);
      }
    },
  );

  testWidgets('Visitante ve acceso y puede mostrar u ocultar contraseña', (
    tester,
  ) async {
    await montar(tester, FakeAdminAuth());
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.byType(InventarioScreen), findsNothing);
    final clave = find
        .descendant(
          of: find.byType(AdminLoginScreen),
          matching: find.byType(EditableText),
        )
        .last;
    expect(tester.widget<EditableText>(clave).obscureText, isTrue);
    await pulsarControlVisible(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Mostrar contraseña',
      ),
    );
    expect(tester.widget<EditableText>(clave).obscureText, isFalse);
    await pulsarControlVisible(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Ocultar contraseña',
      ),
    );
    expect(tester.widget<EditableText>(clave).obscureText, isTrue);
  });

  testWidgets(
    'Cuenta sin rol conserva sesión cliente sin acceso administrativo',
    (tester) async {
      final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
      await montar(tester, auth);
      expect(auth.cuentaActual, isNotNull);
      expect(auth.salidas, 0);
      expect(find.byType(ClienteShell), findsOneWidget);
      expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
      expect(find.byType(InventarioScreen), findsNothing);
    },
  );

  testWidgets(
    'Restaura admin, conserva navegación independiente y cierra sesión',
    (tester) async {
      final cuenta = FakeCuentaAdmin(true);
      final auth = FakeAdminAuth(cuenta: cuenta);
      await montar(tester, auth);
      expect(cuenta.comprobaciones, greaterThan(0));
      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(ClienteShell, skipOffstage: false), findsNothing);
      await abrirModuloAdmin(tester, 1);
      expect(find.text('Buscar productos'), findsOneWidget);
      await abrirModuloAdmin(tester, 3);
      expect(find.byType(InventarioScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(auth.cuentaActual, isNull);
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Formulario inicia sesión y solo muestra inventario al comprobar admin',
    (tester) async {
      await montar(tester, FakeAdminAuth());
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'admin@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'clave-de-prueba',
      );
      await pulsarControlVisible(
        tester,
        find.widgetWithText(FilledButton, 'Iniciar sesión'),
      );
      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
      expect(find.byType(AdminShell), findsOneWidget);
      await abrirModuloAdmin(tester, 3);
      expect(find.byType(InventarioScreen), findsOneWidget);
    },
  );

  testWidgets('Ingreso sin admin abre la interfaz cliente', (tester) async {
    await montar(tester, FakeAdminAuth(adminAlEntrar: false));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'usuario@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'clave-de-prueba',
    );
    await pulsarControlVisible(
      tester,
      find.widgetWithText(FilledButton, 'Iniciar sesión'),
    );
    expect(find.byType(ClienteShell), findsOneWidget);
    expect(find.byType(AdminShell, skipOffstage: false), findsNothing);
    expect(find.byType(InventarioScreen), findsNothing);
  });

  testWidgets('Una salida externa también oculta el formulario local abierto', (
    tester,
  ) async {
    final auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(true));
    await montar(tester, auth);
    await abrirModuloAdmin(tester, 3);
    await tester.scrollUntilVisible(find.text('Agregar producto'), 200);
    await tester.tap(find.text('Agregar producto'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await auth.cerrarSesion();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Red, credenciales y sesión expirada nunca conceden acceso', () async {
    for (final codigo in [
      'network-request-failed',
      'invalid-credential',
      'user-token-expired',
    ]) {
      final auth = FakeAdminAuth();
      final session = AdminSession(auth);
      await Future<void>.delayed(Duration.zero);
      auth.errorIngreso = FirebaseAuthException(code: codigo);
      await session.iniciarSesion('admin@example.test', 'clave-de-prueba');
      expect(session.esAdmin, isFalse);
      expect(session.mensaje, isNotEmpty);
      session.dispose();
      await auth.dispose();
    }
  });

  test(
    'Fallo al renovar token bloquea una sesión previamente válida',
    () async {
      final cuenta = FakeCuentaAdmin(true);
      final auth = FakeAdminAuth(cuenta: cuenta);
      final session = AdminSession(auth);
      await Future<void>.delayed(Duration.zero);
      expect(session.esAdmin, isTrue);
      cuenta.error = FirebaseAuthException(code: 'user-token-expired');
      await session.comprobar();
      expect(session.esAdmin, isFalse);
      expect(session.mensaje, contains('expiró'));
      session.dispose();
      await auth.dispose();
    },
  );

  test(
    'No concede acceso si se cierra o desmonta durante la comprobación',
    () async {
      final cuenta = FakeCuentaAdmin(true)..pendiente = Completer<bool>();
      final auth = FakeAdminAuth(cuenta: cuenta);
      final session = AdminSession(auth);
      await session.cerrarSesion();
      cuenta.pendiente!.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(session.esAdmin, isFalse);
      session.dispose();
      await auth.dispose();

      final otra = FakeCuentaAdmin(true)..pendiente = Completer<bool>();
      final otroAuth = FakeAdminAuth(cuenta: otra);
      final desmontada = AdminSession(otroAuth);
      desmontada.dispose();
      otra.pendiente!.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(desmontada.esAdmin, isFalse);
      await otroAuth.dispose();
    },
  );
}
