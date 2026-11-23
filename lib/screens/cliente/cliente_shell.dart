import 'package:flutter/material.dart';

import '../../auth/session_scope.dart';
import '../../data/catalogo_state.dart';
import '../../data/favoritos_state.dart';
import '../../models/delivery_pedido.dart';
import '../../models/producto.dart';
import '../../models/servicio.dart';
import '../home_screen.dart';
import '../favoritos_screen.dart';
import '../catalogo_screen.dart';
import '../delivery_pedidos_screen.dart';
import '../delivery_seguimiento_screen.dart';
import '../delivery_ubicacion_screen.dart';
import '../producto_detalle_screen.dart';
import '../servicios_screen.dart';
import '../reserva_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_components.dart';
import '../account_screen.dart';
import 'tienda_web.dart';

class ClienteShell extends StatefulWidget {
  const ClienteShell({
    super.key,
    required this.productos,
    this.web = false,
    this.cuenta,
  });
  final bool web;
  final Widget? cuenta;
  final List<Producto> productos;
  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  List<Producto> get productos => widget.productos;
  final _favoritos = FavoritosState();
  Set<String> get favoritos => _favoritos.skus;

  static String? _clienteUid(BuildContext context) {
    final sesion = SessionScope.of(context);
    return sesion.autenticado && !sesion.esAdmin
        ? sesion.cuentaVerificada?.identificador
        : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _favoritos.cambiarCliente(_clienteUid(context));
  }

  @override
  void initState() {
    super.initState();
    _favoritos.addListener(_actualizarFavoritos);
  }

  void _actualizarFavoritos() => setState(() {});

  @override
  void dispose() {
    _favoritos.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClienteShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final porSku = {for (final p in productos) p.sku: p};
    carrito.updateAll(
      (sku, linea) =>
          (producto: porSku[sku] ?? linea.producto, cantidad: linea.cantidad),
    );
  }

  void sumarAlCarrito(Producto producto, int cantidad) {
    final sku = producto.sku;
    final actual = productos.where((p) => p.sku == sku).firstOrNull;
    carrito[sku] = (
      producto: actual ?? producto,
      cantidad: (carrito[sku]?.cantidad ?? 0) + cantidad,
    );
  }

  int indice = 0;
  void irA(int pagina) => setState(() => indice = pagina);
  String categoria = 'Todos', busqueda = '';
  int revisionCatalogo = 0, revisionReserva = 0;
  String? servicioSeleccionado;
  final carrito = <String, ({Producto producto, int cantidad})>{};
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
  void favorito(Producto p) => _favoritos.alternar(p.sku);

