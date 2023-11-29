// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../color_filter.dart';
import '../display.dart';
import 'canvaskit_api.dart';
import 'color_filter.dart';
import 'image.dart';
import 'image_filter.dart';
import 'painting.dart';
import 'path.dart';
import 'picture.dart';
import 'text.dart';
import 'util.dart';
import 'vertices.dart';

/// Memoized value for ClipOp.Intersect, so we don't have to hit JS-interop
/// every time we need it.
final SkClipOp _clipOpIntersect = canvasKit.ClipOp.Intersect;

/// A Dart wrapper around Skia's [SkCanvas].
///
/// This is intentionally not memory-managing the underlying [SkCanvas]. See
/// the docs on [SkCanvas], which explain the reason.
class CkCanvas {
  CkCanvas(this.skCanvas);

  // Cubic equation coefficients recommended by Mitchell & Netravali
  // in their paper on cubic interpolation.
  static const double _kMitchellNetravali_B = 1.0 / 3.0;
  static const double _kMitchellNetravali_C = 1.0 / 3.0;

  final SkCanvas skCanvas;

  int? get saveCount => skCanvas.getSaveCount().toInt();

  void clear(ui.Color color) {
    skCanvas.clear(toSharedSkColor1(color));
  }

  void clipPath(CkPath path, bool doAntiAlias) {
    skCanvas.clipPath(
      path.skiaObject,
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

  ui.Rect getDeviceClipBounds() {
    return rectFromSkIRect(skCanvas.getDeviceClipBounds());
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

  // TODO(flar): CanvasKit does not expose sampling options available on SkCanvas.drawAtlas
  void drawAtlasRaw(
    CkPaint paint,
    CkImage atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
  ) {
    skCanvas.drawAtlas(
      atlas.skImage,
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
      color.value.toDouble(),
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

  void drawImage(CkImage image, ui.Offset offset, CkPaint paint) {
    final ui.FilterQuality filterQuality = paint.filterQuality;
    if (filterQuality == ui.FilterQuality.high) {
      skCanvas.drawImageCubic(
        image.skImage,
        offset.dx,
        offset.dy,
        _kMitchellNetravali_B,
        _kMitchellNetravali_C,
        paint.skiaObject,
      );
    } else {
      skCanvas.drawImageOptions(
        image.skImage,
        offset.dx,
        offset.dy,
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        paint.skiaObject,
      );
    }
  }

  void drawImageRect(CkImage image, ui.Rect src, ui.Rect dst, CkPaint paint) {
    final ui.FilterQuality filterQuality = paint.filterQuality;
    if (filterQuality == ui.FilterQuality.high) {
      skCanvas.drawImageRectCubic(
        image.skImage,
        toSkRect(src),
        toSkRect(dst),
        _kMitchellNetravali_B,
        _kMitchellNetravali_C,
        paint.skiaObject,
      );
    } else {
      skCanvas.drawImageRectOptions(
        image.skImage,
        toSkRect(src),
        toSkRect(dst),
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        paint.skiaObject,
      );
    }
  }

  void drawImageNine(
      CkImage image, ui.Rect center, ui.Rect dst, CkPaint paint) {
    skCanvas.drawImageNine(
      image.skImage,
      toSkRect(center),
      toSkRect(dst),
      toSkFilterMode(paint.filterQuality),
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
    skCanvas.drawPath(path.skiaObject, paint.skiaObject);
  }

  void drawPicture(CkPicture picture) {
    assert(picture.debugCheckNotDisposed('Failed to draw picture.'));
    skCanvas.drawPicture(picture.skiaObject);
  }

  void drawPoints(CkPaint paint, ui.PointMode pointMode, Float32List points) {
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

  void drawShadow(
      CkPath path, ui.Color color, double elevation, bool transparentOccluder) {
    drawSkShadow(skCanvas, path, color, elevation, transparentOccluder,
        EngineFlutterDisplay.instance.devicePixelRatio);
  }

  void drawVertices(
      CkVertices vertices, ui.BlendMode blendMode, CkPaint paint) {
    skCanvas.drawVertices(
      vertices.skiaObject,
      toSkBlendMode(blendMode),
      paint.skiaObject,
    );
  }

  void restore() {
    skCanvas.restore();
  }

  void restoreToCount(int count) {
    skCanvas.restoreToCount(count.toDouble());
  }

  void rotate(double radians) {
    skCanvas.rotate(radians * 180.0 / math.pi, 0.0, 0.0);
  }

  int save() {
    return skCanvas.save().toInt();
  }

  void saveLayer(ui.Rect bounds, CkPaint? paint) {
    skCanvas.saveLayer(
      paint?.skiaObject,
      toSkRect(bounds),
      null,
      null,
    );
  }

  void saveLayerWithoutBounds(CkPaint? paint) {
    skCanvas.saveLayer(paint?.skiaObject, null, null, null);
  }

  void saveLayerWithFilter(ui.Rect bounds, ui.ImageFilter filter,
      [CkPaint? paint]) {
    final CkManagedSkImageFilterConvertible convertible;
    if (filter is ui.ColorFilter) {
      convertible = createCkColorFilter(filter as EngineColorFilter)!;
    } else {
      convertible = filter as CkManagedSkImageFilterConvertible;
    }
    convertible.imageFilter((SkImageFilter filter) {
      skCanvas.saveLayer(
        paint?.skiaObject,
        toSkRect(bounds),
        filter,
        0,
      );
    });
  }

  void scale(double sx, double sy) {
    skCanvas.scale(sx, sy);
  }

  void skew(double sx, double sy) {
    skCanvas.skew(sx, sy);
  }

  void transform(Float32List matrix4) {
    skCanvas.concat(toSkM44FromFloat32(matrix4));
  }

  void translate(double dx, double dy) {
    skCanvas.translate(dx, dy);
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
}
