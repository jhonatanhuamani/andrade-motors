import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../auth/admin_session.dart';
import '../data/delivery_fcm.dart';
import '../data/delivery_state.dart';
import '../models/delivery_aviso.dart';
import '../screens/delivery_pedidos_screen.dart';
import '../screens/delivery_seguimiento_screen.dart';

class DeliveryPushHost extends StatefulWidget {
  const DeliveryPushHost({
    super.key,
    required this.sesion,
    required this.delivery,
    required this.canal,
    required this.navigator,
    required this.mensajero,
    required this.child,
    this.alCambiarRegistro,
  });

  final AdminSession sesion;
  final DeliveryState delivery;
  final DeliveryCanalPush canal;
  final GlobalKey<NavigatorState> navigator;
  final GlobalKey<ScaffoldMessengerState> mensajero;
  final Widget child;

  /// Punto de integración para un futuro registro autenticado de dispositivos.
  final ValueChanged<RegistroDeliveryFcm?>? alCambiarRegistro;

  @override
  State<DeliveryPushHost> createState() => _DeliveryPushHostState();
}

class _DeliveryPushHostState extends State<DeliveryPushHost> {
  final _subs = <StreamSubscription<Object>>[];
  late final AppLifecycleListener _ciclo;
  Future<void> _cola = Future.value();
  RegistroDeliveryFcm? _registro;
  DeliveryAviso? _pendiente;
  String? _uid, _ultimoMensajeAbierto;
  bool _pidioPermiso = false;

  @override
  void initState() {
    super.initState();
    _ciclo = AppLifecycleListener(onResume: _revisarPermisosAlVolver);
    _subs.addAll([
      widget.canal.enPrimerPlano.listen(_mostrar, onError: _errorSeguro),
      widget.canal.alAbrir.listen(_alAbrir, onError: _errorSeguro),
      widget.canal.tokensRenovados.listen((token) {
        final uid = _uid;
        if (uid != null && _registro?.clienteId == uid && token.isNotEmpty) {
          _guardarRegistro((clienteId: uid, token: token));
        }
      }, onError: _errorSeguro),
    ]);
    widget.sesion.addListener(_actualizarSesion);
    _actualizarSesion();
    unawaited(_leerMensajeInicial());
  }

  Future<void> _leerMensajeInicial() async {
    try {
      final mensaje = await widget.canal.mensajeInicial();
      if (mounted && mensaje != null) _alAbrir(mensaje);
    } catch (error) {
      _errorSeguro(error);
    }
  }

  void _actualizarSesion() {
    final nuevo = widget.sesion.estado == EstadoAdmin.cliente
        ? widget.sesion.cuentaVerificada?.identificador
        : null;
    if (_uid != nuevo) {
      final anterior = _uid;
      _uid = nuevo;
      _guardarRegistro(null);
      if (anterior != null) {
        widget.mensajero.currentState?.clearSnackBars();
        if (_pendiente?.clienteId == anterior) _pendiente = null;
      }

      // Serializa borrado y obtención para no borrar el token de otra cuenta.
      _encolar(() async {
        if (anterior != null) {
          try {
            await widget.canal.borrarToken();
          } catch (error) {
            _errorSeguro(error);
          }
        }
        if (!mounted || nuevo == null || _uid != nuevo) return;
        final pedirPermiso = !_pidioPermiso;
        _pidioPermiso = true;
        await _registrar(nuevo, pedirPermiso: pedirPermiso);
      });
    }
    if (widget.sesion.autenticado && _pendiente?.clienteId != _uid) {
      _pendiente = null;
    }
    _intentarAbrir();
  }

  void _revisarPermisosAlVolver() {
    final uid = _uid;
    if (uid != null) {
      _encolar(() => _registrar(uid, pedirPermiso: false));
    }
  }

  void _encolar(Future<void> Function() accion) {
    _cola = _cola.then((_) => accion()).catchError(_errorSeguro);
  }

  Future<void> _registrar(String uid, {required bool pedirPermiso}) async {
    if (!mounted || _uid != uid) return;
    final token = await widget.canal.obtenerToken(pedirPermiso: pedirPermiso);
    if (!mounted || _uid != uid) return;
    _guardarRegistro(
      token == null || token.isEmpty ? null : (clienteId: uid, token: token),
    );
  }

  void _guardarRegistro(RegistroDeliveryFcm? registro) {
    if (_registro == registro) return;
    _registro = registro;
    widget.alCambiarRegistro?.call(registro);
  }

  void _errorSeguro(Object _) {
    // Los valores del token y los datos del pedido no se escriben en logs.
    debugPrint(
      '[Delivery FCM] No se pudo completar una operación de notificaciones.',
    );
  }

  void _mostrar(RemoteMessage mensaje) {
    final aviso = DeliveryAviso.desdeDatos(mensaje.data);
    if (!mounted || aviso == null || aviso.clienteId != _uid) return;
    _despuesDelFrame(() {
      if (aviso.clienteId != _uid) return;
      widget.mensajero.currentState?.showSnackBar(
        SnackBar(
          content: Text('${DeliveryAviso.titulo}\n${aviso.mensaje}'),
          action: SnackBarAction(
            label: 'Ver pedido',
            onPressed: () => _seleccionarAviso(aviso),
          ),
        ),
      );
    });
  }

  void _alAbrir(RemoteMessage mensaje) {
    if (!mounted) return;
    final aviso = DeliveryAviso.desdeDatos(mensaje.data);
    if (aviso == null ||
        (widget.sesion.autenticado && aviso.clienteId != _uid)) {
      return;
    }
    final id = mensaje.messageId;
    if (id != null && id == _ultimoMensajeAbierto) return;
    _ultimoMensajeAbierto = id;
    _seleccionarAviso(aviso);
  }

  void _seleccionarAviso(DeliveryAviso aviso) {
    _pendiente = aviso;
    _intentarAbrir();
  }

  void _intentarAbrir() {
    final aviso = _pendiente;
    if (aviso == null || aviso.clienteId != _uid) return;
    _despuesDelFrame(() {
      if (!identical(_pendiente, aviso) || aviso.clienteId != _uid) return;
      final navigator = widget.navigator.currentState;
      if (navigator == null) return;
      _pendiente = null;
      final pedido = widget.delivery.buscar(aviso.pedidoId);
      // Los pedidos siguen en memoria. Tras un cierre se abre Mis pedidos.
      final destino = pedido?.clienteId == aviso.clienteId
          ? DeliverySeguimientoScreen(pedidoId: aviso.pedidoId)
          : const DeliveryPedidosScreen();
      unawaited(
        navigator.push<void>(MaterialPageRoute(builder: (_) => destino)),
      );
    });
  }

  void _despuesDelFrame(VoidCallback accion) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) accion();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.sesion.removeListener(_actualizarSesion);
    _ciclo.dispose();
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
