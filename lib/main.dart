import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/admin_auth_service.dart';
import 'auth/admin_session.dart';
import 'auth/auth_router.dart';
import 'auth/session_scope.dart';
import 'data/catalogo_state.dart';
import 'data/delivery_fcm.dart';
import 'data/delivery_state.dart';
import 'data/productos_repository.dart';
import 'firebase_options.dart';
import 'screens/presentacion_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/delivery_push_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    AndradeMotorsApp(
      deliveryPush: DeliveryFcm.paraPlataformaActual(),
      mostrarPresentacion: true,
      catalogoEnVivo: true,
      escaparateWeb: kIsWeb,
    ),
  );
}

class AndradeMotorsApp extends StatefulWidget {
  const AndradeMotorsApp({
    super.key,
    this.productosRepository,
    this.deliveryPush,
    this.adminAuthService,
    this.mostrarPresentacion = false,
    this.catalogoEnVivo = false,
    this.escaparateWeb = false,
  });
  final AdminAuthService? adminAuthService;
  final DeliveryCanalPush? deliveryPush;
  final ProductosRepository? productosRepository;
  final bool mostrarPresentacion, catalogoEnVivo, escaparateWeb;
  @override
  State<AndradeMotorsApp> createState() => _AndradeMotorsAppState();
}

class _AndradeMotorsAppState extends State<AndradeMotorsApp>
    with WidgetsBindingObserver {
  late final AdminSession session;
  late final CatalogoState catalogo;
  final delivery = DeliveryState();
  final _navigator = GlobalKey<NavigatorState>();
  final _mensajero = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    final auth = widget.adminAuthService ?? FirebaseAdminAuthService();
    session = AdminSession(auth);
    catalogo = CatalogoState(
      widget.productosRepository ?? ProductosRepository(authService: auth),
      enVivo: widget.catalogoEnVivo,
    );
    if (catalogo.enVivo) {
      session.addListener(_observarCatalogo);
      _observarCatalogo();
    } else {
      unawaited(catalogo.cargar());
    }
    WidgetsBinding.instance.addObserver(this);
  }

  void _observarCatalogo() => catalogo.observar(
    admin: session.esAdmin,
    cuenta: session.cuentaVerificada?.identificador,
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(session.comprobar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.removeListener(_observarCatalogo);
    session.dispose();
    catalogo.dispose();
    delivery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionScope(
    session: session,
    child: DeliveryScope(
      delivery: delivery,
      child: CatalogoScope(
        catalogo: catalogo,
        child: MaterialApp(
          title: 'ANDRADE MOTORS',
          navigatorKey: _navigator,
          scaffoldMessengerKey: _mensajero,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.oscuro,
          locale: const Locale('es', 'PE'),
          supportedLocales: const [Locale('es', 'PE')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          onGenerateRoute: (settings) => rutaAdministrativa(settings, catalogo),
          builder: (context, child) {
            Widget contenido = child!;
            final push = widget.deliveryPush;
            if (push != null) {
              contenido = DeliveryPushHost(
                sesion: session,
                delivery: delivery,
                canal: push,
                navigator: _navigator,
                mensajero: _mensajero,
                child: contenido,
              );
            }
            return widget.mostrarPresentacion
                ? PresentacionScreen(child: contenido)
                : contenido;
          },
          home: AuthRouter(
            catalogo: catalogo,
            escaparateWeb: widget.escaparateWeb,
          ),
        ),
      ),
    ),
  );
}
