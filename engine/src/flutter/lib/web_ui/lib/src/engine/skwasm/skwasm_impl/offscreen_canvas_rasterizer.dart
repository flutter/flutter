// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../skwasm_impl.dart';

/// A [Rasterizer] that uses a single GL context in an OffscreenCanvas to do
/// all the rendering. It transfers bitmaps created in the OffscreenCanvas to
/// one or many on-screen <canvas> elements to actually display the scene.
class SkwasmOffscreenCanvasRasterizer extends Rasterizer {
  SkwasmOffscreenCanvasRasterizer(this.offscreenSurface);

  /// This is an SkSurface backed by an OffScreenCanvas. This single Surface is
  /// used to render to many RenderCanvases to produce the rendered scene.
  final SkwasmSurface offscreenSurface;

  @override
  SkwasmOffscreenCanvasViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return _viewRasterizers.putIfAbsent(
      view,
      () => SkwasmOffscreenCanvasViewRasterizer(view, this),
    );
  }

  final Map<EngineFlutterView, SkwasmOffscreenCanvasViewRasterizer> _viewRasterizers =
      <EngineFlutterView, SkwasmOffscreenCanvasViewRasterizer>{};

  @override
  void setResourceCacheMaxBytes(int bytes) {
    offscreenSurface.setSkiaResourceCacheMaxBytes(bytes);
  }

  @override
  void dispose() {
    offscreenSurface.dispose();
    for (final SkwasmOffscreenCanvasViewRasterizer viewRasterizer in _viewRasterizers.values) {
      viewRasterizer.dispose();
    }
  }
}

class SkwasmOffscreenCanvasViewRasterizer extends ViewRasterizer {
  SkwasmOffscreenCanvasViewRasterizer(super.view, this.rasterizer);

  final SkwasmOffscreenCanvasRasterizer rasterizer;

  @override
  final DisplayCanvasFactory<RenderCanvas> displayFactory = DisplayCanvasFactory<RenderCanvas>(
    createCanvas: () => RenderCanvas(),
  );

  @override
  void prepareToDraw() {
    // No need to do anything here. Skwasm sizes the surface in the `rasterize`
    // call below.
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    if (displayCanvases.length != pictures.length) {
      throw ArgumentError('Called rasterize() with a different number of canvases and pictures.');
    }
    final RenderResult renderResult = await rasterizer.offscreenSurface.renderPictures(
      pictures.cast<SkwasmPicture>(),
      currentFrameSize.width,
      currentFrameSize.height,
    );
    recorder?.recordRasterStart(renderResult.rasterStartMicros);
    recorder?.recordRasterFinish(renderResult.rasterEndMicros);
    for (var i = 0; i < displayCanvases.length; i++) {
      final renderCanvas = displayCanvases[i] as RenderCanvas;
      final DomImageBitmap bitmap = renderResult.imageBitmaps[i];
      renderCanvas.render(bitmap);
    }
  }
}
