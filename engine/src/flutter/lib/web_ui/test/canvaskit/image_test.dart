// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';
import 'test_data.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit image', () {
    setUpAll(() async {
      await ui.webOnlyInitializePlatform();
    });

    test('CkAnimatedImage toString', () {
      final SkAnimatedImage skAnimatedImage = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
      final CkAnimatedImage image = CkAnimatedImage(skAnimatedImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
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

    test('CkAnimatedImage can be cloned and explicitly disposed of', () async {
      final SkAnimatedImage skAnimatedImage = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage);
      final CkAnimatedImage image = CkAnimatedImage(skAnimatedImage);
      final CkAnimatedImage imageClone = image.clone();

      expect(image.isCloneOf(imageClone), true);
      expect(image.box.isDeleted, false);
      await Future<void>.delayed(Duration.zero);
      expect(skAnimatedImage.isDeleted(), false);
      image.dispose();
      expect(image.box.isDeleted, true);
      expect(imageClone.box.isDeleted, false);
      await Future<void>.delayed(Duration.zero);
      expect(skAnimatedImage.isDeleted(), false);
      imageClone.dispose();
      expect(image.box.isDeleted, true);
      expect(imageClone.box.isDeleted, true);
      await Future<void>.delayed(Duration.zero);
      expect(skAnimatedImage.isDeleted(), true);
    });

    test('CkImage toString', () {
      final SkImage skImage = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage).getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
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

    test('CkImage can be explicitly disposed of when cloned', () async {
      final SkImage skImage = canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage).getCurrentFrame();
      final CkImage image = CkImage(skImage);
      final CkImage imageClone = image.clone();

      expect(image.isCloneOf(imageClone), true);
      expect(image.box.isDeleted, false);
      await Future<void>.delayed(Duration.zero);
      expect(skImage.isDeleted(), false);
      image.dispose();
      expect(image.box.isDeleted, true);
      expect(imageClone.box.isDeleted, false);
      await Future<void>.delayed(Duration.zero);
      expect(skImage.isDeleted(), false);
      imageClone.dispose();
      expect(image.box.isDeleted, true);
      expect(imageClone.box.isDeleted, true);
      await Future<void>.delayed(Duration.zero);
      expect(skImage.isDeleted(), true);
    });
  // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
