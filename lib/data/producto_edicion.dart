import 'dart:typed_data';

/// Datos admitidos por el formulario; no contiene objetos visuales ni permisos.
class ProductoEdicion {
  ProductoEdicion({
    required String sku,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.descripcion,
    required List<String> caracteristicas,
    required List<String> compatibilidad,
    this.imagenAsset,
    this.imagenUrl,
    this.activo = true,
    this.fotografia,
  }) : sku = normalizarSku(sku),
       caracteristicas = List.unmodifiable(caracteristicas),
       compatibilidad = List.unmodifiable(compatibilidad);

  final String sku, nombre, categoria, descripcion;
  final double precio;
  final int stock;
  final List<String> caracteristicas, compatibilidad;
  final String? imagenAsset;
  final String? imagenUrl;
  final bool activo;
  final Uint8List? fotografia;

  static String normalizarSku(String valor) => valor.trim().toUpperCase();
  static String? validarSku(String valor) {
    final sku = normalizarSku(valor);
    return sku.length > 64 ||
            !RegExp(r'^[A-Z0-9]+(?:-[A-Z0-9]+)*$').hasMatch(sku)
        ? 'Ingresa un SKU de hasta 64 letras, números y guiones, sin espacios.'
        : null;
  }

  static double? leerPrecio(String valor) =>
      double.tryParse(valor.trim().replaceAll(',', '.'));
  static String? validarPrecio(String valor) {
    final numero = leerPrecio(valor);
    return numero == null || !numero.isFinite || numero <= 0
        ? 'Ingresa un precio válido mayor que cero.'
        : null;
  }

  static String? validarStock(String valor) {
    final numero = int.tryParse(valor.trim());
    return numero == null || numero < 0
        ? 'Ingresa un stock entero no negativo.'
        : null;
  }

  void validar() {
    final errorSku = validarSku(sku);
    if (errorSku != null) throw FormatException(errorSku);
    if ([nombre, categoria, descripcion].any((v) => v.trim().isEmpty)) {
      throw const FormatException('Completa nombre, categoría y descripción.');
    }
    if (!precio.isFinite || precio <= 0) {
      throw const FormatException('El precio debe ser mayor que cero.');
    }
    if (stock < 0) {
      throw const FormatException('El stock no puede ser negativo.');
    }
    if ([
      caracteristicas,
      compatibilidad,
    ].any((lista) => lista.isEmpty || lista.any((v) => v.trim().isEmpty))) {
      throw const FormatException('Completa características y compatibilidad.');
    }
  }

  Map<String, dynamic> camposEditables() => {
    'nombre': nombre.trim(),
    'activo': activo,
    if (imagenUrl != null) 'imagenUrl': imagenUrl,
    'categoria': categoria.trim(),
    'precio': precio,
    'stock': stock,
    'descripcion': descripcion.trim(),
    'caracteristicas': caracteristicas.map((v) => v.trim()).toList(),
    'compatibilidad': compatibilidad.map((v) => v.trim()).toList(),
  };
}
