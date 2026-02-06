// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_data.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  group('CanvasKit Images', () {
    setUpCanvasKitTest(withImplicitView: true);

    test('ImageDecoder toByteData(PNG)', () async {
      final image = CkAnimatedImage.decodeFromBytes(kAnimatedGif, 'test');
      final ui.FrameInfo frame = await image.getNextFrame();
      final ByteData? png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      expect(png, isNotNull);

      // The precise PNG encoding is browser-specific, but we can check the file
      // signature.
      expect(detectImageType(png!.buffer.asUint8List()), ImageType.png);
    });

    test('CkAnimatedImage toByteData(RGBA)', () async {
      final image = CkAnimatedImage.decodeFromBytes(kAnimatedGif, 'test');
      const expectedColors = <List<int>>[
        <int>[255, 0, 0, 255],
        <int>[0, 255, 0, 255],
        <int>[0, 0, 255, 255],
      ];
      for (var i = 0; i < image.frameCount; i++) {
        final ui.FrameInfo frame = await image.getNextFrame();
        final ByteData? rgba = await frame.image.toByteData();
        expect(rgba, isNotNull);
        expect(rgba!.buffer.asUint8List(), expectedColors[i]);
      }
    });
  });
}
