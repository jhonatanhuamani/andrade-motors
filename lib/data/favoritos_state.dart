import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritosState extends ChangeNotifier {
  // Serializa lecturas y escrituras incluso al reconstruir la sesión.
  static Future<void>? _operaciones;

  Set<String> _skus = {};
  final _cambiosDuranteCarga = <String, bool>{};
  String? _uid;
  int _revision = 0;
  bool cargando = false;

  Set<String> get skus => Set.unmodifiable(_skus);
  bool contiene(String sku) => _skus.contains(sku);

  void _encolar(Future<void> Function() operacion) {
    final siguiente = (_operaciones ?? Future<void>.value())
        .then((_) => operacion())
        .catchError(
          (Object error) => debugPrint(
            '[Favoritos] Almacenamiento local: ${error.runtimeType}',
          ),
        );
    _operaciones = siguiente;
    unawaited(
      siguiente.whenComplete(() {
        if (identical(_operaciones, siguiente)) _operaciones = null;
      }),
    );
  }

  void cambiarCliente(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    final revision = ++_revision;
    _skus = {};
    _cambiosDuranteCarga.clear();
    cargando = uid != null;
    if (uid != null) {
      _encolar(() async {
        try {
          final guardados = await SharedPreferencesAsync().getStringList(
            'favoritos.$uid',
          );
          if (revision != _revision) return;
          _skus = {...?guardados};
          _cambiosDuranteCarga.forEach(_aplicar);
        } finally {
          if (revision == _revision) {
            _cambiosDuranteCarga.clear();
            cargando = false;
            notifyListeners();
          }
        }
      });
    }
    // Los consumidores reconstruyen su vista al cambiar SessionScope.
  }

  void _aplicar(String sku, bool guardar) {
    if (guardar) {
      _skus.add(sku);
    } else {
      _skus.remove(sku);
    }
  }

  void alternar(String sku) {
    final guardar = !contiene(sku);
    _aplicar(sku, guardar);
    if (cargando) _cambiosDuranteCarga[sku] = guardar;
    final uid = _uid;
    if (uid != null) {
      _encolar(() async {
        final clave = 'favoritos.$uid';
        final preferencias = SharedPreferencesAsync();
        final guardados = {...?await preferencias.getStringList(clave)};
        if (guardar) {
          guardados.add(sku);
        } else {
          guardados.remove(sku);
        }
        await preferencias.setStringList(clave, guardados.toList());
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }
}
