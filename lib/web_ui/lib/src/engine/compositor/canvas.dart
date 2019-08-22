// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// An actual [SkCanvas] which can receive raw drawing commands.
///
/// In order for the drawing commands to be flushed to the associated HTML
/// canvas, you must call `flush()` on the canvas's `SkSurface`.
///
/// Although this class is backed by an `SkCanvas` and can in theory perform
/// arbitrary drawing operations, this class is only used in the final
/// compositing by the layers, and arbitrary drawings are done in a
/// [ui.Picture] which uses a Skia recording canvas. This class receives
/// drawing calls from the various `Layer` classes, e.g. [ClipRectLayer] and
/// so only exposes a subset of the drawing operations that can be performed
/// on a canvas.
class SkCanvas {
  final js.JsObject skCanvas;
  final html.CanvasElement htmlCanvas;
  final js.JsObject skSurface;
  final ui.Size size;

  SkCanvas(this.skCanvas, this.htmlCanvas, this.skSurface, this.size);

  int save() {
    return skCanvas.callMethod('save');
  }

  int saveLayer(ui.Rect bounds, ui.Paint paint) {
    return skCanvas.callMethod(
        'saveLayer', <js.JsObject>[makeSkRect(bounds), makeSkPaint(paint)]);
  }

  void restore() {
    skCanvas.callMethod('restore');
  }

  void restoreToCount(int count) {
    skCanvas.callMethod('restoreToCount', <int>[count]);
  }

  void clear() {
    skCanvas.callMethod('clear', <int>[0xffffffff]);
  }

  void translate(double dx, double dy) {
    skCanvas.callMethod('translate', <double>[dx, dy]);
  }

  void transform(Float64List matrix) {
    skCanvas.callMethod('concat', <js.JsArray<double>>[makeSkMatrix(matrix)]);
  }

  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    final SkPath skPath = path;
    final js.JsObject intersectClipOp = canvasKit['ClipOp']['Intersect'];
    skCanvas.callMethod('clipPath', <dynamic>[
      skPath._skPath,
      intersectClipOp,
      doAntiAlias,
    ]);
  }

  void clipRect(ui.Rect rect, {bool doAntiAlias = true}) {
    final js.JsObject intersectClipOp = canvasKit['ClipOp']['Intersect'];
    skCanvas.callMethod('clipRect', <dynamic>[
      makeSkRect(rect),
      intersectClipOp,
      doAntiAlias,
    ]);
  }

  void clipRRect(ui.RRect rrect) {
    final SkPath skPath = SkPath();
    skPath.addRRect(rrect);
    clipPath(skPath);
  }

  void drawPicture(ui.Picture picture) {
    final SkPicture skPicture = picture;
    skCanvas.callMethod('drawPicture', <js.JsObject>[skPicture.skPicture]);
  }

  void drawPath(ui.Path path, ui.Paint paint) {
    final SkPath skPath = path;
    skCanvas.callMethod(
        'drawPath', <js.JsObject>[skPath._skPath, makeSkPaint(paint)]);
  }

  void drawPaint(ui.Paint paint) {
    skCanvas.callMethod('drawPaint', <js.JsObject>[makeSkPaint(paint)]);
  }

  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    drawSkShadow(skCanvas, path, color, elevation, transparentOccluder);
  }

  Matrix4 get currentTransform => throw 'currentTransform';
}
