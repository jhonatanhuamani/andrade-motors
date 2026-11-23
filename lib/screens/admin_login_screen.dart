import 'package:flutter/material.dart';

import '../auth/admin_session.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.session});
  final AdminSession session;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _ocultar = true;

  Future<void> _entrar() async {
    if (widget.session.ocupado || !_form.currentState!.validate()) return;
    final solicitud = widget.session.iniciarSesion(_correo.text, _clave.text);
    // El SDK gestiona la sesión; la interfaz no conserva la contraseña.
    _clave.clear();
    await solicitud;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: PremiumPanel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AndradeLogo(size: 64)),
                  const SizedBox(height: 24),
                  const Eyebrow('ANDRADE MOTORS'),
                  const SizedBox(height: 12),
                  Text(
                    'Inicia sesión',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bienvenido. Ingresa a tu cuenta para continuar.',
                    style: TextStyle(color: AppTheme.secundario),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _correo,
                    enabled: !widget.session.ocupado,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) =>
                        value == null ||
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value.trim())
                        ? 'Ingresa un correo válido'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clave,
                    enabled: !widget.session.ocupado,
                    obscureText: _ocultar,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _ocultar
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        onPressed: () => setState(() => _ocultar = !_ocultar),
                        icon: Icon(
                          _ocultar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Ingresa tu contraseña'
                        : null,
                  ),
                  if (widget.session.mensaje != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.session.mensaje!,
                        style: const TextStyle(color: AppTheme.alerta),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: widget.session.ocupado ? null : _entrar,
                    icon: widget.session.ocupado
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      widget.session.ocupado
                          ? 'Verificando sesión…'
                          : 'Iniciar sesión',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
