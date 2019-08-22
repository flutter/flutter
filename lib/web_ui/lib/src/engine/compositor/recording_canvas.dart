// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class SkRecordingCanvas implements RecordingCanvas {
  final js.JsObject skCanvas;
  SkRecordingCanvas(this.skCanvas);

  @override
  bool _didDraw = true;

  @override
  bool _hasArbitraryPaint = true;

  @override
  int saveCount = 0;

  @override
  // TODO: implement _commands
  List<PaintCommand> get _commands => null;

  @override
  // TODO: implement _paintBounds
  _PaintBounds get _paintBounds => null;

  @override
  void apply(EngineCanvas engineCanvas) {
    throw 'apply';
  }

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    final SkPath skPath = path;
    final js.JsObject intersectClipOp = canvasKit['ClipOp']['Intersect'];
    skCanvas.callMethod('clipPath', <dynamic>[
      skPath._skPath,
      intersectClipOp,
      doAntiAlias,
    ]);
  }

  @override
  void clipRRect(
    ui.RRect rrect, {
    bool doAntiAlias = true,
  }) {
    // TODO(het): Use `clipRRect` when CanvasKit makes it available.
    // CanvasKit doesn't expose `Canvas.clipRRect`, so we create a path, add the
    // RRect to it, and call clipPath with it.
    final SkPath rrectPath = SkPath();
    rrectPath.addRRect(rrect);
    clipPath(rrectPath, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(
    ui.Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    js.JsObject skClipOp;
    switch (clipOp) {
      case ui.ClipOp.difference:
        skClipOp = canvasKit['ClipOp']['Difference'];
        break;
      case ui.ClipOp.intersect:
        skClipOp = canvasKit['ClipOp']['Intersect'];
        break;
    }

    skCanvas.callMethod(
        'clipRect', <dynamic>[makeSkRect(rect), skClipOp, doAntiAlias]);
  }

  @override
  ui.Rect computePaintBounds() {
    throw 'computePaintBounds';
  }

  @override
  void debugDumpCommands() {
    throw 'debugDumpCommands';
  }

  @override
  void debugEnforceArbitraryPaint() {
    throw 'debugEnforceArbitraryPaint';
  }

  @override
  String debugPrintCommands() {
    throw 'debugPrintCommands';
  }

  @override
  bool get didDraw => true;

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    final js.JsObject skPaint = makeSkPaint(paint);
    // TODO(het): Use `drawCircle` when CanvasKit makes it available.
    // Since CanvasKit does not expose `drawCircle`, use `drawOval` instead.
    final js.JsObject skRect = makeSkRect(ui.Rect.fromLTWH(
        c.dx - radius, c.dy - radius, 2.0 * radius, 2.0 * radius));
    skCanvas.callMethod('drawOval', <js.JsObject>[skRect, skPaint]);
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    throw 'drawColor';
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    throw 'drawDRRect';
  }

  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {
    throw 'drawImage';
  }

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    final SkImage skImage = image;
    skCanvas.callMethod('drawImageRect', <dynamic>[
      skImage.skImage,
      makeSkRect(src),
      makeSkRect(dst),
      makeSkPaint(paint),
      false,
    ]);
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    skCanvas.callMethod('drawLine', <dynamic>[
      p1.dx,
      p1.dy,
      p2.dx,
      p2.dy,
      makeSkPaint(paint),
    ]);
  }

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {
    throw 'drawOval';
  }

  @override
  void drawPaint(ui.Paint paint) {
    throw 'drawPaint';
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    // TODO(het): This doesn't support most paragraph features. We are just
    // creating a font from the family and size, and drawing it with
    // ShapedText.
    final EngineParagraph engineParagraph = paragraph;
    final ParagraphGeometricStyle style = engineParagraph.geometricStyle;
    final js.JsObject skFont =
        skiaFontCollection.getFont(style.effectiveFontFamily, style.fontSize);
    final js.JsObject skShapedTextOpts = js.JsObject.jsify(<String, dynamic>{
      'font': skFont,
      'leftToRight': true,
      'text': engineParagraph.plainText,
      'width': engineParagraph.width + 1,
    });
    final js.JsObject skShapedText =
        js.JsObject(canvasKit['ShapedText'], <js.JsObject>[skShapedTextOpts]);
    skCanvas.callMethod('drawText', <dynamic>[
      skShapedText,
      offset.dx + engineParagraph._alignOffset,
      offset.dy,
      makeSkPaint(engineParagraph._paint)
    ]);
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    final js.JsObject skPaint = makeSkPaint(paint);
    final SkPath enginePath = path;
    final js.JsObject skPath = enginePath._skPath;
    skCanvas.callMethod('drawPath', <js.JsObject>[skPath, skPaint]);
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    // Since CanvasKit does not expose `drawRRect` we have to make do with
    // `drawRoundRect`. The downside of `drawRoundRect` is that all of the
    // corner radii must be the same.
    assert(
      rrect.tlRadius == rrect.trRadius &&
          rrect.tlRadius == rrect.brRadius &&
          rrect.tlRadius == rrect.blRadius,
      'CanvasKit only supports drawing RRects where the radii are all the same.',
    );
    skCanvas.callMethod('drawRoundRect', <dynamic>[
      makeSkRect(rrect.outerRect),
      rrect.tlRadiusX,
      rrect.tlRadiusY,
      makeSkPaint(paint),
    ]);
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    final js.JsObject skRect = makeSkRect(rect);
    final js.JsObject skPaint = makeSkPaint(paint);
    skCanvas.callMethod('drawRect', <js.JsObject>[skRect, skPaint]);
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    drawSkShadow(skCanvas, path, color, elevation, transparentOccluder);
  }

  @override
  bool get hasArbitraryPaint => true;

  @override
  void restore() {
    skCanvas.callMethod('restore');
    saveCount--;
  }

  @override
  void rotate(double radians) {
    skCanvas
        .callMethod('rotate', <double>[radians * 180.0 / math.pi, 0.0, 0.0]);
  }

  @override
  void save() {
    skCanvas.callMethod('save');
    saveCount++;
  }

  @override
  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    skCanvas.callMethod('saveLayer', <js.JsObject>[
      makeSkRect(bounds),
      makeSkPaint(paint),
    ]);
    saveCount++;
  }

  @override
  void saveLayerWithoutBounds(ui.Paint paint) {
    throw 'saveLayerWithoutBounds';
  }

  @override
  void scale(double sx, double sy) {
    skCanvas.callMethod('scale', <double>[sx, sy]);
  }

  @override
  void skew(double sx, double sy) {
    throw 'skew';
  }

  @override
  void transform(Float64List matrix4) {
    skCanvas.callMethod('concat', <js.JsArray<double>>[makeSkMatrix(matrix4)]);
  }

  @override
  void translate(double dx, double dy) {
    skCanvas.callMethod('translate', <double>[dx, dy]);
  }
}
