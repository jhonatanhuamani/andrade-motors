import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CategoriaCard extends StatelessWidget {
  const CategoriaCard({
    super.key,
    required this.nombre,
    required this.icono,
    required this.onTap,
  });
  final String nombre;
  final IconData icono;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 94,
    child: Material(
      color: AppTheme.superficie,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.linea),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: AppTheme.oro, size: 28),
              const SizedBox(height: 9),
              Flexible(
                child: Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 2,
                width: 13,
                color: AppTheme.oro.withValues(alpha: .4),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
