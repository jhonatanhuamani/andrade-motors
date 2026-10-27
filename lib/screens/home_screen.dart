import 'package:flutter/material.dart';

import '../data/datos_demo.dart' show categorias, servicios;
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_card.dart';
import '../widgets/premium_banner.dart';
import '../widgets/producto_card.dart';
import '../widgets/premium_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.productos,
    required this.onCatalogo,
    required this.onServicios,
    required this.onProducto,
    required this.favoritos,
    required this.onFavorito,
    required this.onAgregar,
  });
  final void Function(String categoria, String busqueda) onCatalogo;
  final VoidCallback onServicios;
  final void Function(Producto) onProducto, onFavorito, onAgregar;
  final List<Producto> productos;
  final Set<String> favoritos;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    children: [
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Para los que viven sobre dos ruedas'),
                SizedBox(height: 10),
                Text(
                  'Hola, motociclista.',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Todo lo que tu moto necesita, en un solo lugar.',
                  style: TextStyle(color: AppTheme.secundario, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.linea),
              color: AppTheme.superficie,
            ),
            child: const Icon(
              Icons.waving_hand_outlined,
              color: AppTheme.oro,
              size: 20,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      TextField(
        onSubmitted: (value) => onCatalogo('Todos', value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          hintText: 'Buscar repuestos, accesorios, aceites...',
          suffixIcon: IconButton(
            tooltip: 'Filtrar catálogo',
            onPressed: () => onCatalogo('Todos', ''),
            icon: const Icon(Icons.tune_rounded, size: 19),
          ),
        ),
      ),
      const SizedBox(height: 24),
      PremiumBanner(onTap: () => onCatalogo('Todos', '')),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == 0 ? 22 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: i == 0 ? AppTheme.oro : AppTheme.linea,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _Promise(Icons.verified_outlined, 'Selección de calidad'),
          _Promise(Icons.handyman_outlined, 'Soporte especializado'),
          _Promise(Icons.two_wheeler_outlined, 'Pasión por las motos'),
        ],
      ),
      const SizedBox(height: 30),
      const SectionHeading(
        'Tu moto. Tu estilo.',
        subtitle: 'Todo lo que necesitas, en un solo lugar.',
      ),
      SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categorias.length,
          separatorBuilder: (_, index) => const SizedBox(width: 10),
          itemBuilder: (_, index) {
            final e = categorias.entries.elementAt(index);
            return CategoriaCard(
              nombre: e.key,
              icono: e.value,
              onTap: () =>
                  e.key == 'Taller' ? onServicios() : onCatalogo(e.key, ''),
            );
          },
        ),
      ),
      const SizedBox(height: 30),
      SectionHeading(
        'Elegidos para ti',
        subtitle: 'Rendimiento y diseño en cada detalle.',
        action: 'Ver todo ↗',
        onAction: () => onCatalogo('Todos', ''),
      ),
      ResponsiveProductGrid(
        children: productos
            .take(4)
            .map(
              (p) => ProductoCard(
                producto: p,
                favorito: favoritos.contains(p.sku),
                onFavorito: () => onFavorito(p),
                onTap: () => onProducto(p),
                onAgregar: () => onAgregar(p),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 28),
      PremiumPanel(
        gold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                IconTile(Icons.build_circle_outlined, size: 46),
                SizedBox(width: 12),
                Expanded(child: Eyebrow('Andrade / Taller')),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Más kilómetros.\nMenos preocupaciones.',
              style: TextStyle(
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dale a tu moto el mantenimiento que merece. Elige tu servicio y agenda tu visita.',
              style: TextStyle(color: AppTheme.secundario),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onServicios,
              label: const Text('Explorar servicios y reservar'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      const SectionHeading(
        'Servicios destacados',
        subtitle: 'Servicios locales de Andrade Motors.',
      ),
      for (final servicio in servicios.take(2))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconTile(servicio.icono),
              title: Text(servicio.nombre),
              subtitle: Text(
                '${servicio.descripcion}\nS/ ${servicio.precio.toStringAsFixed(2)} · ${servicio.duracion}',
              ),
              isThreeLine: true,
              onTap: onServicios,
            ),
          ),
        ),
      const Center(
        child: Eyebrow(
          'ANDRADE MOTORS • PASIÓN EN MOVIMIENTO',
          color: AppTheme.secundario,
        ),
      ),
    ],
  );
}

class _Promise extends StatelessWidget {
  const _Promise(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppTheme.oro),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(color: AppTheme.secundario, fontSize: 9),
      ),
    ],
  );
}
