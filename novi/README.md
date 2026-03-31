# Novi

**Novi** es una aplicación móvil (APK Android) desarrollada con Flutter. Incluye pantalla de inicio de sesión, pantalla de inicio tras “entrar”, y **modo claro / oscuro** que puedes dejar automático según el teléfono o fijar a mano; la preferencia se guarda en el dispositivo.

> Proyecto personal en evolución: más adelante se puede conectar a un backend real (cuentas, API, etc.).

---

## Qué hace la app

| | |
|---|---|
| **Inicio de sesión** | Correo y contraseña con validación básica; el flujo de autenticación es de demostración hasta conectar un servidor. |
| **Tema** | Tres modos: según el sistema, siempre claro o siempre oscuro. Icono arriba a la derecha en login y en la pantalla principal. |
| **Plataforma** | Pensada para **Android** (APK). El mismo código también corre en web y escritorio si lo compilas desde el proyecto. |

---

## Instalar la APK en Android

1. Genera la release en tu PC: `flutter build apk --release --split-per-abi`
2. En el móvil **ARM 64 bits** (casi todos los actuales), usa:  
   `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
3. Copia el archivo al teléfono y ábrelo para instalar (puede hacer falta permitir *fuentes desconocidas* en ajustes).

Para **actualizar** la app instalada, vuelve a instalar una APK nueva con el mismo identificador de aplicación (misma firma / mismo proyecto).

---

## Desarrollo (clonar y ejecutar)

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) (Dart ^3.11) y, para Android, el SDK configurado (`flutter doctor`).

```bash
git clone https://github.com/TU_USUARIO/novi.git
cd novi
flutter pub get
flutter run -d chrome    # o el dispositivo que uses
```

Estructura principal del código:

```
lib/
├── main.dart
├── screens/          # login, inicio
├── theme/            # tema y preferencia guardada
└── widgets/
```

```bash
flutter test
```

---

## Licencia

Indica aquí la licencia que quieras usar para Novi (por ejemplo MIT o uso privado).
