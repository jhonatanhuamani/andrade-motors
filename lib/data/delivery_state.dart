import 'package:flutter/widgets.dart';

import '../models/delivery_pedido.dart';

/// Almacén en memoria, compartido por clientes y administración en esta app.
class DeliveryState extends ChangeNotifier {
  final _pedidos = <String, DeliveryPedido>{};
  int _siguiente = 0;

  List<DeliveryPedido> get pedidos =>
      _pedidos.values.toList(growable: false).reversed.toList(growable: false);

  List<DeliveryPedido> deCliente(String? clienteId) =>
      pedidos.where((p) => p.clienteId == clienteId).toList(growable: false);

  DeliveryPedido? buscar(String id) => _pedidos[id];

  DeliveryPedido confirmar({
    required String? clienteId,
    required String cliente,
    required List<DeliveryItem> items,
    required double costoDelivery,
    required DeliveryUbicacion ubicacion,
    required String direccion,
    required String referencia,
    required double distanciaKm,
  }) {
    final fecha = DateTime.now();
    final pedido = DeliveryPedido(
      id: 'DEL-${++_siguiente}',
      clienteId: clienteId,
      cliente: cliente,
      items: items,
      costoDelivery: costoDelivery,
      ubicacion: ubicacion,
      direccion: direccion,
      referencia: referencia,
      distanciaKm: distanciaKm,
      createdAt: fecha,
    );
    _pedidos[pedido.id] = pedido;
    notifyListeners();
    return pedido;
  }

  void cambiarEstado(String id, DeliveryEstado estado) {
    final pedido = _pedidos[id];
    if (pedido == null || pedido.estado == estado) return;
    _pedidos[id] = pedido.conEstado(estado);
    notifyListeners();
  }
}

class DeliveryScope extends InheritedNotifier<DeliveryState> {
  const DeliveryScope({
    super.key,
    required DeliveryState delivery,
    required super.child,
  }) : super(notifier: delivery);

  static DeliveryState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeliveryScope>()!.notifier!;
}
