// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Memoized value for ClipOp.Intersect, so we don't have to hit JS-interop
/// every time we need it.
final SkClipOp _clipOpIntersect = canvasKit.ClipOp.Intersect;

/// A Dart wrapper around Skia's [SkCanvas].
///
/// This is intentionally not memory-managing the underlying [SkCanvas]. See
/// the docs on [SkCanvas], which explain the reason.
class CkCanvas implements LayerCanvas {
  factory CkCanvas(ui.PictureRecorder recorder, [ui.Rect? cullRect]) {
    if (recorder.isRecording) {
      throw ArgumentError('"recorder" must not already be associated with another Canvas.');
    }
    cullRect ??= ui.Rect.largest;
    final CkPictureRecorder ckRecorder = recorder as CkPictureRecorder;
    return ckRecorder.beginRecording(cullRect);
  }

  CkCanvas.fromSkCanvas(this.skCanvas);

  // Cubic equation coefficients recommended by Mitchell & Netravali
  // in their paper on cubic interpolation.
  static const double _kMitchellNetravali_B = 1.0 / 3.0;
  static const double _kMitchellNetravali_C = 1.0 / 3.0;

  final SkCanvas skCanvas;

  int? get saveCount => skCanvas.getSaveCount().toInt();

  @override
  void clear(ui.Color color) {
    skCanvas.clear(toSharedSkColor1(color));
  }

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) {
    final SkPath skPath = ((path as LazyPath).builtPath as CkPath).snapshotSkPath();
    skCanvas.clipPath(skPath, _clipOpIntersect, doAntiAlias);
    skPath.delete();
  }

  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) {
    assert(rrectIsValid(rrect));
    skCanvas.clipRRect(toSkRRect(rrect), _clipOpIntersect, doAntiAlias);
  }

  @override
  void clipRSuperellipse(ui.RSuperellipse rsuperellipse, {bool doAntiAlias = true}) {
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    translate(offset.dx, offset.dy);

    final SkPath skPath = ((path as LazyPath).builtPath as CkPath).snapshotSkPath();
    skCanvas.clipPath(skPath, _clipOpIntersect, doAntiAlias);
    skPath.delete();

    translate(-offset.dx, -offset.dy);
  }

  @override
  void clipRect(ui.Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    assert(rectIsValid(rect));
    skCanvas.clipRect(toSkRect(rect), toSkClipOp(clipOp), doAntiAlias);
  }

  ui.Rect getDeviceClipBounds() {
    return rectFromSkIRect(skCanvas.getDeviceClipBounds());
  }

  @override
  void drawArc(ui.Rect oval, double startAngle, double sweepAngle, bool useCenter, ui.Paint paint) {
    assert(rectIsValid(oval));
    const double toDegrees = 180 / math.pi;

    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawArc(
      toSkRect(oval),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      useCenter,
      skPaint,
    );
    skPaint.delete();
  }

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) {
    assert(offsetIsValid(c));
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawCircle(c.dx, c.dy, radius, skPaint);
    skPaint.delete();
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    skCanvas.drawColorInt(color.value.toDouble(), toSkBlendMode(blendMode));
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) {
    assert(rrectIsValid(outer));
    assert(rrectIsValid(inner));
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawDRRect(toSkRRect(outer), toSkRRect(inner), skPaint);
    skPaint.delete();
  }

  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) {
    assert(offsetIsValid(offset));
    final ui.FilterQuality filterQuality = paint.filterQuality;
    final skPaint = (paint as CkPaint).toSkPaint(defaultBlurTileMode: ui.TileMode.clamp);
    if (filterQuality == ui.FilterQuality.high) {
      skCanvas.drawImageCubic(
        (image as CkImage).skImage,
        offset.dx,
        offset.dy,
        _kMitchellNetravali_B,
        _kMitchellNetravali_C,
        skPaint,
      );
    } else {
      skCanvas.drawImageOptions(
        (image as CkImage).skImage,
        offset.dx,
        offset.dy,
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        skPaint,
      );
    }
    skPaint.delete();
  }

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {
    assert(rectIsValid(src));
    assert(rectIsValid(dst));
    final ui.FilterQuality filterQuality = paint.filterQuality;
    final skPaint = (paint as CkPaint).toSkPaint(defaultBlurTileMode: ui.TileMode.clamp);
    if (filterQuality == ui.FilterQuality.high) {
      skCanvas.drawImageRectCubic(
        (image as CkImage).skImage,
        toSkRect(src),
        toSkRect(dst),
        _kMitchellNetravali_B,
        _kMitchellNetravali_C,
        skPaint,
      );
    } else {
      skCanvas.drawImageRectOptions(
        (image as CkImage).skImage,
        toSkRect(src),
        toSkRect(dst),
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        skPaint,
      );
    }
    skPaint.delete();
  }

  @override
  void drawImageNine(ui.Image image, ui.Rect center, ui.Rect dst, ui.Paint paint) {
    assert(rectIsValid(center));
    assert(rectIsValid(dst));
    final skPaint = (paint as CkPaint).toSkPaint(defaultBlurTileMode: ui.TileMode.clamp);
    skCanvas.drawImageNine(
      (image as CkImage).skImage,
      toSkRect(center),
      toSkRect(dst),
      toSkFilterMode(paint.filterQuality),
      skPaint,
    );
    skPaint.delete();
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) {
    assert(offsetIsValid(p1));
    assert(offsetIsValid(p2));
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawLine(p1.dx, p1.dy, p2.dx, p2.dy, skPaint);
    skPaint.delete();
  }

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) {
    assert(rectIsValid(rect));
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawOval(toSkRect(rect), skPaint);
    skPaint.delete();
  }

  @override
  void drawPaint(ui.Paint paint) {
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawPaint(skPaint);
    skPaint.delete();
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    assert(offsetIsValid(offset));
    if (paragraph is CkParagraph) {
      skCanvas.drawParagraph(paragraph.skiaObject, offset.dx, offset.dy);
    } else if (paragraph is WebParagraph) {
      paragraph.paint(this, offset);
    } else {
      throw UnimplementedError('Unknown paragraph type.');
    }
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) {
    final skPaint = (paint as CkPaint).toSkPaint();
    final SkPath skPath = ((path as LazyPath).builtPath as CkPath).snapshotSkPath();
    skCanvas.drawPath(skPath, skPaint);
    skPath.delete();
    skPaint.delete();
  }

  @override
  void drawPicture(ui.Picture picture) {
    assert((picture as CkPicture).debugCheckNotDisposed('Failed to draw picture.'));
    skCanvas.drawPicture((picture as CkPicture).skiaObject);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<ui.Offset> points, ui.Paint paint) {
    final SkFloat32List skPoints = toMallocedSkPoints(points);
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawPoints(toSkPointMode(pointMode), skPoints.toTypedArray(), skPaint);
    skPaint.delete();
    free(skPoints);
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, ui.Paint paint) {
    if (points.length % 2 != 0) {
      throw ArgumentError('"points" must have an even number of values.');
    }
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawPoints(toSkPointMode(pointMode), points, skPaint);
    skPaint.delete();
  }

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) {
    assert(rrectIsValid(rrect));
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawRRect(toSkRRect(rrect), skPaint);
    skPaint.delete();
  }

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, ui.Paint paint) {
    final skPaint = (paint as CkPaint).toSkPaint();
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    translate(offset.dx, offset.dy);

    final SkPath skPath = ((path as LazyPath).builtPath as CkPath).snapshotSkPath();
    skCanvas.drawPath(skPath, skPaint);
    skPath.delete();

    translate(-offset.dx, -offset.dy);
    skPaint.delete();
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    assert(rectIsValid(rect));
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawRect(toSkRect(rect), skPaint);
    skPaint.delete();
  }

  @override
  void drawShadow(ui.Path path, ui.Color color, double elevation, bool transparentOccluder) {
    drawSkShadow(
      skCanvas,
      (path as LazyPath).builtPath as CkPath,
      color,
      elevation,
      transparentOccluder,
      EngineFlutterDisplay.instance.devicePixelRatio,
    );
  }

  @override
  void drawVertices(ui.Vertices vertices, ui.BlendMode blendMode, ui.Paint paint) {
    final CkVertices ckVertices = vertices as CkVertices;
    if (ckVertices.hasNoPoints) {
      return;
    }
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.drawVertices(ckVertices.skiaObject, toSkBlendMode(blendMode), skPaint);
    skPaint.delete();
  }

  @override
  void restore() {
    skCanvas.restore();
  }

  @override
  void restoreToCount(int count) {
    skCanvas.restoreToCount(count.toDouble());
  }

  @override
  void rotate(double radians) {
    skCanvas.rotate(radians * 180.0 / math.pi, 0.0, 0.0);
  }

  @override
  int save() {
    return skCanvas.save().toInt();
  }

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) {
    if (bounds == null) {
      saveLayerWithoutBounds(paint);
    } else {
      assert(rectIsValid(bounds));
      _saveLayer(bounds, paint);
    }
  }

  void _saveLayer(ui.Rect bounds, ui.Paint paint) {
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.saveLayer(skPaint, toSkRect(bounds), null, null, canvasKit.TileMode.Clamp);
    skPaint.delete();
  }

  void saveLayerWithoutBounds(ui.Paint paint) {
    final skPaint = (paint as CkPaint).toSkPaint();
    skCanvas.saveLayer(skPaint, null, null, null, canvasKit.TileMode.Clamp);
    skPaint.delete();
  }

  @override
  void saveLayerWithFilter(ui.Rect? bounds, ui.Paint? paint, ui.ImageFilter filter) {
    final CkManagedSkImageFilterConvertible convertible;
    if (filter is ui.ColorFilter) {
      convertible = createCkColorFilter(filter as EngineColorFilter)!;
    } else {
      convertible = filter as CkManagedSkImageFilterConvertible;
    }
    // There are 2 ImageFilter objects applied here. The filter in the paint
    // object is applied to the contents and its default tile mode is decal
    // (automatically applied by toSkPaint).
    // The filter supplied as an argument to this function [convertible] will
    // be applied to the backdrop and its default tile mode will be mirror.
    // We also pass in the blur tile mode as an argument to saveLayer because
    // that operation will not adopt the tile mode from the backdrop filter
    // and instead needs it supplied to the saveLayer call itself as a
    // separate argument.
    convertible.withSkImageFilter((SkImageFilter filter) {
      final skPaint = (paint as CkPaint?)?.toSkPaint(/*ui.TileMode.decal*/);
      skCanvas.saveLayer(
        skPaint,
        bounds == null ? null : toSkRect(bounds),
        filter,
        0,
        toSkTileMode(convertible.backdropTileMode ?? ui.TileMode.mirror),
      );
      skPaint?.delete();
    }, defaultBlurTileMode: ui.TileMode.mirror);
  }

  @override
  void scale(double sx, [double? sy]) {
    skCanvas.scale(sx, sy ?? sx);
  }

  @override
  void skew(double sx, double sy) {
    skCanvas.skew(sx, sy);
  }

  @override
  void transform(Float64List matrix4) {
    if (matrix4.length != 16) {
      throw ArgumentError('"matrix4" must have 16 entries.');
    }
    skCanvas.concat(toSkM44FromFloat32(toMatrix32(matrix4)));
  }

  @override
  void translate(double dx, double dy) {
    skCanvas.translate(dx, dy);
  }

  @override
  bool quickReject(ui.Rect rect) {
    return skCanvas.quickReject(toSkRect(rect));
  }

  Float32List getLocalToDevice() {
    final List<dynamic> list = skCanvas.getLocalToDevice();
    final Float32List matrix4 = Float32List(16);
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        matrix4[c * 4 + r] = (list[r * 4 + c] as num).toDouble();
      }
    }
    return matrix4;
  }

  @override
  void drawAtlas(
    ui.Image atlas,
    List<ui.RSTransform> transforms,
    List<ui.Rect> rects,
    List<ui.Color>? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {
    assert(colors == null || colors.isEmpty || blendMode != null);

    final int rectCount = rects.length;
    if (transforms.length != rectCount) {
      throw ArgumentError('"transforms" and "rects" lengths must match.');
    }
    if (colors != null && colors.isNotEmpty && colors.length != rectCount) {
      throw ArgumentError(
        'If non-null, "colors" length must match that of "transforms" and "rects".',
      );
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

    final Uint32List? colorBuffer = (colors == null || colors.isEmpty)
        ? null
        : toFlatColors(colors);

    _drawAtlas(
      paint as CkPaint,
      atlas as CkImage,
      rstTransformBuffer,
      rectBuffer,
      colorBuffer,
      blendMode ?? ui.BlendMode.src,
    );
  }

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) {
    assert(colors == null || blendMode != null);

    final int rectCount = rects.length;
    if (rstTransforms.length != rectCount) {
      throw ArgumentError('"rstTransforms" and "rects" lengths must match.');
    }
    if (rectCount % 4 != 0) {
      throw ArgumentError('"rstTransforms" and "rects" lengths must be a multiple of four.');
    }
    if (colors != null && colors.length * 4 != rectCount) {
      throw ArgumentError(
        'If non-null, "colors" length must be one fourth the length of "rstTransforms" and "rects".',
      );
    }

    Uint32List? unsignedColors;
    if (colors != null) {
      unsignedColors = colors.buffer.asUint32List(colors.offsetInBytes, colors.length);
    }

    _drawAtlas(
      paint as CkPaint,
      atlas as CkImage,
      rstTransforms,
      rects,
      unsignedColors,
      blendMode ?? ui.BlendMode.src,
    );
  }

  // TODO(flar): CanvasKit does not expose sampling options available on SkCanvas.drawAtlas
  void _drawAtlas(
    CkPaint paint,
    CkImage atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
  ) {
    final skPaint = paint.toSkPaint(defaultBlurTileMode: ui.TileMode.clamp);
    skCanvas.drawAtlas(
      atlas.skImage,
      rects,
      rstTransforms,
      skPaint,
      toSkBlendMode(blendMode),
      colors,
    );
    skPaint.delete();
  }

  @override
  ui.Rect getDestinationClipBounds() {
    return rectFromSkIRect(skCanvas.getDeviceClipBounds());
  }

  @override
  ui.Rect getLocalClipBounds() {
    final Matrix4 transform = Matrix4.fromFloat32List(getLocalToDevice());
    if (transform.invert() == 0) {
      // non-invertible transforms collapse space to a line or point
      return ui.Rect.zero;
    }
    return transform.transformRect(getDeviceClipBounds());
  }

  @override
  int getSaveCount() {
    return skCanvas.getSaveCount().toInt();
  }

  @override
  Float64List getTransform() {
    return toMatrix64(getLocalToDevice());
  }
}
