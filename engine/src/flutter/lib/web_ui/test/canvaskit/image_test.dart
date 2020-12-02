// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' show ProgressEvent;
import 'dart:typed_data';

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
    setUpCanvasKitTest();

    test('CkAnimatedImage can be explicitly disposed of', () {
      final CkAnimatedImage image = CkAnimatedImage.decodeFromBytes(kTransparentImage);
      expect(image.debugDisposed, false);
      image.dispose();
      expect(image.debugDisposed, true);

      // Disallow usage after disposal
      expect(() => image.frameCount, throwsAssertionError);
      expect(() => image.repetitionCount, throwsAssertionError);
      expect(() => image.getNextFrame(), throwsAssertionError);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
      testCollector.collectNow();
    });

    test('CkImage toString', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.toString(), '[1×1]');
      image.dispose();
      testCollector.collectNow();
    });

    test('CkImage can be explicitly disposed of', () {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect(image.debugDisposed, false);
      expect(image.box.isDeletedPermanently, false);
      image.dispose();
      expect(image.debugDisposed, true);
      expect(image.box.isDeletedPermanently, true);

      // Disallow double-dispose.
      expect(() => image.dispose(), throwsAssertionError);
      testCollector.collectNow();
    });

    test('CkImage can be explicitly disposed of when cloned', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      final SkiaObjectBox<CkImage, SkImage> box = image.box;
      expect(box.refCount, 1);
      expect(box.debugGetStackTraces().length, 1);

      final CkImage clone = image.clone();
      expect(box.refCount, 2);
      expect(box.debugGetStackTraces().length, 2);

      expect(image.isCloneOf(clone), true);
      expect(box.isDeletedPermanently, false);

      testCollector.collectNow();
      expect(skImage.isDeleted(), false);
      image.dispose();
      expect(box.refCount, 1);
      expect(box.isDeletedPermanently, false);

      testCollector.collectNow();
      expect(skImage.isDeleted(), false);
      clone.dispose();
      expect(box.refCount, 0);
      expect(box.isDeletedPermanently, true);

      testCollector.collectNow();
      expect(skImage.isDeleted(), true);
      expect(box.debugGetStackTraces().length, 0);
      testCollector.collectNow();
    });

    test('skiaInstantiateWebImageCodec throws exception if given invalid URL',
        () async {
      expect(skiaInstantiateWebImageCodec('invalid-url', null),
          throwsA(isA<ProgressEvent>()));
      testCollector.collectNow();
    });

    test('CkImage toByteData', () async {
      final SkImage skImage =
          canvasKit.MakeAnimatedImageFromEncoded(kTransparentImage)
              .getCurrentFrame();
      final CkImage image = CkImage(skImage);
      expect((await image.toByteData()).lengthInBytes, greaterThan(0));
      expect((await image.toByteData(format: ui.ImageByteFormat.png)).lengthInBytes, greaterThan(0));
      testCollector.collectNow();
    });

    test('Reports error when failing to decode image', () async {
      try {
        await ui.instantiateImageCodec(Uint8List(0));
        fail('Expected to throw');
      } on Exception catch (exception) {
        expect(exception.toString(), 'Exception: Failed to decode image');
      }
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
