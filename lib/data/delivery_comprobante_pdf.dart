import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/delivery_pedido.dart';

const _negro = PdfColor.fromInt(0xff141414);
const _oro = PdfColor.fromInt(0xffdbb65d);
const _linea = PdfColor.fromInt(0xffe2ded5);
const _gris = PdfColor.fromInt(0xff5a5650);

String nombreComprobanteDelivery(String id) =>
    'Andrade_Motors_Pedido_${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';

Future<Uint8List> generarComprobanteDelivery(DeliveryPedido pedido) async {
  final logoBytes = await rootBundle.load(
    'assets/images/logo/logo_andrade_motors.png',
  );
  final logo = pw.MemoryImage(
    logoBytes.buffer.asUint8List(
      logoBytes.offsetInBytes,
      logoBytes.lengthInBytes,
    ),
  );
  final fecha = pedido.createdAt.toLocal();
  String dos(int valor) => valor.toString().padLeft(2, '0');
  // El modelo actual conserva el correo como identificador visible del cliente.
  final cliente = pedido.cliente.trim();
  final correo = RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(cliente)
      ? cliente
      : 'No registrado en el pedido';
  final documento = pw.Document(
    title: 'Comprobante de pedido ${pedido.id}',
    author: 'ANDRADE MOTORS',
  );
  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      maxPages: 100,
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        padding: const pw.EdgeInsets.only(top: 7),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _linea)),
        ),
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: _gris),
        ),
      ),
      build: (_) => [
        pw.Container(
          color: _negro,
          padding: const pw.EdgeInsets.all(16),
          child: pw.Row(
            children: [
              pw.Image(logo, width: 62, height: 62, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ANDRADE MOTORS',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 21,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'PASIÓN EN MOVIMIENTO',
                      style: const pw.TextStyle(fontSize: 10, color: _oro),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        _titulo('Comprobante de pedido', tamano: 18),
        pw.SizedBox(height: 8),
        _dato('Número de pedido', pedido.id),
        _dato('Fecha', '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}'),
        _dato('Hora', '${dos(fecha.hour)}:${dos(fecha.minute)}'),
        _dato('Cliente', cliente.isEmpty ? 'No registrado' : cliente),
        _dato('Correo del cliente', correo),
        _dato('Estado actual del pedido', pedido.estado.hito),
        pw.SizedBox(height: 18),
        _titulo('Productos'),
        pw.SizedBox(height: 7),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(5),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _linea),
            bottom: pw.BorderSide(color: _linea),
          ),
          children: [
            pw.TableRow(
              repeat: true,
              decoration: const pw.BoxDecoration(color: _negro),
              children: [
                _celda('Producto', encabezado: true),
                _celda('Cantidad', encabezado: true, derecha: true),
                _celda('Precio unitario', encabezado: true, derecha: true),
                _celda('Subtotal', encabezado: true, derecha: true),
              ],
            ),
            for (final item in pedido.items)
              pw.TableRow(
                children: [
                  _celda(item.nombre),
                  _celda('${item.cantidad}', derecha: true),
                  _celda(importeDelivery(item.precioUnitario), derecha: true),
                  _celda(importeDelivery(item.subtotal), derecha: true),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 215,
            color: const PdfColor.fromInt(0xfff7f3e9),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _importe('Subtotal', pedido.subtotal),
                _importe('Costo delivery', pedido.costoDelivery),
                pw.Divider(color: _linea),
                _importe('TOTAL', pedido.total, total: true),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 18),
        _titulo('Datos de entrega'),
        pw.SizedBox(height: 6),
        _dato('Dirección de entrega', pedido.direccion),
        _dato(
          'Referencia',
          pedido.referencia.trim().isEmpty
              ? 'Sin referencia'
              : pedido.referencia,
        ),
        _dato(
          'Distancia aproximada',
          '${pedido.distanciaKm.toStringAsFixed(2)} km',
        ),
      ],
    ),
  );
  return documento.save();
}

pw.Widget _titulo(String texto, {double tamano = 13}) => pw.Text(
  texto,
  style: pw.TextStyle(
    color: _negro,
    fontSize: tamano,
    fontWeight: pw.FontWeight.bold,
  ),
);

pw.Widget _dato(String etiqueta, String valor) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.RichText(
    text: pw.TextSpan(
      style: const pw.TextStyle(fontSize: 10, color: _negro),
      children: [
        pw.TextSpan(
          text: '$etiqueta: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: valor),
      ],
    ),
  ),
);

pw.Widget _celda(
  String texto, {
  bool encabezado = false,
  bool derecha = false,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
  child: pw.Text(
    texto,
    textAlign: derecha ? pw.TextAlign.right : pw.TextAlign.left,
    style: pw.TextStyle(
      color: encabezado ? _oro : _negro,
      fontSize: 10,
      fontWeight: encabezado ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

pw.Widget _importe(String etiqueta, double valor, {bool total = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _titulo(etiqueta, tamano: total ? 13 : 10),
          _titulo(importeDelivery(valor), tamano: total ? 13 : 10),
        ],
      ),
    );
