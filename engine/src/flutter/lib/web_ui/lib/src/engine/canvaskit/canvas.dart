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

/// The CanvasKit [BackendCanvas]: translates canvas operations into calls on
/// an [SkCanvas].
///
/// This class is stateless apart from the [SkCanvas] it wraps. Validation,
/// image tracking and paint lifetimes are handled by [EngineCanvas].
///
/// This is intentionally not memory-managing the underlying [SkCanvas]. See
/// the docs on [SkCanvas], which explain the reason.
class CkCanvas implements BackendCanvas {
  /// Creates a backend canvas that draws into [skCanvas].
  CkCanvas(SkCanvas skCanvas) : _skCanvas = skCanvas;

  // Cubic equation coefficients recommended by Mitchell & Netravali
  // in their paper on cubic interpolation.
  static const double _kMitchellNetravali_B = 1.0 / 3.0;
  static const double _kMitchellNetravali_C = 1.0 / 3.0;

  final SkCanvas _skCanvas;

  static SkImage _getSkImage(BackendImage image) {
    if (image is CkImageDelegate) {
      return image.skImage;
    }
    throw ArgumentError('The image being drawn must be a CanvasKit image.');
  }

  @override
  void save() {
    _skCanvas.save();
  }

  @override
  void saveLayer(ui.Rect? bounds, BackendPaint paint) {
    _skCanvas.saveLayer(
      (paint as CkPaint).skiaObject,
      bounds == null ? null : toSkRect(bounds),
      null,
      0,
      canvasKit.TileMode.Clamp,
    );
  }

  @override
  void saveLayerWithFilter(
    ui.Rect? bounds,
    BackendPaint paint,
    BackendImageFilter backdropFilter,
    ui.TileMode backdropTileMode,
  ) {
    _skCanvas.saveLayer(
      (paint as CkPaint).skiaObject,
      bounds == null ? null : toSkRect(bounds),
      (backdropFilter as CkImageFilter).nativeFilter,
      0,
      toSkTileMode(backdropTileMode),
    );
  }

  @override
  void restore() {
    _skCanvas.restore();
  }

  @override
  void restoreToCount(int count) {
    _skCanvas.restoreToCount(count.toDouble());
  }

  @override
  int getSaveCount() {
    return _skCanvas.getSaveCount().toInt();
  }

  @override
  void translate(double dx, double dy) {
    _skCanvas.translate(dx, dy);
  }

  @override
  void scale(double sx, double sy) {
    _skCanvas.scale(sx, sy);
  }

  @override
  void rotate(double radians) {
    _skCanvas.rotate(radians * 180.0 / math.pi, 0.0, 0.0);
  }

  @override
  void skew(double sx, double sy) {
    _skCanvas.skew(sx, sy);
  }

  @override
  void transform(Float64List matrix4) {
    _skCanvas.concat(toSkM44FromFloat32(toMatrix32(matrix4)));
  }

  @override
  Float64List getTransform() {
    return toMatrix64(_getLocalToDevice());
  }

