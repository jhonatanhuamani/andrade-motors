import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/producto_card.dart';
import '../widgets/premium_components.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({
    super.key,
    required this.productos,
    required this.categoria,
    required this.busqueda,
    required this.favoritos,
    required this.onFavorito,
    required this.onProducto,
    required this.onAgregar,
    this.web = false,
    this.footer = const SizedBox.shrink(),
  });
  final String categoria, busqueda;
  final bool web;
  final Widget footer;
  final List<Producto> productos;
  final Set<String> favoritos;
  final void Function(Producto) onFavorito, onProducto, onAgregar;
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  late String categoria = widget.categoria;
  late String busqueda = widget.busqueda;
  late final controller = TextEditingController(text: busqueda);
  String orden = 'Selección';
  bool soloFavoritos = false;
  String disponibilidad = 'Todos';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void filtros() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tu selección, a tu medida',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo mis favoritos'),
                value: soloFavoritos,
                onChanged: (v) {
                  setState(() => soloFavoritos = v);
                  refresh(() {});
                },
              ),
              const SizedBox(height: 12),
              const Eyebrow('Ordenar por'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Selección', 'Menor precio', 'Mayor precio']
                    .map(
                      (v) => ChoiceChip(
                        label: Text(v),
                        selected: orden == v,
                        onSelected: (_) {
                          setState(() => orden = v);
                          refresh(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ver resultados'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final categorias = widget.web
        ? {
            'Todos',
            ...widget.productos.map((p) => p.categoria),
            categoria,
          }.toList()
        : ['Todos', 'Repuestos', 'Accesorios', 'Cascos', 'Aceites', 'Llantas'];
    final filtrosCategoria = [
      for (final c in categorias)
        ChoiceChip(
          label: Text(c),
          selected: c == categoria,
          onSelected: (_) => setState(() => categoria = c),
        ),
    ];
    final lista = widget.productos
        .where(
          (p) =>
              (categoria == 'Todos' ||
                  p.categoria == categoria ||
                  (!widget.web &&
                      categoria == 'Cascos' &&
                      p.nombre.contains('Casco'))) &&
              ('${p.nombre} ${p.sku}'.toLowerCase().contains(
                busqueda.trim().toLowerCase(),
              )) &&
              (!soloFavoritos || widget.favoritos.contains(p.sku)) &&
              (disponibilidad == 'Todos' ||
                  (p.stock > 0) == (disponibilidad == 'En stock')),
        )
        .toList();
    if (orden == 'Menor precio') {
      lista.sort((a, b) => a.precio.compareTo(b.precio));
    }
    if (orden == 'Mayor precio') {
      lista.sort((a, b) => b.precio.compareTo(a.precio));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        PageIntro(
          kicker: 'Andrade / Tienda',
          title: widget.web ? 'Productos' : 'Catálogo',
          subtitle: 'Encuentra el componente perfecto para tu moto.',
        ),
        TextField(
          controller: controller,
          onChanged: (v) => setState(() => busqueda = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Buscar productos...',
            suffixIcon: busqueda.isEmpty
                ? IconButton(
                    tooltip: 'Filtrar productos',
                    onPressed: filtros,
                    icon: const Icon(Icons.tune_rounded, size: 19),
                  )
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      controller.clear();
                      setState(() => busqueda = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        if (widget.web) ...[
          Wrap(spacing: 8, runSpacing: 8, children: filtrosCategoria),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Disponibilidad'),
              for (final estado in ['Todos', 'En stock', 'Sin stock'])
                ChoiceChip(
                  label: Text(estado == 'Todos' ? 'Cualquier stock' : estado),
                  selected: disponibilidad == estado,
                  onSelected: (_) => setState(() => disponibilidad = estado),
                ),
            ],
          ),
        ] else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in filtrosCategoria)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: chip,
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                '${lista.length} productos',
                style: const TextStyle(
                  color: AppTheme.secundario,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              tooltip: soloFavoritos
                  ? 'Ver todos los productos'
                  : 'Solo favoritos',
              onPressed: () => setState(() => soloFavoritos = !soloFavoritos),
              icon: Icon(
                soloFavoritos
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 19,
                color: soloFavoritos ? AppTheme.oro : AppTheme.secundario,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ordenar productos',
              initialValue: orden,
              onSelected: (v) => setState(() => orden = v),
              itemBuilder: (_) => [
                'Selección',
                'Menor precio',
                'Mayor precio',
              ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
              child: Row(
                children: [
                  Text(
                    orden,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (lista.isEmpty)
          PremiumPanel(
            child: Column(
              children: [
                const IconTile(Icons.search_off_rounded, size: 60),
                const SizedBox(height: 18),
                const Text(
                  'Una nueva búsqueda, otra posibilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Prueba otra categoría o cambia los términos de búsqueda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.secundario),
                ),
                TextButton(
                  onPressed: () {
                    controller.clear();
                    setState(() {
                      busqueda = '';
                      categoria = 'Todos';
                      soloFavoritos = false;
                      disponibilidad = 'Todos';
                    });
                  },
                  child: const Text('Ver toda la colección'),
                ),
              ],
            ),
          ),
        ResponsiveProductGrid(
          web: widget.web,
          children: lista
              .map(
                (p) => ProductoCard(
                  producto: p,
                  web: widget.web,
                  favorito: widget.favoritos.contains(p.sku),
                  onFavorito: () => widget.onFavorito(p),
                  onTap: () => widget.onProducto(p),
                  onAgregar: () => widget.onAgregar(p),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 26),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, color: AppTheme.oro, size: 14),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                'Una selección pensada para cada kilómetro.',
                style: TextStyle(color: AppTheme.secundario, fontSize: 11),
              ),
            ),
          ],
        ),
        widget.footer,
      ],
    );
  }
}
