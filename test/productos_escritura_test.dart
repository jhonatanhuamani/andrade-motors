import 'dart:async';

import 'package:andrade_motors/data/catalogo_state.dart';
import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/producto_edicion.dart';
import 'package:andrade_motors/data/productos_escritura.dart';
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_admin_auth.dart';
import 'support/memory_firestore.dart';

class _PermisoRevocado extends FakeCuentaAdmin {
  _PermisoRevocado() : super(true);
  @override
  Future<bool> comprobarAdmin() async => ++comprobaciones == 1;
}

ProductoEdicion productoPrueba({
  String sku = ' TEST-001 ',
  double precio = 25.5,
  int stock = 4,
  String nombre = 'Producto de prueba',
}) => ProductoEdicion(
  sku: sku,
  nombre: nombre,
  categoria: 'Repuestos',
  precio: precio,
  stock: stock,
  descripcion: 'Descripción de prueba',
  caracteristicas: ['Característica de prueba'],
  compatibilidad: ['Compatibilidad de prueba'],
);

void main() {
  late FakeAdminAuth auth;
  late MemoryFirestore firestore;
  late ProductosRepository repository;
  setUp(() {
    auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(true));
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
  });
  tearDown(() => auth.dispose());

  test(
    'Revalida el token dentro de la operación y rechaza permisos revocados',
    () async {
      final cuenta = _PermisoRevocado();
      final revocada = FakeAdminAuth(cuenta: cuenta);
      final restringido = ProductosRepository(
        authService: revocada,
        escritura: firestore,
      );
      await expectLater(
        restringido.crearProducto(productoPrueba()),
        throwsA(
          isA<ErrorEscrituraProducto>().having(
            (e) => e.codigo,
            'código',
            'permission-denied',
          ),
        ),
      );
      expect(cuenta.comprobaciones, 2);
      expect(firestore.confirmaciones, 0);
      expect(firestore.documentos, hasLength(8));
      await revocada.dispose();
    },
  );

  test('Crear válido normaliza SKU, conserva el esquema y no modifica los ocho originales', () async {
    final anteriores = {
      for (final p in demo.productos)
        p.sku: ProductosRepository.haciaDocumento(p),
    };
    expect(firestore.confirmaciones, 0);
    final producto = await repository.crearProducto(
      productoPrueba(sku: ' test-001 '),
    );
    expect(producto.sku, 'TEST-001');
    expect(producto.precio, 25.5);
    expect(producto.imagenAsset, isNull);
    expect(
      firestore.documentos['TEST-001']!.keys.toSet(),
      ProductosRepository.haciaDocumento(producto).keys.toSet(),
    );
    expect(producto.resenas, 0);
    expect(firestore.documentos, hasLength(9));
    for (final entry in anteriores.entries) {
      expect(firestore.documentos[entry.key], entry.value);
    }
    expect(firestore.sets, 1);
  });

  test('SKU duplicado nunca sobrescribe un documento existente', () async {
    final original = Map.of(firestore.documentos[demo.productos.first.sku]!);
    await expectLater(
      repository.crearProducto(productoPrueba(sku: demo.productos.first.sku)),
      throwsA(
        isA<ErrorEscrituraProducto>().having(
          (e) => e.codigo,
          'código',
          'sku-duplicado',
        ),
      ),
    );
    expect(firestore.documentos[demo.productos.first.sku], original);
    expect(firestore.sets, 0);
    expect(firestore.confirmaciones, 0);
  });

  test('Dos creaciones simultáneas del mismo SKU confirman solo una', () async {
    Future<bool> crear(String nombre) async {
      try {
        await repository.crearProducto(productoPrueba(nombre: nombre));
        return true;
      } on ErrorEscrituraProducto catch (error) {
        expect(error.codigo, 'sku-duplicado');
        return false;
      }
    }

    final resultados = await Future.wait([crear('Primero'), crear('Segundo')]);
    expect(resultados.where((v) => v), hasLength(1));
    expect(firestore.sets, 1);
    expect(firestore.documentos, hasLength(9));
  });

  test('Valida precios, stock y SKU antes de enviar escrituras', () async {
    for (final precio in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(
        repository.crearProducto(productoPrueba(precio: precio)),
        throwsFormatException,
      );
    }
    await expectLater(
      repository.crearProducto(productoPrueba(stock: -1)),
      throwsFormatException,
    );
    for (final sku in ['', 'A/B', 'A B', '..', '-A']) {
      await expectLater(
        repository.crearProducto(productoPrueba(sku: sku)),
        throwsFormatException,
      );
    }
    for (final stock in ['1.5', '-1', 'NaN', '']) {
      expect(ProductoEdicion.validarStock(stock), isNotNull);
    }
    expect(ProductoEdicion.validarStock('0'), isNull);
    expect(ProductoEdicion.validarPrecio('25,50'), isNull);
    expect(firestore.confirmaciones, 0);
  });

  test('Editar actualiza solo campos editables y conserva imagen, SKU, reseñas y campos desconocidos', () async {
    final sku = demo.productos.first.sku;
    final original = firestore.documentos[sku]!;
    original['rating'] = 3.9;
    original['resenas'] = 7;
    original['metadato'] = {'origen': 'valor preexistente'};
    final conservados = {
      for (final campo in [
        'sku',
        'imagenAsset',
        'rating',
        'resenas',
        'metadato',
      ])
        campo: original[campo],
    };
    final cambiado = await repository.actualizarProducto(
      sku,
      productoPrueba(
        sku: sku,
        nombre: 'Nombre editado de prueba',
        precio: 30,
        stock: 9,
      ),
    );
    expect(cambiado.nombre, 'Nombre editado de prueba');
    expect(cambiado.stock, 9);
    for (final entry in conservados.entries) {
      expect(firestore.documentos[sku]![entry.key], entry.value);
    }
    expect(firestore.camposActualizados.single, {
      'nombre',
      'categoria',
      'precio',
      'stock',
      'descripcion',
      'caracteristicas',
      'compatibilidad',
    });
    expect(firestore.sets, 0);
    expect(firestore.updates, 1);
  });

  test(
    'Editar no crea documentos inexistentes ni permite cambiar SKU',
    () async {
      await expectLater(
        repository.actualizarProducto('TEST-001', productoPrueba()),
        throwsA(
          isA<ErrorEscrituraProducto>().having(
            (e) => e.codigo,
            'código',
            'producto-inexistente',
          ),
        ),
      );
      await expectLater(
        repository.actualizarProducto(
          demo.productos.first.sku,
          productoPrueba(),
        ),
        throwsFormatException,
      );
      expect(firestore.documentos, hasLength(8));
      expect(firestore.updates, 0);
    },
  );

  test(
    'Niega crear y editar a clientes y visitantes sin alcanzar Firestore',
    () async {
      for (final cuenta in [null, FakeCuentaAdmin(false)]) {
        final sinPermiso = FakeAdminAuth(cuenta: cuenta);
        final restringido = ProductosRepository(
          escritura: firestore,
          authService: sinPermiso,
        );
        await expectLater(
          restringido.crearProducto(productoPrueba()),
          throwsA(
            isA<ErrorEscrituraProducto>().having(
              (e) => e.codigo,
              'código',
              'permission-denied',
            ),
          ),
        );
        await expectLater(
          restringido.actualizarProducto(
            demo.productos.first.sku,
            productoPrueba(sku: demo.productos.first.sku),
          ),
          throwsA(isA<ErrorEscrituraProducto>()),
        );
        await sinPermiso.dispose();
      }
      expect(firestore.confirmaciones, 0);
      expect(firestore.sets, 0);
      expect(firestore.updates, 0);
    },
  );

  test('Errores de red y de reglas se propagan sin informar un guardado ni alterar catálogo', () async {
    final catalogo = CatalogoState(repository);
    await catalogo.cargar();
    final anterior = catalogo.productos;
    for (final codigo in ['unavailable', 'permission-denied']) {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: codigo,
        message: 'Error de prueba',
      );
      firestore.error = error;
      await expectLater(
        catalogo.crearProducto(productoPrueba()),
        throwsA(same(error)),
      );
      expect(identical(catalogo.productos, anterior), isTrue);
    }
    expect(firestore.confirmaciones, 0);
    expect(firestore.documentos, hasLength(8));
    catalogo.dispose();
  });

  test('Catálogo incorpora confirmaciones sin duplicados y actualiza los indicadores', () async {
    final catalogo = CatalogoState(repository);
    await catalogo.cargar();
    await catalogo.crearProducto(productoPrueba());
    expect(catalogo.productos, hasLength(9));
    expect(catalogo.productos.map((p) => p.sku).toSet(), hasLength(9));
    final anterior = catalogo.productos.fold<double>(
      0,
      (s, p) => s + p.precio * p.stock,
    );
    await catalogo.actualizarProducto(
      'TEST-001',
      productoPrueba(precio: 100, stock: 8),
    );
    expect(catalogo.productos, hasLength(9));
    expect(
      catalogo.productos.fold<double>(0, (s, p) => s + p.precio * p.stock),
      anterior - 25.5 * 4 + 800,
    );
    expect(
      catalogo.productos.take(8).map((p) => p.sku),
      demo.productos.map((p) => p.sku),
    );
    catalogo.dispose();
  });

  test(
    'Una lectura anterior al guardado no reemplaza la confirmación remota',
    () async {
      final lectura = Completer<Map<String, Map<String, dynamic>>>();
      final catalogo = CatalogoState(
        ProductosRepository(
          escritura: firestore,
          authService: auth,
          cargar: () => lectura.future,
        ),
      );
      final carga = catalogo.cargar();
      await catalogo.crearProducto(productoPrueba());
      lectura.complete({});
      await carga;
      expect(catalogo.productos.any((p) => p.sku == 'TEST-001'), isTrue);
      catalogo.dispose();
    },
  );
}
