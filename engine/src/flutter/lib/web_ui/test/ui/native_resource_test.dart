// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  group('ui.Image native resource tracking', () {
    test('onCreate and onDispose are balanced for cloned images', () {
      var createCount = 0;
      var disposeCount = 0;
      ui.Image? lastCreatedImage;
      ui.Image? lastDisposedImage;

      ui.Image.onCreate = (ui.Image image) {
        createCount++;
        lastCreatedImage = image;
      };
      ui.Image.onDispose = (ui.Image image) {
        disposeCount++;
        lastDisposedImage = image;
      };

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 1, 1), ui.Paint());
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image1 = picture.toImageSync(1, 1);

      expect(createCount, 1);
      expect(disposeCount, 0);
      expect(lastCreatedImage, same(image1));

      final ui.Image image2 = image1.clone();
      // Should NOT call onCreate for clones if we are tracking native resources
      expect(createCount, 1);
      expect(disposeCount, 0);

      image1.dispose();
      // Should NOT call onDispose yet as image2 is still alive
      expect(createCount, 1);
      expect(disposeCount, 0);

      image2.dispose();
      // NOW it should call onDispose
      expect(createCount, 1);
      expect(disposeCount, 1);
      expect(lastDisposedImage, same(image2));

      picture.dispose();
      ui.Image.onCreate = null;
      ui.Image.onDispose = null;
    });
  });

  group('ui.Picture native resource tracking', () {
    test('onCreate and onDispose are balanced for cloned pictures', () {
      var createCount = 0;
      var disposeCount = 0;
      ui.Picture? lastCreatedPicture;
      ui.Picture? lastDisposedPicture;

      ui.Picture.onCreate = (ui.Picture picture) {
        createCount++;
        lastCreatedPicture = picture;
      };
      ui.Picture.onDispose = (ui.Picture picture) {
        disposeCount++;
        lastDisposedPicture = picture;
      };

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 10, 10), ui.Paint());
      final ui.Picture picture1 = recorder.endRecording();

      expect(createCount, 1);
      expect(disposeCount, 0);
      expect(lastCreatedPicture, same(picture1));

      final LayerPicture picture2 = (picture1 as LayerPicture).clone();
      expect(createCount, 1);
      expect(disposeCount, 0);

      // The original picture should call onDispose when it is disposed,
      // regardless of whether there are live clones.
      picture1.dispose();
      expect(createCount, 1);
      expect(disposeCount, 1);

      // Disposing the clone should not call onDispose again.
      picture2.dispose();
      expect(createCount, 1);
      expect(disposeCount, 1);
      expect(lastDisposedPicture, same(picture1));

      ui.Picture.onCreate = null;
      ui.Picture.onDispose = null;
    });
  });
}
