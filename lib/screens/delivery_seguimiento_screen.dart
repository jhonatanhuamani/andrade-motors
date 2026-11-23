import 'package:flutter/material.dart';

import '../auth/session_scope.dart';
import '../data/delivery_state.dart';
import '../models/delivery_pedido.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';
import 'delivery_mapa_pedido_screen.dart';
import 'delivery_comprobante_screen.dart';

class DeliverySeguimientoScreen extends StatelessWidget {
  const DeliverySeguimientoScreen({
    super.key,
    required this.pedidoId,
    this.administrar = false,
  });

  final String pedidoId;
  final bool administrar;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final store = DeliveryScope.of(context);
    final pedido = store.buscar(pedidoId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          administrar ? 'Pedido delivery' : 'Seguimiento del delivery',
        ),
      ),
      body:
          pedido == null ||
              (administrar
                  ? !session.esAdmin
                  : pedido.clienteId != session.cuentaVerificada?.identificador)
          ? const Center(child: Text('Pedido no disponible.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    PremiumPanel(
                      gold: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeading(
                            pedido.id,
                            subtitle: pedido.estado.nombre,
                          ),
                          if (administrar) Text('Cliente: ${pedido.cliente}'),
                          Text('Total: ${importeDelivery(pedido.total)}'),
                          Text('Dirección: ${pedido.direccion}'),
                          Text(
                            'Referencia: ${pedido.referencia.isEmpty ? '—' : pedido.referencia}',
                          ),
                          Text(
                            'Latitud: ${pedido.ubicacion.latitud.toStringAsFixed(6)}',
                          ),
                          Text(
                            'Longitud: ${pedido.ubicacion.longitud.toStringAsFixed(6)}',
                          ),
                          Text(
                            'Distancia aproximada: ${pedido.distanciaKm.toStringAsFixed(1)} km',
                          ),
                          Text('Origen: ${pedido.ubicacion.origen.etiqueta}'),
                          if (administrar || session.autenticado)
                            VerComprobanteButton(
                              pedidoId: pedido.id,
                              administrar: administrar,
                            ),
                          if (administrar) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => DeliveryMapaPedidoScreen(
                                    pedidoId: pedido.id,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Ver ubicación'),
                            ),
                            const SizedBox(height: 12),
                            const Text('Estado del pedido'),
                            DropdownButton<DeliveryEstado>(
                              value: pedido.estado,
                              isExpanded: true,
                              onChanged: (estado) {
                                if (estado != null &&
                                    SessionScope.of(context).esAdmin) {
                                  store.cambiarEstado(pedido.id, estado);
                                }
                              },
                              items: [
                                for (final estado in DeliveryEstado.values)
                                  DropdownMenuItem(
                                    value: estado,
                                    child: Text(estado.nombre),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LineaDeTiempo(pedido: pedido),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LineaDeTiempo extends StatelessWidget {
  const _LineaDeTiempo({required this.pedido});

  final DeliveryPedido pedido;

  @override
  Widget build(BuildContext context) {
    // Datos de demostración: ningún repartidor transmite ubicación en vivo.
    final (fraccion, minutos) = switch (pedido.estado) {
      DeliveryEstado.pendiente => (1.0, 45),
      DeliveryEstado.preparando => (1.0, 35),
      DeliveryEstado.repartidorAsignado => (1.0, 25),
      DeliveryEstado.enCamino => (.55, 15),
      DeliveryEstado.cerca => (.12, 4),
      DeliveryEstado.entregado => (0.0, 0),
    };
    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            'Estado de entrega',
            subtitle: 'Seguimiento demostrativo',
          ),
          Text(
            'Distancia restante simulada: ${(pedido.distanciaKm * fraccion).toStringAsFixed(1)} km',
          ),
          Text('Tiempo estimado simulado: $minutos min'),
          const SizedBox(height: 12),
          for (final estado in DeliveryEstado.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                estado == pedido.estado
                    ? Icons.radio_button_checked
                    : estado.index < pedido.estado.index
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: estado == pedido.estado
                    ? AppTheme.oro
                    : AppTheme.secundario,
              ),
              title: Text(
                estado.hito,
                style: TextStyle(
                  color: estado == pedido.estado
                      ? AppTheme.oro
                      : AppTheme.texto,
                  fontWeight: estado == pedido.estado
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: estado == pedido.estado
                  ? const Text('Estado actual')
                  : null,
            ),
        ],
      ),
    );
  }
}
