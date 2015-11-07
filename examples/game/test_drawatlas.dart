import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _bundle = _initBundle();

ImageMap _images;
SpriteSheet _spriteSheet;

final ThemeData _theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.purple
);

main() async {
  _images = new ImageMap(_bundle);

  await _images.load(<String>[
    'assets/sprites.png'
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_images['assets/sprites.png'], json);

  runApp(new MaterialApp(
    title: 'Test drawAtlas',
    theme: _theme,
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) {
        return new SpriteWidget(
          new TestDrawAtlas(),
          SpriteBoxTransformMode.fixedWidth
        );
      }
    }
  ));
}

class TestDrawAtlas extends NodeWithSize {
  TestDrawAtlas() : super(new Size(1024.0, 1024.0));

  void paint(PaintingCanvas canvas) {
    List<RSTransform> transforms = <RSTransform>[
      new RSTransform(1.0, 0.0, 100.0, 100.0)
    ];
    List<Rect> rects = <Rect>[
      _spriteSheet["ship.png"].frame
    ];
    List<Color> colors = <Color>[
      new Color(0xffffffff)
    ];

    canvas.drawAtlas(
      _spriteSheet.image,
      transforms,
      rects,
      colors,
      TransferMode.src,
      null,
      new Paint()
        ..filterQuality = FilterQuality.low
        ..isAntiAlias = false
    );
  }
}
