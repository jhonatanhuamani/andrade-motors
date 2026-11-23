import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/delivery_config.dart';
import '../models/delivery_pedido.dart';
import '../theme/app_theme.dart';

class DeliveryMapa extends StatefulWidget {
  const DeliveryMapa({
    super.key,
    this.entrega,
    this.gps,
    this.seguirGps = false,
    this.onSeleccion,
  });

  final DeliveryUbicacion? entrega, gps;
  final bool seguirGps;
  final ValueChanged<LatLng>? onSeleccion;

  @override
  State<DeliveryMapa> createState() => _DeliveryMapaState();
}

class _DeliveryMapaState extends State<DeliveryMapa> {
  static const _tienda = LatLng(latitudTiendaDelivery, longitudTiendaDelivery);
  static const _colorCliente = Color(0xFF176E76);
  static const _colorEntrega = Color(0xFFA04527);
  final _mapa = MapController();
  bool _listo = false;

  LatLng? _punto(DeliveryUbicacion? u) =>
      u == null ? null : LatLng(u.latitud, u.longitud);

  @override
  void didUpdateWidget(covariant DeliveryMapa oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gps = _punto(widget.gps);
    final entrega = _punto(widget.entrega);
    final entregaAnterior = _punto(oldWidget.entrega);
    final entregaCambiada =
        entrega != entregaAnterior ||
        widget.entrega?.origen != oldWidget.entrega?.origen;
    final cambioSinSeguir =
        entregaCambiada &&
        (widget.entrega?.origen != DeliveryOrigen.gps ||
            oldWidget.entrega?.origen != DeliveryOrigen.gps);
    if (cambioSinSeguir && entrega != null) {
      _programarCentro(entrega);
    } else if (widget.seguirGps &&
        gps != null &&
        (!oldWidget.seguirGps || gps != _punto(oldWidget.gps))) {
      _programarCentro(gps);
    }
  }

  void _programarCentro(LatLng punto) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centrar(punto);
    });
  }

  void _centrar(LatLng punto) {
    if (!_listo) return;
    final zoom = _mapa.camera.zoom.clamp(14.0, 18.0).toDouble();
    _mapa.move(punto, zoom);
  }

  CameraFit _encuadrarEntrega(LatLng entrega) => CameraFit.coordinates(
    coordinates: [_tienda, entrega],
    padding: const EdgeInsets.fromLTRB(56, 48, 56, 68),
    maxZoom: 16,
  );

  Marker _marcador(
    LatLng punto,
    String etiqueta,
    IconData icono,
    Color color, {
    Alignment alignment = Alignment.center,
  }) => Marker(
    point: punto,
    width: 42,
    height: 42,
    alignment: alignment,
    child: Tooltip(
      message: etiqueta,
      excludeFromSemantics: true,
      child: Semantics(
        label: etiqueta,
        image: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icono, color: Colors.white, size: 22),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gps = _punto(widget.gps);
    final entrega = _punto(widget.entrega);
    final admin = widget.onSeleccion == null;
    final centro = gps ?? entrega;
    final distinta = entrega != null && entrega != _tienda;
    return SizedBox(
      height: MediaQuery.sizeOf(context).width >= 720 ? 390 : 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: entrega ?? gps ?? _tienda,
                initialZoom: 15.5,
                initialCameraFit: admin && distinta
                    ? _encuadrarEntrega(entrega)
                    : null,
                minZoom: 3,
                maxZoom: 19,
                backgroundColor: AppTheme.superficie,
                keepAlive: true,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () => _listo = true,
                onTap: widget.onSeleccion == null
                    ? null
                    : (_, punto) => widget.onSeleccion!(punto),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.andrade_motors',
                  maxNativeZoom: 19,
                  panBuffer: 0,
                ),
                MarkerLayer(
                  markers: [
                    _marcador(
                      _tienda,
                      tiendaDeliveryProvisional
                          ? 'ANDRADE MOTORS (ubicación provisional)'
                          : 'ANDRADE MOTORS',
                      Icons.storefront_outlined,
                      const Color(0xFF795518),
                      // Separa los símbolos si ambos representan el mismo punto.
                      alignment: entrega == _tienda || gps == _tienda
                          ? const Alignment(2.1, 0)
                          : Alignment.center,
                    ),
                    if (entrega != null && (entrega != gps || admin))
                      _marcador(
                        entrega,
                        admin
                            ? 'Ubicación de entrega del cliente'
                            : 'Punto de entrega',
                        Icons.place,
                        _colorEntrega,
                      ),
                    if (gps != null)
                      _marcador(
                        gps,
                        'Mi ubicación',
                        Icons.my_location,
                        _colorCliente,
                      ),
                  ],
                ),
                SimpleAttributionWidget(
                  source: const Text('OpenStreetMap contributors'),
                  backgroundColor: Colors.black87,
                  onTap: () => launchUrl(
                    Uri.https('www.openstreetmap.org', '/copyright'),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Acercar mapa',
                    icon: const Icon(Icons.add),
                    onPressed: () => _zoom(1),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Alejar mapa',
                    icon: const Icon(Icons.remove),
                    onPressed: () => _zoom(-1),
                  ),
                  IconButton.filledTonal(
                    tooltip: admin
                        ? 'Centrar en el cliente'
                        : 'Centrar en mi ubicación',
                    icon: const Icon(Icons.my_location),
                    onPressed: centro == null ? null : () => _centrar(centro),
                  ),
                  if (admin && distinta)
                    IconButton.filledTonal(
                      tooltip: 'Ver tienda y cliente',
                      icon: const Icon(Icons.fit_screen_outlined),
                      onPressed: () {
                        if (_listo) _mapa.fitCamera(_encuadrarEntrega(entrega));
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoom(double delta) {
    if (!_listo) return;
    final camara = _mapa.camera;
    _mapa.move(
      camara.center,
      (camara.zoom + delta).clamp(3.0, 19.0).toDouble(),
    );
  }
}
