import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_components.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key, required this.productos});
  final List<Producto> productos;
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final List<({String nombre, int stock, double precio})> agregados = [];
  Future<void> agregar() async {
    final form = GlobalKey<FormState>();
    final nombre = TextEditingController();
    final precio = TextEditingController();
    final stock = TextEditingController();
    final resultado = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar producto'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precio,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Precio (S/)'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return n == null || !n.isFinite || n <= 0
                        ? 'Ingresa un precio válido'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  validator: (v) => (int.tryParse(v ?? '') ?? -1) < 0
                      ? 'Ingresa un stock válido'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (resultado == true && mounted) {
      setState(
        () => agregados.add((
          nombre: nombre.text.trim(),
          stock: int.parse(stock.text),
          precio: double.parse(precio.text.replaceAll(',', '.')),
        )),
      );
    }
    // El diálogo debe terminar de desmontarse antes de liberar sus campos.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nombre.dispose();
    precio.dispose();
    stock.dispose();
  }

  void gestionar() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Inventario de demostración',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...widget.productos.map(
                    (p) => ListTile(
                      leading: Icon(p.icono, color: AppTheme.oro),
                      title: Text(p.nombre),
                      subtitle: Text('${p.sku} × ${p.precioTexto}'),
                      trailing: Text('${p.stock} uds.'),
                    ),
                  ),
                  ...agregados.map(
                    (p) => ListTile(
                      leading: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppTheme.oro,
                      ),
                      title: Text(p.nombre),
                      subtitle: Text(
                        'S/ ${p.precio.toStringAsFixed(2)} · Nuevo local',
                      ),
                      trailing: Text('${p.stock} uds.'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  void reportes() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Eyebrow('Andrade / Inteligencia comercial'),
            const SizedBox(height: 12),
            const Text(
              'Reporte de ventas',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Resumen mensual · Datos de ejemplo',
              style: TextStyle(color: AppTheme.secundario),
            ),
            const SizedBox(height: 24),
            const PremiumPanel(
              gold: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Eyebrow('Ventas del mes'),
                  SizedBox(height: 10),
                  Text(
                    'S/ 8,450',
                    style: TextStyle(
                      fontSize: 36,
                      color: AppTheme.oro,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '18 pedidos · Ticket promedio S/ 469.44',
                    style: TextStyle(color: AppTheme.secundario, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading('Distribución por categoría'),
            ...[
              ('Accesorios', .46),
              ('Repuestos', .28),
              ('Llantas', .16),
              ('Aceites', .10),
            ].map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 17),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.$1)),
                        Text(
                          '${(e.$2 * 100).round()}%',
                          style: const TextStyle(color: AppTheme.oro),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    LinearProgressIndicator(
                      value: e.$2,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: AppTheme.linea,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final valor =
        (widget.productos.fold<double>(
                  0,
                  (sum, p) => sum + p.precio * p.stock,
                ) +
                agregados.fold<double>(0, (sum, p) => sum + p.precio * p.stock))
            .toStringAsFixed(0)
            .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const Row(
          children: [
            Expanded(child: Eyebrow('Andrade / Centro de control')),
            StatusPill(
              'Vista local',
              color: AppTheme.secundario,
              icon: Icons.storage_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Tu negocio,\nen perspectiva.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text(
          'Inventario, alertas y movimientos en un solo lugar.',
          style: TextStyle(color: AppTheme.secundario),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 4 : 2;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  value: '${widget.productos.length + agregados.length}',
                  label: 'Productos',
                  detail: 'Referencias registradas',
                  icon: Icons.inventory_2_outlined,
                  width: width,
                ),
                _Metric(
                  value:
                      '${widget.productos.where((p) => p.stock <= 5).length + agregados.where((p) => p.stock <= 5).length}',
                  label: 'Stock bajo',
                  detail: 'Requieren atención',
                  icon: Icons.warning_amber_rounded,
                  width: width,
                  warning: true,
                ),
                _Metric(
                  value: 'S/ $valor',
                  label: 'Valor inventario',
                  detail: 'Capital en productos',
                  icon: Icons.payments_outlined,
                  width: width,
                ),
                _Metric(
                  value: '18',
                  label: 'Pedidos',
                  detail: 'Resumen del mes',
                  icon: Icons.receipt_long_outlined,
                  width: width,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: agregar,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar producto'),
        ),
        const SizedBox(height: 28),
        PremiumPanel(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  IconTile(Icons.notifications_active_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atención al stock',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Planifica tu próxima reposición.',
                          style: TextStyle(
                            color: AppTheme.secundario,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...widget.productos
                  .where((p) => p.stock <= 5)
                  .map(
                    (p) =>
                        _StockRow(nombre: p.nombre, sku: p.sku, stock: p.stock),
                  ),
              ...agregados
                  .where((p) => p.stock <= 5)
                  .map(
                    (p) => _StockRow(
                      nombre: p.nombre,
                      sku: 'Nuevo producto local',
                      stock: p.stock,
                    ),
                  ),
              const SizedBox(height: 6),
              const Text(
                'Muestra de productos con 5 unidades o menos.',
                style: TextStyle(color: AppTheme.secundario, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SectionHeading(
          'Productos en inventario',
          subtitle: 'Una vista rápida de tus referencias.',
          action: 'Gestionar ↗',
          onAction: gestionar,
        ),
        PremiumPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ...widget.productos
                  .take(4)
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          IconTile(p.icono, gold: false),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.nombre,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${p.categoria} · ${p.sku}',
                                  style: const TextStyle(
                                    color: AppTheme.secundario,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                p.precioTexto,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${p.stock} uds.',
                                style: TextStyle(
                                  color: p.stock <= 5
                                      ? AppTheme.oro
                                      : AppTheme.verde,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ...agregados.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.nombre, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    'S/ ${p.precio.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.oro),
                  ),
                  trailing: Text('${p.stock} uds.'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: gestionar,
          icon: const Icon(Icons.inventory_outlined, size: 18),
          label: const Text('Gestionar inventario'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: reportes,
          icon: const Icon(Icons.bar_chart_rounded, size: 18),
          label: const Text('Reportes de ventas'),
        ),
        const SizedBox(height: 20),
        const Text(
          'Datos de ejemplo. Los cambios se conservan durante esta sesión.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.secundario, fontSize: 10),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
    required this.width,
    this.warning = false,
  });
  final String value, label, detail;
  final IconData icon;
  final double width;
  final bool warning;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: PremiumPanel(
      gold: warning,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, size: 35, gold: warning),
          const SizedBox(height: 20),
          SizedBox(
            height: 34,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: warning ? AppTheme.oro : AppTheme.texto,
                  letterSpacing: -.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(color: AppTheme.secundario, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    required this.nombre,
    required this.sku,
    required this.stock,
  });
  final String nombre, sku;
  final int stock;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sku,
                style: const TextStyle(color: AppTheme.secundario, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusPill('$stock uds.', color: AppTheme.oro),
      ],
    ),
  );
}
