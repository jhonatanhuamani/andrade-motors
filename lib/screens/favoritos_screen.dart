import 'package:flutter/material.dart';

import '../data/catalogo_state.dart';
import '../data/favoritos_state.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';
import '../widgets/producto_preview.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({
    super.key,
    required this.estado,
    required this.onProducto,
  });

  final FavoritosState estado;
  final ValueChanged<Producto> onProducto;

  @override
  Widget build(BuildContext context) {
    final catalogo = CatalogoScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Mis favoritos'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: estado,
          builder: (context, _) {
            final productos = catalogo.productos
                .where((p) => p.activo && estado.contiene(p.sku))
                .toList();
            if (productos.isEmpty) {
              return Center(
                child: estado.cargando
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          estado.skus.isEmpty
                              ? 'Todavía no has guardado productos favoritos.'
                              : 'Tus productos favoritos no están disponibles.',
                          textAlign: TextAlign.center,
                        ),
                      ),
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: productos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = productos[index];
                    return PremiumPanel(
                      key: ValueKey(p.sku),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 64,
                            child: ProductoPreview(producto: p, height: 72),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.nombre),
                                Text(
                                  p.precioTexto,
                                  style: const TextStyle(color: AppTheme.oro),
                                ),
                                Text('Stock: ${p.stock} uds.'),
                                TextButton(
                                  onPressed: () => onProducto(p),
                                  child: const Text('Ver producto'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar de favoritos',
                            color: AppTheme.oro,
                            onPressed: () => estado.alternar(p.sku),
                            icon: const Icon(Icons.favorite_rounded),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
