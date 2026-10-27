import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/admin_auth_service.dart';
import 'auth/admin_session.dart';
import 'auth/auth_router.dart';
import 'auth/session_scope.dart';
import 'data/catalogo_state.dart';
import 'data/productos_repository.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AndradeMotorsApp());
}

class AndradeMotorsApp extends StatefulWidget {
  const AndradeMotorsApp({
    super.key,
    this.productosRepository,
    this.adminAuthService,
  });
  final AdminAuthService? adminAuthService;
  final ProductosRepository? productosRepository;
  @override
  State<AndradeMotorsApp> createState() => _AndradeMotorsAppState();
}

class _AndradeMotorsAppState extends State<AndradeMotorsApp>
    with WidgetsBindingObserver {
  late final AdminSession session;
  late final CatalogoState catalogo;

  @override
  void initState() {
    super.initState();
    final auth = widget.adminAuthService ?? FirebaseAdminAuthService();
    session = AdminSession(auth);
    catalogo = CatalogoState(
      widget.productosRepository ?? ProductosRepository(authService: auth),
    );
    unawaited(catalogo.cargar());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(session.comprobar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    session.dispose();
    catalogo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionScope(
    session: session,
    child: CatalogoScope(
      catalogo: catalogo,
      child: MaterialApp(
        title: 'ANDRADE MOTORS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.oscuro,
        locale: const Locale('es', 'PE'),
        supportedLocales: const [Locale('es', 'PE')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        onGenerateRoute: (settings) => rutaAdministrativa(settings, catalogo),
        home: AuthRouter(catalogo: catalogo),
      ),
    ),
  );
}
