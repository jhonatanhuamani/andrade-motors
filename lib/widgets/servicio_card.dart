import 'package:flutter/material.dart';

import '../models/servicio.dart';
import '../theme/app_theme.dart';
import 'premium_components.dart';

class ServicioCard extends StatelessWidget {
  const ServicioCard({
    super.key,
    required this.servicio,
    required this.onReservar,
    this.index = 0,
  });
  final Servicio servicio;
  final VoidCallback onReservar;
  final int index;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: PremiumPanel(
      gold: index == 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (servicio.imagenAsset != null)
            Image.asset(
              servicio.imagenAsset!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                  frame == null && !wasSynchronouslyLoaded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: child,
                    ),
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          Row(
            children: [
              IconTile(servicio.icono, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Eyebrow(
                  index == 0 ? 'Cuidado esencial' : 'Servicio especializado',
                ),
              ),
              Text(
                '0${index + 1}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: .07),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            servicio.nombre,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            servicio.descripcion,
            style: const TextStyle(color: AppTheme.secundario, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                servicio.duracion,
                color: AppTheme.secundario,
                icon: Icons.schedule_rounded,
              ),
              const StatusPill(
                'Atención técnica',
                color: AppTheme.secundario,
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MANO DE OBRA DESDE',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppTheme.secundario,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'S/ ${servicio.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.oro,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onReservar,
                label: const Text('Reservar'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
