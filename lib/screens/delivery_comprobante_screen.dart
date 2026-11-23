import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../auth/session_scope.dart';
import '../data/delivery_comprobante_pdf.dart';
import '../data/delivery_state.dart';
import '../models/delivery_pedido.dart';

class VerComprobanteButton extends StatelessWidget {
  const VerComprobanteButton({
    super.key,
    required this.pedidoId,
    required this.administrar,
  });

  final String pedidoId;
  final bool administrar;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DeliveryComprobanteScreen(
          pedidoId: pedidoId,
          administrar: administrar,
        ),
      ),
    ),
    icon: const Icon(Icons.picture_as_pdf_outlined),
    label: const Text('Ver comprobante'),
  );
}

class DeliveryComprobanteScreen extends StatelessWidget {
  const DeliveryComprobanteScreen({
    super.key,
    required this.pedidoId,
    required this.administrar,
  });

  final String pedidoId;
  final bool administrar;

  @override
  Widget build(BuildContext context) {
    final sesion = SessionScope.of(context);
    final pedido = DeliveryScope.of(context).buscar(pedidoId);
    final autorizado = administrar
        ? sesion.esAdmin
        : sesion.autenticado &&
              pedido?.clienteId != null &&
              pedido?.clienteId == sesion.cuentaVerificada?.identificador;
    if (!autorizado || pedido == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprobante')),
        body: const Center(child: Text('Comprobante no disponible.')),
      );
    }
    return _VistaComprobante(key: ObjectKey(pedido), pedido: pedido);
  }
}

class _VistaComprobante extends StatefulWidget {
  const _VistaComprobante({super.key, required this.pedido});

  final DeliveryPedido pedido;

  @override
  State<_VistaComprobante> createState() => _VistaComprobanteState();
}

class _VistaComprobanteState extends State<_VistaComprobante> {
  late final _pdf = generarComprobanteDelivery(widget.pedido);
  bool _exportando = false;

  Future<void> _exportar(BuildContext boton, Uint8List bytes) async {
    setState(() => _exportando = true);
    try {
      final caja = boton.findRenderObject() as RenderBox;
      await Printing.sharePdf(
        bytes: bytes,
        filename: nombreComprobanteDelivery(widget.pedido.id),
        bounds: caja.localToGlobal(Offset.zero) & caja.size,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo exportar el comprobante.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _pdf,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Comprobante'),
          actions: [
            if (bytes != null)
              Builder(
                builder: (context) => IconButton(
                  onPressed: _exportando
                      ? null
                      : () => _exportar(context, bytes),
                  tooltip: kIsWeb
                      ? 'Descargar comprobante'
                      : 'Compartir comprobante',
                  icon: Icon(kIsWeb ? Icons.download : Icons.share_outlined),
                ),
              ),
          ],
        ),
        body: bytes == null
            ? Center(
                child: snapshot.hasError
                    ? const Text('No se pudo generar el comprobante.')
                    : const CircularProgressIndicator(),
              )
            : PdfPreview(
                build: (_) => bytes,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName: nombreComprobanteDelivery(widget.pedido.id),
                maxPageWidth: 850,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowSharing: false,
                dynamicLayout: false,
                onError: (_, _) => const Center(
                  child: Text(
                    'Vista previa no disponible. Puedes exportar el PDF.',
                  ),
                ),
                onPrintError: (context, _) => ScaffoldMessenger.of(context)
                    .showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo imprimir el comprobante.'),
                      ),
                    ),
              ),
      );
    },
  );
}
