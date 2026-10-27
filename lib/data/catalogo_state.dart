import 'package:flutter/widgets.dart';

import '../models/producto.dart';
import 'datos_demo.dart' as demo;
import 'productos_repository.dart';
import 'producto_edicion.dart';

/// Una sola lectura por ejecución, compartida por ambas interfaces.
class CatalogoState extends ChangeNotifier {
  CatalogoState(this.repository);
  final ProductosRepository repository;
  List<Producto> productos = demo.productos;
  bool usaRespaldo = true;
  bool _disposed = false;
  int _revision = 0;

  Future<void> cargar() async {
    final revision = _revision;
    final resultado = await repository.consultarProductos();
    if (_disposed || revision != _revision) return;
    productos = resultado.productos;
    usaRespaldo = resultado.usaRespaldo;
    debugPrint(
      '[Productos] Fuente: ${usaRespaldo ? 'respaldo local' : 'Firestore (servidor)'}; ${productos.length} productos',
    );
    notifyListeners();
  }

  Future<Producto> crearProducto(ProductoEdicion datos) async {
    final confirmado = await repository.crearProducto(datos);
    _incorporar(confirmado);
    return confirmado;
  }

  Future<Producto> actualizarProducto(String sku, ProductoEdicion datos) async {
    final confirmado = await repository.actualizarProducto(sku, datos);
    _incorporar(confirmado);
    return confirmado;
  }

  void _incorporar(Producto confirmado) {
    if (_disposed) return;
    ++_revision;
    final porSku = {
      for (final p in productos) p.sku: p,
      confirmado.sku: confirmado,
    };
    final orden = {
      for (var i = 0; i < demo.productos.length; i++) demo.productos[i].sku: i,
    };
    final lista = porSku.values.toList()
      ..sort((a, b) {
        final comparacion = (orden[a.sku] ?? orden.length).compareTo(
          orden[b.sku] ?? orden.length,
        );
        return comparacion != 0 ? comparacion : a.sku.compareTo(b.sku);
      });
    productos = List.unmodifiable(lista);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class CatalogoScope extends InheritedNotifier<CatalogoState> {
  const CatalogoScope({
    super.key,
    required CatalogoState catalogo,
    required super.child,
  }) : super(notifier: catalogo);
  static CatalogoState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CatalogoScope>()!.notifier!;
}
