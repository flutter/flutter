// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A tree of [Layer]s that, together with a [Size] compose a frame.
class LayerTree {
  /// The root of the layer tree.
  Layer rootLayer;

  /// The size (in physical pixels) of the frame to paint this layer tree into.
  ui.Size frameSize;

  /// Performs a preroll phase before painting the layer tree.
  ///
  /// In this phase, the paint boundary for each layer is computed and
  /// pictures are registered with the raster cache as potential candidates
  /// to raster. If [ignoreRasterCache] is `true`, then there will be no
  /// attempt to register pictures to cache.
  void preroll(Frame frame, {bool ignoreRasterCache = false}) {
    final PrerollContext context =
        PrerollContext(ignoreRasterCache ? null : frame.rasterCache);
    rootLayer.preroll(context, Matrix4.identity());
  }

  /// Paints the layer tree into the given [frame].
  ///
  /// If [ignoreRasterCache] is `true`, then the raster cache will
  /// not be used.
  void paint(Frame frame, {bool ignoreRasterCache = false}) {
    final PaintContext context = PaintContext(
        frame.canvas, ignoreRasterCache ? null : frame.rasterCache);
    if (rootLayer.needsPainting) {
      rootLayer.paint(context);
    }
  }
}

/// A single frame to be rendered.
class Frame {
  /// The canvas to render this frame to.
  final SkCanvas canvas;

  /// A cache of pre-rastered pictures.
  final RasterCache rasterCache;

  Frame(this.canvas, this.rasterCache);

  /// Rasterize the given layer tree into this frame.
  bool raster(LayerTree layerTree, {bool ignoreRasterCache = false}) {
    layerTree.preroll(this, ignoreRasterCache: ignoreRasterCache);
    layerTree.paint(this, ignoreRasterCache: ignoreRasterCache);
    return true;
  }
}

/// The state of the compositor, which is persisted between frames.
class CompositorContext {
  /// A cache of pictures, which is shared between successive frames.
  RasterCache rasterCache;

  /// Acquire a frame using this compositor's settings.
  Frame acquireFrame(SkCanvas canvas) {
    return Frame(canvas, rasterCache);
  }
}
