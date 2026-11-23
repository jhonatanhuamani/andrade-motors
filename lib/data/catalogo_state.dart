import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/producto.dart';
import 'datos_demo.dart' as demo;
import 'productos_repository.dart';
import 'producto_edicion.dart';

/// Catálogo compartido; se recarga al cambiar la sesión.
class CatalogoState extends ChangeNotifier {
  CatalogoState(this.repository, {this.enVivo = false});
  final bool enVivo;
  final ProductosRepository repository;
  List<Producto> productos = demo.productos;
  bool usaRespaldo = true;
  bool _disposed = false;
  int _revision = 0;
  bool? _admin;
  String? _cuenta;
  int _demoraReintento = 15;
  StreamSubscription<ResultadoProductos>? _suscripcion;
  Timer? _reintento;

  void observar({required bool admin, String? cuenta}) {
    if (_disposed || (_admin == admin && _cuenta == cuenta)) return;
    _admin = admin;
    _cuenta = cuenta;
    _demoraReintento = 15;
    _reintento?.cancel();
    if (!admin && productos.any((producto) => !producto.activo)) {
      productos = List.unmodifiable(productos.where((p) => p.activo));
      notifyListeners();
    }
    _conectar(admin);
  }

  void _conectar(bool admin) {
    final revision = ++_revision;
    unawaited(_suscripcion?.cancel());
    void reconectar() {
      if (_disposed || revision != _revision) return;
      if (_reintento?.isActive ?? false) return;
      _reintento = Timer(
        Duration(seconds: _demoraReintento),
        () => _conectar(admin),
      );
      _demoraReintento = (_demoraReintento * 2).clamp(15, 300);
    }

    _suscripcion = repository
        .observarProductos(admin: admin)
        .listen(
          (resultado) {
            if (_disposed || revision != _revision) return;
            if (!resultado.usaRespaldo) _demoraReintento = 15;
            // Un error transitorio no reemplaza datos ya confirmados.
            if (resultado.usaRespaldo && !usaRespaldo) return;
            _publicar(resultado);
          },
          onError: (Object error) {
            debugPrint('[Productos] Error al escuchar Firestore: $error');
            reconectar();
          },
          onDone: reconectar,
        );
  }

  Future<void> cargar() async {
    final revision = ++_revision;
    final resultado = await repository.consultarProductos();
    if (_disposed || revision != _revision) return;
    _publicar(resultado);
  }

  void _publicar(ResultadoProductos resultado) {
    if (usaRespaldo == resultado.usaRespaldo &&
        listEquals(productos, resultado.productos)) {
      return;
    }
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
    if (enVivo) return;
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
    _reintento?.cancel();
    unawaited(_suscripcion?.cancel());
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
