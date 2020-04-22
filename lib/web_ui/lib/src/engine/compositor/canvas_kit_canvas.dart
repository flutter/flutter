// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// An implementation of [ui.Canvas] that is backed by a CanvasKit canvas.
class CanvasKitCanvas implements ui.Canvas {
  final SkCanvas _canvas;

  factory CanvasKitCanvas(ui.PictureRecorder recorder, [ui.Rect cullRect]) {
    assert(recorder != null);
    if (recorder.isRecording) {
      throw ArgumentError(
          '"recorder" must not already be associated with another Canvas.');
    }
    cullRect ??= ui.Rect.largest;
    final SkPictureRecorder skRecorder = recorder;
    return CanvasKitCanvas._(skRecorder.beginRecording(cullRect));
  }

  CanvasKitCanvas._(this._canvas);

  @override
  void save() {
    _canvas.save();
  }

  @override
  void saveLayer(ui.Rect bounds, ui.Paint paint) {
    assert(paint != null);
    if (bounds == null) {
      _saveLayerWithoutBounds(paint);
    } else {
      assert(rectIsValid(bounds));
      _saveLayer(bounds, paint);
    }
  }

  void _saveLayerWithoutBounds(ui.Paint paint) {
    _canvas.saveLayerWithoutBounds(paint);
  }

  void _saveLayer(ui.Rect bounds, ui.Paint paint) {
    _canvas.saveLayer(bounds, paint);
  }

  @override
  void restore() {
    _canvas.restore();
  }

  @override
  int getSaveCount() {
    return _canvas.saveCount;
  }

  @override
  void translate(double dx, double dy) {
    _canvas.translate(dx, dy);
  }

  @override
  void scale(double sx, [double sy]) => _scale(sx, sy ?? sx);

  void _scale(double sx, double sy) {
    _canvas.scale(sx, sy);
  }

  @override
  void rotate(double radians) {
    _canvas.rotate(radians);
  }

  @override
  void skew(double sx, double sy) {
    _canvas.skew(sx, sy);
  }

  @override
  void transform(Float64List matrix4) {
    assert(matrix4 != null);
    if (matrix4.length != 16) {
      throw ArgumentError('"matrix4" must have 16 entries.');
    }
    _transform(toMatrix32(matrix4));
  }

  void _transform(Float32List matrix4) {
    _canvas.transform(matrix4);
  }

