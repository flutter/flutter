// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../skwasm_impl.dart';

/// A [Rasterizer] that uses a single GL context in an OffscreenCanvas to do
/// all the rendering. It transfers bitmaps created in the OffscreenCanvas to
/// one or many on-screen <canvas> elements to actually display the scene.
class OffscreenCanvasRasterizer extends Rasterizer {
  /// This is an SkSurface backed by an OffScreenCanvas. This single Surface is
  /// used to render to many RenderCanvases to produce the rendered scene.
  final SkwasmSurface offscreenSurface = SkwasmSurface();

  @override
  OffscreenCanvasViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return _viewRasterizers.putIfAbsent(view, () => OffscreenCanvasViewRasterizer(view, this));
  }

  final Map<EngineFlutterView, OffscreenCanvasViewRasterizer> _viewRasterizers =
      <EngineFlutterView, OffscreenCanvasViewRasterizer>{};

  @override
  void setResourceCacheMaxBytes(int bytes) {
    // XXX DO NOT SUBMIT
    // Do something here.
    // offscreenSurface.setSkiaResourceCacheMaxBytes(bytes);
  }

  @override
  void dispose() {
    offscreenSurface.dispose();
    for (final OffscreenCanvasViewRasterizer viewRasterizer in _viewRasterizers.values) {
      viewRasterizer.dispose();
    }
  }
}

class OffscreenCanvasViewRasterizer extends ViewRasterizer {
  OffscreenCanvasViewRasterizer(super.view, this.rasterizer);

  final OffscreenCanvasRasterizer rasterizer;

  @override
  final DisplayCanvasFactory<RenderCanvas> displayFactory = DisplayCanvasFactory<RenderCanvas>(
    createCanvas: () => RenderCanvas(),
  );

  @override
  void prepareToDraw() {
    // XXX DO NOT SUBMIT
    // Set the size of the surface here?
    // rasterizer.offscreenSurface.createOrUpdateSurface(currentFrameSize);
  }

  @override
  Future<void> rasterize(List<DisplayCanvas> displayCanvases, List<ui.Picture> pictures) async {
    if (displayCanvases.length != pictures.length) {
      throw ArgumentError('Called rasterize() with a different number of canvases and pictures.');
    }
    final RenderResult renderResult = await rasterizer.offscreenSurface.renderPictures(
      pictures.cast<SkwasmPicture>(),
    );
    for (int i = 0; i < displayCanvases.length; i++) {
      final RenderCanvas renderCanvas = displayCanvases[i] as RenderCanvas;
      final DomImageBitmap bitmap = renderResult.imageBitmaps[i];
      renderCanvas.render(bitmap);
    }
    return Future<void>.value();
  }
}
