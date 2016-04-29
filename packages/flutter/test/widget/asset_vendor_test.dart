// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mojo/core.dart' as core;
import 'package:test/test.dart';

class TestImage extends ui.Image {
  TestImage(this.scale);
  final double scale;

  @override
  int get width => (48*scale).floor();

  @override
  int get height => (48*scale).floor();

  @override
  void dispose() { }
}

class TestMojoDataPipeConsumer extends core.MojoDataPipeConsumer {
  TestMojoDataPipeConsumer(this.scale) : super(null);
  final double scale;
}

String testManifest = '''
{
  "assets/image.png" : [
    "assets/1.5x/image.png",
    "assets/2.0x/image.png",
    "assets/3.0x/image.png",
    "assets/4.0x/image.png"
  ]
}
''';

class TestAssetBundle extends AssetBundle {
  // Image loading logic routes through load(key)
  @override
  ImageResource loadImage(String key) => null;

  @override
  Future<String> loadString(String key) {
    if (key == 'AssetManifest.json')
      return (new Completer<String>()..complete(testManifest)).future;
    return null;
  }

  @override
  Future<core.MojoDataPipeConsumer> load(String key) {
    core.MojoDataPipeConsumer pipe;
    switch (key) {
      case 'assets/image.png':
        pipe = new TestMojoDataPipeConsumer(1.0);
        break;
      case 'assets/1.5x/image.png':
        pipe = new TestMojoDataPipeConsumer(1.5);
        break;
      case 'assets/2.0x/image.png':
        pipe = new TestMojoDataPipeConsumer(2.0);
        break;
      case 'assets/3.0x/image.png':
        pipe = new TestMojoDataPipeConsumer(3.0);
        break;
      case 'assets/4.0x/image.png':
        pipe = new TestMojoDataPipeConsumer(4.0);
        break;
    }
    return (new Completer<core.MojoDataPipeConsumer>()..complete(pipe)).future;
  }

  @override
  String toString() => '$runtimeType@$hashCode()';
}

Future<ui.Image> testDecodeImageFromDataPipe(core.MojoDataPipeConsumer pipe) {
  TestMojoDataPipeConsumer testPipe = pipe;
  assert(testPipe != null);
  ui.Image image = new TestImage(testPipe.scale);
  return (new Completer<ui.Image>()..complete(image)).future;
}

Widget buildImageAtRatio(String image, Key key, double ratio, bool inferSize) {
  const double windowSize = 500.0; // 500 logical pixels
  const double imageSize = 200.0; // 200 logical pixels

  return new MediaQuery(
    data: new MediaQueryData(
      size: const Size(windowSize, windowSize),
      devicePixelRatio: ratio,
      padding: const EdgeInsets.all(0.0)
    ),
    child: new AssetVendor(
      bundle: new TestAssetBundle(),
      devicePixelRatio: ratio,
      imageDecoder: testDecodeImageFromDataPipe,
      child: new Center(
        child: inferSize ?
          new AssetImage(
            key: key,
            name: image
          ) :
          new AssetImage(
            key: key,
            name: image,
            height: imageSize,
            width: imageSize,
            fit: ImageFit.fill
          )
      )
    )
  );
}

RenderImage getRenderImage(WidgetTester tester, Key key) {
  return tester.renderObject/*<RenderImage>*/(find.byKey(key));
}
TestImage getTestImage(WidgetTester tester, Key key) {
  return tester.renderObject/*<RenderImage>*/(find.byKey(key)).image;
}

void pumpTreeToLayout(WidgetTester tester, Widget widget) {
  Duration pumpDuration = const Duration(milliseconds: 0);
  EnginePhase pumpPhase = EnginePhase.layout;
  tester.pumpWidget(widget, pumpDuration, pumpPhase);
}

void main() {
  String image = 'assets/image.png';

  testWidgets('Image for device pixel ratio 1.0', (WidgetTester tester) {
    const double ratio = 1.0;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 1.0);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 1.0);
  });

  testWidgets('Image for device pixel ratio 0.5', (WidgetTester tester) {
    const double ratio = 0.5;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 1.0);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 1.0);
  });

  testWidgets('Image for device pixel ratio 1.5', (WidgetTester tester) {
    const double ratio = 1.5;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 1.5);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 1.5);
  });

  testWidgets('Image for device pixel ratio 1.75', (WidgetTester tester) {
    const double ratio = 1.75;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 1.5);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 1.5);
  });

  testWidgets('Image for device pixel ratio 2.3', (WidgetTester tester) {
    const double ratio = 2.3;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 2.0);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 2.0);
  });

  testWidgets('Image for device pixel ratio 3.7', (WidgetTester tester) {
    const double ratio = 3.7;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 4.0);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 4.0);
  });

  testWidgets('Image for device pixel ratio 5.1', (WidgetTester tester) {
    const double ratio = 5.1;
    Key key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, false));
    expect(getRenderImage(tester, key).size, const Size(200.0, 200.0));
    expect(getTestImage(tester, key).scale, 4.0);
    key = new GlobalKey();
    pumpTreeToLayout(tester, buildImageAtRatio(image, key, ratio, true));
    expect(getRenderImage(tester, key).size, const Size(48.0, 48.0));
    expect(getTestImage(tester, key).scale, 4.0);
  });

}
