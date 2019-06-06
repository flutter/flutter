# [![Flutter logo][]][flutter.dev]

[![Build Status - Cirrus][]][Build status]
[![Gitter Channel][]][Gitter badge]


Flutter é um SDK de aplicativos mobile do Google para criar interfaces nativas de alta qualidade em dispositivos iOS e Android, em tempo record. Flutter funcionar com código existente, é usado por desenvolvedores e organizações ao redor do mundo, e é gratuito e open source.

## Documentação

* [Instalação do Flutter](https://flutter.dev/get-started/)
* [Documentação do Flutter](https://flutter.dev/docs)
* [Wiki de desenvolvimento](https://github.com/flutter/flutter/wiki)
* [Contribuindo para o Flutter](https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md)

Para atualizações sobre novas releases e alterações de quebra, então siga
[flutter-announce@googlegroups.com](https://groups.google.com/forum/#!forum/flutter-announce) lista de discussão.
[Clique aqui](../) para ver esse README.md em outra língua.

## Sobre o Flutter

Achamos que o Flutter irá ajudar você a criar aplicativos bonitos e rápidos, com um modelo de desenvolvimento aberto e extensível.

## Belos aplicativos

Queremos possibilitar que designers entregrem inteiramente suas visões criativas sem serem forçados a complicar-se devido a limitações da estrutura do framework. A [arquitetura em camadas][layered architecture] do Flutter oferece controle sobre cada pixel na tela, e seus poderosos recursos de composição possibilitam que você sobreponha e anime gráficos, videos, textos e controles sem limitações. Flutter iclui um completo [conjunto de widgets][widget catalog] que entrega experiêcias perfeitas por pixel em dispositivos iOS e Android.

![Reflectly hero image][Reflectly hero image]

## Aplicativos rápidos

Flutter é rápido. É alimentado pela mesma biblioteca gráfica 2D [Skia], que provê suporte para aceleração de hardware ao Chrome e Android. Nós arquiteturamos o Flutter para dar suporte à gráficos sem falhas e sem erros, na velocidade nativa do seu dispositivo.
O código do Flutter é provido pelas classes da [Plataforma Dart][Dart platform], que possibilita a compilação do código para arquiteturas ARM 32-bit e 64-bit nativamente para iOS e Android.

## Desenvolvimento produtivo

Flutter oferece hot reload com estado completo, permitindo que você faça mudanças no seu código e veja os resultados instantâneamente sem precisar restartar sua aplicação ou perder seu estado.

[![Hot reload animation][]][Hot reload]

## Extensível e modelo aberto

Flutter funciona em qualquer ferramenta de desenvolvimento, mas inclui plug-ins para ambos os editores [Visual Studio Code] e [IntelliJ / Android Studio]. Flutter provê [centenas de pacotes] para agilizar seu desenvolvimento, independentemente da plataforma alvo. E acessar os recursos da plataforma é fácil, aqui está pequeno trecho como exemplo da nossa [interop example](https://github.com/flutter/flutter/tree/master/examples/platform_channel):

```dart
Future<void> getBatteryLevel() async {
  var batteryLevel = 'unknown';
  try {
    int result = await methodChannel.invokeMethod('getBatteryLevel');
    batteryLevel = 'Battery level: $result%';
  } on PlatformException {
    batteryLevel = 'Failed to get battery level.';
  }
  setState(() {
    _batteryLevel = batteryLevel;
  });
}
```

Flutter é um projeto completamente open source, e nós adoramos contribuições.
Informações sobre como começar podem ser encontradas no nosso [guia do contribuidor](../../CONTRIBUTING.md).


[Flutter logo]: https://flutter.dev/assets/flutter-lockup-4cb0ee072ab312e59784d9fbf4fb7ad42688a7fdaea1270ccf6bbf4f34b7e03f.svg
[flutter.dev]: https://flutter.dev
[Build Status - Cirrus]: https://api.cirrus-ci.com/github/flutter/flutter.svg
[Build status]: https://cirrus-ci.com/github/flutter/flutter/master
[Gitter Channel]: https://badges.gitter.im/flutter/flutter.svg
[Gitter badge]: https://gitter.im/flutter/flutter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[layered architecture]: https://flutter.dev/docs/resources/inside-flutter
[widget catalog]: https://flutter.dev/widgets/
[Reflectly hero image]: https://github.com/flutter/website/blob/master/src/images/homepage/reflectly-hero-600px.png
[Skia]: https://skia.org/
[Dart platform]: https://dart.dev/
[Hot reload animation]: https://raw.githubusercontent.com/flutter/website/master/src/_assets/image/tools/android-studio/hot-reload.gif
[Hot reload]: https://flutter.dev/docs/development/tools/hot-reload
[Visual Studio Code]: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
[IntelliJ / Android Studio]: https://plugins.jetbrains.com/plugin/9212-flutter
[Flutter packages]: https://pub.dev/flutter
[interop example]: https://github.com/flutter/flutter/tree/master/examples/platform_channel