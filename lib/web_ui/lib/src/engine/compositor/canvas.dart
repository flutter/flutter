// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// A Dart wrapper around Skia's SKCanvas.
class SkCanvas {
  final js.JsObject skCanvas;

  SkCanvas(this.skCanvas);

  int? get saveCount => skCanvas.callMethod('getSaveCount');

  void clear(ui.Color color) {
    setSharedSkColor1(color);
    skCanvas.callMethod('clear', <js.JsObject?>[sharedSkColor1]);
  }

  void clipPath(ui.Path path, bool doAntiAlias) {
    final SkPath skPath = path as SkPath;
    final js.JsObject? intersectClipOp = canvasKit['ClipOp']['Intersect'];
    skCanvas.callMethod('clipPath', <dynamic>[
      skPath._skPath,
      intersectClipOp,
      doAntiAlias,
    ]);
  }

  void clipRRect(ui.RRect rrect, bool doAntiAlias) {
    final js.JsObject? intersectClipOp = canvasKit['ClipOp']['Intersect'];
    skCanvas.callMethod('clipRRect', <dynamic>[
      makeSkRRect(rrect),
      intersectClipOp,
      doAntiAlias,
    ]);
  }

  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    js.JsObject? skClipOp;
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

  void drawArc(
    ui.Rect oval,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    SkPaint paint,
  ) {
    const double toDegrees = 180 / math.pi;
    skCanvas.callMethod('drawArc', <dynamic>[
      makeSkRect(oval),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      useCenter,
      paint.skiaObject,
    ]);
  }

  void drawAtlasRaw(
    SkPaint paint,
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    js.JsArray<Float32List>? colors,
    ui.BlendMode blendMode,
  ) {
    final SkImage skAtlas = atlas as SkImage;
    skCanvas.callMethod('drawAtlas', <dynamic>[
      skAtlas.skImage,
      rects,
      rstTransforms,
      paint.skiaObject,
      makeSkBlendMode(blendMode),
      colors,
    ]);
  }

