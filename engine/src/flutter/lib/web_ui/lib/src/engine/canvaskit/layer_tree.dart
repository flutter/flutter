// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../../engine.dart' show kProfileApplyFrame, kProfilePrerollFrame;
import '../profiler.dart';
import '../vector_math.dart';
import 'canvas.dart';
import 'embedded_views.dart';
import 'layer.dart';
import 'n_way_canvas.dart';
import 'picture_recorder.dart';
import 'raster_cache.dart';

/// A tree of [Layer]s that, together with a [Size] compose a frame.
class LayerTree {
  LayerTree(this.rootLayer);

  /// The root of the layer tree.
  final RootLayer rootLayer;

  /// The size (in physical pixels) of the frame to paint this layer tree into.
  final ui.Size frameSize = ui.window.physicalSize;

  /// The devicePixelRatio of the frame to paint this layer tree into.
  double? devicePixelRatio;

  /// Performs a preroll phase before painting the layer tree.
  ///
  /// In this phase, the paint boundary for each layer is computed and
  /// pictures are registered with the raster cache as potential candidates
  /// to raster. If [ignoreRasterCache] is `true`, then there will be no
  /// attempt to register pictures to cache.
  void preroll(Frame frame, {bool ignoreRasterCache = false}) {
    final PrerollContext context = PrerollContext(
      ignoreRasterCache ? null : frame.rasterCache,
      frame.viewEmbedder,
    );
    rootLayer.preroll(context, Matrix4.identity());
  }

  /// Paints the layer tree into the given [frame].
  ///
  /// If [ignoreRasterCache] is `true`, then the raster cache will
  /// not be used.
  void paint(Frame frame, {bool ignoreRasterCache = false}) {
    final CkNWayCanvas internalNodesCanvas = CkNWayCanvas();
    internalNodesCanvas.addCanvas(frame.canvas);
    final Iterable<CkCanvas> overlayCanvases =
        frame.viewEmbedder!.getOverlayCanvases();
    overlayCanvases.forEach(internalNodesCanvas.addCanvas);
    final PaintContext context = PaintContext(
      internalNodesCanvas,
      frame.canvas,
      ignoreRasterCache ? null : frame.rasterCache,
      frame.viewEmbedder,
    );
    if (rootLayer.needsPainting) {
      rootLayer.paint(context);
    }
  }

  /// Flattens the tree into a single [ui.Picture].
  ///
  /// This picture does not contain any platform views.
  ui.Picture flatten() {
    final CkPictureRecorder recorder = CkPictureRecorder();
    final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
    final PrerollContext prerollContext = PrerollContext(null, null);
    rootLayer.preroll(prerollContext, Matrix4.identity());

    final CkNWayCanvas internalNodesCanvas = CkNWayCanvas();
    internalNodesCanvas.addCanvas(canvas);
    final PaintContext paintContext =
        PaintContext(internalNodesCanvas, canvas, null, null);
    if (rootLayer.needsPainting) {
      rootLayer.paint(paintContext);
    }
    return recorder.endRecording();
  }
}

/// A single frame to be rendered.
class Frame {
  Frame(this.canvas, this.rasterCache, this.viewEmbedder);

  /// The canvas to render this frame to.
  final CkCanvas canvas;

  /// A cache of pre-rastered pictures.
  final RasterCache? rasterCache;

  /// The platform view embedder.
  final HtmlViewEmbedder? viewEmbedder;

  /// Rasterize the given layer tree into this frame.
  bool raster(LayerTree layerTree, {bool ignoreRasterCache = false}) {
    timeAction<void>(kProfilePrerollFrame, () {
      layerTree.preroll(this, ignoreRasterCache: ignoreRasterCache);
    });
    timeAction<void>(kProfileApplyFrame, () {
      layerTree.paint(this, ignoreRasterCache: ignoreRasterCache);
    });
    return true;
  }
}

/// The state of the compositor, which is persisted between frames.
class CompositorContext {
  /// A cache of pictures, which is shared between successive frames.
  RasterCache? rasterCache;

  /// Acquire a frame using this compositor's settings.
  Frame acquireFrame(CkCanvas canvas, HtmlViewEmbedder? viewEmbedder) {
    return Frame(canvas, rasterCache, viewEmbedder);
  }
}
