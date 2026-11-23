import 'package:flutter/material.dart';

import '../auth/session_scope.dart';
import '../data/delivery_state.dart';
import '../models/delivery_pedido.dart';
import '../widgets/premium_components.dart';
import 'delivery_comprobante_screen.dart';
import 'delivery_seguimiento_screen.dart';

class MisPedidosTile extends StatelessWidget {
  const MisPedidosTile({super.key});

  @override
  Widget build(BuildContext context) => PremiumPanel(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const IconTile(Icons.receipt_long_outlined),
      title: const Text('Mis pedidos'),
      subtitle: const Text('Seguimiento del delivery'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const DeliveryPedidosScreen()),
      ),
    ),
  );
}

class DeliveryPedidosScreen extends StatelessWidget {
  const DeliveryPedidosScreen({super.key, this.administrar = false});

  final bool administrar;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (administrar && !session.esAdmin) {
      return const Center(child: Text('Acceso reservado a administración.'));
    }
    final store = DeliveryScope.of(context);
    final pedidos = administrar
        ? store.pedidos
        : store.deCliente(session.cuentaVerificada?.identificador);
    final contenido = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (administrar) const SectionHeading('Pedidos delivery'),
            const Text(
              'Pedidos de demostración disponibles en esta instancia de la app.',
            ),
            const SizedBox(height: 16),
            if (pedidos.isEmpty) const Text('Todavía no hay pedidos delivery.'),
            for (final pedido in pedidos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const IconTile(Icons.local_shipping_outlined),
                        title: Text(pedido.id),
                        subtitle: Text(
                          [
                            if (administrar) pedido.cliente,
                            importeDelivery(pedido.total),
                            '${pedido.distanciaKm.toStringAsFixed(1)} km',
                            pedido.estado.nombre,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => DeliverySeguimientoScreen(
                              pedidoId: pedido.id,
                              administrar: administrar,
                            ),
                          ),
                        ),
                      ),
                      if (administrar || session.autenticado)
                        VerComprobanteButton(
                          pedidoId: pedido.id,
                          administrar: administrar,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return administrar
        ? contenido
        : Scaffold(
            appBar: AppBar(title: const Text('Mis pedidos')),
            body: contenido,
          );
  }
}
