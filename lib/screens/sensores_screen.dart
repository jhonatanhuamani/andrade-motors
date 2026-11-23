import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

enum _Sensor {
  acelerometro('Acelerómetro', Icons.speed, 'm/s²'),
  giroscopio('Giroscopio', Icons.rotate_right, 'rad/s'),
  proximidad('Proximidad', Icons.sensors, 'cm'),
  luz('Luz ambiental', Icons.light_mode_outlined, 'lx');

  const _Sensor(this.titulo, this.icono, this.unidad);

  final String titulo, unidad;
  final IconData icono;
}

class SensoresScreen extends StatefulWidget {
  const SensoresScreen({super.key});

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen> {
  static const _canal = EventChannel('andrade_motors/sensores');
  final _lecturas = <_Sensor, List<double>>{};
  final _rangos = <_Sensor, double>{};
  final bool _android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  StreamSubscription<dynamic>? _suscripcion;
  Timer? _temporizador;
  Timer? _esperaCanal;
  Set<String>? _disponibles;
  bool _simular = false;
  double _fase = 0;

  @override
  void initState() {
    super.initState();
    _actualizarCanal();
    _temporizador = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_Sensor.values.any(_esSimulado)) {
        setState(() => _fase += .25);
      }
    });
  }

  bool _esSimulado(_Sensor sensor) =>
      _simular || !_android || (_disponibles?.contains(sensor.name) == false);

  void _actualizarCanal() {
    _esperaCanal?.cancel();
    unawaited(_suscripcion?.cancel());
    _suscripcion = null;
    _lecturas.clear();
    _rangos.clear();
    _disponibles = null;
    if (!_android || _simular) return;
    _esperaCanal = Timer(const Duration(seconds: 3), _activarRespaldo);
    _suscripcion = _canal.receiveBroadcastStream().listen(
      _recibir,
      onError: (Object error) => _activarRespaldo(),
      onDone: _activarRespaldo,
    );
  }

  void _activarRespaldo() {
    if (!mounted) return;
    _esperaCanal?.cancel();
    setState(() => _disponibles = const <String>{});
  }

  void _recibir(dynamic evento) {
    if (!mounted || evento is! Map) return;
    final disponibles = evento['disponibles'];
    if (disponibles is List) {
      _esperaCanal?.cancel();
      setState(() => _disponibles = disponibles.whereType<String>().toSet());
      return;
    }
    final sensor = _Sensor.values.where((s) => s.name == evento['sensor']).firstOrNull;
    final valores = evento['valores'];
    if (sensor == null || valores is! List) return;
    final lectura = valores.whereType<num>().map((v) => v.toDouble()).toList();
    final esperado = sensor == _Sensor.acelerometro || sensor == _Sensor.giroscopio
        ? 3
        : 1;
    if (lectura.length != esperado) return;
    final rango = evento['rango'];
    setState(() {
      _lecturas[sensor] = lectura;
      if (rango is num) _rangos[sensor] = rango.toDouble();
    });
  }

  List<double> _lecturaSimulada(_Sensor sensor) => switch (sensor) {
    _Sensor.acelerometro => [math.sin(_fase), math.cos(_fase) * .6, 9.81],
    _Sensor.giroscopio => [math.sin(_fase) * .5, math.cos(_fase) * .4, 0],
    _Sensor.proximidad => [_fase % 6 < 3 ? 0 : 5],
    _Sensor.luz => [250 + math.sin(_fase) * 175],
  };

  String _formatear(_Sensor sensor, List<double> valores, bool simulado) {
    String unidad(double v) => '${v.toStringAsFixed(2)} ${sensor.unidad}';
    if (valores.length == 3) {
      return 'X ${unidad(valores[0])}   Y ${unidad(valores[1])}   Z ${unidad(valores[2])}';
    }
    if (sensor == _Sensor.proximidad) {
      final rango = simulado ? 5.0 : _rangos[sensor];
      if (rango != null && rango > 0) {
        final estado = valores.first < rango ? 'Cerca' : 'Lejos';
        return '$estado · ${unidad(valores.first)}';
      }
    }
    return unidad(valores.first);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _esperaCanal?.cancel();
    unawaited(_suscripcion?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sensores del dispositivo')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Lecturas en directo del dispositivo. Cada tarjeta indica su fuente.'),
            if (_android)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Simular todos los sensores'),
                value: _simular,
                onChanged: (valor) {
                  setState(() => _simular = valor);
                  _actualizarCanal();
                },
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('En esta plataforma las lecturas son simuladas.'),
              ),
            const SizedBox(height: 16),
            for (final sensor in _Sensor.values) _tarjeta(sensor),
          ],
        ),
      ),
    ),
  );

  Widget _tarjeta(_Sensor sensor) {
    final simulado = _esSimulado(sensor);
    final valores = simulado ? _lecturaSimulada(sensor) : _lecturas[sensor];
    final fuente = simulado
        ? 'Simulación'
        : _disponibles == null
        ? 'Detectando sensor'
        : 'Sensor Android';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(sensor.icono),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sensor.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(fuente, style: const TextStyle(color: AppTheme.oro)),
                  const SizedBox(height: 8),
                  Text(valores == null ? 'Esperando lectura…' : _formatear(sensor, valores, simulado)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
