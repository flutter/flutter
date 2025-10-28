// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A tree of [Layer]s that, together with a [Size] compose a frame.
class LayerTree {
  LayerTree(this.rootLayer);

  /// The root of the layer tree.
  final RootLayer rootLayer;

  /// The devicePixelRatio of the frame to paint this layer tree into.
  double? devicePixelRatio;

  /// Performs a preroll phase before painting the layer tree.
  ///
  /// In this phase, the paint boundary for each layer is computed and
  /// pictures are registered with the raster cache as potential candidates
  /// to raster. If [ignoreRasterCache] is `true`, then there will be no
  /// attempt to register pictures to cache.
  void preroll(Frame frame) {
    final PrerollVisitor prerollVisitor = PrerollVisitor(frame.viewEmbedder);
    rootLayer.accept(prerollVisitor);
  }

  /// Performs a paint pass with a recording canvas for each picture in the
  /// tree. This paint pass is just used to measure the bounds for each picture
  /// so we can optimize the total number of canvases required.
  void measure(Frame frame, BitmapSize size) {
    final MeasureVisitor measureVisitor = MeasureVisitor(size, frame.viewEmbedder);
    if (rootLayer.needsPainting) {
      rootLayer.accept(measureVisitor);
    }
    measureVisitor.dispose();
  }

  /// Paints the layer tree into the given [frame].
  void paint(Frame frame) {
    final NWayCanvas internalNodesCanvas = NWayCanvas();
    final Iterable<LayerCanvas> overlayCanvases = frame.viewEmbedder!.getOptimizedCanvases();
    overlayCanvases.forEach(internalNodesCanvas.addCanvas);
    final PaintVisitor paintVisitor = PaintVisitor(internalNodesCanvas, frame.viewEmbedder!);
    if (rootLayer.needsPainting) {
      rootLayer.accept(paintVisitor);
    }
  }

  Map<String, dynamic> dumpDebugInfo() {
    final DebugInfoVisitor debugInfoVisitor = DebugInfoVisitor();
    return rootLayer.accept(debugInfoVisitor);
  }

  /// Flattens the tree into a single [ui.Picture].
  ///
  /// This picture does not contain any platform views.
  ui.Picture flatten(ui.Size size) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder, ui.Offset.zero & size);
    final PrerollVisitor prerollVisitor = PrerollVisitor(null);
    rootLayer.accept(prerollVisitor);

    final NWayCanvas internalNodesCanvas = NWayCanvas();
    internalNodesCanvas.addCanvas(canvas as LayerCanvas);
    final PaintVisitor paintVisitor = PaintVisitor.forToImage(internalNodesCanvas, canvas);
    if (rootLayer.needsPainting) {
      rootLayer.accept(paintVisitor);
    }
    return recorder.endRecording();
  }
}

/// A single frame to be rendered.
class Frame {
  Frame(this.viewEmbedder);

  /// The platform view embedder.
  final PlatformViewEmbedder? viewEmbedder;

  /// Rasterize the given layer tree into this frame.
  bool raster(LayerTree layerTree, BitmapSize size, FrameTimingRecorder? recorder) {
    timeAction<void>(kProfilePrerollFrame, () {
      layerTree.preroll(this);
      layerTree.measure(this, size);
      viewEmbedder?.optimizeComposition();
      recorder?.recordBuildFinish();
    });
    timeAction<void>(kProfileApplyFrame, () {
      layerTree.paint(this);
    });
    return true;
  }
}

/// The state of the compositor, which is persisted between frames.
class CompositorContext {
  /// Acquire a frame using this compositor's settings.
  Frame acquireFrame(PlatformViewEmbedder? viewEmbedder) {
    return Frame(viewEmbedder);
  }
}
