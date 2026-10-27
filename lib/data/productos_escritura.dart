import 'package:cloud_firestore/cloud_firestore.dart';

typedef AutorizarProducto = Future<void> Function();

class ErrorEscrituraProducto implements Exception {
  const ErrorEscrituraProducto(this.codigo, this.mensaje);
  final String codigo, mensaje;
  @override
  String toString() => mensaje;
}

/// Contrato atómico sustituible en pruebas, sin acceso a datos reales.
abstract interface class ProductosEscritura {
  Future<Map<String, dynamic>> crearSiAusente(
    String sku,
    Map<String, dynamic> datos,
    AutorizarProducto autorizar,
  );
  Future<Map<String, dynamic>> actualizarExistente(
    String sku,
    Map<String, dynamic> cambios,
    AutorizarProducto autorizar,
  );
}

class FirestoreProductosEscritura implements ProductosEscritura {
  FirestoreProductosEscritura(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<Map<String, dynamic>> crearSiAusente(
    String sku,
    Map<String, dynamic> datos,
    AutorizarProducto autorizar,
  ) {
    final ref = firestore.collection('productos').doc(sku);
    return firestore.runTransaction<Map<String, dynamic>>((transaction) async {
      await autorizar();
      final actual = await transaction.get(ref);
      if (actual.exists) {
        throw const ErrorEscrituraProducto(
          'sku-duplicado',
          'Ya existe un producto con ese SKU. No se sobrescribió.',
        );
      }
      transaction.set(ref, datos);
      return Map<String, dynamic>.from(datos);
    });
  }

  @override
  Future<Map<String, dynamic>> actualizarExistente(
    String sku,
    Map<String, dynamic> cambios,
    AutorizarProducto autorizar,
  ) {
    final ref = firestore.collection('productos').doc(sku);
    return firestore.runTransaction<Map<String, dynamic>>((transaction) async {
      await autorizar();
      final actual = await transaction.get(ref);
      if (!actual.exists) {
        throw const ErrorEscrituraProducto(
          'producto-inexistente',
          'El producto ya no existe. No se creó otro documento.',
        );
      }
      transaction.update(ref, cambios);
      return {...actual.data()!, ...cambios};
    });
  }
}
