# Productos con fotografias

El flujo conserva Authentication y el claim existente `admin: true`. No se crean
cuentas, no se cambian roles y no se precargan productos reales.

## Datos

Coleccion: `productos/{sku}`. El SKU sigue siendo el ID permanente para conservar
reservas, carrito y favoritos existentes.

Campos principales: `nombre` (string), `categoria` (string), `descripcion` (string),
`precio` (number positivo), `stock` (int no negativo), `imagenUrl` (string HTTPS o
null), `activo` (bool), `createdAt` y `updatedAt` (timestamps del servidor).
Se conservan `sku`, `imagenAsset`, `caracteristicas`, `compatibilidad`, `rating`,
`resenas` y cualquier campo desconocido al editar.

Storage: `productos/{sku}/principal-{microsecondsSinceEpoch}.png`.
La imagen seleccionada se convierte realmente a PNG, con limite de 10 MB.
Cada reemplazo tiene nombre unico para evitar cache obsoleta y conservar la
foto anterior si falla el guardado. Se sube primero y se confirma el documento
con su URL en una unica escritura. Si Firestore falla, se intenta eliminar
solamente la foto nueva. Las versiones anteriores se conservan.

Catalogo, detalle y vista admin comparten `ProductoPreview`: URL remota,
asset local y finalmente ilustracion vectorial. Se utiliza BoxFit.contain,
indicador de carga y manejo de errores.

## Configuracion del proyecto Firebase

El bucket ya figura en firebase_options.dart:
`andrade-motors-2026.firebasestorage.app`.

1. Comprobar que Cloud Storage este habilitado en ese proyecto.
2. Integrar las reglas de `firestore.rules` y `storage.rules` con las reglas
   actuales del proyecto antes de publicarlas. Este repositorio no contenia
   copias de las reglas remotas: no reemplazar reglas de servicios, reservas
   u otras colecciones sin conservarlas. Las reglas incluidas solo conceden
   acceso a productos y sus fotografias.
3. Publicar las reglas integradas desde Firebase Console o Firebase CLI.
   Si son las reglas completas del proyecto:
   `firebase deploy --only firestore:rules,storage --project andrade-motors-2026`.
4. Al publicar reglas de Storage que consultan Firestore, habilitar el permiso
   entre servicios que solicite Firebase.
5. Los documentos antiguos sin `activo` no coinciden con la consulta cliente.
   Abrirlos como admin y guardarlos con Activo habilitado. La edicion agrega
   createdAt si faltaba y actualiza updatedAt. No se ejecuta migracion automatica.

Solo el token con `admin: true` permite crear, editar o eliminar. El cliente
consulta `where('activo', isEqualTo: true)` y las reglas verifican ese estado.
La activacion es independiente del stock. Un catalogo remoto vacio permanece
vacio; los errores de lectura conservan el respaldo local existente.

## Validacion

Las pruebas usan almacenamiento y autenticacion en memoria: crear con foto,
conservar URL, reemplazar, desactivar, fallos de subida/escritura y lectura de 50
documentos sinteticos (sin escribir productos en Firebase).
Se ejecutan tambien las pruebas existentes de formularios, roles, navegacion,
catalogo, inventario, servicios y reservas.

La prueba de extremo a extremo contra Firebase real y la publicacion de reglas
requieren un proyecto conectado y una sesion admin; no se realizaron desde este
entorno. No se modifico C:\flutter: se uso una copia temporal del SDK.

Referencias: https://firebase.google.com/docs/storage/flutter/upload-files
Dependencias: firebase_storage ^14.0.1 e image_picker ^1.2.4.

## Archivos modificados o agregados

