import 'package:flutter/material.dart';

import '../data/datos_demo.dart';
import '../models/servicio.dart';
import '../widgets/servicio_card.dart';
import '../widgets/premium_components.dart';
import '../theme/app_theme.dart';

class ServiciosScreen extends StatelessWidget {
  const ServiciosScreen({super.key, required this.onReservar});
  final void Function(Servicio) onReservar;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    children: [
      const PageIntro(
        kicker: 'Andrade / Servicio técnico',
        title: 'Cuida lo que\nte mueve.',
        subtitle: 'Mantenimiento con atención al detalle. Para que tu única preocupación sea el camino.',
      ),
      PremiumPanel(
        gold: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                IconTile(Icons.handyman_rounded, size: 50),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('Tu moto, en buenas manos'),
                      SizedBox(height: 6),
                      Text(
                        'Precisión en cada ajuste.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 22,
                runSpacing: 12,
                children: const [
                  _WorkshopFact('01', 'Elige tu servicio'),
                  _WorkshopFact('02', 'Agenda tu visita'),
                  _WorkshopFact('03', 'Vuelve a rodar'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      const SectionHeading(
        'Mantenimiento a tu medida',
        subtitle: 'El cuidado correcto, en el momento indicado.',
      ),
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 16,
          children: servicios
              .asMap()
              .entries
              .map(
                (e) => SizedBox(
                  width: constraints.maxWidth > 650
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: ServicioCard(
                    servicio: e.value,
                    index: e.key,
                    onReservar: () => onReservar(e.value),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 8),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.secundario,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Precios referenciales de mano de obra. Los repuestos y materiales se cotizan por separado según tu motocicleta.',
              style: TextStyle(fontSize: 11, color: AppTheme.secundario),
            ),
          ),
        ],
      ),
    ],
  );
}

class _WorkshopFact extends StatelessWidget {
  const _WorkshopFact(this.number, this.text);
  final String number, text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        number,
        style: const TextStyle(
          color: AppTheme.oro,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 7),
      Text(
        text,
        style: const TextStyle(color: AppTheme.secundario, fontSize: 10),
      ),
    ],
  );
}
