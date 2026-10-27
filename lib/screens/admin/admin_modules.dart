import 'package:flutter/material.dart';

import '../../auth/session_scope.dart';
import '../../data/datos_demo.dart' as demo;
import '../../models/producto.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_components.dart';
import '../../widgets/admin_producto_card.dart';
import '../../widgets/premium_banner.dart' show MotoShowcasePainter;
import 'producto_form_screen.dart';

class PendingModule extends StatelessWidget {
  const PendingModule({
    super.key,
    required this.titulo,
    required this.descripcion,
  });
  final String titulo, descripcion;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      PageIntro(
        kicker: 'Andrade / Administración',
        title: titulo,
        subtitle: 'Pendiente de implementación',
      ),
      PremiumPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(Icons.construction_outlined),
            const SizedBox(height: 16),
            Text(descripcion),
            const SizedBox(height: 12),
            const Text(
              'Sin conexión remota. No se muestran registros ficticios como datos reales.',
              style: TextStyle(color: AppTheme.secundario),
            ),
          ],
        ),
      ),
    ],
  );
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.productos,
    required this.usaRespaldo,
    this.onProductos,
    this.onInventario,
    this.onServicios,
  });
  final List<Producto> productos;
  final bool usaRespaldo;
  final VoidCallback? onProductos, onInventario, onServicios;
  @override
  Widget build(BuildContext context) {
    final valor = productos.fold<double>(
      0,
      (sum, p) => sum + p.precio * p.stock,
    );
    final valorTexto = valor
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            const Eyebrow('Andrade / Centro de control'),
            StatusPill(
              usaRespaldo ? 'Respaldo local' : 'Catálogo Firestore',
              color: usaRespaldo ? AppTheme.secundario : AppTheme.oro,
              icon: Icons.storage_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _DashboardBanner(),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in [
                (
                  '${productos.length}',
                  'Productos',
                  'Referencias registradas',
                  Icons.inventory_2_outlined,
                  false,
                ),
                (
                  '${productos.where((p) => p.stock <= 5).length}',
                  'Stock bajo',
                  'Requieren atención',
                  Icons.warning_amber_rounded,
                  true,
                ),
                (
                  'S/ $valorTexto',
                  'Valor del inventario',
                  'Capital en productos',
                  Icons.payments_outlined,
                  false,
                ),
                (
                  '${demo.servicios.length}',
                  'Servicios',
                  'Servicios locales',
                  Icons.build_outlined,
                  false,
                ),
              ])
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: _DashboardMetric(
                    value: item.$1,
                    label: item.$2,
                    detail: item.$3,
                    icon: item.$4,
                    gold: item.$5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeading(
          'Accesos rápidos',
          subtitle: 'Lo esencial de tu negocio, a un toque.',
        ),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final acceso in [
                ('Productos', Icons.grid_view_outlined, onProductos),
                ('Inventario', Icons.inventory_2_outlined, onInventario),
                ('Servicios', Icons.build_outlined, onServicios),
              ])
                SizedBox(
                  width: (constraints.maxWidth - 24) / 3,
                  child: OutlinedButton(
                    onPressed: acceso.$3,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      side: BorderSide(
                        color: AppTheme.oro.withValues(alpha: .25),
                      ),
                      backgroundColor: AppTheme.oro.withValues(alpha: .04),
                    ),
                    child: Column(
                      children: [
                        IconTile(acceso.$2, size: 35),
                        const SizedBox(height: 10),
                        Text(
                          acceso.$1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
              for (final p in productos.where((p) => p.stock <= 5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
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
                            const SizedBox(height: 4),
                            Text(
                              p.sku,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.secundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill('${p.stock} uds.', color: AppTheme.oro),
                    ],
                  ),
                ),
              if (!productos.any((p) => p.stock <= 5))
                const Text('Sin alertas de stock bajo.'),
              OutlinedButton.icon(
                onPressed: onInventario,
                icon: const Icon(Icons.inventory_outlined, size: 18),
                label: const Text('Consultar inventario'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(
          'Resumen general',
          subtitle: 'Servicios disponibles y próximos módulos.',
        ),
        PremiumPanel(
          child: Column(
            children: [
              Row(
                children: [
                  const IconTile(Icons.build_outlined, size: 35),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Servicios locales',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${demo.servicios.length}',
                    style: const TextStyle(
                      color: AppTheme.oro,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              const Row(
                children: [
                  IconTile(Icons.receipt_long_outlined, size: 35, gold: false),
                  SizedBox(width: 12),
                  Expanded(child: Text('Pedidos')),
                  StatusPill('Pendiente', color: AppTheme.secundario),
                ],
              ),
              const Divider(height: 28),
              const Row(
                children: [
                  IconTile(
                    Icons.calendar_month_outlined,
                    size: 35,
                    gold: false,
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('Reservas')),
                  StatusPill('Pendiente', color: AppTheme.secundario),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Servicios: datos locales. Pedidos y reservas: integración pendiente; no hay totales remotos disponibles.',
          style: TextStyle(color: AppTheme.secundario),
        ),
      ],
    );
  }
}

class _DashboardBanner extends StatelessWidget {
  const _DashboardBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppTheme.oro.withValues(alpha: .28)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF302A20), Color(0xFF111418), Color(0xFF080A0D)],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= 620;
        final texto = Padding(
          padding: EdgeInsets.fromLTRB(24, 26, ancho ? 0 : 24, ancho ? 26 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('ANDRADE MOTORS'),
              const SizedBox(height: 18),
              Text.rich(
                const TextSpan(
                  text: 'Tu negocio,\n',
                  children: [
                    TextSpan(
                      text: 'en movimiento.',
                      style: TextStyle(color: AppTheme.oro),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontSize: ancho ? 32 : 28, height: 1.12),
              ),
              const SizedBox(height: 14),
              const Text(
                'Control de productos, inventario y servicios.',
                style: TextStyle(
                  color: AppTheme.secundario,
                  height: 1.6,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 42,
                height: 2,
                decoration: const BoxDecoration(
                  gradient: AppTheme.gradienteOro,
                ),
              ),
            ],
          ),
        );
        final moto = Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: AspectRatio(
            aspectRatio: 1.5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/banner/moto_principal.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, trace) =>
                      const CustomPaint(painter: MotoShowcasePainter()),
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00101418),
                          Color(0x00101418),
                          Color(0x88080A0D),
                        ],
                        stops: [0, .75, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return ancho
            ? Row(
                children: [
                  Expanded(flex: 4, child: texto),
                  Expanded(flex: 5, child: moto),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [texto, moto],
              );
      },
    ),
  );
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
    required this.gold,
  });
  final String value, label, detail;
  final IconData icon;
  final bool gold;
  @override
  Widget build(BuildContext context) => PremiumPanel(
    gold: gold,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon, size: 35, gold: gold),
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
                letterSpacing: -.8,
                color: gold ? AppTheme.oro : AppTheme.texto,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: const TextStyle(fontSize: 9, color: AppTheme.secundario),
        ),
      ],
    ),
  );
}

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key, required this.productos});
  final List<Producto> productos;
  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  String busqueda = '', categoria = 'Todos';
  final controller = TextEditingController();

  Future<void> _abrirFormulario([Producto? producto]) async {
    if (!SessionScope.of(context).esAdmin) return;
    final confirmado = await Navigator.of(context).push<Producto>(
      MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: producto)),
    );
    if (!mounted || confirmado == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${confirmado.nombre} guardado en Firestore.')),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autorizado = SessionScope.of(context).esAdmin;
    final lista = widget.productos
        .where(
          (p) =>
              (categoria == 'Todos' || categoria == p.categoria) &&
              '${p.nombre} ${p.sku}'.toLowerCase().contains(
                busqueda.toLowerCase(),
              ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const PageIntro(
          kicker: 'Andrade / Administración',
          title: 'Productos',
          subtitle: 'Tu catálogo, con cada detalle bajo control.',
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Buscar productos',
            hintText: 'Nombre o SKU',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: busqueda.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      controller.clear();
                      setState(() => busqueda = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
          onChanged: (v) => setState(() => busqueda = v),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in [
                'Todos',
                ...widget.productos.map((p) => p.categoria).toSet(),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: categoria == c,
                    onSelected: (_) => setState(() => categoria = c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PremiumPanel(
          padding: const EdgeInsets.all(14),
          gold: true,
          child: Row(
            children: [
              const IconTile(Icons.edit_note_rounded, size: 35),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Agrega o edita productos y confirma Guardar para enviarlos a Firestore. Fotografías nuevas y activación independiente pendientes.',
                  style: TextStyle(fontSize: 11, color: AppTheme.secundario),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: autorizado ? _abrirFormulario : null,
          style: FilledButton.styleFrom(
            disabledBackgroundColor: AppTheme.oro.withValues(alpha: .12),
            disabledForegroundColor: AppTheme.oro.withValues(alpha: .6),
            side: BorderSide(color: AppTheme.oro.withValues(alpha: .25)),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Agregar producto'),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                '${lista.length} productos',
                style: const TextStyle(
                  color: AppTheme.secundario,
                  fontSize: 12,
                ),
              ),
            ),
            const Eyebrow('Colección Andrade'),
          ],
        ),
        const SizedBox(height: 14),
        if (lista.isEmpty)
          const PremiumPanel(
            child: Column(
              children: [
                IconTile(Icons.search_off_rounded, size: 60),
                SizedBox(height: 16),
                Text('No se encontraron productos.'),
                SizedBox(height: 8),
                Text(
                  'Prueba otro nombre, SKU o categoría.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.secundario),
                ),
              ],
            ),
          ),
        ResponsiveProductGrid(
          children: [
            for (final p in lista)
              AdminProductoCard(
                producto: p,
                onEditar: autorizado ? () => _abrirFormulario(p) : null,
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Fotografías originales. Los cambios se confirman en Firestore únicamente al guardar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.secundario, fontSize: 10),
        ),
      ],
    );
  }
}

class AdminServices extends StatelessWidget {
  const AdminServices({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const PageIntro(
        kicker: 'Andrade / Administración',
        title: 'Servicios',
        subtitle: 'Datos locales actuales. Gestión remota pendiente (3C).',
      ),
      const FilledButton(
        onPressed: null,
        child: Text('Agregar servicio · Pendiente'),
      ),
      const SizedBox(height: 16),
      for (final s in demo.servicios)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nombre, style: Theme.of(context).textTheme.titleMedium),
                Text(s.descripcion),
                Text(
                  'S/ ${s.precio.toStringAsFixed(2)} · ${s.duracion}',
                  style: const TextStyle(color: AppTheme.oro),
                ),
                const TextButton(
                  onPressed: null,
                  child: Text('Editar / activar / desactivar · Pendiente'),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Cuenta actual: ${SessionScope.of(context).cuentaVerificada?.correo ?? 'Sin correo'} · Administrador',
        ),
      ),
      const Expanded(
        child: PendingModule(
          titulo: 'Usuarios',
          descripcion: 'Consulta de cuentas, identificación de administradores y clientes, edición y permisos: pendientes (3D). Requieren un servidor seguro con Firebase Admin SDK. No se consultan ni modifican otras cuentas.',
        ),
      ),
    ],
  );
}
