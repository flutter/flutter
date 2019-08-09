// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class SkRecordingCanvas implements RecordingCanvas {
  final js.JsObject skCanvas;
  SkRecordingCanvas(this.skCanvas);

  js.JsObject _makeSkRect(ui.Rect rect) {
    return js.JsObject(canvasKit['LTRBRect'],
        <double>[rect.left, rect.top, rect.right, rect.bottom]);
  }

  js.JsObject _makeSkPaint(ui.Paint paint) {
    final skPaint = js.JsObject(canvasKit['SkPaint']);

    skPaint.callMethod('setColor', <int>[paint.color.value]);

    js.JsObject skPaintStyle;
    switch (paint.style) {
      case ui.PaintingStyle.stroke:
        skPaintStyle = canvasKit['PaintStyle']['Stroke'];
        break;
      case ui.PaintingStyle.fill:
        skPaintStyle = canvasKit['PaintStyle']['Fill'];
        break;
    }
    skPaint.callMethod('setStyle', <js.JsObject>[skPaintStyle]);

    skPaint.callMethod('setAntiAlias', <bool>[paint.isAntiAlias]);
    return skPaint;
  }

  @override
  bool _didDraw = true;

  @override
  bool _hasArbitraryPaint = true;

  @override
  int saveCount;

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
  void clipPath(ui.Path path) {
    throw 'clipPath';
  }

  @override
  void clipRRect(ui.RRect rrect) {
    throw 'clipRRect';
  }

  @override
  void clipRect(ui.Rect rect) {
    throw 'clipRect';
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
    throw 'drawCircle';
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
    throw 'drawImageRect';
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    throw 'drawLine';
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
    throw 'drawParagraph';
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    throw 'drawPath';
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    throw 'drawRRect';
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    final js.JsObject skRect = _makeSkRect(rect);
    final js.JsObject skPaint = _makeSkPaint(paint);
    skCanvas.callMethod('drawRect', <js.JsObject>[skRect, skPaint]);
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    throw 'drawShadow';
  }

  @override
  bool get hasArbitraryPaint => true;

  @override
  void restore() {
    throw 'restore';
  }

  @override
  void rotate(double radians) {
    throw 'rotate';
  }

  @override
  void save() {
    throw 'save';
  }

  @override
  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    throw 'saveLayer';
  }

  @override
  void saveLayerWithoutBounds(ui.Paint paint) {
    throw 'saveLayerWithoutBounds';
  }

  @override
  void scale(double sx, double sy) {
    throw 'scale';
  }

  @override
  void skew(double sx, double sy) {
    throw 'skew';
  }

  @override
  void transform(Float64List matrix4) {
    throw 'transform';
  }

  @override
  void translate(double dx, double dy) {
    throw 'translate';
  }
}
