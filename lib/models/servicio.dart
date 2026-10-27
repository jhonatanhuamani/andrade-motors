import 'package:flutter/material.dart';

class Servicio {
  const Servicio(
    this.nombre,
    this.descripcion,
    this.precio,
    this.duracion,
    this.icono, {
    this.imagenAsset,
  });
  final String? imagenAsset;
  final String nombre, descripcion, duracion;
  final double precio;
  final IconData icono;
}
