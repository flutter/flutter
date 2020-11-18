// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' show ProgressEvent;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../matchers.dart';
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

    test('CkAnimatedImage can be explicitly disposed of', () {
      final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kTransparentImage);
      expect(image.box.isDeleted, false);
      expect(image.debugDisposed, false);
      image.dispose();
      expect(image.box.isDeleted, true);
      expect(image.debugDisposed, true);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
    });

    test('CkAnimatedImage can be cloned and explicitly disposed of', () async {
      final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kTransparentImage);
      final SkAnimatedImage skAnimatedImage = image.box.skiaObject;
      final SkiaObjectBox<CkAnimatedImage, SkAnimatedImage> box = image.box;
      expect(box.refCount, 1);
      expect(box.debugGetStackTraces().length, 1);

      image.dispose();
      expect(box.isDeleted, true);
      await Future<void>.delayed(Duration.zero);
      expect(skAnimatedImage.isDeleted(), true);
      expect(box.debugGetStackTraces().length, 0);
    });

    test('CkImage toString', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
    });

    test('CkImage can be explicitly disposed of', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.debugDisposed, false);
      expect(image.box.isDeleted, false);
      image.dispose();
      expect(image.debugDisposed, true);
      expect(image.box.isDeleted, true);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
    });

    test('CkImage can be explicitly disposed of when cloned', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      final SkiaObjectBox<CkImage, SkImage> box = image.box;
      expect(box.refCount, 1);
      expect(box.debugGetStackTraces().length, 1);

      final CkImage imageClone = image.clone();
      expect(box.refCount, 2);
      expect(box.debugGetStackTraces().length, 2);

      expect(image.isCloneOf(imageClone), true);
      expect(box.isDeleted, false);
      await Future<void>.delayed(Duration.zero);
      expect(skImage.isDeleted(), false);
      image.dispose();
      expect(box.isDeleted, false);
      await Future<void>.delayed(Duration.zero);
      expect(skImage.isDeleted(), false);
      imageClone.dispose();
      expect(box.isDeleted, true);
      await Future<void>.delayed(Duration.zero);
      expect(skImage.isDeleted(), true);
      expect(box.debugGetStackTraces().length, 0);
    });

    test('skiaInstantiateWebImageCodec throws exception if given invalid URL',
        () async {
      expect(skiaInstantiateWebImageCodec('invalid-url', null),
          throwsA(isA<ProgressEvent>()));
    });

    test('CkImage toByteData', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect((await image.toByteData()).lengthInBytes, greaterThan(0));
      expect((await image.toByteData(format: ui.ImageByteFormat.png)).lengthInBytes, greaterThan(0));
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