  void _verFavoritos() {
    final uid = _clienteUid(context);
    if (uid == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _clienteUid(context) == uid
            ? FavoritosScreen(estado: _favoritos, onProducto: detalle)
            : const Scaffold(),
      ),
    );
  }

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
      builder: (context) {
        final fuente = CatalogoScope.of(context);
        final actual = fuente.enVivo
            ? fuente.productos
                  .where((actual) => actual.sku == p.sku && actual.activo)
                  .firstOrNull
            : p;
        if (actual == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Producto')),
            body: const Center(
              child: Text('Este producto ya no está disponible.'),
            ),
          );
        }
        // En Web una ruta pública puede permanecer abierta al cambiar de sesión.
        SessionScope.of(context);
        return ListenableBuilder(
          listenable: _favoritos,
          builder: (context, _) => ProductoDetalleScreen(
            producto: actual,
            web: widget.web,
            favorito: _favoritos.contiene(p.sku),
            onFavorito: () => favorito(actual),
            onCarrito: verCarrito,
            onAgregar: (cantidad) =>
                setState(() => sumarAlCarrito(actual, cantidad)),
          ),
        );
      },
    ),
  );
  void agregarRapido(Producto p) {
    setState(() => sumarAlCarrito(p, 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${p.nombre} agregado al carrito local')),
    );
  }

  Future<void> _solicitarDelivery(BuildContext hoja) async {
    final items = [
      for (final linea in carrito.values)
        DeliveryItem(
          sku: linea.producto.sku,
          nombre: linea.producto.nombre,
          cantidad: linea.cantidad,
          precioUnitario: linea.producto.precio,
        ),
    ];
    if (items.isEmpty) return;
    Navigator.of(hoja).pop();
    final pedido = await Navigator.of(context).push<DeliveryPedido>(
      MaterialPageRoute(builder: (_) => DeliveryUbicacionScreen(items: items)),
    );
    if (!mounted || pedido == null) return;
    setState(() {
      for (final item in pedido.items) {
        final linea = carrito[item.sku];
        if (linea == null) continue;
        final restante = linea.cantidad - item.cantidad;
        if (restante <= 0) {
          carrito.remove(item.sku);
        } else {
          carrito[item.sku] = (producto: linea.producto, cantidad: restante);
        }
      }
    });
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DeliverySeguimientoScreen(pedidoId: pedido.id),
      ),
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
            height:
                MediaQuery.sizeOf(ctx).height * (carrito.isEmpty ? .65 : .78),
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
                                        IconTile(e.value.producto.icono),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.value.producto.nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${e.value.cantidad} uds. · S/ ${(e.value.producto.precio * e.value.cantidad).toStringAsFixed(2)}',
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
                        'S/ ${carrito.entries.fold<double>(0, (s, e) => s + e.value.producto.precio * e.value.cantidad).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.oro,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _solicitarDelivery(ctx),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Solicitar delivery'),
                  ),
                  const SizedBox(height: 12),
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
    final ancho = MediaQuery.sizeOf(context).width;
    final desktop = !widget.web && ancho >= 1050;
    final webAncha = widget.web && ancho > 1000;
    final footer = widget.web
        ? TiendaFooter(onPagina: irA)
        : const SizedBox.shrink();
    final perfil = widget.web && !SessionScope.of(context).autenticado
        ? 'Iniciar sesión'
        : 'Perfil';
    const paginasWeb = [0, 1, 2, 5, 4];
    const enlacesWeb = [
      (0, 'Inicio'),
      (1, 'Productos'),
      (2, 'Servicios'),
      (5, 'Contacto'),
    ];
    final content = SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.web ? anchoTienda : AppTheme.anchoContenido,
          ),
          child: IndexedStack(
            index: indice,
            children: [
              HeroMode(
                enabled: indice == 0,
                child: widget.web
                    ? InicioTiendaWeb(
                        productos: productos,
                        onCategoria: (c) => catalogo(c, ''),
                        onServicios: () => irA(2),
                        onReservar: reservar,
                        onProducto: detalle,
                        onAgregar: agregarRapido,
                        favoritos: favoritos,
                        onFavorito: favorito,
                        footer: footer,
                      )
                    : HomeScreen(
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
                  web: widget.web,
                  footer: footer,
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
              ServiciosScreen(
                onReservar: reservar,
                web: widget.web,
                footer: footer,
              ),
              ReservaScreen(
                servicioInicial: servicioSeleccionado,
                revision: revisionReserva,
              ),
              if (widget.cuenta case final acceso?)
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: MisPedidosTile(),
                    ),
                    Expanded(child: acceso),
                  ],
                )
              else
                AccountScreen(onFavoritos: _verFavoritos),
              if (widget.web) ContactoTienda(footer: footer),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: webAncha ? 70 : null,
        centerTitle: widget.web ? false : null,
        title: webAncha
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: anchoTienda),
                  child: Row(
                    children: [
                      const Expanded(child: AndradeBrand()),
                      for (final (pagina, label) in enlacesWeb)
                        TextButton(
                          onPressed: () => irA(pagina),
                          style: TextButton.styleFrom(
                            foregroundColor: indice == pagina
                                ? AppTheme.oro
                                : AppTheme.texto,
                          ),
                          child: Text(label),
                        ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: perfil,
                        onPressed: () => irA(4),
                        color: indice == 4 ? AppTheme.oro : AppTheme.texto,
                        icon: const Icon(Icons.person_outline),
                      ),
                      _botonCarrito(),
                    ],
                  ),
                ),
              )
            : const AndradeBrand(),
        actions: webAncha
            ? null
            : [
                if (!widget.web)
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
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 21,
                    ),
                  ),
                if (desktop)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Eyebrow(labels[indice], color: AppTheme.secundario),
                  ),
                _botonCarrito(),
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
      bottomNavigationBar: desktop || webAncha
          ? null
          : widget.web
          ? NavigationBar(
              selectedIndex: paginasWeb.indexOf(indice == 3 ? 2 : indice),
              onDestinationSelected: (i) => irA(paginasWeb[i]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  label: 'Productos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.build_outlined),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.contact_support_outlined),
                  label: 'Contacto',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Perfil',
                ),
              ],
            )
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

  Widget _botonCarrito() => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: IconButton.outlined(
      tooltip: 'Ver carrito',
      style: IconButton.styleFrom(
        side: const BorderSide(color: AppTheme.linea),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: verCarrito,
      icon: Badge(
        backgroundColor: AppTheme.oro,
        textColor: AppTheme.fondo,
        isLabelVisible: carrito.isNotEmpty,
        label: Text('${carrito.values.fold<int>(0, (a, b) => a + b.cantidad)}'),
        child: const Icon(Icons.shopping_bag_outlined, size: 21),
      ),
    ),
  );
}
