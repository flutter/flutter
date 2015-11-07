import 'dart:ui' as ui;
import 'dart:math' as math;

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
    title: 'Test Sprite Performance',
    theme: _theme,
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new SpriteWidget(new TestPerformance())
    }
  ));
}

class TestPerformance extends NodeWithSize {

  TestPerformance() : super(new Size(1024.0, 1024.0));

  final int numFramesPerTest = 100;
  final int numTests = 5;

  int test = 0;
  int frame = 0;
  int testStartTime;

  void update(double dt) {
    if (frame % numFramesPerTest == 0) {
      if (test > 0 && test <= numTests) {
        // End last test
        int currentTime = new DateTime.now().millisecondsSinceEpoch;
        int totalTestTime = currentTime - testStartTime;
        double millisPerFrame =
          totalTestTime.toDouble() / numFramesPerTest.toDouble();
        print("  - RESULT fps: ${(1.0 / (millisPerFrame / 1000)).toStringAsFixed(1)} millis/frame: ${millisPerFrame.round()}");

        // Clear test
        removeAllChildren();
      }

      if (test < numTests) {
        // Start new test
        PerformanceTest perfTest = createTest(test);
        addChild(perfTest);

        print("TEST ${test + 1}/$numTests STARTING: ${perfTest.name}");

        testStartTime = new DateTime.now().millisecondsSinceEpoch;
      }
      test++;
    }
    frame++;
  }

  PerformanceTest createTest(int n) {
    if (test == 0) {
      // Test atlas performance
      return new TestPerformanceAtlas();
    } else if (test == 1) {
      // Test atlas performance
      return new TestPerformanceAtlas2();
    } else if (test == 2) {
      // Test sprite performance
      return new TestPerformanceSprites();
    } else if (test == 3) {
      // Test sprite performance
      return new TestPerformanceSprites2();
    } else if (test == 4) {
      // Test particle performance
      return new TestPerformanceParticles();
    }
    return null;
  }
}

abstract class PerformanceTest extends Node {
  String get name;
}

class TestPerformanceParticles extends PerformanceTest {
  String get name => "64 particle systems";

  final grid = 8;
  TestPerformanceParticles() {
    for (int x = 0; x < grid; x++) {
      for (int y = 0; y < grid; y++) {
        ParticleSystem particles = new ParticleSystem(
          _spriteSheet["explosion_particle.png"],
          rotateToMovement: true,
          startRotation:90.0,
          startRotationVar: 0.0,
          endRotation: 90.0,
          startSize: 0.3,
          startSizeVar: 0.1,
          endSize: 0.3,
          endSizeVar: 0.1,
          emissionRate:100.0,
          greenVar: 127,
          redVar: 127
        );
        particles.position = new Point(x * 1024.0 / (grid - 1), y * 1024.0 / (grid - 1));
        addChild(particles);
      }
    }
  }
}

class TestPerformanceSprites extends PerformanceTest {
  String get name => "1001 sprites (24% offscreen)";

  final int grid = 100;

  TestPerformanceSprites() {
    for (int x = 0; x < grid; x++) {
      for (int y = 0; y < grid; y++) {
        Sprite sprite = new Sprite(_spriteSheet["asteroid_big_1.png"]);
        sprite.scale = 1.0;
        sprite.position = new Point(x * 1024.0 / (grid - 1), y * 1024.0 / (grid - 1));
        addChild(sprite);
      }
    }

    Sprite sprite = new Sprite(_spriteSheet["asteroid_big_1.png"]);
    sprite.position = new Point(512.0, 512.0);
    addChild(sprite);
  }

  void update(double dt) {
    for (Node child in children) {
      final Sprite sprite = child;
      sprite.rotation += 1;
    }
  }
}

class TestPerformanceSprites2 extends PerformanceTest {
  String get name => "1001 sprites (24% offscreen never added)";

  final int grid = 100;

  TestPerformanceSprites2() {
    for (int x = 12; x < grid - 12; x++) {
      for (int y = 0; y < grid; y++) {
        Sprite sprite = new Sprite(_spriteSheet["asteroid_big_1.png"]);
        sprite.scale = 1.0;
        sprite.position = new Point(x * 1024.0 / (grid - 1), y * 1024.0 / (grid - 1));
        addChild(sprite);
      }
    }

    Sprite sprite = new Sprite(_spriteSheet["asteroid_big_1.png"]);
    sprite.position = new Point(512.0, 512.0);
    addChild(sprite);
  }

