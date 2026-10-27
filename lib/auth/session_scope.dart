import 'package:flutter/widgets.dart';

import 'admin_session.dart';

class SessionScope extends InheritedNotifier<AdminSession> {
  const SessionScope({
    super.key,
    required AdminSession session,
    required super.child,
  }) : super(notifier: session);

  static AdminSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}

/// Protege también widgets abiertos directamente o mediante rutas con nombre.
class AdminOnly extends StatelessWidget {
  const AdminOnly({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SessionScope.of(context).esAdmin
      ? child
      : const Center(
          child: Text(
            'Acceso denegado. Se requiere una sesión administradora.',
          ),
        );
}
