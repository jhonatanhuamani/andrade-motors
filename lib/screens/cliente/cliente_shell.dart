import 'package:flutter/material.dart';

import '../../models/producto.dart';
import '../../models/servicio.dart';
import '../home_screen.dart';
import '../catalogo_screen.dart';
import '../producto_detalle_screen.dart';
import '../servicios_screen.dart';
import '../reserva_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_components.dart';
import '../account_screen.dart';

class ClienteShell extends StatefulWidget {
  const ClienteShell({super.key, required this.productos});
  final List<Producto> productos;
  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  List<Producto> get productos => widget.productos;

  @override
  void didUpdateWidget(covariant ClienteShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final porSku = {for (final p in productos) p.sku: p};
    final actualizado = <Producto, int>{};
    for (final entry in carrito.entries) {
      final producto = porSku[entry.key.sku] ?? entry.key;
      actualizado.update(
        producto,
        (v) => v + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    carrito
      ..clear()
      ..addAll(actualizado);
  }

  void sumarAlCarrito(Producto producto, int cantidad) {
    final actual = productos.where((p) => p.sku == producto.sku).firstOrNull;
    final clave = carrito.keys.where((p) => p.sku == producto.sku).firstOrNull;
    final acumulado = clave == null ? 0 : carrito.remove(clave)!;
    carrito[actual ?? producto] = acumulado + cantidad;
  }

  int indice = 0;
  String categoria = 'Todos', busqueda = '';
  int revisionCatalogo = 0, revisionReserva = 0;
  String? servicioSeleccionado;
  final favoritos = <String>{};
  final carrito = <Producto, int>{};
  static const labels = [
    'Inicio',
    'Catálogo',
    'Servicios',
    'Reservas',
    'Perfil',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.grid_view_outlined,
    Icons.build_outlined,
    Icons.calendar_month_outlined,
    Icons.person_outline,
  ];
  static const selectedIcons = [
    Icons.home,
    Icons.grid_view_rounded,
    Icons.build,
    Icons.calendar_month,
    Icons.person,
  ];
  void favorito(Producto p) => setState(() {
    if (!favoritos.add(p.sku)) favoritos.remove(p.sku);
  });
  void catalogo(String c, String b) => setState(() {
    categoria = c;
    busqueda = b;
    revisionCatalogo++;
    indice = 1;
  });
  void reservar(Servicio s) => setState(() {
    servicioSeleccionado = s.nombre;
    revisionReserva++;
    indice = 3;
  });
  void detalle(Producto p) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => ProductoDetalleScreen(
        producto: p,
        favorito: favoritos.contains(p.sku),
        onFavorito: () => favorito(p),
        onCarrito: verCarrito,
        onAgregar: (cantidad) => setState(() => sumarAlCarrito(p, cantidad)),
      ),
    ),
  );
  void agregarRapido(Producto p) {
    setState(() => sumarAlCarrito(p, 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.nombre} agregado al carrito local')),
    );
  }

  void verCarrito() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, refresh) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Eyebrow('Andrade / Tu selección'),
                const SizedBox(height: 10),
                const Text(
                  'Listo para tu próxima ruta.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: carrito.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconTile(Icons.shopping_bag_outlined, size: 70),
                              SizedBox(height: 20),
                              Text(
                                'Tu próxima aventura empieza aquí.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Descubre la colección y elige tus favoritos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.secundario),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: carrito.entries
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PremiumPanel(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        IconTile(e.key.icono),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.key.nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${e.value} uds. · S/ ${(e.key.precio * e.value).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: AppTheme.oro,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Quitar del carrito',
                                          onPressed: () {
                                            setState(
                                              () => carrito.remove(e.key),
                                            );
                                            refresh(() {});
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 17,
                                            color: AppTheme.secundario,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                if (carrito.isNotEmpty) ...[
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(child: Text('Total de tu selección')),
                      Text(
                        'S/ ${carrito.entries.fold<double>(0, (s, e) => s + e.key.precio * e.value).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.oro,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Carrito local del prototipo. No se realizan cobros.',
                  style: TextStyle(color: AppTheme.secundario, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1050;
    final content = SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.anchoContenido),
          child: IndexedStack(
            index: indice,
            children: [
              HeroMode(
                enabled: indice == 0,
                child: HomeScreen(
                  productos: productos,
                  onCatalogo: catalogo,
                  onServicios: () => setState(() => indice = 2),
                  onProducto: detalle,
                  onAgregar: agregarRapido,
                  favoritos: favoritos,
                  onFavorito: favorito,
                ),
              ),
              HeroMode(
                enabled: indice == 1,
                child: CatalogoScreen(
                  productos: productos,
                  key: ValueKey(revisionCatalogo),
                  categoria: categoria,
                  busqueda: busqueda,
                  favoritos: favoritos,
                  onFavorito: favorito,
                  onProducto: detalle,
                  onAgregar: agregarRapido,
                ),
              ),
              ServiciosScreen(onReservar: reservar),
              ReservaScreen(
                servicioInicial: servicioSeleccionado,
                revision: revisionReserva,
              ),
              const AccountScreen(),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.gradienteOro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Color(0xFF231C12),
                size: 29,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANDRADE MOTORS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'PASIÓN EN MOVIMIENTO',
                    style: TextStyle(
                      color: AppTheme.oro,
                      fontSize: 7,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: AppTheme.oro,
                        size: 32,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Estás al día',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aquí encontrarás las novedades de ANDRADE MOTORS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.secundario),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded, size: 21),
          ),
          if (desktop)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Eyebrow(labels[indice], color: AppTheme.secundario),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.outlined(
              tooltip: 'Ver carrito',
              style: IconButton.styleFrom(
                side: const BorderSide(color: AppTheme.linea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: verCarrito,
              icon: Badge(
                backgroundColor: AppTheme.oro,
                textColor: AppTheme.fondo,
                isLabelVisible: carrito.isNotEmpty,
                label: Text('${carrito.values.fold<int>(0, (a, b) => a + b)}'),
                child: const Icon(Icons.shopping_bag_outlined, size: 21),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.linea.withValues(alpha: .6),
          ),
        ),
      ),
      body: desktop
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: AppTheme.fondo,
                  selectedIndex: indice,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (v) => setState(() => indice = v),
                  selectedIconTheme: const IconThemeData(color: AppTheme.oro),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.oro,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppTheme.secundario,
                    fontSize: 11,
                  ),
                  indicatorColor: AppTheme.oro.withValues(alpha: .13),
                  destinations: List.generate(
                    5,
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      selectedIcon: Icon(selectedIcons[i]),
                      label: Text(labels[i]),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: desktop
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.linea)),
              ),
              child: NavigationBar(
                selectedIndex: indice,
                onDestinationSelected: (v) => setState(() => indice = v),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: List.generate(
                  5,
                  (i) => NavigationDestination(
                    icon: Icon(icons[i]),
                    selectedIcon: Icon(selectedIcons[i]),
                    label: labels[i],
                  ),
                ),
              ),
            ),
    );
  }
}
