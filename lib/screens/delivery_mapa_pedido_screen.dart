import 'package:flutter/material.dart';

import '../auth/session_scope.dart';
import '../data/delivery_config.dart';
import '../data/delivery_state.dart';
import '../theme/app_theme.dart';
import '../widgets/delivery_mapa.dart';
import '../widgets/premium_components.dart';

class DeliveryMapaPedidoScreen extends StatelessWidget {
  const DeliveryMapaPedidoScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    final admin = SessionScope.of(context).esAdmin;
    final pedido = admin ? DeliveryScope.of(context).buscar(pedidoId) : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación del pedido')),
      body: pedido == null
          ? const Center(child: Text('Pedido no disponible.'))
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      PremiumPanel(
                        gold: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionHeading(
                              pedido.id,
                              subtitle: pedido.estado.nombre,
                            ),
                            DeliveryMapa(entrega: pedido.ubicacion),
                            const SizedBox(height: 12),
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
                              'Distancia aproximada: ${pedido.distanciaKm.toStringAsFixed(2)} km',
                            ),
                            Text('Origen: ${pedido.ubicacion.origen.etiqueta}'),
                            if (tiendaDeliveryProvisional)
                              const Text(
                                'La ubicación de ANDRADE MOTORS es provisional.',
                                style: TextStyle(color: AppTheme.alerta),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
