import 'package:andrade_motors/auth/auth_router.dart';
import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/producto_edicion.dart';
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:andrade_motors/main.dart';
import 'package:andrade_motors/screens/admin/admin_modules.dart';
import 'package:andrade_motors/screens/admin/producto_form_screen.dart';
import 'package:andrade_motors/screens/cliente/cliente_shell.dart';
import 'package:andrade_motors/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/admin_navigation.dart';
import 'support/fake_admin_auth.dart';
import 'support/memory_firestore.dart';

void main() {
  late FakeAdminAuth auth;
  late MemoryFirestore firestore;
  late ProductosRepository repository;
  // MemoryFirestore crea una Future para su cola. Debe pertenecer a la misma
  // zona FakeAsync que los pumps, no a la zona externa de setUp.
  void preparar({bool administrador = true}) {
    auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(administrador));
    firestore = MemoryFirestore(
      datos: {
        for (final p in demo.productos)
          p.sku: ProductosRepository.haciaDocumento(p),
      },
    );
    repository = ProductosRepository(
      escritura: firestore,
      authService: auth,
      cargar: () async => firestore.documentos,
    );
  }

  tearDown(() => auth.dispose());

  Future<void> pulsar(
    WidgetTester tester,
    Finder control, {
    bool esperarAnimaciones = true,
  }) async {
    await tester.pumpAndSettle();
    expect(
      control,
      findsOneWidget,
      reason: 'El control debe estar construido antes de desplazarlo.',
    );
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    expect(control.hitTestable(), findsOneWidget);
    await tester.tap(control);
    if (esperarAnimaciones) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> guardarYEsperar(
    WidgetTester tester,
    bool Function() terminado,
    String motivo,
  ) async {
    final guardar = find.byKey(const ValueKey('producto-guardar'));
    expect(guardar, findsOneWidget);
    expect(tester.widget(guardar), isA<FilledButton>());
    expect(tester.widget<FilledButton>(guardar).onPressed, isNotNull);
    await pulsar(tester, guardar, esperarAnimaciones: false);
    // Esperar el resultado, no el fin de la animación indeterminada del spinner.
    // El límite falla con la condición concreta si la operación queda pendiente.
    final limite = tester.binding.clock.fromNowBy(const Duration(seconds: 3));
    while (!terminado() && tester.binding.clock.now().isBefore(limite)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(terminado(), isTrue, reason: motivo);
    expect(
      find.descendant(
        of: find.byType(ProductoFormScreen),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    if (guardar.evaluate().isNotEmpty) {
      expect(tester.widget<FilledButton>(guardar).onPressed, isNotNull);
    }
    // El guardado ya terminó: solo quedan transiciones finitas de ruta o botón.
    await tester.pumpAndSettle();
  }

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      AndradeMotorsApp(adminAuthService: auth, productosRepository: repository),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirAlta(WidgetTester tester) async {
    preparar();
    await montar(tester);
    await abrirModuloAdmin(tester, 1);
    await pulsar(tester, find.widgetWithText(FilledButton, 'Agregar producto'));
    expect(find.byType(ProductoFormScreen), findsOneWidget);
    expect(firestore.confirmaciones, 0);
  }

  Future<void> completar(
    WidgetTester tester, {
    String sku = ' test-001 ',
  }) async {
    for (final entry in {
      'sku': sku,
      'nombre': 'Producto de prueba',
      'precio': '25,50',
      'stock': '4',
      'descripcion': 'Descripción de prueba',
      'caracteristicas': 'Primera característica\nSegunda característica',
      'compatibilidad': 'Modelo de prueba',
    }.entries) {
      final campo = find.byKey(ValueKey('producto-${entry.key}'));
      expect(campo, findsOneWidget);
      await tester.ensureVisible(campo);
      await tester.pumpAndSettle();
      await tester.enterText(campo, entry.value);
      await tester.pumpAndSettle();
    }
    final categoria = find.descendant(
      of: find.byKey(const ValueKey('producto-categoria')),
      matching: find.byType(DropdownButton<String>),
    );
    await pulsar(tester, categoria);
    final opcion = find
        .ancestor(
          of: find.text('Repuestos').last,
          matching: find.byType(InkWell),
        )
        .first;
    await pulsar(tester, opcion);
  }

  testWidgets(
    'Abrir y cancelar alta no escribe; formulario incompleto no guarda',
    (tester) async {
      await abrirAlta(tester);
      await pulsar(tester, find.byKey(const ValueKey('producto-guardar')));
      expect(find.byType(ProductoFormScreen), findsOneWidget);
      expect(firestore.confirmaciones, 0);
      final form = tester.widget<Form>(find.byType(Form));
      expect(
        (form.key! as GlobalKey<FormState>).currentState!.validate(),
        isFalse,
      );
      final volver = find.descendant(
        of: find.byType(ProductoFormScreen),
        matching: find.byType(BackButton),
      );
      await pulsar(tester, volver);
      expect(firestore.documentos, hasLength(demo.productos.length));
      expect(find.byType(ProductoFormScreen), findsNothing);
      expect(find.byType(AdminProducts), findsOneWidget);
      expect(firestore.confirmaciones, 0);
    },
  );

  testWidgets(
    'Guardar crea una sola vez y actualiza catálogo administrativo tras confirmación',
    (tester) async {
      await abrirAlta(tester);
      await completar(tester);
      expect(firestore.confirmaciones, 0);
      await guardarYEsperar(
        tester,
        () =>
            firestore.confirmaciones == 1 &&
            find.byType(ProductoFormScreen).evaluate().isEmpty,
        'Debe confirmarse la creación y cerrarse el formulario.',
      );
      expect(find.byType(ProductoFormScreen), findsNothing);
      expect(find.textContaining('guardado en Firestore'), findsOneWidget);
      expect(firestore.documentos['TEST-001']!['precio'], 25.5);
      expect(firestore.documentos['TEST-001']!['imagenAsset'], isNull);
      expect(firestore.confirmaciones, 1);
      expect(
        tester.widget<AdminProducts>(find.byType(AdminProducts)).productos,
        hasLength(demo.productos.length + 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tarjeta abre edición con SKU bloqueado y conserva fotografía y reseñas',
    (tester) async {
      preparar();
      await montar(tester);
      await abrirModuloAdmin(tester, 1);
      final original = demo.productos.first;
      final editar = find.byKey(ValueKey('editar-${original.sku}'));
      final lista = find
          .descendant(
            of: find.byType(AdminProducts),
            matching: find.byType(Scrollable),
          )
          .first;
      // La cuadrícula es un hijo perezoso del ListView; ensureVisible no puede
      // construirla. Desplazar primero la lista vertical hasta encontrarla.
      expect(lista, findsOneWidget);
      await tester.scrollUntilVisible(editar, 250, scrollable: lista);
      expect(editar, findsOneWidget);
      expect(tester.widget(editar), isA<OutlinedButton>());
      await pulsar(tester, editar);
      expect(find.byType(ProductoFormScreen), findsOneWidget);
      final sku = find.descendant(
        of: find.byKey(const ValueKey('producto-sku')),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(sku).readOnly, isTrue);
      final stock = find.byKey(const ValueKey('producto-stock'));
      expect(stock, findsOneWidget);
      await tester.ensureVisible(stock);
      await tester.pumpAndSettle();
      await tester.enterText(stock, '10');
      await guardarYEsperar(
        tester,
        () =>
            firestore.updates == 1 &&
            find.byType(ProductoFormScreen).evaluate().isEmpty,
        'Debe confirmarse la edición y cerrarse el formulario.',
      );
      expect(firestore.documentos[original.sku]!['stock'], 10);
      expect(
        firestore.documentos[original.sku]!['imagenAsset'],
        original.imagenAsset,
      );
      expect(firestore.documentos[original.sku]!['resenas'], original.resenas);
      expect(firestore.sets, 0);
      expect(firestore.updates, 1);
      expect(
        tester
            .widget<AdminProducts>(find.byType(AdminProducts))
            .productos
            .first
            .stock,
        10,
      );
    },
  );

  testWidgets(
    'Error de conexión permanece visible sin éxito ni producto ficticio',
    (tester) async {
      await abrirAlta(tester);
      await completar(tester);
      firestore.error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Conexión de prueba interrumpida',
      );
      await guardarYEsperar(
        tester,
        () => find.textContaining('unavailable:').evaluate().isNotEmpty,
        'El error de conexión debe mostrarse y finalizar la carga.',
      );
      expect(find.byType(ProductoFormScreen), findsOneWidget);
      expect(find.textContaining('unavailable:'), findsOneWidget);
      expect(find.textContaining('guardado en Firestore'), findsNothing);
      expect(firestore.documentos, hasLength(demo.productos.length));
      expect(firestore.confirmaciones, 0);
    },
  );

  testWidgets('SKU duplicado muestra el error sin cerrar el formulario', (
    tester,
  ) async {
    await abrirAlta(tester);
    await completar(tester, sku: demo.productos.first.sku);
    await guardarYEsperar(
      tester,
      () => find.textContaining('Ya existe un producto').evaluate().isNotEmpty,
      'El SKU duplicado debe rechazarse y finalizar la carga.',
    );
    expect(find.textContaining('Ya existe un producto'), findsOneWidget);
    expect(find.byType(ProductoFormScreen), findsOneWidget);
    expect(firestore.documentos, hasLength(demo.productos.length));
    expect(firestore.confirmaciones, 0);
  });

  testWidgets(
    'Cliente no tiene controles administrativos ni puede abrir el formulario directamente',
    (tester) async {
      preparar(administrador: false);
      await montar(tester);
      expect(find.byType(ClienteShell), findsOneWidget);
      expect(find.text('Editar producto'), findsNothing);
      final context = tester.element(find.byType(ClienteShell));
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const ProductoFormScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Acceso denegado'), findsOneWidget);
      expect(find.byKey(const ValueKey('producto-guardar')), findsNothing);
      expect(firestore.confirmaciones, 0);
    },
  );

  testWidgets(
    'Cambio remoto confirmado conserva favoritos y cantidades del carrito por SKU',
    (tester) async {
      preparar();
      final writer = repository;
      final clienteAuth = FakeAdminAuth(cuenta: FakeCuentaAdmin(false));
      addTearDown(clienteAuth.dispose);
      await tester.pumpWidget(
        AndradeMotorsApp(
          adminAuthService: clienteAuth,
          productosRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      final inicio = tester.widget<HomeScreen>(find.byType(HomeScreen));
      final original = inicio.productos.first;
      inicio.onFavorito(original);
      inicio.onAgregar(original);
      await tester.pumpAndSettle();
      final catalogo = tester
          .widget<AuthRouter>(find.byType(AuthRouter))
          .catalogo;
      await writer.actualizarProducto(
        original.sku,
        ProductoEdicion(
          sku: original.sku,
          nombre: original.nombre,
          categoria: original.categoria,
          precio: 50,
          stock: original.stock,
          descripcion: original.descripcion,
          caracteristicas: original.caracteristicas,
          compatibilidad: original.compatibilidad,
        ),
      );
      await catalogo.cargar();
      await tester.pumpAndSettle();
      final actualizado = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(actualizado.favoritos, contains(original.sku));
      expect(actualizado.productos.first.precio, 50);
      actualizado.onAgregar(actualizado.productos.first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ver carrito'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quitar del carrito'), findsOneWidget);
      expect(find.text('2 uds. · S/ 100.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}