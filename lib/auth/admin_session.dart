import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'admin_auth_service.dart';

enum EstadoAdmin { comprobando, visitante, cliente, administrador }

class AdminSession extends ChangeNotifier {
  AdminSession(this.servicio) {
    _suscripcion = servicio.cambios.listen((_) {
      if (_accion) return;
      if (_comprobando) {
        ++_revision;
        _revisarOtraVez = true;
      } else {
        unawaited(comprobar());
      }
    }, onError: (Object error) => _fallo(error));
    // También comprueba cuentas restauradas antes del primer evento del SDK.
    unawaited(comprobar());
    _temporizador = Timer.periodic(const Duration(minutes: 5), (_) {
      if (autenticado) unawaited(comprobar());
    });
  }

  final AdminAuthService servicio;
  late final StreamSubscription<CuentaAdministrativa?> _suscripcion;
  late final Timer _temporizador;
  EstadoAdmin estado = EstadoAdmin.comprobando;
  String? mensaje;
  bool _accion = false, _comprobando = false, _disposed = false;
  bool _revisarOtraVez = false;
  int _revision = 0;

  CuentaAdministrativa? cuentaVerificada;
  bool get autenticado =>
      estado == EstadoAdmin.cliente || estado == EstadoAdmin.administrador;
  bool get esAdmin => estado == EstadoAdmin.administrador;
  bool get ocupado =>
      _accion || _comprobando || estado == EstadoAdmin.comprobando;

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  Future<void> comprobar() async {
    if (_disposed || _accion || _comprobando) return;
    _comprobando = true;
    final revision = ++_revision;
    if (!autenticado) estado = EstadoAdmin.comprobando;
    _avisar();
    try {
      await _validar(revision);
    } catch (error) {
      if (revision == _revision) _fallo(error);
    } finally {
      _comprobando = false;
      if (_revisarOtraVez && !_disposed) {
        _revisarOtraVez = false;
        unawaited(comprobar());
      }
      _avisar();
    }
  }

  Future<void> _validar(int revision) async {
    final cuenta = servicio.cuentaActual;
    final autorizado = cuenta != null && await cuenta.comprobarAdmin();
    if (_disposed || revision != _revision) return;
    final actual = servicio.cuentaActual;
    if (cuenta?.identificador != actual?.identificador) {
      _revisarOtraVez = true;
      return;
    }
    cuentaVerificada = actual;
    estado = actual == null
        ? EstadoAdmin.visitante
        : autorizado
        ? EstadoAdmin.administrador
        : EstadoAdmin.cliente;
    if (autenticado) mensaje = null;
    _avisar();
  }

  Future<void> iniciarSesion(String correo, String clave) async {
    if (ocupado || _disposed) return;
    _accion = true;
    final revision = ++_revision;
    estado = EstadoAdmin.comprobando;
    mensaje = null;
    _avisar();
    try {
      await servicio.iniciarSesion(correo.trim(), clave);
      if (!_disposed && revision == _revision) await _validar(revision);
    } catch (error) {
      if (revision == _revision) _fallo(error);
    } finally {
      _accion = false;
      _avisar();
    }
  }

  Future<void> cerrarSesion() async {
    if (_accion || _disposed) return;
    ++_revision;
    _accion = true;
    estado = EstadoAdmin.visitante;
    cuentaVerificada = null;
    mensaje = null;
    _avisar();
    try {
      await servicio.cerrarSesion();
    } catch (error) {
      _fallo(error);
    } finally {
      _accion = false;
      _avisar();
    }
  }

  void _fallo(Object error) {
    if (_disposed) return;
    ++_revision;
    cuentaVerificada = null;
    estado = EstadoAdmin.visitante;
    mensaje = switch (error) {
      FirebaseAuthException(code: 'network-request-failed') =>
        'No se pudo conectar. Comprueba tu conexión e inténtalo de nuevo.',
      FirebaseAuthException(
        code: 'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' ||
            'invalid-email',
      ) =>
        'Correo o contraseña incorrectos.',
      FirebaseAuthException(code: 'too-many-requests') =>
        'Demasiados intentos. Espera unos minutos antes de volver a intentar.',
      FirebaseAuthException(
        code: 'user-disabled' || 'user-token-expired' || 'invalid-user-token',
      ) =>
        'La sesión expiró o la cuenta no está disponible. Inicia sesión nuevamente.',
      _ => 'No se pudo verificar la sesión. Inténtalo de nuevo.',
    };
    _avisar();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _temporizador.cancel();
    unawaited(_suscripcion.cancel());
    super.dispose();
  }
}
