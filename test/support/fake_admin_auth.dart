import 'dart:async';

import 'package:andrade_motors/auth/admin_auth_service.dart';

class FakeCuentaAdmin implements CuentaAdministrativa {
  FakeCuentaAdmin(this.admin);
  @override
  String get identificador => 'cuenta-prueba';
  @override
  String get correo => 'cuenta@example.test';
  final bool admin;
  int comprobaciones = 0;
  Object? error;
  Completer<bool>? pendiente;

  @override
  Future<bool> comprobarAdmin() async {
    comprobaciones++;
    if (error != null) throw error!;
    return pendiente == null ? admin : await pendiente!.future;
  }
}

class FakeAdminAuth implements AdminAuthService {
  FakeAdminAuth({this._cuenta, this.adminAlEntrar = true});

  final bool adminAlEntrar;
  CuentaAdministrativa? _cuenta;
  final _cambios = StreamController<CuentaAdministrativa?>.broadcast();
  int salidas = 0;
  Object? errorIngreso;

  @override
  CuentaAdministrativa? get cuentaActual => _cuenta;
  @override
  Stream<CuentaAdministrativa?> get cambios => _cambios.stream;

  @override
  Future<void> iniciarSesion(String correo, String clave) async {
    if (errorIngreso != null) throw errorIngreso!;
    _cuenta = FakeCuentaAdmin(adminAlEntrar);
    _cambios.add(_cuenta);
  }

  @override
  Future<void> cerrarSesion() async {
    salidas++;
    _cuenta = null;
    _cambios.add(null);
  }

  Future<void> dispose() => _cambios.close();
}
