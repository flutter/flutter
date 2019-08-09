// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A class that can rasterize [LayerTree]s into a given [Surface].
class Rasterizer {
  final Surface surface;
  final CompositorContext context = CompositorContext();

  Rasterizer(this.surface);

  /// Creates a new frame from this rasterizer's surface, draws the given
  /// [LayerTree] into it, and then submits the frame.
  void draw(LayerTree layerTree) {
    final SurfaceFrame frame = surface.acquireFrame(ui.window.physicalSize);
    final SkCanvas canvas = frame.canvas;
    final Frame compositorFrame = context.acquireFrame(canvas);

    canvas.clear();

    compositorFrame.raster(layerTree, ignoreRasterCache: true);
    frame.submit();
  }
}
