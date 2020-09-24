// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  await ui.webOnlyInitializeTestDomRenderer();
  group('HtmCodec', () {
    test('supports raw images - RGBA8888', () async {
      final Completer<ui.Image> completer = Completer<ui.Image>();
      const int width = 200;
      const int height = 300;
      final Uint32List list = Uint32List(width * height);
      for (int index = 0; index < list.length; index += 1) {
        list[index] = 0xFF0000FF;
      }
      ui.decodeImageFromPixels(
        list.buffer.asUint8List(),
        width,
        height,
        ui.PixelFormat.rgba8888,
        (ui.Image image) => completer.complete(image),
      );
      final ui.Image image = await completer.future;
      expect(image.width, width);
      expect(image.height, height);
    });
    test('supports raw images - BGRA8888', () async {
      final Completer<ui.Image> completer = Completer<ui.Image>();
      const int width = 200;
      const int height = 300;
      final Uint32List list = Uint32List(width * height);
      for (int index = 0; index < list.length; index += 1) {
        list[index] = 0xFF0000FF;
      }
      ui.decodeImageFromPixels(
        list.buffer.asUint8List(),
        width,
        height,
        ui.PixelFormat.bgra8888,
        (ui.Image image) => completer.complete(image),
      );
      final ui.Image image = await completer.future;
      expect(image.width, width);
      expect(image.height, height);
    });
    test('loads sample image', () async {
      final HtmlCodec codec = HtmlCodec('sample_image1.png');
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image, isNotNull);
      expect(frameInfo.image.width, 100);
      expect(frameInfo.image.toString(), '[100×100]');
    });
    test('provides image loading progress', () async {
      StringBuffer buffer = new StringBuffer();
      final HtmlCodec codec = HtmlCodec('sample_image1.png',
          chunkCallback: (int loaded, int total) {
        buffer.write('$loaded/$total,');
      });
      await codec.getNextFrame();
      expect(buffer.toString(), '0/100,100/100,');
    });
  });

  group('ImageCodecUrl', () {
    test('loads sample image from web', () async {
      final Uri uri = Uri.base.resolve('sample_image1.png');
      final HtmlCodec codec = await ui.webOnlyInstantiateImageCodecFromUrl(uri);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image, isNotNull);
      expect(frameInfo.image.width, 100);
    });
    test('provides image loading progress from web', () async {
      final Uri uri = Uri.base.resolve('sample_image1.png');
      StringBuffer buffer = new StringBuffer();
      final HtmlCodec codec = await ui.webOnlyInstantiateImageCodecFromUrl(uri,
          chunkCallback: (int loaded, int total) {
        buffer.write('$loaded/$total,');
      });
      await codec.getNextFrame();
      expect(buffer.toString(), '0/100,100/100,');
    });
  });
}
