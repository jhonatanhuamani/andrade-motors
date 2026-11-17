import 'package:andrade_motors/data/datos_demo.dart' as demo;
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Conserva el orden original aunque Firestore entregue otro orden',
    () async {
      final repository = ProductosRepository(
        cargar: () async => {
          for (final p in demo.productos.reversed)
            p.sku: ProductosRepository.haciaDocumento(p),
        },
      );
      final resultado = await repository.consultarProductos();
      expect(resultado.usaRespaldo, isFalse);
      expect(
        resultado.productos.map((p) => p.sku),
        demo.productos.map((p) => p.sku),
      );
    },
  );

  test('Los ocho productos conservan campos, rutas e iconos al convertir', () {
    expect(demo.productos, hasLength(demo.productos.length));
    for (final original in demo.productos) {
      final campos = ProductosRepository.haciaDocumento(original);
      expect(campos.containsKey('icono'), isFalse);
      final convertido = ProductosRepository.desdeDocumento(
        original.sku,
        campos,
      );
      expect(ProductosRepository.haciaDocumento(convertido), campos);
      expect(convertido.icono, original.icono);
    }
  });

  test('Convierte num a double y rechaza SKU o tipos contradictorios', () {
    final campos = ProductosRepository.haciaDocumento(demo.productos.first);
    campos['precio'] = 1250;
    campos['rating'] = 5;
    final producto = ProductosRepository.desdeDocumento('AM-ACC-001', campos);
    expect(producto.precio, isA<double>());
    expect(producto.rating, 5.0);
    expect(
      () => ProductosRepository.desdeDocumento('otro', campos),
      throwsFormatException,
    );
    campos['stock'] = '16';
    expect(
      () => ProductosRepository.desdeDocumento('AM-ACC-001', campos),
      throwsFormatException,
    );
  });

  test('Colección vacía y errores utilizan respaldo con diagnóstico', () async {
    final vacio = await ProductosRepository(cargar: () async => {})
        .consultarProductos();
    expect(vacio.usaRespaldo, isTrue);
    expect(vacio.error, isNull);
    final fallo = await ProductosRepository(
      cargar: () async => throw Exception('lectura'),
    ).consultarProductos();
    expect(fallo.usaRespaldo, isTrue);
    expect(fallo.error, isNotNull);
    expect(fallo.productos, demo.productos);
  });

  test('Reutiliza instancias por SKU y actualiza datos cambiados', () async {
    final original = demo.productos.first;
    final campos = ProductosRepository.haciaDocumento(original);
    final repository = ProductosRepository(
      cargar: () async => {original.sku: Map.of(campos)},
    );
    final primero = await repository.consultarProductos();
    expect(primero.usaRespaldo, isFalse);
    expect(identical(primero.productos.single, original), isTrue);
    campos['stock'] = 2;
    final segundo = await repository.consultarProductos();
    final tercero = await repository.consultarProductos();
    expect(segundo.productos.single.stock, 2);
    expect(
      identical(segundo.productos.single, tercero.productos.single),
      isTrue,
    );
    campos['nombre'] = null;
    final invalido = await repository.consultarProductos();
    expect(invalido.usaRespaldo, isTrue);
    expect(invalido.error, isA<FormatException>());
    expect(invalido.productos, demo.productos);
  });
}