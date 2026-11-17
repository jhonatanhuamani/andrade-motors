import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../auth/admin_auth_service.dart';
import 'datos_demo.dart' as demo;
import 'producto_edicion.dart';
import 'productos_escritura.dart';
import 'productos_fotografias.dart';

/// Una fila contiene el ID del documento y sus campos, sin objetos visuales.
typedef CargarProductos = Future<Map<String, Map<String, dynamic>>> Function();

class ResultadoProductos {
  const ResultadoProductos(
    this.productos, {
    required this.usaRespaldo,
    this.error,
  });

  final List<Producto> productos;
  final bool usaRespaldo;
  final Object? error;
}

/// No realiza lecturas ni escrituras al construir el repositorio.
class ProductosRepository {
  ProductosRepository({
    this._firestore,
    this._cargar,
    this._authService,
    this._escritura,
    this.fotografias,
  });

  final FirebaseFirestore? _firestore;
  final CargarProductos? _cargar;
  final AdminAuthService? _authService;
  final ProductosEscritura? _escritura;
  final ProductosFotografias? fotografias;
  ProductosFotografias get _fotos =>
      fotografias ?? FirebaseProductosFotografias();

  Future<void> _autorizar() async {
    final auth = _authService ?? FirebaseAdminAuthService();
    final cuenta = auth.cuentaActual;
    if (cuenta == null ||
        !await cuenta.comprobarAdmin() ||
        auth.cuentaActual?.identificador != cuenta.identificador) {
      throw const ErrorEscrituraProducto(
        'permission-denied',
        'Se requiere una sesión administrativa válida.',
      );
    }
  }

  ProductosEscritura get _almacen =>
      _escritura ??
      FirestoreProductosEscritura(_firestore ?? FirebaseFirestore.instance);

  Future<Producto> crearProducto(ProductoEdicion datos) async {
    datos.validar();
    await _autorizar();
    if (datos.imagenAsset != null &&
        !demo.productos.any((p) => p.imagenAsset == datos.imagenAsset)) {
      throw const FormatException(
        'Selecciona una imagen local existente o el respaldo visual.',
      );
    }
    final documento = {
      'sku': datos.sku,
      ...datos.camposEditables(),
      'imagenAsset': datos.imagenAsset,
      'imagenUrl': datos.imagenUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Un producto nuevo todavía no tiene reseñas.
      'rating': 0.0,
      'resenas': 0,
    };
    return _guardarConFotografia(datos, (url) async {
      if (url != null) documento['imagenUrl'] = url;
      final confirmado = await _almacen.crearSiAusente(
        datos.sku,
        documento,
        _autorizar,
      );
      return _conservarIdentidad(desdeDocumento(datos.sku, confirmado));
    });
  }

  Future<Producto> actualizarProducto(
    String skuOriginal,
    ProductoEdicion datos,
  ) async {
    datos.validar();
    if (skuOriginal != datos.sku) {
      throw const FormatException('El SKU del producto no se puede modificar.');
    }
    await _autorizar();
    final cambios = datos.camposEditables()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    return _guardarConFotografia(datos, (url) async {
      if (url != null) cambios['imagenUrl'] = url;
      final confirmado = await _almacen.actualizarExistente(
        skuOriginal,
        cambios,
        _autorizar,
      );
      return _conservarIdentidad(desdeDocumento(skuOriginal, confirmado));
    });
  }

  Future<Producto> _guardarConFotografia(
    ProductoEdicion datos,
    Future<Producto> Function(String?) guardar,
  ) async {
    String? url;
    try {
      if (datos.fotografia != null) {
        url = await _subirFotografia(datos.sku, datos.fotografia!);
      }
      return await guardar(url);
    } catch (_) {
      if (url != null) {
        try {
          await _fotos.eliminar(url);
        } catch (error) {
          debugPrint('No se pudo limpiar la fotografía sin asociar: $error');
        }
      }
      rethrow;
    }
  }

