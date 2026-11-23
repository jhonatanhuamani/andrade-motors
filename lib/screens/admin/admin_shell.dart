import 'package:flutter/material.dart';

import '../../auth/session_scope.dart';
import '../../models/producto.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_components.dart';
import '../account_screen.dart';
import '../delivery_pedidos_screen.dart';
import '../inventario_screen.dart';
import 'admin_modules.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.productos,
    required this.usaRespaldo,
    this.moduloInicial = 0,
  });
  final List<Producto> productos;
  final bool usaRespaldo;
  final int moduloInicial;
  static const modulos = [
    'Panel principal',
    'Productos',
    'Servicios',
    'Inventario',
    'Usuarios',
    'Reservas',
    'Pedidos',
    'Configuración',
  ];
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int indice = widget.moduloInicial;
  final visitados = <int>{};
  static const iconos = [
    Icons.dashboard_outlined,
    Icons.grid_view_outlined,
    Icons.build_outlined,
    Icons.inventory_2_outlined,
    Icons.people_outline,
    Icons.calendar_month_outlined,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];

  Widget modulo(int i) => switch (i) {
    0 => AdminDashboard(
      productos: widget.productos,
      usaRespaldo: widget.usaRespaldo,
      onProductos: () => setState(() => indice = 1),
      onInventario: () => setState(() => indice = 3),
      onServicios: () => setState(() => indice = 2),
    ),
    1 => AdminProducts(productos: widget.productos),
    2 => const AdminServices(),
    3 => Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Cantidades del catálogo. Altas locales de sesión. Pedidos y reportes: demostración.',
          ),
        ),
        Expanded(child: InventarioScreen(productos: widget.productos)),
      ],
    ),
    4 => const AdminUsers(),
    5 => const PendingModule(
      titulo: 'Reservas',
      descripcion: 'Consulta y administración remota de reservas pendientes (3D). El formulario de reserva del cliente continúa siendo local.',
    ),
    6 => const DeliveryPedidosScreen(administrar: true),
    _ => const AccountScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    visitados.add(indice);
    final escritorio = MediaQuery.sizeOf(context).width >= 1050;
    final contenido = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.anchoContenido),
        child: IndexedStack(
          index: indice,
          children: [
            for (var i = 0; i < AdminShell.modulos.length; i++)
              visitados.contains(i) ? modulo(i) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
    return AdminOnly(
      child: Scaffold(
        appBar: AppBar(
          title: const AndradeBrand(),
          actions: [
            if (escritorio)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                  child: Eyebrow(
                    AdminShell.modulos[indice],
                    color: AppTheme.secundario,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: session.ocupado ? null : session.cerrarSesion,
              icon: const Icon(Icons.logout_rounded),
              style: IconButton.styleFrom(foregroundColor: AppTheme.oro),
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
        drawer: escritorio
            ? null
            : Drawer(
                backgroundColor: AppTheme.fondo,
                child: SafeArea(
                  child: ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
                        child: AndradeBrand(),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
                        child: Eyebrow('Andrade / Administración'),
                      ),
                      const Divider(height: 1),
                      for (var i = 0; i < AdminShell.modulos.length; i++)
                        ListTile(
                          key: ValueKey('admin-modulo-$i'),
                          leading: Icon(iconos[i]),
                          title: Text(AdminShell.modulos[i]),
                          selected: indice == i,
                          selectedColor: AppTheme.oro,
                          selectedTileColor: AppTheme.oro.withValues(
                            alpha: .08,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() => indice = i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
        body: SafeArea(
          child: escritorio
              ? Row(
                  children: [
                    NavigationRail(
                      backgroundColor: AppTheme.fondo,
                      indicatorColor: AppTheme.oro.withValues(alpha: .13),
                      selectedIconTheme: const IconThemeData(
                        color: AppTheme.oro,
                      ),
                      selectedLabelTextStyle: const TextStyle(
                        color: AppTheme.oro,
                        fontWeight: FontWeight.w600,
                      ),
                      extended: true,
                      scrollable: true,
                      selectedIndex: indice,
                      onDestinationSelected: (i) => setState(() => indice = i),
                      destinations: [
                        for (var i = 0; i < AdminShell.modulos.length; i++)
                          NavigationRailDestination(
                            icon: Icon(iconos[i]),
                            label: Text(AdminShell.modulos[i]),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: contenido),
                  ],
                )
              : contenido,
        ),
        bottomNavigationBar: escritorio
            ? null
            : Builder(
                builder: (context) {
                  const principales = [0, 1, 3, 2];
                  final seleccionado = principales.indexOf(indice);
                  return DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.linea)),
                    ),
                    child: NavigationBar(
                      selectedIndex: seleccionado < 0 ? 4 : seleccionado,
                      onDestinationSelected: (i) {
                        if (i == 4) {
                          Scaffold.of(context).openDrawer();
                        } else {
                          setState(() => indice = principales[i]);
                        }
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: 'Panel',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_outlined),
                          selectedIcon: Icon(Icons.grid_view_rounded),
                          label: 'Productos',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2_rounded),
                          label: 'Inventario',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.build_outlined),
                          selectedIcon: Icon(Icons.build_rounded),
                          label: 'Servicios',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.more_horiz_rounded),
                          label: 'Más',
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
