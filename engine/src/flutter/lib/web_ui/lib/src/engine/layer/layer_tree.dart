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
  void preroll([Frame? frame]) {
    final prerollVisitor = PrerollVisitor();
    rootLayer.accept(prerollVisitor);
  }

  /// Performs a paint pass with a recording canvas for each picture in the
  /// tree.
  void measure([Frame? frame, BitmapSize? size]) {
    // No-op in single-surface HTML-in-Canvas compositing.
  }

  /// Paints the layer tree into the given [canvasOrFrame].
  void paint(dynamic canvasOrFrame, [CkOnscreenSurface? surface]) {
    if (canvasOrFrame is LayerCanvas) {
      final paintVisitor = PaintVisitor(canvasOrFrame, surface);
      if (rootLayer.needsPainting) {
        rootLayer.accept(paintVisitor);
      }
    }
  }

  Map<String, dynamic> dumpDebugInfo() {
    final debugInfoVisitor = DebugInfoVisitor();
    return rootLayer.accept(debugInfoVisitor);
  }

  /// Flattens the tree into a single [ui.Picture].
  ///
  /// This picture does not contain any platform views.
  ui.Picture flatten(ui.Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
    final prerollVisitor = PrerollVisitor();
    rootLayer.accept(prerollVisitor);

    final paintVisitor = PaintVisitor(canvas as LayerCanvas);
    if (rootLayer.needsPainting) {
      rootLayer.accept(paintVisitor);
    }
    return recorder.endRecording();
  }
}

/// A single frame to be rendered.
class Frame {
  Frame([Object? _]);

  /// Rasterize the given layer tree into this frame.
  bool raster(LayerTree layerTree, BitmapSize size, FrameTimingRecorder? recorder) {
    timeAction<void>(kProfilePrerollFrame, () {
      layerTree.preroll(this);
      recorder?.recordBuildFinish();
    });
    return true;
  }
}

/// The state of the compositor, which is persisted between frames.
class CompositorContext {
  /// Acquire a frame using this compositor's settings.
  Frame acquireFrame([Object? _]) {
    return Frame();
  }
}
