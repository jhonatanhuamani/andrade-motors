import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../auth/session_scope.dart';
import '../data/delivery_config.dart';
import '../data/delivery_state.dart';
import '../models/delivery_pedido.dart';
import '../theme/app_theme.dart';
import '../widgets/delivery_mapa.dart';
import '../widgets/premium_components.dart';

class DeliveryUbicacionScreen extends StatefulWidget {
  const DeliveryUbicacionScreen({super.key, required this.items});

  final List<DeliveryItem> items;

  @override
  State<DeliveryUbicacionScreen> createState() =>
      _DeliveryUbicacionScreenState();
}

class _DeliveryUbicacionScreenState extends State<DeliveryUbicacionScreen>
    with WidgetsBindingObserver {
  final _formulario = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  final _referencia = TextEditingController();
  final _latitud = TextEditingController(text: '$latitudTiendaDelivery');
  final _longitud = TextEditingController(text: '$longitudTiendaDelivery');
  DeliveryUbicacion? _real, _simulada, _manual;
  StreamSubscription<Position>? _gps;
  Timer? _primeraLectura;
  int _intentoGps = 0;
  bool _simulacion = false, _buscando = false, _confirmado = false;
  bool _seguir = true, _gpsSolicitado = false, _primerPlano = true;
  static const _gpsInestable =
      'El GPS perdió señal temporalmente. Se conserva la última lectura disponible.';
  String? _mensaje;

  DeliveryUbicacion? get _ubicacion =>
      _simulacion ? _simulada : _manual ?? _real;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _primerPlano = true;
      if (_gpsSolicitado && _gps == null && !_buscando) {
        unawaited(_iniciarGps(pedirPermiso: false));
      }
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _primerPlano = false;
      if (_gps != null) {
        ++_intentoGps;
        unawaited(_detenerGps());
        if (_buscando) setState(() => _buscando = false);
      }
    }
  }

  Future<void> _detenerGps() async {
    _primeraLectura?.cancel();
    _primeraLectura = null;
    final suscripcion = _gps;
    _gps = null;
    await suscripcion?.cancel();
  }

  bool _vigente(int intento) => mounted && intento == _intentoGps;

  void _usarGps() {
    if (_buscando) return;
    setState(() {
      _manual = null;
      _simulacion = false;
      _seguir = true;
      _mensaje = null;
    });
    if (_gps == null) unawaited(_iniciarGps(pedirPermiso: true));
  }

  Future<void> _iniciarGps({required bool pedirPermiso}) async {
    final intento = ++_intentoGps;
    _gpsSolicitado = true;
    setState(() {
      _buscando = true;
      if (pedirPermiso) _real = null;
      _mensaje = null;
    });
    try {
      // El navegador solicita el permiso al comenzar la lectura.
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const LocationServiceDisabledException();
        }
        var permiso = await Geolocator.checkPermission();
        if (!_vigente(intento)) return;
        if (permiso == LocationPermission.denied &&
            pedirPermiso &&
            _primerPlano) {
          permiso = await Geolocator.requestPermission();
        }
        if (permiso == LocationPermission.deniedForever) {
          _falloGps(
            intento,
            'El permiso está bloqueado. Habilítalo en los ajustes de la aplicación.',
          );
          return;
        }
        if (permiso == LocationPermission.denied) {
          _falloGps(intento, 'Permiso de ubicación denegado.');
          return;
        }
      }
      if (!_vigente(intento)) return;
      if (!_primerPlano) {
        setState(() => _buscando = false);
        return;
      }
      _primeraLectura = Timer(const Duration(seconds: 20), () {
        _falloGps(intento, 'La primera lectura del GPS tardó demasiado.');
      });
      _gps =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            (posicion) {
              if (!_vigente(intento) || !_primerPlano) return;
              _primeraLectura?.cancel();
              setState(() {
                _buscando = false;
                if (_mensaje == _gpsInestable) _mensaje = null;
                _real = DeliveryUbicacion(
                  latitud: posicion.latitude,
                  longitud: posicion.longitude,
                  precisionMetros: posicion.accuracy,
                  actualizada: posicion.timestamp,
                  origen: DeliveryOrigen.gps,
                );
              });
            },
            onError: (Object error) {
              if (error is PositionUpdateException) {
                if (_vigente(intento)) setState(() => _mensaje = _gpsInestable);
              } else {
                _falloGps(intento, _errorGps(error));
              }
            },
            onDone: () =>
                _falloGps(intento, 'Se interrumpieron las lecturas del GPS.'),
          );
    } catch (error) {
      _falloGps(intento, _errorGps(error));
    }
  }

  String _errorGps(Object error) => switch (error) {
    LocationServiceDisabledException() =>
      'La ubicación está desactivada. Actívala en los ajustes del dispositivo.',
    PermissionDeniedException() =>
      kIsWeb
          ? 'El navegador bloqueó el permiso. Revísalo en los ajustes del sitio.'
          : 'Permiso de ubicación denegado. Revísalo en los ajustes de la aplicación.',
    UnsupportedError() || MissingPluginException() =>
      'La ubicación no está disponible en esta plataforma.',
    _ =>
      kIsWeb
          ? 'No se pudo obtener la ubicación. Verifica el permiso y usa HTTPS o localhost.'
          : 'No se pudo obtener la ubicación. Inténtalo de nuevo.',
  };

  void _falloGps(int intento, String mensaje) {
    if (!_vigente(intento)) return;
    ++_intentoGps;
    _gpsSolicitado = false;
    unawaited(_detenerGps());
    setState(() {
      _real = null;
      _buscando = false;
      _mensaje =
          '$mensaje Puedes elegir un punto en el mapa o usar la simulación.';
      if (kIsWeb && _manual == null) _simulacion = true;
    });
  }

  void _seleccionarEnMapa(LatLng punto) {
    setState(() {
      _simulacion = false;
      _seguir = false;
      _mensaje = null;
      _manual = DeliveryUbicacion(
        latitud: punto.latitude,
        longitud: punto.longitude,
        actualizada: DateTime.now(),
        origen: DeliveryOrigen.manual,
      );
    });
  }

  void _aplicarSimulacion() {
    double? leer(String valor) =>
        double.tryParse(valor.trim().replaceAll(',', '.'));
    final lat = leer(_latitud.text);
    final lon = leer(_longitud.text);
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      setState(
        () => _mensaje = 'Ingresa una latitud entre −90 y 90 y una longitud entre −180 y 180.',
      );
      return;
    }
    setState(() {
      _mensaje = null;
      _seguir = false;
      _simulada = DeliveryUbicacion(
        latitud: lat,
        longitud: lon,
        actualizada: DateTime.now(),
        origen: DeliveryOrigen.simulacion,
      );
    });
  }

  void _confirmar(DeliveryUbicacion ubicacion, double distancia, double costo) {
    if (_confirmado || !_formulario.currentState!.validate()) return;
    final session = SessionScope.of(context);
    final cuenta = session.cuentaVerificada;
    final store = DeliveryScope.of(context);
    _confirmado = true;
    final pedido = store.confirmar(
      clienteId: cuenta?.identificador,
      cliente: cuenta?.correo ?? cuenta?.identificador ?? 'Visitante',
      items: widget.items,
      costoDelivery: costo,
      ubicacion: ubicacion,
      direccion: _direccion.text.trim(),
      referencia: _referencia.text.trim(),
      distanciaKm: distancia,
    );
    Navigator.of(context).pop(pedido);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_intentoGps;
    unawaited(_detenerGps());
    _direccion.dispose();
    _referencia.dispose();
    _latitud.dispose();
    _longitud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = _ubicacion;
    final distancia = ubicacion == null
        ? null
        : Geolocator.distanceBetween(
                latitudTiendaDelivery,
                longitudTiendaDelivery,
                ubicacion.latitud,
                ubicacion.longitud,
              ) /
              1000;
    final costo = distancia == null ? null : cotizarDelivery(distancia);
    final subtotal = widget.items.fold<double>(
      0,
      (s, item) => s + item.subtotal,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación de entrega')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formulario,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Tu ubicación se utiliza únicamente para calcular y gestionar tu entrega.',
                  ),
                  const SizedBox(height: 16),
                  PremiumPanel(
                    gold: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeading('Mapa de entrega'),
                        const Text(
                          'Toca el mapa para elegir un punto de entrega.',
                        ),
                        const SizedBox(height: 12),
                        DeliveryMapa(
                          entrega: ubicacion,
                          gps: _real,
                          seguirGps: _seguir,
                          onSeleccion: _seleccionarEnMapa,
                        ),
                        const SizedBox(height: 12),
                        if (ubicacion != null) ...[
                          Eyebrow('Origen: ${ubicacion.origen.etiqueta}'),
                          if (ubicacion.origen == DeliveryOrigen.manual)
                            const Text('Ubicación seleccionada manualmente'),
                          const SizedBox(height: 8),
                          Text(
                            'Latitud: ${ubicacion.latitud.toStringAsFixed(6)}',
                          ),
                          Text(
                            'Longitud: ${ubicacion.longitud.toStringAsFixed(6)}',
                          ),
                          Text(
                            ubicacion.precisionMetros == null
                                ? 'Precisión GPS: no aplica a este punto'
                                : 'Precisión GPS: ${ubicacion.precisionMetros!.toStringAsFixed(1)} m',
                          ),
                          Text(
                            'Hora de actualización: '
                            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(ubicacion.actualizada.toLocal()))}',
                          ),
                        ] else
                          const Text(
                            'Todavía no se ha seleccionado una ubicación.',
                          ),
                        Text(
                          'Distancia a ANDRADE MOTORS: ${distancia == null ? '—' : '${distancia.toStringAsFixed(2)} km'}',
                        ),
                        Text(
                          'Costo estimado de delivery: ${costo != null
                              ? importeDelivery(costo)
                              : distancia == null
                              ? '—'
                              : 'Consultar disponibilidad'}',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _buscando ? null : _usarGps,
                          icon: const Icon(Icons.my_location),
                          label: Text(
                            _buscando
                                ? 'Obteniendo ubicación…'
                                : _manual != null || _simulacion
                                ? 'Usar nuevamente mi ubicación GPS'
                                : 'Usar mi ubicación actual',
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Seguir mi ubicación'),
                          value: _seguir,
                          onChanged: (valor) => setState(() => _seguir = valor),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Modo simulación'),
                          subtitle: const Text(
                            'Solo cambia la ubicación de este pedido.',
                          ),
                          value: _simulacion,
                          onChanged: (valor) => setState(() {
                            _simulacion = valor;
                            if (valor) _seguir = false;
                            _mensaje = null;
                          }),
                        ),
                        if (_simulacion) ...[
                          TextField(
                            controller: _latitud,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitud',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _longitud,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Longitud',
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _aplicarSimulacion,
                            child: const Text('Aplicar ubicación simulada'),
                          ),
                        ],
                        if (_mensaje != null) ...[
                          const SizedBox(height: 8),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _mensaje!,
                              style: const TextStyle(color: AppTheme.alerta),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccion,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Dirección de entrega',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Ingresa la dirección de entrega.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referencia,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Referencia (opcional)',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  PremiumPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading('Resumen del pedido'),
                        for (final item in widget.items)
                          Text(
                            '${item.cantidad} × ${item.nombre} · ${importeDelivery(item.subtotal)}',
                          ),
                        const Divider(),
                        Text('Subtotal: ${importeDelivery(subtotal)}'),
                        Text(
                          'Distancia aproximada: ${distancia == null ? '—' : '${distancia.toStringAsFixed(2)} km'}',
                        ),
                        if (tiendaDeliveryProvisional)
                          const Text(
                            'La ubicación de la tienda es provisional. La distancia y la tarifa son de demostración.',
                            style: TextStyle(color: AppTheme.alerta),
                          ),
                        Text(
                          'Costo estimado de delivery: ${costo != null
                              ? importeDelivery(costo)
                              : distancia == null
                              ? '—'
                              : 'Consultar disponibilidad'}',
                        ),
                        Text(
                          'Total: ${costo == null ? 'Por cotizar' : importeDelivery(subtotal + costo)}',
                        ),
                        const Divider(),
                        Text(
                          'Dirección: ${_direccion.text.trim().isEmpty ? 'Pendiente' : _direccion.text.trim()}',
                        ),
                        Text(
                          'Referencia: ${_referencia.text.trim().isEmpty ? '—' : _referencia.text.trim()}',
                        ),
                        Text(
                          'Ubicación: ${ubicacion == null ? 'Pendiente' : '${ubicacion.latitud.toStringAsFixed(6)}, ${ubicacion.longitud.toStringAsFixed(6)}'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        ubicacion == null ||
                            distancia == null ||
                            costo == null ||
                            widget.items.isEmpty
                        ? null
                        : () => _confirmar(ubicacion, distancia, costo),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar ubicación de entrega'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
