import 'dart:sky';

import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/services.dart';
import 'package:sky/widgets.dart';
import 'package:skysprites/skysprites.dart';

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _bundle = _initBundle();

ImageMap _images;
SpriteSheet _spriteSheet;
TestBedApp _app;

main() async {
  _images = new ImageMap(_bundle);

  await _images.load([
    'assets/sprites.png'
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_images['assets/sprites.png'], json);

  _app = new TestBedApp();
  runApp(_app);
}

class TestBedApp extends App {

  Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.purple
    );

    return new Theme(
      data: theme,
      child: new Title(
        title: 'Test Bed',
        child: new SpriteWidget(
          new TestBed(),
          SpriteBoxTransformMode.letterbox
        )
      )
    );
  }
}

class TestBed extends NodeWithSize {
  TestBed() : super(new Size(1024.0, 1024.0)) {
  }
}
