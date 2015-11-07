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
TestBedApp _app;

main() async {
  _images = new ImageMap(_bundle);

  await _images.load(<String>[
    'assets/sprites.png'
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_images['assets/sprites.png'], json);

  _app = new TestBedApp();
  runApp(_app);
}

class TestBedApp extends MaterialApp {

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
  TestBed() : super(new Size(1024.0, 1024.0));
}
