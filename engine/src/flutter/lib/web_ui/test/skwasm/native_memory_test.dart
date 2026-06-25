// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/primitives/image.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('Skwasm native memory', () {
    test('SkwasmImage.clone share same handle and box', () {
      final pixels = Uint8List(4);
      final SkwasmImage backendImage = createSkwasmImageFromPixels(
        pixels,
        1,
        1,
        ui.PixelFormat.rgba8888,
      );
      final EngineImage image = EngineImage(backendImage, 1, 1);

      final EngineImage clone = image.clone();
      expect(
        (clone.backendImage as SkwasmImage).handle,
        (image.backendImage as SkwasmImage).handle,
      );
      expect(clone.box, image.box);
      expect(image.box.refCount, 2);

      image.dispose();
      expect(clone.debugDisposed, isFalse);
      expect(clone.box.refCount, 1);

      clone.dispose();
      expect(clone.debugDisposed, isTrue);
      expect(clone.box.refCount, 0);
    });

    test('SkwasmPicture.clone share same handle and box', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 10, 10), ui.Paint());
      final picture = recorder.endRecording() as SkwasmPicture;

      final clone = picture.clone() as SkwasmPicture;
      expect(clone.handle, picture.handle);
      expect(clone.box, picture.box);
      expect(picture.box.refCount, 2);

      picture.dispose();
      expect(clone.isDisposed, isFalse);
      expect(clone.box.refCount, 1);

      clone.dispose();
      expect(clone.isDisposed, isTrue);
      expect(clone.box.refCount, 0);
    });
  });
}
