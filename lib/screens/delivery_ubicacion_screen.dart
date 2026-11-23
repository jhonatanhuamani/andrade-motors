import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/session_scope.dart';
import '../data/delivery_config.dart';
import '../data/delivery_state.dart';
import '../models/delivery_pedido.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

class DeliveryUbicacionScreen extends StatefulWidget {
  const DeliveryUbicacionScreen({super.key, required this.items});

  final List<DeliveryItem> items;

  @override
  State<DeliveryUbicacionScreen> createState() => _DeliveryUbicacionScreenState();
}

class _DeliveryUbicacionScreenState extends State<DeliveryUbicacionScreen> {
  final _formulario = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  final _referencia = TextEditingController();
  final _latitud = TextEditingController(text: '$latitudTiendaDelivery');
  final _longitud = TextEditingController(text: '$longitudTiendaDelivery');
  DeliveryUbicacion? _real, _simulada;
  bool _simulacion = false, _buscando = false, _confirmado = false;
  String? _mensaje;

  DeliveryUbicacion? get _ubicacion => _simulacion ? _simulada : _real;

  Future<void> _obtenerUbicacion() async {
    setState(() {
      _buscando = true;
      _real = null;
      _mensaje = null;
    });
    String? error;
    try {
      // El navegador solicita el permiso al pedir la posición. Algunos
      // navegadores carecen de una API independiente para consultar el permiso.
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          error = 'La ubicación está desactivada. Actívala en los ajustes del dispositivo.';
          return;
        }
        var permiso = await Geolocator.checkPermission();
        if (!mounted) return;
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }
        if (permiso == LocationPermission.deniedForever) {
          error = 'El permiso está bloqueado. Habilítalo en los ajustes de la aplicación.';
          return;
        }
        if (permiso == LocationPermission.denied) {
          error = 'Permiso de ubicación denegado. Puedes pedirlo de nuevo o usar la simulación.';
          return;
        }
      }
      if (!mounted) return;
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      _real = DeliveryUbicacion(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        precisionMetros: posicion.accuracy,
        actualizada: posicion.timestamp,
        simulada: false,
      );
    } on PermissionDeniedException {
      error = kIsWeb
          ? 'El navegador bloqueó el permiso. Revísalo en los ajustes del sitio o usa la simulación.'
          : 'Permiso de ubicación denegado. Revísalo en los ajustes de la aplicación.';
    } on LocationServiceDisabledException {
      error = 'La ubicación está desactivada. Actívala o utiliza la simulación.';
    } on TimeoutException {
      error = 'La ubicación tardó demasiado. Inténtalo de nuevo o utiliza la simulación.';
    } on UnsupportedError {
      error = 'La ubicación no está disponible en esta plataforma. Usa la simulación.';
    } on MissingPluginException {
      error = 'La ubicación no está disponible en este dispositivo. Usa la simulación.';
    } on Exception {
      error = kIsWeb
          ? 'El navegador no pudo obtener la ubicación. Verifica el permiso y que el sitio use HTTPS o localhost.'
          : 'No se pudo obtener la ubicación. Inténtalo de nuevo o usa la simulación.';
    } finally {
      if (mounted) {
        setState(() {
          _buscando = false;
          _mensaje = error;
          if (error != null && kIsWeb) _simulacion = true;
        });
      }
    }
  }

  void _aplicarSimulacion() {
    double? leer(String valor) => double.tryParse(valor.trim().replaceAll(',', '.'));
    final lat = leer(_latitud.text);
    final lon = leer(_longitud.text);
    if (lat == null || lon == null ||
        !lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
      setState(() => _mensaje = 'Ingresa una latitud entre −90 y 90 y una longitud entre −180 y 180.');
      return;
    }
    setState(() {
      _mensaje = null;
      _simulada = DeliveryUbicacion(
        latitud: lat,
        longitud: lon,
        actualizada: DateTime.now(),
        simulada: true,
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
          ) / 1000;
    final costo = distancia == null ? null : cotizarDelivery(distancia);
    final subtotal = widget.items.fold<double>(0, (s, item) => s + item.subtotal);
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
                  const Text('Tu ubicación se utiliza únicamente para calcular y gestionar la entrega.'),
                  const SizedBox(height: 16),
                  PremiumPanel(
                    gold: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeading('Ubicación actual'),
                        if (ubicacion != null) ...[
                          Eyebrow(ubicacion.simulada ? 'Simulada' : 'Dispositivo'),
                          const SizedBox(height: 8),
                          Text('Latitud: ${ubicacion.latitud.toStringAsFixed(6)}'),
                          Text('Longitud: ${ubicacion.longitud.toStringAsFixed(6)}'),
                          Text(ubicacion.precisionMetros == null
                              ? 'Precisión: no aplica a la simulación'
                              : 'Precisión: ${ubicacion.precisionMetros!.toStringAsFixed(1)} m'),
                          Text('Hora de actualización: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(ubicacion.actualizada.toLocal()))}'),
                        ] else
                          const Text('Todavía no se ha seleccionado una ubicación.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _buscando || _simulacion ? null : _obtenerUbicacion,
                          icon: const Icon(Icons.my_location),
                          label: Text(_buscando ? 'Obteniendo ubicación…' : 'Usar mi ubicación actual'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Modo simulación'),
                          subtitle: const Text('Solo cambia la ubicación de este pedido.'),
                          value: _simulacion,
                          onChanged: _buscando ? null : (valor) => setState(() {
                            _simulacion = valor;
                            _mensaje = null;
                          }),
                        ),
                        if (_simulacion) ...[
                          TextField(
                            controller: _latitud,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(labelText: 'Latitud'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _longitud,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(labelText: 'Longitud'),
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
                            child: Text(_mensaje!, style: const TextStyle(color: AppTheme.alerta)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccion,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Dirección de entrega'),
                    textInputAction: TextInputAction.next,
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Ingresa la dirección de entrega.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referencia,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Referencia (opcional)'),
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
                          Text('${item.cantidad} × ${item.nombre} · ${importeDelivery(item.subtotal)}'),
                        const Divider(),
                        Text('Subtotal: ${importeDelivery(subtotal)}'),
                        Text('Distancia aproximada: ${distancia == null ? '—' : '${distancia.toStringAsFixed(1)} km'}'),
                        if (tiendaDeliveryProvisional)
                          const Text('La ubicación de la tienda es provisional. La distancia y la tarifa son de demostración.', style: TextStyle(color: AppTheme.alerta)),
                        Text('Costo estimado de delivery: ${costo != null ? importeDelivery(costo) : distancia == null ? '—' : 'Consultar disponibilidad'}'),
                        Text('Total: ${costo == null ? 'Por cotizar' : importeDelivery(subtotal + costo)}'),
                        const Divider(),
                        Text('Dirección: ${_direccion.text.trim().isEmpty ? 'Pendiente' : _direccion.text.trim()}'),
                        Text('Referencia: ${_referencia.text.trim().isEmpty ? '—' : _referencia.text.trim()}'),
                        Text('Ubicación: ${ubicacion == null ? 'Pendiente' : '${ubicacion.latitud.toStringAsFixed(6)}, ${ubicacion.longitud.toStringAsFixed(6)}'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: ubicacion == null || distancia == null ||
                            costo == null || _buscando || widget.items.isEmpty
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
