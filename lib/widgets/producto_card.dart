import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';
import 'producto_preview.dart';

class ProductoCard extends StatefulWidget {
  const ProductoCard({
    super.key,
    required this.producto,
    required this.favorito,
    required this.onFavorito,
    required this.onTap,
    this.onAgregar,
    this.web = false,
  });
  final Producto producto;
  final bool web;
  final bool favorito;
  final VoidCallback onFavorito, onTap;
  final VoidCallback? onAgregar;
  @override
  State<ProductoCard> createState() => _ProductoCardState();
}

class _ProductoCardState extends State<ProductoCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final textScaler = MediaQuery.textScalerOf(context);
    final stockColor = p.stock <= 5 ? AppTheme.alerta : AppTheme.verde;
    final imagen = Stack(
      fit: widget.web ? StackFit.expand : StackFit.loose,
      children: [
        Hero(
          tag: 'producto-${p.sku}',
          child: ProductoPreview(producto: p, height: widget.web ? 195 : 212),
        ),
        Positioned(
          top: 9,
          left: 9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111418).withValues(alpha: .85),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              p.stock <= 5 ? 'STOCK BAJO' : 'PREMIUM',
              style: TextStyle(
                color: p.stock <= 5 ? AppTheme.alerta : AppTheme.oro,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            tooltip: widget.favorito ? 'Quitar favorito' : 'Guardar favorito',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF111418).withValues(alpha: .7),
            ),
            onPressed: widget.onFavorito,
            icon: Icon(
              widget.favorito
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: widget.favorito ? AppTheme.oro : Colors.white70,
              size: 17,
            ),
          ),
        ),
      ],
    );
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hover ? AppTheme.oro.withValues(alpha: .6) : AppTheme.linea,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hover ? .3 : .1),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppTheme.elevado,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.web) Expanded(child: imagen) else imagen,
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.categoria.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.secundario,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: textScaler.scale(13) * 2.8,
                        child: Text(
                          p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: textScaler.scale(22) * 1.3,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            p.precioTexto,
                            style: const TextStyle(
                              color: AppTheme.oro,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: p.stock <= 5
                                  ? AppTheme.alerta
                                  : AppTheme.verde,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Stock: ${p.stock} uds.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: stockColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.tonal(
                          onPressed: p.stock > 0 ? widget.onAgregar : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.oro.withValues(
                              alpha: .12,
                            ),
                            foregroundColor: AppTheme.oro,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: AppTheme.oro.withValues(alpha: .25),
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_shopping_cart_rounded, size: 18),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Agregar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.web)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: widget.onTap,
                            child: const Text('Ver producto'),
                          ),
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
