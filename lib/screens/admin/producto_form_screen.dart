import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../../auth/session_scope.dart';
import '../../data/catalogo_state.dart';
import '../../data/datos_demo.dart' as demo;
import '../../data/producto_edicion.dart';
import '../../data/productos_escritura.dart';
import '../../models/producto.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_components.dart';
import '../../widgets/producto_preview.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});
  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _campos;
  String? _categoria, _imagen, _error;
  bool _guardando = false;
  bool _seleccionando = false;
  bool _activo = true;
  Uint8List? _fotografia;
  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _categoria = p?.categoria;
    _imagen = p?.imagenAsset;
    _activo = p?.activo ?? true;
    _campos = {
      'sku': TextEditingController(text: p?.sku ?? ''),
      'nombre': TextEditingController(text: p?.nombre ?? ''),
      'precio': TextEditingController(text: p?.precio.toString() ?? ''),
      'stock': TextEditingController(text: p?.stock.toString() ?? ''),
      'descripcion': TextEditingController(text: p?.descripcion ?? ''),
      'caracteristicas': TextEditingController(
        text: p?.caracteristicas.join('\n') ?? '',
      ),
      'compatibilidad': TextEditingController(
        text: p?.compatibilidad.join('\n') ?? '',
      ),
    };
  }

  String _texto(String campo) => _campos[campo]!.text;
  List<String> _lista(String campo) =>
      _texto(campo)
          .split('\n')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();
  Future<void> _seleccionarFotografia() async {
    setState(() => _seleccionando = true);
    ImageSource? fuente;
    try {
      fuente = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (hoja) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seleccionar imagen',
                  style: Theme.of(hoja).textTheme.titleLarge,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppTheme.oro,
                  ),
                  title: const Text('Cámara'),
                  subtitle: const Text('Tomar foto'),
                  onTap: () => Navigator.pop(hoja, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.oro,
                  ),
                  title: const Text('Galería'),
                  subtitle: const Text('Elegir desde galería'),
                  onTap: () => Navigator.pop(hoja, ImageSource.gallery),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(hoja),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      );
      if (fuente == null || !mounted) return;
      final archivo = await ImagePicker().pickImage(
        source: fuente,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (archivo == null) return;
      if (await archivo.length() > 10 * 1024 * 1024) {
        throw const FormatException(
          'Selecciona una fotografía de hasta 10 MB.',
        );
      }
      final codec = await ui.instantiateImageCodec(await archivo.readAsBytes());
      try {
        final frame = await codec.getNextFrame();
        try {
          final data = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (data == null || data.lengthInBytes > 10 * 1024 * 1024) {
            throw const FormatException(
              'La fotografía procesada supera 10 MB.',
            );
          }
          if (mounted) {
            setState(() {
              _fotografia = data.buffer.asUint8List();
              _error = null;
            });
          }
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error = fuente == ImageSource.camera
              ? 'No se pudo acceder a la cámara. Verifica los permisos de la aplicación.'
              : 'No se pudo acceder a la galería. Verifica los permisos de la aplicación.',
        );
      }
    } on UnsupportedError {
      if (mounted) {
        setState(
          () => _error = 'Esta plataforma no admite la opción seleccionada.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo procesar la fotografía.');
      }
    } finally {
      if (mounted) setState(() => _seleccionando = false);
    }
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    final session = SessionScope.of(context);
    if (!session.esAdmin) {
      setState(() => _error = 'Se requiere una sesión administrativa válida.');
      return;
    }
    final catalogo = CatalogoScope.of(context);
    final datos = ProductoEdicion(
      sku: _texto('sku'),
      nombre: _texto('nombre'),
      categoria: _categoria!,
      precio: ProductoEdicion.leerPrecio(_texto('precio'))!,
      stock: int.parse(_texto('stock').trim()),
      descripcion: _texto('descripcion'),
      caracteristicas: _lista('caracteristicas'),
      compatibilidad: _lista('compatibilidad'),
      imagenAsset: _imagen,
      imagenUrl: widget.producto?.imagenUrl,
      activo: _activo,
      fotografia: _fotografia,
    );
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final confirmado = _editando
          ? await catalogo.actualizarProducto(widget.producto!.sku, datos)
          : await catalogo.crearProducto(datos);
      if (!mounted) return;
      // Habilitar la salida del PopScope solo tras la confirmación del servidor.
      setState(() => _guardando = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(confirmado);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = switch (error) {
          ErrorEscrituraProducto() => error.mensaje,
          FormatException() => error.message,
          FirebaseException() =>
            '${error.code}: ${error.message ?? 'No se pudo confirmar el guardado en Firebase.'}',
          _ => 'No se pudo confirmar el guardado: $error',
        };
      });
    }
  }

  Widget _campo(
    String nombre,
    String etiqueta, {
    int lineas = 1,
    TextInputType? teclado,
    String? Function(String)? validar,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('producto-$nombre'),
      controller: _campos[nombre],
      enabled: !_guardando,
      readOnly: nombre == 'sku' && _editando,
      maxLines: lineas,
      keyboardType: teclado,
      autocorrect: nombre != 'sku',
      textCapitalization: nombre == 'sku'
          ? TextCapitalization.characters
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: nombre == 'sku'
            ? 'Identificador permanente. Letras, números y guiones.'
            : null,
      ),
      validator: (v) => validar != null
          ? validar(v ?? '')
          : (v == null || v.trim().isEmpty ? 'Completa este campo.' : null),
    ),
  );

  @override
  void dispose() {
    for (final controller in _campos.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso restringido')),
        body: const Center(
          child: Text(
            'Acceso denegado. Solo administradores pueden editar productos.',
          ),
        ),
      );
    }
    final categorias = {
      ...demo.categorias.keys.where((c) => c != 'Taller'),
      ?_categoria,
    };
    final fotos = {
      for (final p in demo.productos)
        if (p.imagenAsset != null) p.imagenAsset!: p.nombre,
    };
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editando ? 'Editar producto' : 'Agregar producto'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Eyebrow('Andrade / Productos'),
                    const SizedBox(height: 12),
                    PremiumPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _campo(
                            'sku',
                            'SKU',
                            validar: ProductoEdicion.validarSku,
                          ),
                          _campo('nombre', 'Nombre del producto'),
                          DropdownButtonFormField<String>(
                            key: const ValueKey('producto-categoria'),
                            initialValue: _categoria,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items: [
                              for (final c in categorias)
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: _guardando
                                ? null
                                : (v) => setState(() => _categoria = v),
                            validator: (v) =>
                                v == null ? 'Selecciona una categoría.' : null,
                          ),
                          const SizedBox(height: 16),
                          _campo(
                            'precio',
                            'Precio (S/)',
                            teclado: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validar: ProductoEdicion.validarPrecio,
                          ),
                          _campo(
                            'stock',
                            'Stock',
                            teclado: TextInputType.number,
                            validar: ProductoEdicion.validarStock,
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _campos['stock']!,
                            builder: (context, valor, _) {
                              final stock = int.tryParse(valor.text.trim());
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estado de disponibilidad',
                                    style: TextStyle(
                                      color: AppTheme.secundario,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  StatusPill(
                                    stock == null || stock < 0
                                        ? 'Ingresa el stock'
                                        : stock == 0
                                        ? 'Agotado'
                                        : 'Disponible',
                                    color: stock != null && stock > 0
                                        ? AppTheme.verde
                                        : AppTheme.alerta,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'La disponibilidad depende del stock.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.secundario,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Activo'),
                            subtitle: const Text('Visible para clientes'),
                            value: _activo,
                            onChanged: _guardando
                                ? null
                                : (v) => setState(() => _activo = v),
                          ),
                          _campo('descripcion', 'Descripción', lineas: 4),
                          _campo(
                            'caracteristicas',
                            'Características (una por línea)',
                            lineas: 4,
                          ),
                          _campo(
                            'compatibilidad',
                            'Compatibilidad (una por línea)',
                            lineas: 3,
                          ),
                          if (!_editando)
                            DropdownButtonFormField<String>(
                              key: const ValueKey('producto-imagen'),
                              initialValue: _imagen ?? '',
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Imagen del producto',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text(
                                    'Sin fotografía · respaldo visual',
                                  ),
                                ),
                                for (final foto in fotos.entries)
                                  DropdownMenuItem(
                                    value: foto.key,
                                    child: Text(
                                      foto.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (v) => setState(
                                      () => _imagen = v == '' ? null : v,
                                    ),
                            ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _guardando || _seleccionando
                                ? null
                                : _seleccionarFotografia,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              _seleccionando
                                  ? 'Procesando…'
                                  : _fotografia != null ||
                                        _imagen != null ||
                                        widget.producto?.imagenUrl != null
                                  ? 'Cambiar imagen'
                                  : 'Agregar imagen',
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _fotografia != null
                                ? Image.memory(
                                    _fotografia!,
                                    height: 170,
                                    fit: BoxFit.contain,
                                  )
                                : ProductoPreview(
                                    producto: Producto(
                                      sku: _texto('sku'),
                                      nombre: _texto('nombre'),
                                      categoria: _categoria ?? '',
                                      precio: 0,
                                      stock: 0,
                                      descripcion: '',
                                      caracteristicas: const [],
                                      imagenAsset: _imagen,
                                      imagenUrl: widget.producto?.imagenUrl,
                                      icono: Icons.inventory_2_outlined,
                                    ),
                                    height: 170,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _editando
                                ? 'Si no seleccionas otra fotografía, se conserva la actual.'
                                : 'Puedes seleccionar una fotografía o conservar el respaldo local.',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.secundario,
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 20),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.alerta),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const ValueKey('producto-guardar'),
                            onPressed: _guardando || _seleccionando
                                ? null
                                : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _guardando
                                  ? 'Guardando…'
                                  : _editando
                                  ? 'Guardar cambios'
                                  : 'Guardar producto',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
