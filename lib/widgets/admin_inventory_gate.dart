import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/admin_auth_service.dart';
import '../auth/admin_session.dart';
import '../models/producto.dart';
import '../screens/admin_login_screen.dart';
import '../screens/inventario_screen.dart';

class AdminInventoryGate extends StatefulWidget {
  const AdminInventoryGate({
    super.key,
    required this.productos,
    required this.activo,
    this.authService,
  });

  final List<Producto> productos;
  final bool activo;
  final AdminAuthService? authService;

  @override
  State<AdminInventoryGate> createState() => _AdminInventoryGateState();
}

class _AdminInventoryGateState extends State<AdminInventoryGate>
    with WidgetsBindingObserver {
  late final AdminSession _session;
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _session = AdminSession(widget.authService ?? FirebaseAdminAuthService());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant AdminInventoryGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activo && !oldWidget.activo) unawaited(_session.comprobar());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_session.comprobar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _session,
    builder: (context, _) => IndexedStack(
      index: _session.esAdmin ? 1 : 0,
      children: [
        ExcludeFocus(
          excluding: _session.esAdmin,
          child: AdminLoginScreen(session: _session),
        ),
        // Mantener el estado local sin exponer el panel mientras se verifica.
        ExcludeFocus(
          excluding: !_session.esAdmin,
          // Los diálogos locales también quedan dentro del acceso protegido.
          child: NavigatorPopHandler<Object?>(
            enabled: widget.activo && _session.esAdmin,
            onPopWithResult: (_) => _navigator.currentState?.pop(),
            child: Navigator(
              key: _navigator,
              onDidRemovePage: (_) {},
              pages: [
                MaterialPage<void>(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: TextButton.icon(
                            onPressed: _session.ocupado
                                ? null
                                : _session.cerrarSesion,
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: const Text('Cerrar sesión'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InventarioScreen(productos: widget.productos),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