  void drawCircle(ui.Offset c, double radius, SkPaint paint) {
    skCanvas.callMethod('drawCircle', <dynamic>[
      c.dx,
      c.dy,
      radius,
      paint.skiaObject,
    ]);
  }

  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    skCanvas.callMethod('drawColorInt', <dynamic>[
      color.value,
      makeSkBlendMode(blendMode),
    ]);
  }

  void drawDRRect(ui.RRect outer, ui.RRect inner, SkPaint paint) {
    skCanvas.callMethod('drawDRRect', <js.JsObject?>[
      makeSkRRect(outer),
      makeSkRRect(inner),
      paint.skiaObject,
    ]);
  }

  void drawImage(ui.Image image, ui.Offset offset, SkPaint paint) {
    final SkImage skImage = image as SkImage;
    skCanvas.callMethod('drawImage', <dynamic>[
      skImage.skImage,
      offset.dx,
      offset.dy,
      paint.skiaObject,
    ]);
  }

  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, SkPaint paint) {
    final SkImage skImage = image as SkImage;
    skCanvas.callMethod('drawImageRect', <dynamic>[
      skImage.skImage,
      makeSkRect(src),
      makeSkRect(dst),
      paint.skiaObject,
      false,
    ]);
  }

  void drawImageNine(
      ui.Image image, ui.Rect center, ui.Rect dst, SkPaint paint) {
    final SkImage skImage = image as SkImage;
    skCanvas.callMethod('drawImageNine', <dynamic>[
      skImage.skImage,
      makeSkRect(center),
      makeSkRect(dst),
      paint.skiaObject,
    ]);
  }

  void drawLine(ui.Offset p1, ui.Offset p2, SkPaint paint) {
    skCanvas.callMethod('drawLine', <dynamic>[
      p1.dx,
      p1.dy,
      p2.dx,
      p2.dy,
      paint.skiaObject,
    ]);
  }

  void drawOval(ui.Rect rect, SkPaint paint) {
    skCanvas.callMethod('drawOval', <js.JsObject?>[
      makeSkRect(rect),
      paint.skiaObject,
    ]);
  }

  void drawPaint(SkPaint paint) {
    skCanvas.callMethod('drawPaint', <js.JsObject?>[paint.skiaObject]);
  }

  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    final SkParagraph skParagraph = paragraph as SkParagraph;
    skCanvas.callMethod('drawParagraph', <dynamic>[
      skParagraph.skiaObject,
      offset.dx,
      offset.dy,
    ]);
  }

  void drawPath(ui.Path path, SkPaint paint) {
    final js.JsObject? skPaint = paint.skiaObject;
    final SkPath enginePath = path as SkPath;
    final js.JsObject? skPath = enginePath._skPath;
    skCanvas.callMethod('drawPath', <js.JsObject?>[skPath, skPaint]);
  }

  void drawPicture(ui.Picture picture) {
    final SkPicture skPicture = picture as SkPicture;
    skCanvas.callMethod(
        'drawPicture', <js.JsObject?>[skPicture.skPicture.skiaObject]);
  }

  // TODO(hterkelsen): https://github.com/flutter/flutter/issues/58824
  void drawPoints(SkPaint paint, ui.PointMode pointMode,
      js.JsArray<js.JsArray<double>>? points) {
    skCanvas.callMethod('drawPoints', <dynamic>[
      makeSkPointMode(pointMode),
      points,
      paint.skiaObject,
    ]);
  }

  void drawRRect(ui.RRect rrect, SkPaint paint) {
    skCanvas.callMethod('drawRRect', <js.JsObject?>[
      makeSkRRect(rrect),
      paint.skiaObject,
    ]);
  }

  void drawRect(ui.Rect rect, SkPaint paint) {
    final js.JsObject skRect = makeSkRect(rect);
    final js.JsObject? skPaint = paint.skiaObject;
    skCanvas.callMethod('drawRect', <js.JsObject?>[skRect, skPaint]);
  }

  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    drawSkShadow(skCanvas, path as SkPath, color, elevation,
        transparentOccluder, ui.window.devicePixelRatio);
  }

  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, SkPaint paint) {
    SkVertices skVertices = vertices as SkVertices;
    skCanvas.callMethod('drawVertices', <js.JsObject?>[
      skVertices.skVertices,
      makeSkBlendMode(blendMode),
      paint.skiaObject
    ]);
  }

  void restore() {
    skCanvas.callMethod('restore');
  }

  void restoreToCount(int? count) {
    skCanvas.callMethod('restoreToCount', <int?>[count]);
  }

  void rotate(double radians) {
    skCanvas
        .callMethod('rotate', <double>[radians * 180.0 / math.pi, 0.0, 0.0]);
  }

  int? save() {
    return skCanvas.callMethod('save');
  }

  void saveLayer(ui.Rect bounds, SkPaint paint) {
    skCanvas.callMethod('saveLayer', <js.JsObject?>[
      makeSkRect(bounds),
      paint.skiaObject,
    ]);
  }

  void saveLayerWithoutBounds(SkPaint paint) {
    skCanvas.callMethod('saveLayer', <js.JsObject?>[paint.skiaObject]);
  }

  void saveLayerWithFilter(ui.Rect bounds, ui.ImageFilter filter) {
    final SkImageFilter skImageFilter = filter as SkImageFilter;
    return skCanvas.callMethod(
      'saveLayer',
      <dynamic>[
        null,
        skImageFilter.skiaObject,
        0,
        makeSkRect(bounds),
      ],
    );
  }

  void scale(double sx, double sy) {
    skCanvas.callMethod('scale', <double>[sx, sy]);
  }

  void skew(double sx, double sy) {
    skCanvas.callMethod('skew', <double>[sx, sy]);
  }

  void transform(Float32List? matrix4) {
    skCanvas.callMethod(
        'concat', <js.JsArray<double>>[makeSkMatrixFromFloat32(matrix4)]);
  }

  void translate(double dx, double dy) {
    skCanvas.callMethod('translate', <double>[dx, dy]);
  }

  void flush() {
    skCanvas.callMethod('flush');
  }
}
