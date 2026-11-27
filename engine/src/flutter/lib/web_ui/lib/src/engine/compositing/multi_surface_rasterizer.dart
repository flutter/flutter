// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [Rasterizer] which uses one or many on-screen WebGL contexts to display
/// the scene. This way of rendering is prone to bugs because there is a limit
/// to how many WebGL contexts can be live at one time as well as bugs in
/// sharing GL resources between the contexts. However, using
/// [createImageBitmap] is currently very slow on Firefox and Safari browsers,
/// so directly rendering to several [Surface]s is how we can achieve 60 fps on
/// these browsers.
class MultiSurfaceRasterizer extends SurfaceRasterizer<MultiSurfaceViewRasterizer> {
  MultiSurfaceRasterizer(OnscreenSurface Function(OnscreenCanvasProvider) onscreenSurfaceCreateFn)
    : surfaceProvider = OnscreenSurfaceProvider(OnscreenCanvasProvider(), onscreenSurfaceCreateFn);

  @override
  final OnscreenSurfaceProvider surfaceProvider;

  @override
  MultiSurfaceViewRasterizer buildViewRasterizer(EngineFlutterView view) =>
      MultiSurfaceViewRasterizer(view, surfaceProvider);
}

/// A [ViewRasterizer] for a single [EngineFlutterView] managed by a
/// [MultiSurfaceRasterizer], rendering directly onto one or more onscreen
/// [Surface]s.
class MultiSurfaceViewRasterizer extends ViewRasterizer {
  MultiSurfaceViewRasterizer(super.view, this.surfaceProvider);

  /// The [OnscreenSurfaceProvider] used to allocate display surfaces for [view].
  final OnscreenSurfaceProvider surfaceProvider;

  @override
  late final DisplayCanvasFactory<OnscreenSurface> displayFactory =
      DisplayCanvasFactory<OnscreenSurface>(createCanvas: surfaceProvider.createSurface);

  // Nothing to prepare. Each display surface is resized in `rasterizeToCanvas`.
  @override
  Future<void> prepareToDraw() => Future<void>.value();

  /// Rasterizes the given [picture] directly to the given [canvas].
  Future<void> rasterizeToCanvas(OnscreenSurface canvas, ui.Picture picture) async {
    if (isDisposed || canvas.isDisposed) {
      return;
    }
    await canvas.setSize(currentFrameSize);
    if (isDisposed || canvas.isDisposed) {
      return;
    }
    return canvas.rasterizeToCanvas(picture);
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
    final rasterizeFutures = <Future<void>>[];
    for (var i = 0; i < displayCanvases.length; i++) {
      rasterizeFutures.add(rasterizeToCanvas(displayCanvases[i] as OnscreenSurface, pictures[i]));
    }
    await Future.wait<void>(rasterizeFutures);
    recorder?.recordRasterFinish();
  }
}
