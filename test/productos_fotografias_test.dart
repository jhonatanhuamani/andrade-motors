import 'dart:typed_data';

import 'package:andrade_motors/data/producto_edicion.dart';
import 'package:andrade_motors/data/productos_fotografias.dart';
import 'package:andrade_motors/data/productos_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_admin_auth.dart';
import 'support/memory_firestore.dart';

class FotosMemoria implements ProductosFotografias {
  final subidas = <String>[];
  final eliminadas = <String>[];
  bool fallar = false;
  @override
  Future<String> subir(String id, Uint8List bytes) async {
    if (fallar) throw Exception('Sin conexion');
    subidas.add(id);
    return 'https://example.com/$id/${subidas.length}.png';
  }

  @override
  Future<void> eliminar(String url) async {
    eliminadas.add(url);
  }
}

ProductoEdicion datos({Uint8List? foto, bool activo = true}) => ProductoEdicion(
  sku: 'REAL-001',
  nombre: 'Producto real',
  categoria: 'Repuestos',
  precio: 50,
  stock: 10,
  descripcion: 'Producto con fotografia',
  caracteristicas: ['Original'],
  compatibilidad: ['Consultar'],
  fotografia: foto,
  activo: activo,
);

void main() {
  late FakeAdminAuth auth;
  late MemoryFirestore db;
  late FotosMemoria fotos;
  late ProductosRepository repo;
  setUp(() {
    auth = FakeAdminAuth(cuenta: FakeCuentaAdmin(true));
    db = MemoryFirestore();
    fotos = FotosMemoria();
    repo = ProductosRepository(
      authService: auth,
      escritura: db,
      fotografias: fotos,
      cargar: () async => db.documentos,
    );
  });
  tearDown(() => auth.dispose());
  test(
    'Crear con foto, editar sin foto y reemplazar conserva URL y activo',
    () async {
      final creado = await repo.crearProducto(
        datos(foto: Uint8List.fromList([1])),
      );
      expect(creado.imagenUrl, 'https://example.com/REAL-001/1.png');
      final editado = await repo.actualizarProducto(
        'REAL-001',
        datos(activo: false),
      );
      expect(editado.imagenUrl, creado.imagenUrl);
      expect(editado.activo, isFalse);
      expect(fotos.subidas, hasLength(1));
      final reemplazado = await repo.actualizarProducto(
        'REAL-001',
        datos(foto: Uint8List.fromList([2])),
      );
      expect(reemplazado.imagenUrl, 'https://example.com/REAL-001/2.png');
      expect(
        (await repo.consultarProductos()).productos.single.imagenUrl,
        reemplazado.imagenUrl,
      );
    },
  );
  test('Fallo de subida no crea documento; fallo de escritura limpia solo foto nueva', () async {
    fotos.fallar = true;
    await expectLater(
      repo.crearProducto(datos(foto: Uint8List.fromList([1]))),
      throwsException,
    );
    expect(db.documentos, isEmpty);
    fotos.fallar = false;
    db.error = Exception('Firestore sin conexion');
    await expectLater(
      repo.crearProducto(datos(foto: Uint8List.fromList([1]))),
      throwsException,
    );
    expect(db.documentos, isEmpty);
    expect(fotos.eliminadas, ['https://example.com/REAL-001/1.png']);
  });
  test(
    'Lee al menos 50 documentos con esquema minimo sin assets locales',
    () async {
      final repo50 = ProductosRepository(
        cargar: () async => {
          for (var i = 0; i < 50; i++)
            'REAL-$i': {
              'nombre': 'Producto $i',
              'categoria': 'Repuestos',
              'descripcion': 'Real',
              'precio': 25,
              'stock': i,
              'activo': true,
              'imagenUrl': 'https://example.com/$i.png',
            },
        },
      );
      final resultado = await repo50.consultarProductos();
      expect(resultado.usaRespaldo, isFalse);
      expect(resultado.productos, hasLength(50));
    },
  );
}
