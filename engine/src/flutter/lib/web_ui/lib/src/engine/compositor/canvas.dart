// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// A Dart wrapper around Skia's [SkCanvas].
///
/// This is intentionally not memory-managing the underlying [SkCanvas]. See
/// the docs on [SkCanvas], which explain the reason.
class CkCanvas {
  final SkCanvas skCanvas;

  CkCanvas(this.skCanvas);

  int? get saveCount => skCanvas.getSaveCount();

  void clear(ui.Color color) {
    skCanvas.clear(toSharedSkColor1(color));
  }

  static final SkClipOp _clipOpIntersect = canvasKit.ClipOp.Intersect;

  void clipPath(ui.Path path, bool doAntiAlias) {
    final CkPath ckPath = path as CkPath;
    skCanvas.clipPath(
      ckPath._skPath,
      _clipOpIntersect,
      doAntiAlias,
    );
  }

  void clipRRect(ui.RRect rrect, bool doAntiAlias) {
    skCanvas.clipRRect(
      toSkRRect(rrect),
      _clipOpIntersect,
      doAntiAlias,
    );
  }

  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    skCanvas.clipRect(
      toSkRect(rect),
      toSkClipOp(clipOp),
      doAntiAlias,
    );
  }

  void drawArc(
    ui.Rect oval,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    CkPaint paint,
  ) {
    const double toDegrees = 180 / math.pi;
    skCanvas.drawArc(
      toSkRect(oval),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      useCenter,
      paint.skiaObject,
    );
  }

  void drawAtlasRaw(
    CkPaint paint,
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    List<Float32List>? colors,
    ui.BlendMode blendMode,
  ) {
    final CkImage skAtlas = atlas as CkImage;
    skCanvas.drawAtlas(
      skAtlas.skImage,
      rects,
      rstTransforms,
      paint.skiaObject,
      toSkBlendMode(blendMode),
      colors,
    );
  }

  void drawCircle(ui.Offset c, double radius, CkPaint paint) {
    skCanvas.drawCircle(
      c.dx,
      c.dy,
      radius,
      paint.skiaObject,
    );
  }

  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    skCanvas.drawColorInt(
      color.value,
      toSkBlendMode(blendMode),
    );
  }

  void drawDRRect(ui.RRect outer, ui.RRect inner, CkPaint paint) {
    skCanvas.drawDRRect(
      toSkRRect(outer),
      toSkRRect(inner),
      paint.skiaObject,
    );
  }

  void drawImage(ui.Image image, ui.Offset offset, CkPaint paint) {
    final CkImage skImage = image as CkImage;
    skCanvas.drawImage(
      skImage.skImage,
      offset.dx,
      offset.dy,
      paint.skiaObject,
    );
  }

  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, CkPaint paint) {
    final CkImage skImage = image as CkImage;
    skCanvas.drawImageRect(
      skImage.skImage,
      toSkRect(src),
      toSkRect(dst),
      paint.skiaObject,
      false,
    );
  }

  void drawImageNine(
      ui.Image image, ui.Rect center, ui.Rect dst, CkPaint paint) {
    final CkImage skImage = image as CkImage;
    skCanvas.drawImageNine(
      skImage.skImage,
      toSkRect(center),
      toSkRect(dst),
      paint.skiaObject,
    );
  }

  void drawLine(ui.Offset p1, ui.Offset p2, CkPaint paint) {
    skCanvas.drawLine(
      p1.dx,
      p1.dy,
      p2.dx,
      p2.dy,
      paint.skiaObject,
    );
  }

  void drawOval(ui.Rect rect, CkPaint paint) {
    skCanvas.drawOval(
      toSkRect(rect),
      paint.skiaObject,
    );
  }

  void drawPaint(CkPaint paint) {
    skCanvas.drawPaint(paint.skiaObject);
  }

  void drawParagraph(CkParagraph paragraph, ui.Offset offset) {
    skCanvas.drawParagraph(
      paragraph.skiaObject,
      offset.dx,
      offset.dy,
    );
  }

  void drawPath(CkPath path, CkPaint paint) {
    skCanvas.drawPath(path._skPath, paint.skiaObject);
  }

  void drawPicture(CkPicture picture) {
    skCanvas.drawPicture(picture.skiaObject.skiaObject);
  }

  void drawPoints(CkPaint paint, ui.PointMode pointMode,
      Float32List points) {
    skCanvas.drawPoints(
      toSkPointMode(pointMode),
      points,
      paint.skiaObject,
    );
  }

  void drawRRect(ui.RRect rrect, CkPaint paint) {
    skCanvas.drawRRect(
      toSkRRect(rrect),
      paint.skiaObject,
    );
  }

  void drawRect(ui.Rect rect, CkPaint paint) {
    skCanvas.drawRect(toSkRect(rect), paint.skiaObject);
  }

  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    drawSkShadow(skCanvas, path as CkPath, color, elevation,
        transparentOccluder, ui.window.devicePixelRatio);
  }

  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, CkPaint paint) {
    CkVertices skVertices = vertices as CkVertices;
    skCanvas.drawVertices(
      skVertices.skiaObject,
      toSkBlendMode(blendMode),
      paint.skiaObject,
    );
  }

  void restore() {
    skCanvas.restore();
  }

  void restoreToCount(int count) {
    skCanvas.restoreToCount(count);
  }

  void rotate(double radians) {
    skCanvas.rotate(radians * 180.0 / math.pi, 0.0, 0.0);
  }

  int save() {
    return skCanvas.save();
  }

  void saveLayer(ui.Rect bounds, CkPaint paint) {
    skCanvas.saveLayer(
      toSkRect(bounds),
      paint.skiaObject,
    );
  }

  void saveLayerWithoutBounds(CkPaint paint) {
    final SkCanvasSaveLayerWithoutBoundsOverload override = skCanvas as SkCanvasSaveLayerWithoutBoundsOverload;
    override.saveLayer(paint.skiaObject);
  }

  void saveLayerWithFilter(ui.Rect bounds, ui.ImageFilter filter) {
    final SkCanvasSaveLayerWithFilterOverload override = skCanvas as SkCanvasSaveLayerWithFilterOverload;
    final CkImageFilter skImageFilter = filter as CkImageFilter;
    return override.saveLayer(
      null,
      skImageFilter.skiaObject,
      0,
      toSkRect(bounds),
    );
  }

  void scale(double sx, double sy) {
    skCanvas.scale(sx, sy);
  }

  void skew(double sx, double sy) {
    skCanvas.skew(sx, sy);
  }

  void transform(Float32List matrix4) {
    skCanvas.concat(toSkMatrixFromFloat32(matrix4));
  }

  void translate(double dx, double dy) {
    skCanvas.translate(dx, dy);
  }

  void flush() {
    skCanvas.flush();
  }
}
