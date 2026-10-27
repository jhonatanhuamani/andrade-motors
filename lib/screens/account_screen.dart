import 'package:flutter/material.dart';

import '../auth/session_scope.dart';
import '../widgets/premium_components.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageIntro(
          kicker: 'Andrade / Cuenta',
          title: session.esAdmin ? 'Configuración' : 'Mi perfil',
          subtitle: 'Tu sesión en Andrade Motors.',
        ),
        PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(Icons.person_outline),
              const SizedBox(height: 16),
              Text(session.cuentaVerificada?.correo ?? 'Correo no disponible'),
              const SizedBox(height: 8),
              Text(session.esAdmin ? 'Administrador' : 'Cliente'),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: session.ocupado ? null : session.cerrarSesion,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const PremiumPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANDRADE MOTORS'),
              SizedBox(height: 8),
              Text('Tienda y taller de motocicletas.'),
            ],
          ),
        ),
      ],
    );
  }
}