  @override
  void clipRect(ui.Rect rect,
      {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    assert(rectIsValid(rect));
    assert(clipOp != null);
    assert(doAntiAlias != null);
    _clipRect(rect, clipOp, doAntiAlias);
  }

  void _clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    _canvas.clipRect(rect, clipOp, doAntiAlias);
  }

  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) {
    assert(rrectIsValid(rrect));
    assert(doAntiAlias != null);
    _clipRRect(rrect, doAntiAlias);
  }

  void _clipRRect(ui.RRect rrect, bool doAntiAlias) {
    _canvas.clipRRect(rrect, doAntiAlias);
  }

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    assert(path != null); // path is checked on the engine side
    assert(doAntiAlias != null);
    _clipPath(path, doAntiAlias);
  }

  void _clipPath(ui.Path path, bool doAntiAlias) {
    _canvas.clipPath(path, doAntiAlias);
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    assert(color != null);
    assert(blendMode != null);
    _drawColor(color, blendMode);
  }

  void _drawColor(ui.Color color, ui.BlendMode blendMode) {
    _canvas.drawColor(color, blendMode);
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    assert(_offsetIsValid(p1));
    assert(_offsetIsValid(p2));
    assert(paint != null);
    _drawLine(p1, p2, paint);
  }

  void _drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    _canvas.drawLine(p1, p2, paint);
  }

  @override
  void drawPaint(ui.Paint paint) {
    assert(paint != null);
    _drawPaint(paint);
  }

  void _drawPaint(ui.Paint paint) {
    _canvas.drawPaint(paint);
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    assert(rectIsValid(rect));
    assert(paint != null);
    _drawRect(rect, paint);
  }

  void _drawRect(ui.Rect rect, ui.Paint paint) {
    _canvas.drawRect(rect, paint);
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    assert(rrectIsValid(rrect));
    assert(paint != null);
    _drawRRect(rrect, paint);
  }

  void _drawRRect(ui.RRect rrect, ui.Paint paint) {
    _canvas.drawRRect(rrect, paint);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    assert(rrectIsValid(outer));
    assert(rrectIsValid(inner));
    assert(paint != null);
    _drawDRRect(outer, inner, paint);
  }

  void _drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    _canvas.drawDRRect(outer, inner, paint);
  }

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {
    assert(rectIsValid(rect));
    assert(paint != null);
    _drawOval(rect, paint);
  }

  void _drawOval(ui.Rect rect, ui.Paint paint) {
    _canvas.drawOval(rect, paint);
  }

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    assert(_offsetIsValid(c));
    assert(paint != null);
    _drawCircle(c, radius, paint);
  }

  void _drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    _canvas.drawCircle(c, radius, paint);
  }

  @override
  void drawArc(ui.Rect rect, double startAngle, double sweepAngle,
      bool useCenter, ui.Paint paint) {
    assert(rectIsValid(rect));
    assert(paint != null);
    _drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  void _drawArc(ui.Rect rect, double startAngle, double sweepAngle,
      bool useCenter, ui.Paint paint) {
    _canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    assert(path != null); // path is checked on the engine side
    assert(paint != null);
    _drawPath(path, paint);
  }

  void _drawPath(ui.Path path, ui.Paint paint) {
    _canvas.drawPath(path, paint);
  }

  @override
  void drawImage(ui.Image image, ui.Offset p, ui.Paint paint) {
    assert(image != null); // image is checked on the engine side
    assert(_offsetIsValid(p));
    assert(paint != null);
    _drawImage(image, p, paint);
  }

  void _drawImage(ui.Image image, ui.Offset p, ui.Paint paint) {
    _canvas.drawImage(image, p, paint);
  }

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    assert(image != null); // image is checked on the engine side
    assert(rectIsValid(src));
    assert(rectIsValid(dst));
    assert(paint != null);
    _drawImageRect(image, src, dst, paint);
  }

  void _drawImageRect(
      ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    _canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  void drawImageNine(
      ui.Image image, ui.Rect center, ui.Rect dst, ui.Paint paint) {
    assert(image != null); // image is checked on the engine side
    assert(rectIsValid(center));
    assert(rectIsValid(dst));
    assert(paint != null);
    _drawImageNine(image, center, dst, paint);
  }

  void _drawImageNine(
      ui.Image image, ui.Rect center, ui.Rect dst, ui.Paint paint) {
    _canvas.drawImageNine(image, center, dst, paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    assert(picture != null); // picture is checked on the engine side
    _drawPicture(picture);
  }

  void _drawPicture(ui.Picture picture) {
    _canvas.drawPicture(picture);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    assert(paragraph != null);
    assert(_offsetIsValid(offset));
    _drawParagraph(paragraph, offset);
  }

  void _drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    _canvas.drawParagraph(paragraph, offset);
  }

  @override
  void drawPoints(
      ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {
    assert(pointMode != null);
    assert(points != null);
    assert(paint != null);
    _drawPoints(paint, pointMode, encodePointList(points));
  }

  @override
  void drawRawPoints(
      ui.PointMode pointMode, Float32List points, ui.Paint paint) {
    assert(pointMode != null);
    assert(points != null);
    assert(paint != null);
    if (points.length % 2 != 0) {
      throw ArgumentError('"points" must have an even number of values.');
    }
    _drawPoints(paint, pointMode, points);
  }

  void _drawPoints(ui.Paint paint, ui.PointMode pointMode, Float32List points) {
    _canvas.drawPoints(paint, pointMode, points);
  }

  @override
  void drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    assert(vertices != null); // vertices is checked on the engine side
    assert(paint != null);
    assert(blendMode != null);
    _drawVertices(vertices, blendMode, paint);
  }

  void _drawVertices(
      ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    _canvas.drawVertices(vertices, blendMode, paint);
  }

  @override
  void drawAtlas(
      ui.Image atlas,
      List<ui.RSTransform> transforms,
      List<ui.Rect> rects,
      List<ui.Color> colors,
      ui.BlendMode blendMode,
      ui.Rect cullRect,
      ui.Paint paint) {
    assert(atlas != null); // atlas is checked on the engine side
    assert(transforms != null);
    assert(rects != null);
    assert(colors != null);
    assert(blendMode != null);
    assert(paint != null);

    final int rectCount = rects.length;
    if (transforms.length != rectCount) {
      throw ArgumentError('"transforms" and "rects" lengths must match.');
    }
    if (colors.isNotEmpty && colors.length != rectCount) {
      throw ArgumentError(
          'If non-null, "colors" length must match that of "transforms" and "rects".');
    }

    final Float32List rstTransformBuffer = Float32List(rectCount * 4);
    final Float32List rectBuffer = Float32List(rectCount * 4);

    for (int i = 0; i < rectCount; ++i) {
      final int index0 = i * 4;
      final int index1 = index0 + 1;
      final int index2 = index0 + 2;
      final int index3 = index0 + 3;
      final ui.RSTransform rstTransform = transforms[i];
      final ui.Rect rect = rects[i];
      assert(rectIsValid(rect));
      rstTransformBuffer[index0] = rstTransform.scos;
      rstTransformBuffer[index1] = rstTransform.ssin;
      rstTransformBuffer[index2] = rstTransform.tx;
      rstTransformBuffer[index3] = rstTransform.ty;
      rectBuffer[index0] = rect.left;
      rectBuffer[index1] = rect.top;
      rectBuffer[index2] = rect.right;
      rectBuffer[index3] = rect.bottom;
    }

    final Int32List colorBuffer =
        colors.isEmpty ? null : _encodeColorList(colors);

    _drawAtlas(
        paint, atlas, rstTransformBuffer, rectBuffer, colorBuffer, blendMode);
  }

  @override
  void drawRawAtlas(
      ui.Image atlas,
      Float32List rstTransforms,
      Float32List rects,
      Int32List colors,
      ui.BlendMode blendMode,
      ui.Rect cullRect,
      ui.Paint paint) {
    assert(atlas != null); // atlas is checked on the engine side
    assert(rstTransforms != null);
    assert(rects != null);
    assert(colors != null);
    assert(blendMode != null);
    assert(paint != null);

    final int rectCount = rects.length;
    if (rstTransforms.length != rectCount)
      throw ArgumentError('"rstTransforms" and "rects" lengths must match.');
    if (rectCount % 4 != 0)
      throw ArgumentError(
          '"rstTransforms" and "rects" lengths must be a multiple of four.');
    if (colors != null && colors.length * 4 != rectCount)
      throw ArgumentError(
          'If non-null, "colors" length must be one fourth the length of "rstTransforms" and "rects".');

    _drawAtlas(paint, atlas, rstTransforms, rects, colors, blendMode);
  }

  // TODO(hterkelsen): Pass a cull_rect once CanvasKit supports that.
  void _drawAtlas(
    ui.Paint paint,
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List colors,
    ui.BlendMode blendMode,
  ) {
    _canvas.drawAtlasRaw(paint, atlas, rstTransforms, rects, colors, blendMode);
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    assert(path != null); // path is checked on the engine side
    assert(color != null);
    assert(transparentOccluder != null);
    _drawShadow(path, color, elevation, transparentOccluder);
  }

  void _drawShadow(ui.Path path, ui.Color color, double elevation,
      bool transparentOccluder) {
    _canvas.drawShadow(path, color, elevation, transparentOccluder);
  }
}
