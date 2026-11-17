import 'package:flutter/material.dart';

class Producto {
  const Producto({
    this.imagenAsset,
    this.imagenUrl,
    this.activo = true,
    this.compatibilidad = const ['Consultar por modelo'],
    this.rating = 4.8,
    this.resenas = 120,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.sku,
    required this.icono,
    required this.descripcion,
    required this.caracteristicas,
  });
  final String? imagenAsset;
  final String? imagenUrl;
  final bool activo;
  final List<String> compatibilidad;
  final double rating;
  final int resenas;
  final String nombre, categoria, sku, descripcion;
  final double precio;
  final int stock;
  final IconData icono;
  final List<String> caracteristicas;
  String get precioTexto =>
      'S/ ${precio.toStringAsFixed(2).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+\.)"), (m) => "${m[1]},")}';
}
