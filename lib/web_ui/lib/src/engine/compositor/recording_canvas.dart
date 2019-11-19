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
  int get saveCount => skCanvas.callMethod('getSaveCount');

  // This is required to implement RecordingCanvas.
  @override
  int _saveCount = -1;

  @override
  // TODO: implement _commands
  List<PaintCommand> get _commands => null;

  @override
  // TODO: implement _paintBounds
  _PaintBounds get _paintBounds => null;

  @override
  void apply(EngineCanvas engineCanvas) {
    throw UnimplementedError("The Skia backend doesn't support apply()");
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
    throw UnimplementedError(
        "The Skia backend doesn't use computePaintBounds()");
  }

  @override
  void debugDumpCommands() {
    throw UnimplementedError(
        "The Skia backend doesn't use debugDumpCommands()");
  }

  @override
  void debugEnforceArbitraryPaint() {
    throw UnimplementedError(
        "The Skia backend doesn't use debugEnforceArbitraryPaint()");
  }

  @override
  String debugPrintCommands() {
    throw UnimplementedError(
        "The Skia backend doesn't use debugPrintCommands()");
  }

  @override
  bool get didDraw => true;

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    skCanvas.callMethod('drawCircle', <dynamic>[
      c.dx,
      c.dy,
      radius,
      makeSkPaint(paint),
    ]);
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    // TODO(het): Implement this once SkCanvas.drawColor becomes available.
    throw 'drawColor';
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    skCanvas.callMethod('drawDRRect', <js.JsObject>[
      makeSkRRect(outer),
      makeSkRRect(inner),
      makeSkPaint(paint),
    ]);
  }

  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {
    final SkImage skImage = image;
    skCanvas.callMethod('drawImage', <dynamic>[
      skImage.skImage,
      offset.dx,
      offset.dy,
      makeSkPaint(paint),
    ]);
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
    skCanvas.callMethod('drawOval', <js.JsObject>[
      makeSkRect(rect),
      makeSkPaint(paint),
    ]);
  }

  @override
  void drawPaint(ui.Paint paint) {
    skCanvas.callMethod('drawPaint', <js.JsObject>[makeSkPaint(paint)]);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    final SkParagraph skParagraph = paragraph;
    skCanvas.callMethod('drawParagraph', <dynamic>[
      skParagraph.skParagraph,
      offset.dx,
      offset.dy,
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
    skCanvas.callMethod('drawRRect', <js.JsObject>[
      makeSkRRect(rrect),
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
    drawSkShadow(skCanvas, path, color, elevation, transparentOccluder,
        ui.window.devicePixelRatio);
  }

  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    SkVertices skVertices = vertices;
    skCanvas.callMethod('drawVertices', <js.JsObject>[
      skVertices.skVertices,
      makeSkBlendMode(blendMode),
      makeSkPaint(paint)
    ]);
  }

  @override
  bool get hasArbitraryPaint => true;

  @override
  void restore() {
    skCanvas.callMethod('restore');
  }

  @override
  void rotate(double radians) {
    skCanvas
        .callMethod('rotate', <double>[radians * 180.0 / math.pi, 0.0, 0.0]);
  }

  @override
  void save() {
    skCanvas.callMethod('save');
  }

  @override
  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    skCanvas.callMethod('saveLayer', <js.JsObject>[
      makeSkRect(bounds),
      makeSkPaint(paint),
    ]);
  }

  @override
  void saveLayerWithoutBounds(ui.Paint paint) {
    skCanvas.callMethod('saveLayer', <js.JsObject>[null, makeSkPaint(paint)]);
  }

  @override
  void scale(double sx, double sy) {
    skCanvas.callMethod('scale', <double>[sx, sy]);
  }

  @override
  void skew(double sx, double sy) {
    skCanvas.callMethod('skew', <double>[sx, sy]);
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
