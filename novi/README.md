# Novi

Aplicación Flutter multiplataforma con pantalla de inicio de sesión, tema claro/oscuro y persistencia de preferencias. Proyecto pensado para seguir creciendo (API, registro, etc.).

## Características

- **Inicio de sesión**: formulario con correo y contraseña, validación básica y flujo simulado hacia una pantalla de inicio.
- **Tema claro y oscuro**: soporte Material 3; modo **según el sistema**, **claro** u **oscuro**, con botón en login y en la pantalla principal. La elección se guarda en el dispositivo (`shared_preferences`).
- **Plataformas**: Android, iOS, Web, Windows, Linux y macOS (estructura estándar de Flutter).

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK compatible con **Dart ^3.11**).
- Para Android: Android SDK / [Android Studio](https://developer.android.com/studio) según la [guía oficial para Flutter](https://docs.flutter.dev/get-started/install/windows).

Comprobar el entorno:

```bash
flutter doctor -v
```

## Cómo ejecutar el proyecto

```bash
git clone https://github.com/TU_USUARIO/novi.git
cd novi
flutter pub get
```

- **Chrome (web):** `flutter run -d chrome`
- **Windows:** `flutter run -d windows` (requiere Visual Studio con desarrollo de escritorio C++).
- **Android (dispositivo o emulador):** `flutter run` con depuración USB activada o emulador iniciado.

Durante el desarrollo: **`r`** hot reload, **`R`** hot restart.

## Generar APK (Android)

```bash
flutter build apk --release --split-per-abi
```

La APK para la mayoría de móviles actuales (ARM 64 bits) suele ser:

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

## Estructura relevante

```
lib/
├── main.dart                 # MaterialApp, temas claro/oscuro
├── screens/
│   ├── login_screen.dart
│   └── home_screen.dart
├── theme/
│   └── theme_controller.dart # Modo de tema y persistencia
└── widgets/
    └── theme_mode_button.dart
```

## Dependencias principales

| Paquete | Uso |
|--------|-----|
| `shared_preferences` | Guardar la preferencia de tema |
| `cupertino_icons` | Iconos iOS-style (plantilla Flutter) |

## Tests

```bash
flutter test
```

## Notas

- El inicio de sesión es **demostración** (sin backend); sustituir la lógica en `login_screen.dart` cuando conectes una API o Firebase.
- No subas claves ni `google-services.json` con secretos reales; usa variables de entorno o secretos fuera del repositorio.

## Licencia

Define la licencia que prefieras en este repositorio (por ejemplo MIT o propietaria).
