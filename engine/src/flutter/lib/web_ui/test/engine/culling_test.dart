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

void testMain() {
  setUpUnitTests();

  test('Picture is culled when outside of the viewport', () {
    // Create a picture that is outside the viewport.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(200, 200, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final PictureLayer pictureLayer = PictureLayer(
      picture as LayerPicture,
      ui.Offset.zero,
      false,
      false,
    );

    final RootLayer rootLayer = RootLayer();
    rootLayer.children.add(pictureLayer);

    // Preroll and measure the scene. The viewport is 100x100.
    final PrerollVisitor prerollVisitor = PrerollVisitor(null);
    rootLayer.accept(prerollVisitor);

    final MeasureVisitor measureVisitor = MeasureVisitor(const BitmapSize(100, 100), null);
    rootLayer.accept(measureVisitor);

    // The picture should be culled.
    expect(pictureLayer.isCulled, isTrue);
  });

  test('Picture is culled when clipped out', () {
    // Create a picture.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final PictureLayer pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(50, 50), // Position the picture inside the clip.
      false,
      false,
    );

    final ClipRectEngineLayer clipRectLayer = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 20, 20), // Clip rect is at the top-left.
      ui.Clip.hardEdge,
    );
    clipRectLayer.children.add(pictureLayer);

    final RootLayer rootLayer = RootLayer();
    rootLayer.children.add(clipRectLayer);

    // Preroll and measure the scene. The viewport is 100x100.
    final PrerollVisitor prerollVisitor = PrerollVisitor(null);
    rootLayer.accept(prerollVisitor);

    final MeasureVisitor measureVisitor = MeasureVisitor(const BitmapSize(100, 100), null);
    rootLayer.accept(measureVisitor);

    // The picture is outside the clip, so it should be culled.
    expect(pictureLayer.isCulled, isTrue);
  });

  test('Picture is not culled when inside a clip', () {
    // Create a picture.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final PictureLayer pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(5, 5), // Position the picture inside the clip.
      false,
      false,
    );

    final ClipRectEngineLayer clipRectLayer = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 20, 20), // Clip rect is at the top-left.
      ui.Clip.hardEdge,
    );
    clipRectLayer.children.add(pictureLayer);

    final RootLayer rootLayer = RootLayer();
    rootLayer.children.add(clipRectLayer);

    // Preroll and measure the scene. The viewport is 100x100.
    final PrerollVisitor prerollVisitor = PrerollVisitor(null);
    rootLayer.accept(prerollVisitor);

    final MeasureVisitor measureVisitor = MeasureVisitor(const BitmapSize(100, 100), null);
    rootLayer.accept(measureVisitor);

    // The picture is inside the clip, so it should not be culled.
    expect(pictureLayer.isCulled, isFalse);
  });

  test('Picture is not culled when it becomes visible again', () {
    // Create a picture.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final PictureLayer pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(25, 25), // Position the picture.
      false,
      false,
    );

    // Frame 1: The picture is outside the clip, so it should be culled.
    final ClipRectEngineLayer clipRectLayer1 = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 20, 20), // Clip rect is at the top-left.
      ui.Clip.hardEdge,
    );
    clipRectLayer1.children.add(pictureLayer);
    final RootLayer rootLayer1 = RootLayer();
    rootLayer1.children.add(clipRectLayer1);

    final PrerollVisitor prerollVisitor1 = PrerollVisitor(null);
    rootLayer1.accept(prerollVisitor1);
    final MeasureVisitor measureVisitor1 = MeasureVisitor(const BitmapSize(100, 100), null);
    rootLayer1.accept(measureVisitor1);
    expect(pictureLayer.isCulled, isTrue);

    // Frame 2: The clip is moved to contain the picture. It should not be culled.
    final ClipRectEngineLayer clipRectLayer2 = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 40, 40), // Clip rect now contains the picture.
      ui.Clip.hardEdge,
    );
    // IMPORTANT: we are reusing the same pictureLayer instance.
    clipRectLayer2.children.add(pictureLayer);
    final RootLayer rootLayer2 = RootLayer();
    rootLayer2.children.add(clipRectLayer2);

    final PrerollVisitor prerollVisitor2 = PrerollVisitor(null);
    rootLayer2.accept(prerollVisitor2);
    final MeasureVisitor measureVisitor2 = MeasureVisitor(const BitmapSize(100, 100), null);
    rootLayer2.accept(measureVisitor2);
    expect(pictureLayer.isCulled, isFalse);
  });
}
