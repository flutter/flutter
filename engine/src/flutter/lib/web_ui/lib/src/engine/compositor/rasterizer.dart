// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// A class that can rasterize [LayerTree]s into a given [Surface].
class Rasterizer {
  final Surface surface;
  final CompositorContext context = CompositorContext();
  final HtmlViewEmbedder viewEmbedder = HtmlViewEmbedder();
  final List<ui.VoidCallback> _postFrameCallbacks = <ui.VoidCallback>[];

  Rasterizer(this.surface) {
    surface.viewEmbedder = viewEmbedder;
  }

  /// Creates a new frame from this rasterizer's surface, draws the given
  /// [LayerTree] into it, and then submits the frame.
  void draw(LayerTree layerTree) {
    try {
      if (layerTree == null) {
        return;
      }

      final ui.Size physicalSize = ui.window.physicalSize;
      final ui.Size frameSize = ui.Size(
        physicalSize.width.truncate().toDouble(),
        physicalSize.height.truncate().toDouble(),
      );

      if (frameSize.isEmpty) {
        return;
      }
      layerTree.frameSize = frameSize;

      final SurfaceFrame frame = surface.acquireFrame(layerTree.frameSize);
      surface.viewEmbedder.frameSize = layerTree.frameSize;
      final SkCanvas canvas = frame.skiaCanvas;
      final Frame compositorFrame =
          context.acquireFrame(canvas, surface.viewEmbedder);

      compositorFrame.raster(layerTree, ignoreRasterCache: true);
      surface.addToScene();
      frame.submit();
      surface.viewEmbedder.submitFrame();
    } finally {
      _runPostFrameCallbacks();
    }
  }

  void addPostFrameCallback(ui.VoidCallback callback) {
    _postFrameCallbacks.add(callback);
  }

  void _runPostFrameCallbacks() {
    for (int i = 0; i < _postFrameCallbacks.length; i++) {
      final ui.VoidCallback callback = _postFrameCallbacks[i];
      callback();
    }
    for (int i = 0; i < _frameReferences.length; i++) {
      _frameReferences[i].value = null;
    }
    _frameReferences.clear();
  }
}
