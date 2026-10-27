import 'dart:async';

import 'package:andrade_motors/data/productos_escritura.dart';

/// Almacen atomico en memoria. No utiliza el SDK ni accede a Firebase real.
class MemoryFirestore implements ProductosEscritura {
  MemoryFirestore({Map<String, Map<String, dynamic>>? datos})
    : documentos = {
        for (final entry in (datos ?? <String, Map<String, dynamic>>{}).entries)
          entry.key: Map<String, dynamic>.from(entry.value),
      };

  final Map<String, Map<String, dynamic>> documentos;
  Future<void> _cola = Future.value();
  Object? error;
  int confirmaciones = 0, sets = 0, updates = 0;
  final camposActualizados = <Set<String>>[];

  @override
  Future<Map<String, dynamic>> crearSiAusente(
    String sku,
    Map<String, dynamic> datos,
    AutorizarProducto autorizar,
  ) => _operar(sku, datos, autorizar, crear: true);

  @override
  Future<Map<String, dynamic>> actualizarExistente(
    String sku,
    Map<String, dynamic> cambios,
    AutorizarProducto autorizar,
  ) => _operar(sku, cambios, autorizar, crear: false);

  Future<Map<String, dynamic>> _operar(
    String sku,
    Map<String, dynamic> datos,
    AutorizarProducto autorizar, {
    required bool crear,
  }) async {
    final anterior = _cola;
    final fin = Completer<void>();
    _cola = fin.future;
    await anterior;
    try {
      if (error != null) throw error!;
      await autorizar();
      if (crear && documentos.containsKey(sku)) {
        throw const ErrorEscrituraProducto(
          'sku-duplicado',
          'Ya existe un producto con ese SKU. No se sobrescribió.',
        );
      }
      if (!crear && !documentos.containsKey(sku)) {
        throw const ErrorEscrituraProducto(
          'producto-inexistente',
          'El producto ya no existe.',
        );
      }
      final confirmado = <String, dynamic>{
        if (!crear) ...documentos[sku]!,
        ...datos,
      };
      documentos[sku] = confirmado;
      if (crear) {
        sets++;
      } else {
        updates++;
        camposActualizados.add(datos.keys.toSet());
      }
      confirmaciones++;
      return Map<String, dynamic>.from(confirmado);
    } finally {
      fin.complete();
    }
  }
}
