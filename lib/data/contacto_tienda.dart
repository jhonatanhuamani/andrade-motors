import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const whatsappTienda = ''; // Solo dígitos, incluido el código internacional.
const telefonoTienda = '';
const direccionTienda = '';
const horarioTienda = '';

class BotonWhatsApp extends StatelessWidget {
  const BotonWhatsApp({
    super.key,
    required this.etiqueta,
    required this.mensaje,
  });

  final String etiqueta;
  final String mensaje;

  Future<void> _abrir(BuildContext context) async {
    final url = Uri.https('wa.me', '/$whatsappTienda', {'text': mensaje});
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: whatsappTienda.isEmpty
        ? 'Número pendiente de confirmar'
        : etiqueta,
    child: OutlinedButton.icon(
      onPressed: whatsappTienda.isEmpty ? null : () => _abrir(context),
      icon: const Icon(Icons.chat_outlined),
      label: Text(etiqueta),
    ),
  );
}
