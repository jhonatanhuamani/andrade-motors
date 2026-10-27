import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';
import 'premium_components.dart';
import 'producto_preview.dart';

/// Presentación del catálogo original con edición y fotografía local conservada.
class AdminProductoCard extends StatelessWidget {
  const AdminProductoCard({super.key, required this.producto, this.onEditar});
  final Producto producto;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context);
    final bajo = producto.stock <= 5;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.linea),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.elevado,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductoPreview(producto: producto, height: 212),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(
                      bajo ? 'Stock bajo' : producto.categoria,
                      color: bajo ? AppTheme.alerta : AppTheme.oro,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.sku,
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: AppTheme.secundario,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: escala.scale(13) * 2.8,
                    child: Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: escala.scale(22) * 1.3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        producto.precioTexto,
                        style: const TextStyle(
                          color: AppTheme.oro,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    '${producto.stock} uds.',
                    color: bajo ? AppTheme.alerta : AppTheme.verde,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: escala.scale(11) * 4.5,
                    child: Text(
                      producto.descripcion,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppTheme.secundario,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'GESTIÓN DEL PRODUCTO',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: .7,
                      color: AppTheme.secundario,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final accion in [
                    (Icons.edit_outlined, 'Editar producto'),
                    (Icons.photo_library_outlined, 'Fotografías · pendiente'),
                    (
                      Icons.toggle_off_outlined,
                      'Activar / desactivar · pendiente',
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: accion.$1 == Icons.edit_outlined
                              ? ValueKey('editar-${producto.sku}')
                              : null,
                          onPressed: accion.$1 == Icons.edit_outlined
                              ? onEditar
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.oro,
                            disabledForegroundColor: AppTheme.oro.withValues(
                              alpha: .5,
                            ),
                            side: BorderSide(
                              color: AppTheme.oro.withValues(alpha: .16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(accion.$1, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  accion.$2,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
