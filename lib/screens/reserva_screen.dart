import 'package:flutter/material.dart';

import '../data/datos_demo.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

class ReservaScreen extends StatefulWidget {
  const ReservaScreen({super.key, this.servicioInicial, this.revision = 0});
  final String? servicioInicial;
  final int revision;
  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final form = GlobalKey<FormState>();
  late String? servicio = widget.servicioInicial;
  final marca = TextEditingController();
  final modelo = TextEditingController();
  final anio = TextEditingController();
  final notas = TextEditingController();
  DateTime? fecha;
  TimeOfDay? hora;
  final List<String> reservas = [];
  @override
  void didUpdateWidget(covariant ReservaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.servicioInicial != oldWidget.servicioInicial ||
        widget.revision != oldWidget.revision) {
      servicio = widget.servicioInicial;
    }
  }

  @override
  void dispose() {
    marca.dispose();
    modelo.dispose();
    anio.dispose();
    notas.dispose();
    super.dispose();
  }

  String? requerido(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este campo' : null;
  Future<void> elegirFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final elegida = await showDatePicker(
      context: context,
      initialDate: fecha != null && !fecha!.isBefore(hoy) ? fecha : hoy,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (elegida != null && mounted) setState(() => fecha = elegida);
  }

  Future<void> elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: hora ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (elegida != null && mounted) setState(() => hora = elegida);
  }

  void confirmar() {
    if (!form.currentState!.validate()) return;
    if (fecha == null || hora == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona fecha y hora.')));
      return;
    }
    final cita = DateTime(
      fecha!.year,
      fecha!.month,
      fecha!.day,
      hora!.hour,
      hora!.minute,
    );
    if (!cita.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una fecha y hora futuras.')),
      );
      return;
    }
    final resumen =
        '$servicio · ${marca.text.trim()} ${modelo.text.trim()} · ${fecha!.day}/${fecha!.month}/${fecha!.year} · ${hora!.format(context)}';
    setState(() => reservas.insert(0, resumen));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppTheme.oro,
          size: 44,
        ),
        title: const Text('¡Reserva registrada!'),
        content: Text(
          '$resumen\n\nReserva de demostración guardada durante esta sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elegido = servicio == null
        ? null
        : servicios.firstWhere((s) => s.nombre == servicio);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const PageIntro(
              kicker: 'Andrade / Agenda tu visita',
              title: 'Tu próxima ruta,\nen buenas manos.',
              subtitle: 'Cuéntanos sobre tu moto. Nosotros nos encargamos del cuidado.',
            ),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill('01 · Servicio', color: AppTheme.oro),
                StatusPill('02 · Tu moto', color: AppTheme.secundario),
                StatusPill('03 · Tu visita', color: AppTheme.secundario),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReservationSection(
                    number: '01',
                    title: 'Elige tu servicio',
                    subtitle: 'El primer paso para volver a rodar.',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(servicio),
                          initialValue: servicio,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Servicio de mantenimiento',
                            prefixIcon: Icon(Icons.handyman_outlined),
                          ),
                          items: servicios
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.nombre,
                                  child: Text(
                                    s.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => servicio = v),
                          validator: requerido,
                        ),
                        if (elegido != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: AppTheme.oro,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Aprox. ${elegido.duracion}',
                                  style: const TextStyle(
                                    color: AppTheme.secundario,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                'Desde S/ ${elegido.precio.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppTheme.oro,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReservationSection(
                    number: '02',
                    title: 'Conozcamos tu moto',
                    subtitle: 'Cada modelo merece atención especial.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: marca,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Marca de motocicleta',
                            hintText: 'Ej. Yamaha',
                            prefixIcon: Icon(Icons.two_wheeler_rounded),
                          ),
                          validator: requerido,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: modelo,
                          decoration: const InputDecoration(
                            labelText: 'Modelo',
                            hintText: 'Ej. FZ 25',
                            prefixIcon: Icon(Icons.settings_outlined),
                          ),
                          validator: requerido,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: anio,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Año de fabricación',
                            hintText: 'Ej. 2024',
                            prefixIcon: Icon(Icons.date_range_outlined),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return n == null ||
                                    n < 1950 ||
                                    n > DateTime.now().year + 1
                                ? 'Ingresa un año válido'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReservationSection(
                    number: '03',
                    title: 'Reserva tu momento',
                    subtitle: 'Elige cuándo quieres visitarnos.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DateTile(
                          label: 'FECHA DE VISITA',
                          value: fecha == null
                              ? 'Seleccionar fecha'
                              : '${fecha!.day}/${fecha!.month}/${fecha!.year}',
                          icon: Icons.calendar_month_outlined,
                          onTap: elegirFecha,
                        ),
                        const SizedBox(height: 12),
                        _DateTile(
                          label: 'HORA DE ATENCIÓN',
                          value: hora == null
                              ? 'Seleccionar hora'
                              : hora!.format(context),
                          icon: Icons.schedule_rounded,
                          onTap: elegirHora,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notas,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones (opcional)',
                            hintText:
                                '¿Algún ruido o detalle que debamos revisar?',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: confirmar,
                    icon: const Icon(Icons.event_available_rounded, size: 20),
                    label: const Text('Confirmar reserva'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppTheme.secundario,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prototipo local. La reserva se guarda durante esta sesión y no se envía al taller.',
                    style: TextStyle(fontSize: 11, color: AppTheme.secundario),
                  ),
                ),
              ],
            ),
            if (reservas.isNotEmpty) ...[
              const SizedBox(height: 30),
              const SectionHeading(
                'Tus próximas visitas',
                subtitle: 'Reservas guardadas en esta sesión.',
              ),
              ...reservas.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumPanel(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const IconTile(Icons.event_available_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const StatusPill('Registrada en esta sesión'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReservationSection extends StatelessWidget {
  const _ReservationSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String number, title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => PremiumPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.oro.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: AppTheme.oro,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.secundario, fontSize: 11),
        ),
        const SizedBox(height: 22),
        child,
      ],
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    child: Row(
      children: [
        Icon(icon, color: AppTheme.oro, size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.5,
                  color: AppTheme.secundario,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppTheme.secundario,
        ),
      ],
    ),
  );
}
