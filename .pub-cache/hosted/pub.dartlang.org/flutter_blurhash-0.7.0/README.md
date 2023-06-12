[![Flutter Community: flutter_blurhash](https://fluttercommunity.dev/_github/header/flutter_blurhash)](https://github.com/fluttercommunity/community)

[![pub package](https://img.shields.io/pub/v/flutter_blurhash.svg)](https://pub.dev/packages/flutter_blurhash)
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/cloudposse.svg?style=social&label=%20%40BlueAquilae)](https://twitter.com/blueaquilae)
# Flutter BlurHash

Compact representation of a placeholder for an image.


## Generation

<img width="1211" alt="Capture d’écran 2020-02-21 à 19 11 56" src="https://user-images.githubusercontent.com/1295961/75059847-129d6800-54de-11ea-8832-d19ea58eb7eb.png">

You can use https://blurha.sh/ for testing or use any official api on your server side.


## Flutter Code

Constrain your widget render area and let BlurHash fill the pixels.

```dart
class BlurHashApp extends StatelessWidget {
  const BlurHashApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text("BlurHash")),
      body: const SizedBox.expand(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: BlurHash(hash: "L5H2EC=PM+yV0g-mq.wG9c010J}I"),
          ),
        ),
      ),
    ),
  );
}
```


