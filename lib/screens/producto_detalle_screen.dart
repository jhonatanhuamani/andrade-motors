import 'package:flutter/material.dart';

import '../data/contacto_tienda.dart';
import '../models/producto.dart';
import 'cliente/tienda_web.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';
import '../widgets/producto_preview.dart';

class ProductoDetalleScreen extends StatefulWidget {
  const ProductoDetalleScreen({
    super.key,
    required this.producto,
    required this.onAgregar,
    required this.favorito,
    required this.onFavorito,
    required this.onCarrito,
    this.web = false,
  });
  final Producto producto;
  final bool web;
  final bool favorito;
  final VoidCallback onFavorito, onCarrito;
  final void Function(int) onAgregar;
  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  int cantidad = 1;
  @override
  void didUpdateWidget(covariant ProductoDetalleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    cantidad = cantidad.clamp(
      1,
      widget.producto.stock > 0 ? widget.producto.stock : 1,
    );
  }

  void agregar() {
    widget.onAgregar(cantidad);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$cantidad × ${widget.producto.nombre} agregado al carrito local',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final favorito = widget.favorito;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: favorito ? 'Quitar favorito' : 'Guardar favorito',
            onPressed: widget.onFavorito,
            icon: Icon(
              favorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorito ? AppTheme.oro : AppTheme.texto,
            ),
          ),
          IconButton(
            tooltip: 'Ver carrito',
            onPressed: widget.onCarrito,
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 12),
        ],
        title: const Text(
          'Selección Andrade',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.web ? anchoTienda : AppTheme.anchoContenido,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final preview = ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'producto-${p.sku}',
                          child: ProductoPreview(
                            producto: p,
                            height: constraints.maxWidth > 700 ? 430 : 310,
                            large: true,
                          ),
                        ),
                        const Positioned(
                          left: 18,
                          top: 18,
                          child: StatusPill(
                            'EDICIÓN ANDRADE',
                            color: AppTheme.oro,
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                        Positioned(
                          right: 18,
                          bottom: 16,
                          child: Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white.withValues(alpha: .3),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  );
                  final info = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('${p.categoria} / Colección esencial'),
                      const SizedBox(height: 12),
                      Text(
                        p.nombre,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          StatusPill(
                            p.stock > 0
                                ? 'Disponible · ${p.stock} unidades'
                                : 'Sin stock',
                            color: p.stock > 5
                                ? AppTheme.verde
                                : AppTheme.alerta,
                          ),
                          const StatusPill(
                            'Selección premium',
                            color: AppTheme.oro,
                            icon: Icons.verified_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        p.precioTexto,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                          color: AppTheme.oro,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Precio por unidad  /  SKU: ${p.sku}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.secundario,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.oro,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${p.rating} (${p.resenas} reseñas demo)',
                              style: const TextStyle(
                                color: AppTheme.secundario,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Eyebrow('DESCRIPCIÓN'),
                      const SizedBox(height: 10),
                      Text(
                        p.descripcion,
                        style: const TextStyle(
                          color: AppTheme.secundario,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Cantidad',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.linea),
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.superficie,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Disminuir cantidad',
                                  onPressed: cantidad > 1
                                      ? () => setState(() => cantidad--)
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Center(
                                    child: Text(
                                      '$cantidad',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Aumentar cantidad',
                                  onPressed: cantidad < p.stock
                                      ? () => setState(() => cantidad++)
                                      : null,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: p.stock == 0 ? null : agregar,
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                          ),
                          label: const Text('Agregar al carrito'),
                        ),
                      ),
                      if (widget.web) ...[
                        const SizedBox(height: 10),
                        BotonWhatsApp(
                          etiqueta: 'Consultar por WhatsApp',
                          mensaje:
                              'Hola, quisiera consultar por ${p.nombre} (${p.sku}).',
                        ),
                      ],
                      const SizedBox(height: 9),
                      Center(
                        child: Text(
                          'Total: S/ ${(p.precio * cantidad).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.secundario,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  );
                  return constraints.maxWidth > 700
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: preview),
                            const SizedBox(width: 32),
                            Expanded(child: info),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [preview, const SizedBox(height: 26), info],
                        );
                },
              ),
              const SizedBox(height: 30),
              const SectionHeading(
                'Características',
                subtitle: 'Conoce lo que estás llevando.',
              ),
              PremiumPanel(
                child: Column(
                  children: p.caracteristicas
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: EdgeInsets.only(top: e.key == 0 ? 0 : 16),
                          child: Row(
                            children: [
                              const IconTile(Icons.check_rounded, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 26),
              const SectionHeading('Compatible con'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.compatibilidad
                    .map((c) => Chip(label: Text(c)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              const Text(
                '* La compatibilidad depende de la referencia, medida y modelo. Confírmala con el taller.',
                style: TextStyle(color: AppTheme.secundario, fontSize: 11),
              ),
              const SizedBox(height: 24),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatusPill(
                    'Envío seguro',
                    icon: Icons.local_shipping_outlined,
                    color: AppTheme.secundario,
                  ),
                  StatusPill(
                    'Garantía',
                    icon: Icons.verified_user_outlined,
                    color: AppTheme.secundario,
                  ),
                  StatusPill(
                    'Atención especializada',
                    icon: Icons.support_agent,
                    color: AppTheme.secundario,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const PremiumPanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(Icons.support_agent_rounded),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'La pieza correcta para tu moto',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Verifica la medida, talla y compatibilidad con tu modelo antes de comprar. Nuestro taller puede orientarte.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
