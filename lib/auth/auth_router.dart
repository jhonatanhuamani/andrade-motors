import 'package:flutter/material.dart';

import '../data/catalogo_state.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin_login_screen.dart';
import '../screens/cliente/cliente_shell.dart';
import 'session_scope.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({
    super.key,
    required this.catalogo,
    this.moduloAdminInicial = 0,
  });
  final CatalogoState catalogo;
  final int moduloAdminInicial;

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  String? _sesion;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.autenticado) {
      _sesion = null;
      return Scaffold(
        body: SafeArea(child: AdminLoginScreen(session: session)),
      );
    }
    final identidad =
        '${session.cuentaVerificada?.identificador}:${session.estado.name}';
    if (_sesion != identidad) {
      _sesion = identidad;
      _navigator = GlobalKey<NavigatorState>();
    }
    return ListenableBuilder(
      listenable: widget.catalogo,
      builder: (context, _) => NavigatorPopHandler<Object?>(
        onPopWithResult: (_) => _navigator.currentState?.pop(),
        child: Navigator(
          key: _navigator,
          onDidRemovePage: (_) {},
          onGenerateRoute: (settings) =>
              rutaAdministrativa(settings, widget.catalogo),
          pages: [
            MaterialPage<void>(
              child: session.esAdmin
                  ? AdminShell(
                      productos: widget.catalogo.productos,
                      usaRespaldo: widget.catalogo.usaRespaldo,
                      moduloInicial: widget.moduloAdminInicial,
                    )
                  : ClienteShell(productos: widget.catalogo.productos),
            ),
          ],
        ),
      ),
    );
  }
}

Route<void> rutaAdministrativa(RouteSettings settings, CatalogoState catalogo) {
  final nombre = settings.name ?? '';
  const rutas = {
    '/admin': 0,
    '/admin/productos': 1,
    '/admin/servicios': 2,
    '/admin/inventario': 3,
    '/admin/usuarios': 4,
    '/admin/reservas': 5,
    '/admin/pedidos': 6,
    '/admin/configuracion': 7,
  };
  final modulo = rutas[nombre];
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (context) {
      // No se construye ningún módulo administrativo para una cuenta cliente.
      final session = SessionScope.of(context);
      if (modulo != null && !session.autenticado) {
        return AuthRouter(catalogo: catalogo, moduloAdminInicial: modulo);
      }
      if (modulo == null || !session.esAdmin) {
        return Scaffold(
          appBar: AppBar(title: const Text('Acceso restringido')),
          body: const Center(
            child: Text(
              'Acceso denegado. Se requiere una sesión administradora.',
            ),
          ),
        );
      }
      return AuthRouter(catalogo: catalogo, moduloAdminInicial: modulo);
    },
  );
}
