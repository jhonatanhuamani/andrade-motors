import 'delivery_pedido.dart';

/// Intención local de aviso. El servidor debe comprobar el rol del emisor,
/// persistir la transición y resolver el cliente y sus tokens desde el pedido.
class DeliveryAviso {
  const DeliveryAviso._(this.pedidoId, this.clienteId, this.estado);

  static const titulo = 'ANDRADE MOTORS';
  static const tipo = 'delivery_estado';

  final String pedidoId, clienteId;
  final DeliveryEstado estado;

  String get mensaje => switch (estado) {
    DeliveryEstado.preparando => 'Tu pedido está siendo preparado.',
    DeliveryEstado.repartidorAsignado =>
      'Tu pedido ya tiene repartidor asignado.',
    DeliveryEstado.enCamino => 'Tu pedido está en camino.',
    DeliveryEstado.cerca => 'Tu pedido está cerca de tu ubicación.',
    DeliveryEstado.entregado => 'Tu pedido fue entregado.',
    DeliveryEstado.pendiente => '',
  };

  static DeliveryAviso? dePedido(DeliveryPedido pedido) {
    final clienteId = pedido.clienteId;
    if (clienteId == null ||
        clienteId.isEmpty ||
        pedido.estado == DeliveryEstado.pendiente) {
      return null;
    }
    return DeliveryAviso._(pedido.id, clienteId, pedido.estado);
  }

  /// El backend envía estos campos como data junto con notification.title/body.
  Map<String, String> get datos => {
    'tipo': tipo,
    'pedidoId': pedidoId,
    'clienteId': clienteId,
    'estado': estado.codigo,
  };

  static DeliveryAviso? desdeDatos(Map<String, dynamic> datos) {
    if (datos['tipo'] != tipo) return null;
    final pedidoId = datos['pedidoId'];
    final clienteId = datos['clienteId'];
    final estado = DeliveryEstado.values
        .where((estado) => estado.codigo == datos['estado'])
        .firstOrNull;
    if (pedidoId is! String ||
        pedidoId.trim().isEmpty ||
        clienteId is! String ||
        clienteId.trim().isEmpty ||
        estado == null ||
        estado == DeliveryEstado.pendiente) {
      return null;
    }
    return DeliveryAviso._(pedidoId, clienteId, estado);
  }
}
