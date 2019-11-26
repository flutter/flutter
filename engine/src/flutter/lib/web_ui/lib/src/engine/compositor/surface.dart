// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

typedef SubmitCallback = bool Function(SurfaceFrame, SkCanvas);

/// A frame which contains a canvas to be drawn into.
class SurfaceFrame {
  final SkSurface skiaSurface;
  final SubmitCallback submitCallback;
  bool _submitted;

  SurfaceFrame(this.skiaSurface, this.submitCallback)
      : _submitted = false,
        assert(submitCallback != null);

  /// Submit this frame to be drawn.
  bool submit() {
    if (_submitted) {
      return false;
    }
    return submitCallback(this, skiaCanvas);
  }

  SkCanvas get skiaCanvas => skiaSurface?.getCanvas();
}

/// A surface which can be drawn into by the compositor.
///
/// The underlying representation is a [SkSurface], which can be reused by
/// successive frames if they are the same size. Otherwise, a new [SkSurface] is
/// created.
class Surface {
  SkSurface _surface;

  /// Acquire a frame of the given [size] containing a drawable canvas.
  ///
  /// The given [size] is in physical pixels.
  SurfaceFrame acquireFrame(ui.Size size) {
    final SkSurface surface = _acquireRenderSurface(size);

    if (surface == null) return null;

    SubmitCallback submitCallback = (SurfaceFrame surfaceFrame, SkCanvas canvas) {
      _presentSurface(canvas);
    };

    return SurfaceFrame(surface, submitCallback);
  }

  SkSurface _acquireRenderSurface(ui.Size size) {
    if (!_createOrUpdateSurfaces(size)) {
      return null;
    }
    return _surface;
  }

  bool _createOrUpdateSurfaces(ui.Size size) {
    if (_surface != null &&
        size ==
            ui.Size(
              _surface.width().toDouble(),
              _surface.height().toDouble(),
            )) {
      return true;
    }

    _surface?.dispose();
    _surface = null;

    if (size.isEmpty) {
      html.window.console.error('Cannot create surfaces of empty size.');
      return false;
    }
    _surface = _wrapHtmlCanvas(size);

    if (_surface == null) {
      html.window.console.error('Could not create a surface.');
      return false;
    }

    return true;
  }

  SkSurface _wrapHtmlCanvas(ui.Size size) {
    final ui.Size logicalSize = size / ui.window.devicePixelRatio;
    final html.CanvasElement htmlCanvas =
        html.CanvasElement(width: size.width.ceil(), height: size.height.ceil())
          ..id = 'flt-sk-canvas';
    htmlCanvas.style
      ..position = 'absolute'
      ..width = '${logicalSize.width.ceil()}px'
      ..height = '${logicalSize.height.ceil()}px';
    final js.JsObject skSurface =
        canvasKit.callMethod('MakeWebGLCanvasSurface', <dynamic>[
      htmlCanvas,
      size.width,
      size.height,
    ]);

    if (skSurface == null) {
      return null;
    } else {
      domRenderer.renderScene(htmlCanvas);
      return SkSurface(skSurface);
    }
  }

  bool _presentSurface(SkCanvas canvas) {
    if (canvas == null) {
      return false;
    }

    _surface.getCanvas().flush();
    return true;
  }
}

/// A Dart wrapper around Skia's SkSurface.
class SkSurface {
  final js.JsObject _surface;

  SkSurface(this._surface);

  SkCanvas getCanvas() {
    final js.JsObject skCanvas = _surface.callMethod('getCanvas');
    return SkCanvas(skCanvas);
  }

  int width() => _surface.callMethod('width');
  int height() => _surface.callMethod('height');

  void dispose() {
    _surface.callMethod('dispose');
  }
}
