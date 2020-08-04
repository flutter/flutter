// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

Future<void> main() async {
  await ui.webOnlyInitializeTestDomRenderer();
  group('HtmCodec', () {
    test('loads sample image', () async {
      final HtmlCodec codec = HtmlCodec('sample_image1.png');
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      expect(frameInfo.image, isNotNull);
      expect(frameInfo.image.width, 100);
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
