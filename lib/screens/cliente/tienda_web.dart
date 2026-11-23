import 'package:flutter/material.dart';

import '../../data/contacto_tienda.dart';
import '../../data/datos_demo.dart' as demo;
import '../../models/producto.dart';
import '../../models/servicio.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_components.dart';
import '../../widgets/producto_card.dart';
import '../../widgets/servicio_card.dart';

const anchoTienda = 1320.0;

class InicioTiendaWeb extends StatelessWidget {
  const InicioTiendaWeb({
    super.key,
    required this.productos,
    required this.onCategoria,
    required this.onServicios,
    required this.onReservar,
    required this.favoritos,
    required this.onFavorito,
    required this.onProducto,
    required this.onAgregar,
    required this.footer,
  });

  final List<Producto> productos;
  final ValueChanged<String> onCategoria;
  final VoidCallback onServicios;
  final ValueChanged<Servicio> onReservar;
  final Set<String> favoritos;
  final ValueChanged<Producto> onFavorito, onProducto, onAgregar;
  final Widget footer;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    children: [
      _Portada(
        onProductos: () => onCategoria('Todos'),
        onServicios: onServicios,
      ),
      const SizedBox(height: 34),
      const SectionHeading('Explora por categoría'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final categoria in productos.map((p) => p.categoria).toSet())
            OutlinedButton(
              onPressed: () => onCategoria(categoria),
              child: Text(categoria),
            ),
        ],
      ),
      if (productos.isNotEmpty) ...[
        const SizedBox(height: 32),
        const SectionHeading('Productos destacados'),
        ResponsiveProductGrid(
          web: true,
          children: [
            for (final p in productos.take(4))
              ProductoCard(
                producto: p,
                favorito: favoritos.contains(p.sku),
                onFavorito: () => onFavorito(p),
                onTap: () => onProducto(p),
                onAgregar: () => onAgregar(p),
                web: true,
              ),
          ],
        ),
      ],
      const SizedBox(height: 32),
      const SectionHeading('Servicios de taller'),
      ServiciosTiendaGrid(onReservar: onReservar),
      footer,
    ],
  );
}

class _Portada extends StatelessWidget {
  const _Portada({required this.onProductos, required this.onServicios});

  final VoidCallback onProductos, onServicios;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ancho = constraints.maxWidth;
      final horizontal = ancho >= 760;
      final copy = Padding(
        padding: EdgeInsets.all(horizontal ? 42 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('PASIÓN EN MOVIMIENTO'),
            const SizedBox(height: 14),
            Text(
              'ANDRADE MOTORS',
              style: TextStyle(
                height: 1.03,
                fontSize: horizontal ? 56 : 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Repuestos, accesorios y mantenimiento para tu motocicleta.',
              style: TextStyle(
                color: AppTheme.secundario,
                fontSize: 17,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: onProductos,
                  child: const Text('Ver productos'),
                ),
                OutlinedButton(
                  onPressed: onServicios,
                  child: const Text('Nuestros servicios'),
                ),
              ],
            ),
          ],
        ),
      );
      final photo = Image.asset(
        'assets/images/banner/moto_principal.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: horizontal ? 430 : (ancho * .58).clamp(150.0, 300.0),
        alignment: Alignment.center,
        semanticLabel: 'Motocicleta Andrade Motors',
      );
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.superficie,
          border: Border.all(color: AppTheme.linea),
          borderRadius: BorderRadius.circular(24),
        ),
        child: horizontal
            ? Row(
                children: [
                  Expanded(flex: 5, child: copy),
                  Expanded(flex: 6, child: photo),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [copy, photo],
              ),
      );
    },
  );
}

class ServiciosTiendaGrid extends StatelessWidget {
  const ServiciosTiendaGrid({super.key, required this.onReservar});

  final ValueChanged<Servicio> onReservar;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 960
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      const spacing = 16.0;
      final width = (constraints.maxWidth - (count - 1) * spacing) / count;
      return Wrap(
        spacing: spacing,
        children: [
          for (final (index, servicio) in demo.servicios.indexed)
            SizedBox(
              width: width,
              child: ServicioCard(
                servicio: servicio,
                index: index,
                mostrarImagen: false,
                onReservar: () => onReservar(servicio),
              ),
            ),
        ],
      );
    },
  );
}

class ContactoTienda extends StatelessWidget {
  const ContactoTienda({super.key, required this.footer});

  final Widget footer;

  @override
  Widget build(BuildContext context) {
    const datos = [
      ('WhatsApp', whatsappTienda, Icons.chat_outlined),
      ('Teléfono', telefonoTienda, Icons.phone_outlined),
      ('Dirección', direccionTienda, Icons.location_on_outlined),
      ('Horario de atención', horarioTienda, Icons.schedule_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const PageIntro(
          kicker: 'ANDRADE MOTORS',
          title: 'Contacto',
          subtitle: 'Consultas sobre productos y atención en el taller.',
        ),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value, icon) in datos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: AppTheme.oro),
                  title: Text(label),
                  subtitle: Text(
                    value.isEmpty ? 'Pendiente de confirmar' : value,
                  ),
                ),
              const SizedBox(height: 16),
              const BotonWhatsApp(
                etiqueta: 'Contactar por WhatsApp',
                mensaje: 'Hola, Andrade Motors. Quisiera hacer una consulta.',
              ),
            ],
          ),
        ),
        footer,
      ],
    );
  }
}

class TiendaFooter extends StatelessWidget {
  const TiendaFooter({super.key, required this.onPagina});

  final ValueChanged<int> onPagina;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= 1000) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.superficie,
          border: Border(top: BorderSide(color: AppTheme.linea)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Expanded(child: AndradeBrand()),
              TextButton(
                onPressed: () => onPagina(1),
                child: const Text('Productos'),
              ),
              TextButton(
                onPressed: () => onPagina(2),
                child: const Text('Servicios'),
              ),
              TextButton(
                onPressed: () => onPagina(5),
                child: const Text('Contacto'),
              ),
              const SizedBox(width: 24),
              const Text(
                '© ANDRADE MOTORS',
                style: TextStyle(color: AppTheme.secundario, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
