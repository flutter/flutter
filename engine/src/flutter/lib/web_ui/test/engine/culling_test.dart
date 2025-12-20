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
  setUpUnitTests(withImplicitView: true);

  test('Picture is culled when outside of the viewport', () {
    // Create a picture that is outside the viewport.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(200, 200, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final pictureLayer = PictureLayer(picture as LayerPicture, ui.Offset.zero, false, false);

    final rootLayer = RootLayer();
    rootLayer.children.add(pictureLayer);
    final PlatformViewEmbedder embedder = createPlatformViewEmbedder();

    // Preroll and measure the scene. The viewport is 100x100.
    final prerollVisitor = PrerollVisitor(embedder);
    rootLayer.accept(prerollVisitor);

    final measureVisitor = MeasureVisitor(const BitmapSize(100, 100), embedder);
    rootLayer.accept(measureVisitor);

    embedder.optimizeComposition();

    // The picture should be culled and not composited.
    expect(embedder.debugContext.pictureToOptimizedCanvasMap!.containsKey(pictureLayer), isFalse);
  });

  test('Picture is culled when clipped out', () {
    // Create a picture.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(50, 50), // Position the picture inside the clip.
      false,
      false,
    );

    final clipRectLayer = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 20, 20), // Clip rect is at the top-left.
      ui.Clip.hardEdge,
    );
    clipRectLayer.children.add(pictureLayer);

    final rootLayer = RootLayer();
    rootLayer.children.add(clipRectLayer);
    final PlatformViewEmbedder embedder = createPlatformViewEmbedder();

    // Preroll and measure the scene. The viewport is 100x100.
    final prerollVisitor = PrerollVisitor(embedder);
    rootLayer.accept(prerollVisitor);

    final measureVisitor = MeasureVisitor(const BitmapSize(100, 100), embedder);
    rootLayer.accept(measureVisitor);

    embedder.optimizeComposition();

    // The picture is outside the clip, so it should be culled and not composited.
    expect(embedder.debugContext.pictureToOptimizedCanvasMap!.containsKey(pictureLayer), isFalse);
  });

  test('Picture is not culled when inside a clip', () {
    // Create a picture.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(5, 5), // Position the picture inside the clip.
      false,
      false,
    );

    final clipRectLayer = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 20, 20), // Clip rect is at the top-left.
      ui.Clip.hardEdge,
    );
    clipRectLayer.children.add(pictureLayer);

    final rootLayer = RootLayer();
    rootLayer.children.add(clipRectLayer);
    final PlatformViewEmbedder embedder = createPlatformViewEmbedder();

    // Preroll and measure the scene. The viewport is 100x100.
    final prerollVisitor = PrerollVisitor(embedder);
    rootLayer.accept(prerollVisitor);

    final measureVisitor = MeasureVisitor(const BitmapSize(100, 100), embedder);
    rootLayer.accept(measureVisitor);

    embedder.optimizeComposition();

    // The picture is inside the clip, so it should not be culled and should be composited.
    expect(embedder.debugContext.pictureToOptimizedCanvasMap!.containsKey(pictureLayer), isTrue);
  });

  test('Picture is not culled when it becomes visible again', () {
    // Create a picture.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(25, 25), // Position the picture.
      false,
      false,
    );

    void renderAndCheck(ui.Rect clipRect, {required bool isComposited}) {
      final clipRectLayer = ClipRectEngineLayer(clipRect, ui.Clip.hardEdge);
      // IMPORTANT: we are reusing the same pictureLayer instance.
      clipRectLayer.children.add(pictureLayer);
      final rootLayer = RootLayer();
      rootLayer.children.add(clipRectLayer);
      final PlatformViewEmbedder embedder = createPlatformViewEmbedder();

      final prerollVisitor = PrerollVisitor(embedder);
      rootLayer.accept(prerollVisitor);
      final measureVisitor = MeasureVisitor(const BitmapSize(100, 100), embedder);
      rootLayer.accept(measureVisitor);

      embedder.optimizeComposition();
      expect(
        embedder.debugContext.pictureToOptimizedCanvasMap!.containsKey(pictureLayer),
        isComposited,
      );
    }

    // Frame 1: The picture is outside the clip, so it should be culled and not composited.
    renderAndCheck(
      const ui.Rect.fromLTWH(0, 0, 20, 20), // Clip rect is at the top-left.
      isComposited: false,
    );

    // Frame 2: The clip is moved to contain the picture. It should not be culled.
    renderAndCheck(
      const ui.Rect.fromLTWH(0, 0, 40, 40), // Clip rect now contains the picture.
      isComposited: true,
    );
  });
}

PlatformViewEmbedder createPlatformViewEmbedder() {
  return PlatformViewEmbedder(
    createDomHTMLDivElement(),
    FakeRasterizer(EnginePlatformDispatcher.instance.implicitView!),
  )..frameSize = const BitmapSize(100, 100);
}

class FakeRasterizer extends ViewRasterizer {
  FakeRasterizer(super.view);

  @override
  DisplayCanvasFactory<DisplayCanvas> get displayFactory => throw UnimplementedError();

  @override
  void prepareToDraw() {
    throw UnimplementedError();
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) {
    throw UnimplementedError();
  }
}
