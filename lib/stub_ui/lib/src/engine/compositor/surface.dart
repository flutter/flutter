// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A frame which contains a canvas to be drawn into.
class SurfaceFrame {
  final void Function(SkCanvas) submitFn;
  final SkCanvas canvas;
  SurfaceFrame(this.submitFn, this.canvas);

  /// Submit this frame to be drawn.
  void submit() {
    submitFn(canvas);
  }
}

/// A surface which can be drawn into by the compositor.
///
/// The underlying representation is a [BitmapCanvas], which can be reused by
/// successive frames if they are the same size. Otherwise, a new canvas is
/// created.
class Surface {
  final _CanvasCache canvasCache = _CanvasCache();

  /// This function is called with the canvas once drawing on it has been
  /// completed for a frame.
  final void Function(SkCanvas) submitFunction;

  Surface(this.submitFunction);

  /// Acquire a frame of the given [size] containing a drawable canvas.
  SurfaceFrame acquireFrame(ui.Size size) {
    final SkCanvas canvas = canvasCache.acquireCanvas(size);
    return SurfaceFrame(submitFunction, canvas);
  }

  Matrix4 get rootTransformation => null;
}

class _CanvasCache {
  SkCanvas _canvas;

  SkCanvas acquireCanvas(ui.Size size) {
    assert(size != null);
    if (size == _canvas?.size) {
      return _canvas;
    }
    final html.CanvasElement htmlCanvas =
        html.CanvasElement(width: size.width.ceil(), height: size.height.ceil())
          ..id = 'flt-sk-canvas';
    domRenderer.renderScene(htmlCanvas);
    final js.JsObject surface =
        canvasKit.callMethod('MakeCanvasSurface', <String>['flt-sk-canvas']);
    final js.JsObject skCanvas = surface.callMethod('getCanvas');
    _canvas = SkCanvas(skCanvas, htmlCanvas, surface, size);
    return _canvas;
  }
}
