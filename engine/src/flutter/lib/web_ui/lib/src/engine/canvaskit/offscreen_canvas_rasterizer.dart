// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'surface.dart';

/// A [Rasterizer] that uses a single GL context in an OffscreenCanvas to do
/// all the rendering. It transfers bitmaps created in the OffscreenCanvas to
/// one or many on-screen <canvas> elements to actually display the scene.
class OffscreenCanvasRasterizer extends Rasterizer {
  /// This is an SkSurface backed by an OffScreenCanvas. This single Surface is
  /// used to render to many RenderCanvases to produce the rendered scene.
  final Surface offscreenSurface = Surface();

  @override
  OffscreenCanvasViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return _viewRasterizers.putIfAbsent(view, () => OffscreenCanvasViewRasterizer(view, this));
  }

  final Map<EngineFlutterView, OffscreenCanvasViewRasterizer> _viewRasterizers =
      <EngineFlutterView, OffscreenCanvasViewRasterizer>{};

  @override
  void setResourceCacheMaxBytes(int bytes) {
    offscreenSurface.setSkiaResourceCacheMaxBytes(bytes);
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

  /// Render the given [pictures] so it is displayed by the given [canvas].
  Future<void> rasterizeToCanvas(DisplayCanvas canvas, ui.Picture picture) async {
    await rasterizer.offscreenSurface.rasterizeToCanvas(
      currentFrameSize,
      canvas as RenderCanvas,
      picture,
    );
  }

  @override
  void prepareToDraw() {
    rasterizer.offscreenSurface.createOrUpdateSurface(currentFrameSize);
  }

  @override
  Future<void> rasterize(List<CompositionCanvas> compositionCanvases, List<ui.Picture> pictures) {
    if (compositionCanvases.length != pictures.length) {
      throw ArgumentError('Called rasterize() with a different number of canvases and pictures.');
    }
    final List<Future<void>> rasterizeFutures = <Future<void>>[];
    for (int i = 0; i < compositionCanvases.length; i++) {
      rasterizeFutures.add(rasterizeToCanvas(compositionCanvases[i].displayCanvas!, pictures[i]));
    }
    return Future.wait<void>(rasterizeFutures);
  }
}
