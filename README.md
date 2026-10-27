# Andrade Motors

Aplicación Flutter para tienda y taller de motocicletas, con diseño negro y dorado e interfaces independientes para clientes y administración.

## Funcionalidades

- Catálogo, búsqueda, detalle de productos, favoritos y carrito.
- Servicios del taller y reservas.
- Inicio de sesión administrativo mediante Firebase Authentication.
- Lectura, creación y edición de productos mediante Cloud Firestore.
- Comprobación del rol administrativo mediante el custom claim `admin`.

## Desarrollo

Se requiere Flutter con Dart compatible con `^3.13.7`, Git y acceso al proyecto Firebase configurado.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

La configuración Firebase cliente se conserva en `lib/firebase_options.dart` y `android/app/google-services.json`. Sus identificadores no son credenciales de Firebase Admin SDK. Los permisos dependen de Firebase Authentication y de las reglas del servicio; clonar el código no concede acceso administrativo.

No guardar contraseñas, tokens, cuentas de servicio ni claves privadas de firma en el repositorio. Las reglas desplegadas y los datos de Firestore se administran por separado: este repositorio respalda el código fuente, no una exportación de la base de datos.

## Estructura

- `lib/auth/`: autenticación y sesión administrativa.
- `lib/data/`: catálogo y acceso a productos en Firestore.
- `lib/screens/`: pantallas de clientes y administración.
- `lib/theme/` y `lib/widgets/`: diseño y componentes compartidos.
- `assets/`: imágenes locales.
- `test/`: pruebas automatizadas y dobles de servicios.
- `tools/firestore_productos_seed.json`: datos de ejemplo; no se importan al ejecutar los comandos anteriores.

## Continuar trabajando

Después de clonar el repositorio, ejecutar los comandos de desarrollo. Para guardar cambios posteriores:

```powershell
git status
git add <archivos-revisados>
git commit -m "Describe el cambio"
git push
```

Revisar los archivos antes de cada commit y mantener el repositorio privado.
