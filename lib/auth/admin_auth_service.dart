import 'package:firebase_auth/firebase_auth.dart';

abstract interface class CuentaAdministrativa {
  String get identificador;
  String? get correo;
  Future<bool> comprobarAdmin();
}

abstract interface class AdminAuthService {
  CuentaAdministrativa? get cuentaActual;
  Stream<CuentaAdministrativa?> get cambios;
  Future<void> iniciarSesion(String correo, String clave);
  Future<void> cerrarSesion();
}

class FirebaseAdminAuthService implements AdminAuthService {
  FirebaseAdminAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  CuentaAdministrativa? get cuentaActual {
    final user = _auth.currentUser;
    return user == null ? null : _CuentaFirebase(user);
  }

  @override
  Stream<CuentaAdministrativa?> get cambios => _auth.authStateChanges().map(
    (user) => user == null ? null : _CuentaFirebase(user),
  );

  @override
  Future<void> iniciarSesion(String correo, String clave) async {
    await _auth.signInWithEmailAndPassword(email: correo, password: clave);
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();
}

class _CuentaFirebase implements CuentaAdministrativa {
  _CuentaFirebase(this.user);
  final User user;

  @override
  String get identificador => user.uid;
  @override
  String? get correo => user.email;

  @override
  Future<bool> comprobarAdmin() async {
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }
}
