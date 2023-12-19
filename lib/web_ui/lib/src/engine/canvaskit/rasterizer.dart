// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A class that can rasterize [LayerTree]s into a given `sceneHost` element.
class Rasterizer {
  Rasterizer(this.view);

  final EngineFlutterView view;
  DomElement get sceneHost => view.dom.sceneHost;
  final CompositorContext context = CompositorContext();
  final RenderCanvasFactory renderCanvasFactory = RenderCanvasFactory();
  late final HtmlViewEmbedder viewEmbedder =
      HtmlViewEmbedder(sceneHost, this, renderCanvasFactory);

  ui.Size _currentFrameSize = ui.Size.zero;

  /// Render the given [pictures] so it is displayed by the given [canvas].
  Future<void> rasterizeToCanvas(
      RenderCanvas canvas, List<CkPicture> pictures) async {
    await CanvasKitRenderer.instance.offscreenSurface.rasterizeToCanvas(
      _currentFrameSize,
      canvas,
      pictures,
    );
  }

  /// Creates a new frame from this rasterizer's surface, draws the given
  /// [LayerTree] into it, and then submits the frame.
  Future<void> draw(LayerTree layerTree) async {
    final ui.Size frameSize = view.physicalSize;
    if (frameSize.isEmpty) {
      // Available drawing area is empty. Skip drawing.
      return;
    }

    _currentFrameSize = frameSize;
    CanvasKitRenderer.instance.offscreenSurface.acquireFrame(_currentFrameSize);
    viewEmbedder.frameSize = _currentFrameSize;
    final CkPictureRecorder pictureRecorder = CkPictureRecorder();
    pictureRecorder.beginRecording(ui.Offset.zero & _currentFrameSize);
    pictureRecorder.recordingCanvas!.clear(const ui.Color(0x00000000));
    final Frame compositorFrame =
        context.acquireFrame(pictureRecorder.recordingCanvas!, viewEmbedder);

    compositorFrame.raster(layerTree, ignoreRasterCache: true);

    sceneHost.prepend(renderCanvasFactory.baseCanvas.htmlElement);
    await rasterizeToCanvas(renderCanvasFactory.baseCanvas,
        <CkPicture>[pictureRecorder.endRecording()]);

    await viewEmbedder.submitFrame();
  }

  /// Disposes of this rasterizer.
  void dispose() {
    viewEmbedder.dispose();
    renderCanvasFactory.dispose();
  }
}
