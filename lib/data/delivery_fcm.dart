import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef RegistroDeliveryFcm = ({String clienteId, String token});

abstract interface class DeliveryCanalPush {
  Stream<RemoteMessage> get enPrimerPlano;
  Stream<RemoteMessage> get alAbrir;
  Stream<String> get tokensRenovados;
  Future<RemoteMessage?> mensajeInicial();
  Future<String?> obtenerToken({required bool pedirPermiso});
  Future<void> borrarToken();
}

class DeliveryFcm implements DeliveryCanalPush {
  DeliveryFcm(this._fcm);

  final FirebaseMessaging _fcm;

  static DeliveryFcm? paraPlataformaActual() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return null;
    }
    return DeliveryFcm(FirebaseMessaging.instance);
  }

  @override
  Stream<RemoteMessage> get enPrimerPlano => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get alAbrir => FirebaseMessaging.onMessageOpenedApp;

  @override
  // El contrato solicita un token FCM. onRegistered devuelve un FID.
  // ignore: deprecated_member_use
  Stream<String> get tokensRenovados => _fcm.onTokenRefresh;

  @override
  Future<RemoteMessage?> mensajeInicial() => _fcm.getInitialMessage();

  @override
  Future<String?> obtenerToken({required bool pedirPermiso}) async {
    var ajustes = await _fcm.getNotificationSettings();
    bool autorizado() =>
        ajustes.authorizationStatus == AuthorizationStatus.authorized ||
        ajustes.authorizationStatus == AuthorizationStatus.provisional;
    if (!autorizado() && pedirPermiso) {
      ajustes = await _fcm.requestPermission();
    }
    if (!autorizado()) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // APNs puede completar el registro después del diálogo de permisos.
      var tokenApns = await _fcm.getAPNSToken();
      for (var intento = 0; tokenApns == null && intento < 8; intento++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        tokenApns = await _fcm.getAPNSToken();
      }
      if (tokenApns == null) return null;
    }
    // register() devuelve un FID, no el token FCM de este contrato.
    // ignore: deprecated_member_use
    return _fcm.getToken();
  }

  @override
  // Revoca el token FCM obtenido con getToken al salir de la cuenta.
  // ignore: deprecated_member_use
  Future<void> borrarToken() => _fcm.deleteToken();
}
