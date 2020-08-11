// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';
import 'test_data.dart';

void main() {
  group('CanvasKit image', () {
    setUpAll(() async {
      await ui.webOnlyInitializePlatform();
    });

    test('CkAnimatedImage can be explicitly disposed of', () {
      final SkAnimatedImage skAnimatedImage = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
      final CkAnimatedImage image = CkAnimatedImage(skAnimatedImage);
      expect(image.box.isDeleted, false);
      image.dispose();
      expect(image.box.isDeleted, true);
      image.dispose();
      expect(image.box.isDeleted, true);
    });

    test('CkImage can be explicitly disposed of', () {
      final SkImage skImage = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage).getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.box.isDeleted, false);
      image.dispose();
      expect(image.box.isDeleted, true);
      image.dispose();
      expect(image.box.isDeleted, true);
    });
  // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