- `firebase.json`
- `ios/Runner/Info.plist`
- `lib/auth/auth_router.dart`
- `lib/data/catalogo_state.dart`
- `lib/data/producto_edicion.dart`
- `lib/data/productos_escritura.dart`
- `lib/data/productos_repository.dart`
- `lib/models/producto.dart`
- `lib/screens/admin/producto_form_screen.dart`
- `lib/widgets/admin_producto_card.dart`
- `lib/widgets/producto_preview.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Info.plist`
- `macos/Runner/Release.entitlements`
- `pubspec.lock`
- `pubspec.yaml`
- `test/productos_escritura_test.dart`
- `test/productos_repository_test.dart`
- `test/widget_test.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `FIREBASE_PRODUCTOS.md`
- `firestore.rules`
- `lib/data/productos_fotografias.dart`
- `storage.rules`
- `test/productos_fotografias_test.dart`

## Revision de reglas antes del despliegue (sin publicar)

Se revisaron todos los fuentes, configuraciones, herramientas y pruebas del
repositorio, incluidas referencias a Firestore en archivos ocultos/no ignorados.
La unica coleccion consultada/escrita es `productos`, en
`lib/data/productos_repository.dart` y `lib/data/productos_escritura.dart`.
No se encontraron accesos a subcolecciones ni bases con nombre.

`usuarios` y `roles` no son colecciones usadas por la app: la cuenta y el correo
proceden de Firebase Authentication. `FirebaseAdminAuthService.comprobarAdmin()`
renueva el ID token con `getIdTokenResult(true)` y exige `claims['admin'] == true`
booleano. `AdminSession` usa ese resultado para distinguir cliente/admin.
No hay ningun script, Cloud Function ni backend que asigne el claim en este
repositorio. No se verificaron claims de cuentas reales. Su asignacion debe
existir fuera de Flutter mediante Firebase Admin SDK en un entorno privilegiado;
no se ha asignado ni modificado ningun rol durante esta revision.

Servicios usa `demo.servicios`. Reservas guarda una lista en memoria en
`ReservaScreen`. Inventario usa los productos del catalogo y altas de sesion.
Pedidos y administracion remota de usuarios/reservas estan pendientes.
Perfil y configuracion muestran la sesion actual, sin documentos Firestore.
No se agregaron permisos especulativos para estas colecciones ni se mezclaron
claims con un supuesto `usuarios/{uid}.rol`.

Storage acepta metadatos MIME `image/.*`, hasta 10 * 1024 * 1024 bytes, y mantiene
`productos/{productId}/{filename}`. La consulta usa exactamente
`/databases/(default)/documents/productos/$(productId)`.
Los clientes no pueden subir, reemplazar ni eliminar. Admin puede leer y escribir.
La lectura publica de productos activos se conserva por compatibilidad, incluso
antes del login; la app inicia una consulta de catalogo al arrancar.

Riesgos pendientes antes de publicar:
- No se descargaron ni compararon las reglas publicadas en Firebase Console.
  No es posible garantizar compatibilidad con colecciones usadas por otros
  clientes/backends que no figuran en este repositorio. Integrar esas reglas
  si existen; la propuesta deniega rutas no implementadas por esta app.
- Los productos sin `activo: true` no aparecen para clientes; los documentos
  antiguos reciben timestamps al guardarlos desde el panel admin. Un createdAt
  existente de tipo incorrecto necesita corregirse mediante una migracion segura.
- Sin un custom claim admin booleano, una cuenta sigue siendo cliente aunque
  tuviera un campo rol en Firestore. No se presupone que el claim real exista.
- `getDownloadURL()` produce una URL compartible con token. Desactivar un
  producto no revoca URLs previamente conocidas; acceso estricto tras desactivar
  requeriria revocar tokens y cambiar el flujo de entrega de imagenes.
- MIME es metadata declarada, no una inspeccion del contenido binario. La app
  actual decodifica la imagen y la convierte a PNG antes de subirla.
- Storage requiere habilitar la integracion de lectura de Firestore; puede
  implicar lecturas facturables. No se modificaron permisos IAM ni servicios.

Prueba reproducible exclusivamente local (Node y Firebase CLI, Java 21):
`firebase emulators:exec --only "firestore,storage" --project demo-andrade-motors --config firebase.rules-test.json "node tools/firebase-rules.test.cjs"`
El script comprueba hosts locales y el ID demo antes de enviar solicitudes.
No requiere paquetes npm nuevos ni credenciales, y no se ejecuta firebase deploy.

Referencias:
- https://firebase.google.com/docs/auth/admin/custom-claims
- https://firebase.google.com/docs/storage/security/rules-conditions
- https://firebase.google.com/docs/reference/swift/firebasestorage/api/reference/Classes/StorageReference

Resultado de esta revision: 40 comprobaciones aprobadas en los emuladores de
Firestore y Storage. Sintaxis Node y git diff --check correctos. Archivos nuevos
de validacion: firebase.rules-test.json y tools/firebase-rules.test.cjs.
Solo se modificaron reglas locales, documentacion y herramientas de prueba en
esta revision; no se cambiaron los flujos Flutter ni la configuracion remota.
