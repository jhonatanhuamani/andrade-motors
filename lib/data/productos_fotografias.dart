import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

abstract interface class ProductosFotografias {
  Future<String> subir(String productId, Uint8List bytes);
  Future<void> eliminar(String url);
}

class FirebaseProductosFotografias implements ProductosFotografias {
  FirebaseProductosFotografias({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;

  @override
  Future<String> subir(String productId, Uint8List bytes) async {
    final ref = _storage.ref(
      'productos/$productId/principal-${DateTime.now().microsecondsSinceEpoch}.png',
    );
    try {
      await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
      return await ref.getDownloadURL();
    } catch (_) {
      try {
        await ref.delete();
      } catch (_) {
        /* Mantener el error original. */
      }
      rethrow;
    }
  }

  @override
  Future<void> eliminar(String url) => _storage.refFromURL(url).delete();
}