  Future<String> _subirFotografia(String id, Uint8List bytes) async {
    await _autorizar();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const FormatException(
        'La fotografia debe tener entre 1 byte y 10 MB.',
      );
    }
    return _fotos.subir(id, bytes);
  }

  final Map<String, Producto> _porSku = {
    for (final producto in demo.productos) producto.sku: producto,
  };

  Future<Map<String, Map<String, dynamic>>> _leer() async {
    final cuenta = (_authService ?? FirebaseAdminAuthService()).cuentaActual;
    final admin = cuenta != null && await cuenta.comprobarAdmin();
    Query<Map<String, dynamic>> consulta =
        (_firestore ?? FirebaseFirestore.instance).collection('productos');
    if (!admin) consulta = consulta.where('activo', isEqualTo: true);
    final snapshot = await consulta
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  /// Si la consulta falla o contiene datos inválidos, devuelve el catálogo local
  /// completo. Un catálogo vacío utiliza respaldo sin reportar un error.
  Future<ResultadoProductos> consultarProductos() async {
    try {
      final documentos = await (_cargar ?? _leer)();
      if (documentos.isEmpty) {
        return const ResultadoProductos([], usaRespaldo: false);
      }
      // Validar todo antes de actualizar la caché para evitar resultados parciales.
      final lista = [
        for (final entry in documentos.entries)
          desdeDocumento(entry.key, entry.value),
      ];
      final orden = {
        for (var i = 0; i < demo.productos.length; i++)
          demo.productos[i].sku: i,
      };
      lista.sort((a, b) {
        final comparacion = (orden[a.sku] ?? orden.length).compareTo(
          orden[b.sku] ?? orden.length,
        );
        return comparacion != 0 ? comparacion : a.sku.compareTo(b.sku);
      });
      final resultado = [for (final p in lista) _conservarIdentidad(p)];
      return ResultadoProductos(
        List.unmodifiable(resultado),
        usaRespaldo: false,
      );
    } on Exception catch (error) {
      return _respaldo(error);
    }
  }

  ResultadoProductos _respaldo([Object? error]) => ResultadoProductos(
    List.unmodifiable(demo.productos),
    usaRespaldo: true,
    error: error,
  );

  Producto _conservarIdentidad(Producto nuevo) {
    final anterior = _porSku[nuevo.sku];
    if (anterior != null &&
        _mismosCampos(anterior, nuevo) &&
        listEquals(anterior.caracteristicas, nuevo.caracteristicas) &&
        listEquals(anterior.compatibilidad, nuevo.compatibilidad)) {
      return anterior;
    }
    _porSku[nuevo.sku] = nuevo;
    return nuevo;
  }

  bool _mismosCampos(Producto a, Producto b) {
    final camposA = haciaDocumento(a)
      ..remove('caracteristicas')
      ..remove('compatibilidad');
    final camposB = haciaDocumento(b)
      ..remove('caracteristicas')
      ..remove('compatibilidad');
    return mapEquals(camposA, camposB);
  }

  /// El ID es la identidad canónica; un campo SKU contradictorio es inválido.
  static Producto desdeDocumento(String sku, Map<String, dynamic> datos) {
    T campo<T>(String nombre) {
      final valor = datos[nombre];
      if (valor is! T) throw FormatException('Campo inválido: $sku.$nombre');
      return valor;
    }

    List<String> lista(String nombre, [List<String>? defecto]) {
      if (!datos.containsKey(nombre) && defecto != null) return defecto;
      final valor = campo<List<dynamic>>(nombre);
      if (valor.any((item) => item is! String)) {
        throw FormatException('Lista inválida: $sku.$nombre');
      }
      return List<String>.unmodifiable(valor.cast<String>());
    }

    if (sku.isEmpty || (datos.containsKey('sku') && datos['sku'] != sku)) {
      throw FormatException('SKU inválido: $sku');
    }
    final imagen = datos['imagenAsset'];
    if (imagen != null && imagen is! String) {
      throw FormatException('imagenAsset inválido: $sku');
    }
    final local = demo.productos.where((p) => p.sku == sku).firstOrNull;
    final categoria = campo<String>('categoria');
    return Producto(
      sku: sku,
      nombre: campo<String>('nombre'),
      categoria: categoria,
      precio: campo<num>('precio').toDouble(),
      stock: campo<int>('stock'),
      descripcion: campo<String>('descripcion'),
      imagenAsset: imagen as String? ?? local?.imagenAsset,
      imagenUrl: datos['imagenUrl'] as String?,
      activo: datos['activo'] as bool? ?? true,
      caracteristicas: lista('caracteristicas', const []),
      compatibilidad: lista('compatibilidad', const ['Consultar por modelo']),
      rating: datos.containsKey('rating')
          ? campo<num>('rating').toDouble()
          : 4.8,
      resenas: datos.containsKey('resenas') ? campo<int>('resenas') : 120,
      icono:
          local?.icono ??
          demo.categorias[categoria] ??
          Icons.inventory_2_outlined,
    );
  }

  /// Serializa datos únicamente; este método no escribe en Firestore.
  static Map<String, dynamic> haciaDocumento(Producto producto) => {
    'sku': producto.sku,
    'nombre': producto.nombre,
    'categoria': producto.categoria,
    'precio': producto.precio,
    'stock': producto.stock,
    'descripcion': producto.descripcion,
    'imagenAsset': producto.imagenAsset,
    'imagenUrl': producto.imagenUrl,
    'activo': producto.activo,
    'caracteristicas': producto.caracteristicas,
    'compatibilidad': producto.compatibilidad,
    'rating': producto.rating,
    'resenas': producto.resenas,
  };
}