  void update(double dt) {
    for (Node child in children) {
      final Sprite sprite = child;
      sprite.rotation += 1;
    }
  }
}

class TestPerformanceAtlas extends PerformanceTest {
  String get name => "1001 rects drawAtlas (24% offscreen)";

  final int grid = 100;

  double rotation = 0.0;
  List<Rect> rects = <Rect>[];
  Paint cachedPaint = new Paint()
    ..filterQuality = ui.FilterQuality.low
    ..isAntiAlias = false;

  TestPerformanceAtlas() {
    for (int x = 0; x < grid; x++) {
      for (int y = 0; y < grid; y++) {
        rects.add(_spriteSheet["asteroid_big_1.png"].frame);
      }
    }
    rects.add(_spriteSheet["asteroid_big_1.png"].frame);
  }

  void paint(PaintingCanvas canvas) {
    // Setup transforms
    List<ui.RSTransform> transforms = <ui.RSTransform>[];

    for (int x = 0; x < grid; x++) {
      for (int y = 0; y < grid; y++) {
        double xPos = x * 1024.0 / (grid - 1);
        double yPos = y * 1024.0 / (grid - 1);

        transforms.add(createTransform(xPos, yPos, rects[0].size.width / 2.0, rects[0].size.height / 2.0, rotation, 1.0));
      }
    }

    transforms.add(createTransform(512.0, 512.0, rects[0].size.width / 2.0, rects[0].size.height / 2.0, rotation, 1.0));

    // Draw atlas
    Rect cullRect = spriteBox.visibleArea;
    canvas.drawAtlas(_spriteSheet.image, transforms, rects, null, null, cullRect, cachedPaint);
  }

  void update(double dt) {
    rotation += 1.0;
  }

  ui.RSTransform createTransform(double x, double y, double ax, double ay, double rot, double scale) {
    double scos = math.cos(convertDegrees2Radians(rot)) * scale;
    double ssin = math.sin(convertDegrees2Radians(rot)) * scale;
    double tx = x + -scos * ax + ssin * ay;
    double ty = y + -ssin * ax - scos * ay;
    return new ui.RSTransform(scos, ssin, tx, ty);
  }
}

class TestPerformanceAtlas2 extends PerformanceTest {
  String get name => "1001 rects drawAtlas (24% offscreen never added)";

  final int grid = 100;

  double rotation = 0.0;
  List<Rect> rects = <Rect>[];
  Paint cachedPaint = new Paint()
    ..filterQuality = ui.FilterQuality.low
    ..isAntiAlias = false;

  TestPerformanceAtlas2() {
    for (int x = 12; x < grid - 12; x++) {
      for (int y = 0; y < grid; y++) {
        rects.add(_spriteSheet["asteroid_big_1.png"].frame);
      }
    }
    rects.add(_spriteSheet["asteroid_big_1.png"].frame);
  }

  void paint(PaintingCanvas canvas) {
    // Setup transforms
    List<ui.RSTransform> transforms = <ui.RSTransform>[];

    for (int x = 12; x < grid - 12; x++) {
      for (int y = 0; y < grid; y++) {
        double xPos = x * 1024.0 / (grid - 1);
        double yPos = y * 1024.0 / (grid - 1);

        transforms.add(createTransform(xPos, yPos, rects[0].size.width / 2.0, rects[0].size.height / 2.0, rotation, 1.0));
      }
    }

    transforms.add(createTransform(512.0, 512.0, rects[0].size.width / 2.0, rects[0].size.height / 2.0, rotation, 1.0));

    // Draw atlas
    Rect cullRect = spriteBox.visibleArea;
    canvas.drawAtlas(_spriteSheet.image, transforms, rects, null, null, cullRect, cachedPaint);
  }

  void update(double dt) {
    rotation += 1.0;
  }

  ui.RSTransform createTransform(double x, double y, double ax, double ay, double rot, double scale) {
    double scos = math.cos(convertDegrees2Radians(rot)) * scale;
    double ssin = math.sin(convertDegrees2Radians(rot)) * scale;
    double tx = x + -scos * ax + ssin * ay;
    double ty = y + -ssin * ax - scos * ay;
    return new ui.RSTransform(scos, ssin, tx, ty);
  }
}
