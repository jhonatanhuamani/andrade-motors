enum DeliveryEstado {
  pendiente('pendiente', 'Pendiente', 'Pedido confirmado'),
  preparando('preparando', 'Preparando', 'Preparando pedido'),
  repartidorAsignado(
    'repartidor_asignado',
    'Repartidor asignado',
    'Repartidor asignado',
  ),
  enCamino('en_camino', 'En camino', 'En camino'),
  cerca('cerca', 'Cerca', 'Cerca de tu ubicación'),
  entregado('entregado', 'Entregado', 'Entregado');

  const DeliveryEstado(this.codigo, this.nombre, this.hito);

  final String codigo, nombre, hito;
}

class DeliveryItem {
  const DeliveryItem({
    required this.sku,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  final String sku, nombre;
  final int cantidad;
  final double precioUnitario;

  double get subtotal => cantidad * precioUnitario;
}

enum DeliveryOrigen {
  gps('GPS'),
  manual('Manual'),
  simulacion('Simulación');

  const DeliveryOrigen(this.etiqueta);
  final String etiqueta;
}

class DeliveryUbicacion {
  const DeliveryUbicacion({
    required this.latitud,
    required this.longitud,
    required this.actualizada,
    required this.origen,
    this.precisionMetros,
  });

  final double latitud, longitud;
  final double? precisionMetros;
  final DateTime actualizada;
  final DeliveryOrigen origen;
}

class DeliveryPedido {
  DeliveryPedido({
    required this.id,
    required this.clienteId,
    required this.cliente,
    required List<DeliveryItem> items,
    required this.costoDelivery,
    required this.ubicacion,
    required this.direccion,
    required this.referencia,
    required this.distanciaKm,
    required this.createdAt,
    this.estado = DeliveryEstado.pendiente,
  }) : items = List.unmodifiable(items);

  final String id, cliente, direccion, referencia;
  final String? clienteId;
  final List<DeliveryItem> items;
  final double costoDelivery, distanciaKm;
  final DeliveryUbicacion ubicacion;
  final DateTime createdAt;
  final DeliveryEstado estado;

  double get subtotal =>
      items.fold<double>(0, (total, item) => total + item.subtotal);
  double get total => subtotal + costoDelivery;

  DeliveryPedido conEstado(DeliveryEstado nuevo) => DeliveryPedido(
    id: id,
    clienteId: clienteId,
    cliente: cliente,
    items: items,
    costoDelivery: costoDelivery,
    ubicacion: ubicacion,
    direccion: direccion,
    referencia: referencia,
    distanciaKm: distanciaKm,
    createdAt: createdAt,
    estado: nuevo,
  );
}

String importeDelivery(double valor) => 'S/ ${valor.toStringAsFixed(2)}';
