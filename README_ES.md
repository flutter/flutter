<a href="https://flutter.dev/">
  <h1 align="center">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://storage.googleapis.com/cms-storage-bucket/6e19fee6b47b36ca613f.png">
      <img alt="Flutter" src="https://storage.googleapis.com/cms-storage-bucket/c823e53b3a1a7b0d36a9.png">
    </picture>
  </h1>
</a>

[![Build Status - Cirrus][]][Build status]
[![Discord badge][]][Discord instructions]
[![Twitter handle][]][Twitter badge]
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/5631/badge)](https://bestpractices.coreinfrastructure.org/projects/5631)

Flutter es el SDK de Google para crear interfaces de usuario atractivas y rápidas para dispositivos móviles, web y de escritorio a partir de una única base de código. Flutter funciona con código existente, lo utilizan desarrolladores y organizaciones de todo el mundo, es gratuito y de código abierto.

## Documentación

* [Instalar Flutter](https://flutter.dev/get-started/)
* [Flutter documentación](https://flutter.dev/docs)
* [Wiki de desarrollo](https://github.com/flutter/flutter/wiki)
* [Contribuyendo a Flutter](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)

Para anuncios sobre nuevos lanzamientos, siga el grupo
[flutter-announce@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-announce)
Nuestra documentación también rastrea [breaking changes](https://flutter.dev/docs/release/breaking-changes) en todas las versiones.

## Términos de servicio

La herramienta Flutter ocasionalmente puede descargar recursos de los servidores de Google. Al descargar o usar el SDK de Flutter, usted acepta los Términos de servicio de Google:
https://policies.google.com/terms

Por ejemplo, cuando se instala desde GitHub (a diferencia de un archivo preempaquetado), la herramienta Flutter descargará el SDK de Dart de los servidores de Google
inmediatamente cuando se ejecuta por primera vez, ya que se utiliza para ejecutar la propia herramienta `flutter`.
Esto también ocurrirá cuando se actualice Flutter (por ejemplo, al ejecutar el comando `flutter upgrade`).

## Acerca de Flutter

Creemos que Flutter lo ayudará a crear aplicaciones atractivas y rápidas, con un entorno productivo y modelo de desarrollo extensible y abierto, ya sea que se dirija a iOS o Android, Web, Windows, macOS, Linux o sistemas empotrados, como el kit de herramientas de interfaz de usuario para una plataforma de tu elección.

### Hermosas experiencias de usuario

Queremos permitir que los diseñadores entreguen su visión creativa completa sin verse obligados a diluirla debido a las limitaciones del framework.
La [arquitectura en capas] de Flutter le brinda control sobre cada píxel en la pantalla y sus poderosas capacidades de composición le permiten superponer y animar gráficos, video, texto y controles sin limitación.

Flutter incluye una [lista de widgets][catálogo de widgets] que ofrecen experiencias de píxeles perfectos ya sea si está desarrollando para iOS ([Cupertino]) o Android ([Material]), junto con soporte para personalizar o crear componentes visuales completamente nuevos.

<p align="center"><img src="https://github.com/flutter/website/blob/main/src/assets/images/docs/homepage/reflectly-hero-600px.png?raw=true" alt="Reflectly hero image"></p>

### Resultados rápidos

Flutter es rápido. Está alimentado por la misma biblioteca de gráficos 2D acelerada por hardware que sustenta Chrome y Android: [Skia]. Diseñamos Flutter para que sea compatible con gráficos sin fallas ni bloqueos a la velocidad nativa de su dispositivo.
El código de Flutter funciona con [Plataforma de Dart], que permite la compilación en código de máquina ARM de 32 y 64 bits para iOS y Android, así como JavaScript para la web e Intel x64 para dispositivos de escritorio.

<p align="center"><img src="https://github.com/flutter/website/blob/main/src/assets/images/docs/homepage/dart-diagram-small.png?raw=true" alt="Dart diagram"></p>

### Desarrollo productivo

Flutter ofrece recarga en caliente con estado, lo que le permite realizar cambios en su código y ver los resultados al instante sin reiniciar su aplicación o perder su estado.

[![Hot reload animation][]][Hot reload]

### Modelo abierto y extensible

Flutter funciona con cualquier herramienta de desarrollo (o con ninguna), y también incluye complementos de edición para [Visual Studio Code] e [IntelliJ / Android Studio].
Flutter proporciona [tens of thousands of packages][Flutter packages] para acelerar su desarrollo, independientemente de su plataforma de destino. Y acceder a otro código nativo es fácil, con soporte tanto para [FFI] como para [platform-specific APIs][platform
channels].

Flutter es un proyecto totalmente de código abierto y agradecemos las contribuciones.
Puede encontrar información sobre cómo empezar en nuestra
[contributor guide](CONTRIBUTING.md).


[flutter.dev]: https://flutter.dev
[Build Status - Cirrus]: https://api.cirrus-ci.com/github/flutter/flutter.svg
[Build status]: https://cirrus-ci.com/github/flutter/flutter/master
[Discord instructions]: https://github.com/flutter/flutter/wiki/Chat
[Discord badge]: https://img.shields.io/discord/608014603317936148
[Twitter handle]: https://img.shields.io/twitter/follow/flutterdev.svg?style=social&label=Follow
[Twitter badge]: https://twitter.com/intent/follow?screen_name=flutterdev
[arquitectura en capas]: https://flutter.dev/docs/resources/inside-flutter
[architectural overview]: https://docs.flutter.dev/resources/architectural-overview
[catálogo de widgets]: https://flutter.dev/widgets/
[Cupertino]: https://docs.flutter.dev/development/ui/widgets/cupertino
[Material]: https://docs.flutter.dev/development/ui/widgets/material
[Skia]: https://skia.org/
[Plataforma de Dart]: https://dart.dev/
[Hot reload animation]: https://github.com/flutter/website/blob/main/src/assets/images/docs/tools/android-studio/hot-reload.gif?raw=true
[Hot reload]: https://docs.flutter.dev/development/tools/hot-reload
[Visual Studio Code]: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
[IntelliJ / Android Studio]: https://plugins.jetbrains.com/plugin/9212-flutter
[Flutter packages]: https://pub.dev/flutter
[FFI]: https://flutter.dev/docs/development/platform-integration/c-interop
[platform channels]: https://flutter.dev/docs/development/platform-integration/platform-channels
[interop example]: https://github.com/flutter/flutter/tree/master/examples/platform_channel