  Float32List _getLocalToDevice() {
    final List<dynamic> list = _skCanvas.getLocalToDevice();
    final matrix4 = Float32List(16);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        matrix4[c * 4 + r] = (list[r * 4 + c] as num).toDouble();
      }
    }
    return matrix4;
  }

  @override
  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    _skCanvas.clipRect(toSkRect(rect), toSkClipOp(clipOp), doAntiAlias);
  }

  @override
  void clipRRect(ui.RRect rrect, bool doAntiAlias) {
    _skCanvas.clipRRect(toSkRRect(rrect), _clipOpIntersect, doAntiAlias);
  }

  @override
  void clipPath(BackendPath path, bool doAntiAlias) {
    _skCanvas.clipPath((path as CkPath).skiaObject, _clipOpIntersect, doAntiAlias);
  }

  @override
  ui.Rect getDestinationClipBounds() {
    return rectFromSkIRect(_skCanvas.getDeviceClipBounds());
  }

  @override
  void clear(ui.Color color) {
    _skCanvas.clear(toSharedSkColor1(color));
  }

  @override
  bool quickReject(ui.Rect rect) {
    return _skCanvas.quickReject(toSkRect(rect));
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    _skCanvas.drawColorInt(color.value.toDouble(), toSkBlendMode(blendMode));
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, BackendPaint paint) {
    _skCanvas.drawLine(p1.dx, p1.dy, p2.dx, p2.dy, (paint as CkPaint).skiaObject);
  }

  @override
  void drawPaint(BackendPaint paint) {
    _skCanvas.drawPaint((paint as CkPaint).skiaObject);
  }

  @override
  void drawRect(ui.Rect rect, BackendPaint paint) {
    _skCanvas.drawRect(toSkRect(rect), (paint as CkPaint).skiaObject);
  }

  @override
  void drawRRect(ui.RRect rrect, BackendPaint paint) {
    _skCanvas.drawRRect(toSkRRect(rrect), (paint as CkPaint).skiaObject);
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, BackendPaint paint) {
    _skCanvas.drawDRRect(toSkRRect(outer), toSkRRect(inner), (paint as CkPaint).skiaObject);
  }

  @override
  void drawOval(ui.Rect rect, BackendPaint paint) {
    _skCanvas.drawOval(toSkRect(rect), (paint as CkPaint).skiaObject);
  }

  @override
  void drawCircle(ui.Offset center, double radius, BackendPaint paint) {
    _skCanvas.drawCircle(center.dx, center.dy, radius, (paint as CkPaint).skiaObject);
  }

  @override
  void drawArc(
    ui.Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    BackendPaint paint,
  ) {
    const double toDegrees = 180 / math.pi;
    _skCanvas.drawArc(
      toSkRect(rect),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      useCenter,
      (paint as CkPaint).skiaObject,
    );
  }

  @override
  void drawPath(BackendPath path, BackendPaint paint) {
    _skCanvas.drawPath((path as CkPath).skiaObject, (paint as CkPaint).skiaObject);
  }

  @override
  void drawImage(
    BackendImage image,
    ui.Offset offset,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    final SkImage skImage = _getSkImage(image);
    final SkPaint skPaint = (paint as CkPaint).skiaObject;
    if (filterQuality == ui.FilterQuality.high) {
      _skCanvas.drawImageCubic(
        skImage,
        offset.dx,
        offset.dy,
        _kMitchellNetravali_B,
        _kMitchellNetravali_C,
        skPaint,
      );
    } else {
      _skCanvas.drawImageOptions(
        skImage,
        offset.dx,
        offset.dy,
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        skPaint,
      );
    }
  }

  @override
  void drawImageRect(
    BackendImage image,
    ui.Rect src,
    ui.Rect dst,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    final SkImage skImage = _getSkImage(image);
    final SkPaint skPaint = (paint as CkPaint).skiaObject;
    if (filterQuality == ui.FilterQuality.high) {
      _skCanvas.drawImageRectCubic(
        skImage,
        toSkRect(src),
        toSkRect(dst),
        _kMitchellNetravali_B,
        _kMitchellNetravali_C,
        skPaint,
      );
    } else {
      _skCanvas.drawImageRectOptions(
        skImage,
        toSkRect(src),
        toSkRect(dst),
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        skPaint,
      );
    }
  }

  @override
  void drawImageNine(
    BackendImage image,
    ui.Rect center,
    ui.Rect dst,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    _skCanvas.drawImageNine(
      _getSkImage(image),
      toSkRect(center),
      toSkRect(dst),
      toSkFilterMode(filterQuality),
      (paint as CkPaint).skiaObject,
    );
  }

  @override
  void drawPicture(ui.Picture picture) {
    _skCanvas.drawPicture((picture as CkPicture).skiaObject);
  }

  @override
  void drawParagraph(BackendParagraph paragraph, ui.Offset offset) {
    _skCanvas.drawParagraph((paragraph as CkParagraph).skiaObject, offset.dx, offset.dy);
  }

  @override
  void drawPoints(ui.PointMode pointMode, Float32List points, BackendPaint paint) {
    _skCanvas.drawPoints(toSkPointMode(pointMode), points, (paint as CkPaint).skiaObject);
  }

  @override
  void drawVertices(BackendVertices vertices, ui.BlendMode blendMode, BackendPaint paint) {
    _skCanvas.drawVertices(
      (vertices as CkVertices).skiaObject,
      toSkBlendMode(blendMode),
      (paint as CkPaint).skiaObject,
    );
  }

  /// Draws sprites from [atlas].
  ///
  /// [cullRect] is ignored, because the CanvasKit API has no such parameter.
  /// It is only a hint, so ignoring it doesn't change what is drawn.
  @override
  void drawAtlas(
    BackendImage atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
    ui.Rect? cullRect,
    BackendPaint paint,
    ui.FilterQuality filterQuality,
  ) {
    _skCanvas.drawAtlas(
      _getSkImage(atlas),
      rects,
      rstTransforms,
      (paint as CkPaint).skiaObject,
      toSkBlendMode(blendMode),
      colors,
      toSkFilterOptions(filterQuality),
    );
  }

  @override
  void drawShadow(
    BackendPath path,
    ui.Color color,
    double elevation,
    bool transparentOccluder,
    double devicePixelRatio,
  ) {
    drawSkShadow(
      _skCanvas,
      (path as CkPath).skiaObject,
      color,
      elevation,
      transparentOccluder,
      devicePixelRatio,
    );
  }
}
