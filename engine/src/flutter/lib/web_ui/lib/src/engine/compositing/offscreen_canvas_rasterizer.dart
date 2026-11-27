// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [Rasterizer] that uses a single GL context in an OffscreenCanvas to do
/// all the rendering. It transfers bitmaps created in the OffscreenCanvas to
/// one or many on-screen <canvas> elements to actually display the scene.
class OffscreenCanvasRasterizer extends SurfaceRasterizer<OffscreenCanvasViewRasterizer> {
  OffscreenCanvasRasterizer(
    OffscreenSurface Function(OffscreenCanvasProvider) offscreenSurfaceCreateFn,
  ) : surfaceProvider = OffscreenSurfaceProvider(
        OffscreenCanvasProvider(),
        offscreenSurfaceCreateFn,
      );

  @override
  final OffscreenSurfaceProvider surfaceProvider;

  /// This is an SkSurface backed by an OffScreenCanvas. This single Surface is
  /// used to render to many RenderCanvases to produce the rendered scene.
  late final OffscreenSurface offscreenSurface = surfaceProvider.createSurface();

  @override
  OffscreenCanvasViewRasterizer buildViewRasterizer(EngineFlutterView view) =>
      OffscreenCanvasViewRasterizer(view, this);
}

class OffscreenCanvasViewRasterizer extends ViewRasterizer {
  OffscreenCanvasViewRasterizer(super.view, this.rasterizer);

  final OffscreenCanvasRasterizer rasterizer;

  @override
  final DisplayCanvasFactory<RenderCanvas> displayFactory = DisplayCanvasFactory<RenderCanvas>(
    createCanvas: () => RenderCanvas(),
  );

  // Nothing to prepare. The shared offscreen surface is resized as part of
  // each `rasterize` call. Resizing it here, as a separate step, would let
  // another view resize it again before this view renders.
  @override
  Future<void> prepareToDraw() => Future<void>.value();

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    if (displayCanvases.length != pictures.length) {
      throw ArgumentError('Called rasterize() with a different number of canvases and pictures.');
    }
    if (browserSupportsCreateImageBitmap) {
      final List<DomImageBitmap> bitmaps = await rasterizer.offscreenSurface
          .rasterizeToImageBitmaps(currentFrameSize, pictures);
      for (var i = 0; i < bitmaps.length; i++) {
        (displayCanvases[i] as RenderCanvas).render(bitmaps[i]);
      }
    } else {
      await rasterizer.offscreenSurface.rasterizeToCanvasSource(currentFrameSize, pictures, (
        int index,
        DomCanvasImageSource source,
      ) {
        (displayCanvases[index] as RenderCanvas).renderWithNoBitmapSupport(
          source,
          currentFrameSize.height,
          currentFrameSize,
        );
      });
    }
    recorder?.recordRasterFinish();
  }
}
