// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../color_filter.dart';
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
        ui.window.devicePixelRatio);
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

  CkPictureSnapshot? get pictureSnapshot => null;
}

class RecordingCkCanvas extends CkCanvas {
  RecordingCkCanvas(super.skCanvas, ui.Rect bounds)
      : pictureSnapshot = CkPictureSnapshot(bounds);

  @override
  final CkPictureSnapshot pictureSnapshot;

  void _addCommand(CkPaintCommand command) {
    pictureSnapshot._commands.add(command);
  }

  @override
  void clear(ui.Color color) {
    super.clear(color);
    _addCommand(CkClearCommand(color));
  }

  @override
  void clipPath(CkPath path, bool doAntiAlias) {
    super.clipPath(path, doAntiAlias);
    _addCommand(CkClipPathCommand(path, doAntiAlias));
  }

  @override
  void clipRRect(ui.RRect rrect, bool doAntiAlias) {
    super.clipRRect(rrect, doAntiAlias);
    _addCommand(CkClipRRectCommand(rrect, doAntiAlias));
  }

  @override
  void clipRect(ui.Rect rect, ui.ClipOp clipOp, bool doAntiAlias) {
    super.clipRect(rect, clipOp, doAntiAlias);
    _addCommand(CkClipRectCommand(rect, clipOp, doAntiAlias));
  }

  @override
  void drawArc(
    ui.Rect oval,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    CkPaint paint,
  ) {
    super.drawArc(oval, startAngle, sweepAngle, useCenter, paint);
    _addCommand(
        CkDrawArcCommand(oval, startAngle, sweepAngle, useCenter, paint));
  }

  @override
  void drawAtlasRaw(
    CkPaint paint,
    CkImage atlas,
    Float32List rstTransforms,
    Float32List rects,
    Uint32List? colors,
    ui.BlendMode blendMode,
  ) {
    super.drawAtlasRaw(paint, atlas, rstTransforms, rects, colors, blendMode);
    _addCommand(CkDrawAtlasCommand(
        paint, atlas, rstTransforms, rects, colors, blendMode));
  }

  @override
  void drawCircle(ui.Offset c, double radius, CkPaint paint) {
    super.drawCircle(c, radius, paint);
    _addCommand(CkDrawCircleCommand(c, radius, paint));
  }

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) {
    super.drawColor(color, blendMode);
    _addCommand(CkDrawColorCommand(color, blendMode));
  }

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, CkPaint paint) {
    super.drawDRRect(outer, inner, paint);
    _addCommand(CkDrawDRRectCommand(outer, inner, paint));
  }

  @override
  void drawImage(CkImage image, ui.Offset offset, CkPaint paint) {
    super.drawImage(image, offset, paint);
    _addCommand(CkDrawImageCommand(image, offset, paint));
  }

  @override
  void drawImageRect(CkImage image, ui.Rect src, ui.Rect dst, CkPaint paint) {
    super.drawImageRect(image, src, dst, paint);
    _addCommand(CkDrawImageRectCommand(image, src, dst, paint));
  }

  @override
  void drawImageNine(
      CkImage image, ui.Rect center, ui.Rect dst, CkPaint paint) {
    super.drawImageNine(image, center, dst, paint);
    _addCommand(CkDrawImageNineCommand(image, center, dst, paint));
  }

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, CkPaint paint) {
    super.drawLine(p1, p2, paint);
    _addCommand(CkDrawLineCommand(p1, p2, paint));
  }

  @override
  void drawOval(ui.Rect rect, CkPaint paint) {
    super.drawOval(rect, paint);
    _addCommand(CkDrawOvalCommand(rect, paint));
  }

  @override
  void drawPaint(CkPaint paint) {
    super.drawPaint(paint);
    _addCommand(CkDrawPaintCommand(paint));
  }

  @override
  void drawParagraph(CkParagraph paragraph, ui.Offset offset) {
    super.drawParagraph(paragraph, offset);
    _addCommand(CkDrawParagraphCommand(paragraph, offset));
  }

  @override
  void drawPath(CkPath path, CkPaint paint) {
    super.drawPath(path, paint);
    _addCommand(CkDrawPathCommand(path, paint));
  }

  @override
  void drawPicture(CkPicture picture) {
    super.drawPicture(picture);
    _addCommand(CkDrawPictureCommand(picture));
  }

  @override
  void drawPoints(CkPaint paint, ui.PointMode pointMode, Float32List points) {
    super.drawPoints(paint, pointMode, points);
    _addCommand(CkDrawPointsCommand(pointMode, points, paint));
  }

  @override
  void drawRRect(ui.RRect rrect, CkPaint paint) {
    super.drawRRect(rrect, paint);
    _addCommand(CkDrawRRectCommand(rrect, paint));
  }

  @override
  void drawRect(ui.Rect rect, CkPaint paint) {
    super.drawRect(rect, paint);
    _addCommand(CkDrawRectCommand(rect, paint));
  }

  @override
  void drawShadow(
      CkPath path, ui.Color color, double elevation, bool transparentOccluder) {
    super.drawShadow(path, color, elevation, transparentOccluder);
    _addCommand(
        CkDrawShadowCommand(path, color, elevation, transparentOccluder));
  }

  @override
  void drawVertices(
      CkVertices vertices, ui.BlendMode blendMode, CkPaint paint) {
    super.drawVertices(vertices, blendMode, paint);
    _addCommand(CkDrawVerticesCommand(vertices, blendMode, paint));
  }

  @override
  void restore() {
    super.restore();
    _addCommand(const CkRestoreCommand());
  }

  @override
  void restoreToCount(int count) {
    super.restoreToCount(count);
    _addCommand(CkRestoreToCountCommand(count));
  }

  @override
  void rotate(double radians) {
    super.rotate(radians);
    _addCommand(CkRotateCommand(radians));
  }

  @override
  int save() {
    _addCommand(const CkSaveCommand());
    return super.save();
  }

  @override
  void saveLayer(ui.Rect bounds, CkPaint? paint) {
    super.saveLayer(bounds, paint);
    _addCommand(CkSaveLayerCommand(bounds, paint));
  }

  @override
  void saveLayerWithoutBounds(CkPaint? paint) {
    super.saveLayerWithoutBounds(paint);
    _addCommand(CkSaveLayerWithoutBoundsCommand(paint));
  }

  @override
  void saveLayerWithFilter(ui.Rect bounds, ui.ImageFilter filter,
      [CkPaint? paint]) {
    super.saveLayerWithFilter(bounds, filter, paint);
    _addCommand(CkSaveLayerWithFilterCommand(bounds, filter, paint));
  }

  @override
  void scale(double sx, double sy) {
    super.scale(sx, sy);
    _addCommand(CkScaleCommand(sx, sy));
  }

  @override
  void skew(double sx, double sy) {
    super.skew(sx, sy);
    _addCommand(CkSkewCommand(sx, sy));
  }

  @override
  void transform(Float32List matrix4) {
    super.transform(matrix4);
    _addCommand(CkTransformCommand(matrix4));
  }

  @override
  void translate(double dx, double dy) {
    super.translate(dx, dy);
    _addCommand(CkTranslateCommand(dx, dy));
  }
}

class CkPictureSnapshot {
  CkPictureSnapshot(this._bounds);

  final ui.Rect _bounds;
  final List<CkPaintCommand> _commands = <CkPaintCommand>[];

  SkPicture toPicture() {
    final SkPictureRecorder recorder = SkPictureRecorder();
    final Float32List skRect = toSkRect(_bounds);
    final SkCanvas skCanvas = recorder.beginRecording(skRect);
    for (final CkPaintCommand command in _commands) {
      command.apply(skCanvas);
    }
    final SkPicture skPicture = recorder.finishRecordingAsPicture();
    recorder.delete();
    return skPicture;
  }

  void dispose() {
    for (final CkPaintCommand command in _commands) {
      command.dispose();
    }
  }
}

/// A paint command recorded by [RecordingCkCanvas].
///
/// # Special rules when drawing images
///
/// A command painting an image must clone the original image to bump the ref
/// count. Otherwise when the framework decides it doesn't need the image any
/// more it will bump the ref count down and delete the underlying Skia object,
/// leaving the picture that recorded this paint command with a dangling
/// pointer. If we attempt to resurrect the picture we'll hit a use-after-free
/// error. The command must call [CkImage.dispose] in its [dispose]
/// implementation.
abstract class CkPaintCommand {
  const CkPaintCommand();

  /// Applies the command onto the [canvas].
  void apply(SkCanvas canvas);

  /// Frees resources associated with the command.
  void dispose() {}
}

class CkClearCommand extends CkPaintCommand {
  const CkClearCommand(this.color);

  final ui.Color color;

  @override
  void apply(SkCanvas canvas) {
    canvas.clear(toSharedSkColor1(color));
  }
}

class CkSaveCommand extends CkPaintCommand {
  const CkSaveCommand();

  @override
  void apply(SkCanvas canvas) {
    canvas.save();
  }
}

class CkRestoreCommand extends CkPaintCommand {
  const CkRestoreCommand();

  @override
  void apply(SkCanvas canvas) {
    canvas.restore();
  }
}

class CkRestoreToCountCommand extends CkPaintCommand {
  const CkRestoreToCountCommand(this.count);

  final int count;

  @override
  void apply(SkCanvas canvas) {
    canvas.restoreToCount(count.toDouble());
  }
}

class CkTranslateCommand extends CkPaintCommand {
  CkTranslateCommand(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  void apply(SkCanvas canvas) {
    canvas.translate(dx, dy);
  }
}

class CkScaleCommand extends CkPaintCommand {
  CkScaleCommand(this.sx, this.sy);

  final double sx;
  final double sy;

  @override
  void apply(SkCanvas canvas) {
    canvas.scale(sx, sy);
  }
}

class CkRotateCommand extends CkPaintCommand {
  CkRotateCommand(this.radians);

  final double radians;

  @override
  void apply(SkCanvas canvas) {
    canvas.rotate(radians * 180.0 / math.pi, 0.0, 0.0);
  }
}

class CkTransformCommand extends CkPaintCommand {
  CkTransformCommand(this.matrix4);

  final Float32List matrix4;

  @override
  void apply(SkCanvas canvas) {
    canvas.concat(toSkM44FromFloat32(matrix4));
  }
}

class CkSkewCommand extends CkPaintCommand {
  CkSkewCommand(this.sx, this.sy);

  final double sx;
  final double sy;

  @override
  void apply(SkCanvas canvas) {
    canvas.skew(sx, sy);
  }
}

class CkClipRectCommand extends CkPaintCommand {
  CkClipRectCommand(this.rect, this.clipOp, this.doAntiAlias);

  final ui.Rect rect;
  final ui.ClipOp clipOp;
  final bool doAntiAlias;

  @override
  void apply(SkCanvas canvas) {
    canvas.clipRect(
      toSkRect(rect),
      toSkClipOp(clipOp),
      doAntiAlias,
    );
  }
}

class CkDrawArcCommand extends CkPaintCommand {
  CkDrawArcCommand(
      this.oval, this.startAngle, this.sweepAngle, this.useCenter, this.paint);

  final ui.Rect oval;
  final double startAngle;
  final double sweepAngle;
  final bool useCenter;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    const double toDegrees = 180 / math.pi;
    canvas.drawArc(
      toSkRect(oval),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      useCenter,
      paint.skiaObject,
    );
  }
}

class CkDrawAtlasCommand extends CkPaintCommand {
  CkDrawAtlasCommand(this.paint, this.atlas, this.rstTransforms, this.rects,
      this.colors, this.blendMode);

  final CkPaint paint;
  final CkImage atlas;
  final Float32List rstTransforms;
  final Float32List rects;
  final Uint32List? colors;
  final ui.BlendMode blendMode;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawAtlas(
      atlas.skImage,
      rects,
      rstTransforms,
      paint.skiaObject,
      toSkBlendMode(blendMode),
      colors,
    );
  }
}

class CkClipRRectCommand extends CkPaintCommand {
  CkClipRRectCommand(this.rrect, this.doAntiAlias);

  final ui.RRect rrect;
  final bool doAntiAlias;

  @override
  void apply(SkCanvas canvas) {
    canvas.clipRRect(
      toSkRRect(rrect),
      _clipOpIntersect,
      doAntiAlias,
    );
  }
}

class CkClipPathCommand extends CkPaintCommand {
  CkClipPathCommand(this.path, this.doAntiAlias);

  final CkPath path;
  final bool doAntiAlias;

  @override
  void apply(SkCanvas canvas) {
    canvas.clipPath(
      path.skiaObject,
      _clipOpIntersect,
      doAntiAlias,
    );
  }
}

class CkDrawColorCommand extends CkPaintCommand {
  CkDrawColorCommand(this.color, this.blendMode);

  final ui.Color color;
  final ui.BlendMode blendMode;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawColorInt(
      color.value.toDouble(),
      toSkBlendMode(blendMode),
    );
  }
}

class CkDrawLineCommand extends CkPaintCommand {
  CkDrawLineCommand(this.p1, this.p2, this.paint);

  final ui.Offset p1;
  final ui.Offset p2;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawLine(
      p1.dx,
      p1.dy,
      p2.dx,
      p2.dy,
      paint.skiaObject,
    );
  }
}

class CkDrawPaintCommand extends CkPaintCommand {
  CkDrawPaintCommand(this.paint);

  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawPaint(paint.skiaObject);
  }
}

class CkDrawVerticesCommand extends CkPaintCommand {
  CkDrawVerticesCommand(this.vertices, this.blendMode, this.paint);

  final CkVertices vertices;
  final ui.BlendMode blendMode;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawVertices(
      vertices.skiaObject,
      toSkBlendMode(blendMode),
      paint.skiaObject,
    );
  }
}

class CkDrawPointsCommand extends CkPaintCommand {
  CkDrawPointsCommand(this.pointMode, this.points, this.paint);

  final Float32List points;
  final ui.PointMode pointMode;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawPoints(
      toSkPointMode(pointMode),
      points,
      paint.skiaObject,
    );
  }
}

class CkDrawRectCommand extends CkPaintCommand {
  CkDrawRectCommand(this.rect, this.paint);

  final ui.Rect rect;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawRect(toSkRect(rect), paint.skiaObject);
  }
}

class CkDrawRRectCommand extends CkPaintCommand {
  CkDrawRRectCommand(this.rrect, this.paint);

  final ui.RRect rrect;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawRRect(
      toSkRRect(rrect),
      paint.skiaObject,
    );
  }
}

class CkDrawDRRectCommand extends CkPaintCommand {
  CkDrawDRRectCommand(this.outer, this.inner, this.paint);

  final ui.RRect outer;
  final ui.RRect inner;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawDRRect(
      toSkRRect(outer),
      toSkRRect(inner),
      paint.skiaObject,
    );
  }
}

class CkDrawOvalCommand extends CkPaintCommand {
  CkDrawOvalCommand(this.rect, this.paint);

  final ui.Rect rect;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawOval(
      toSkRect(rect),
      paint.skiaObject,
    );
  }
}

class CkDrawCircleCommand extends CkPaintCommand {
  CkDrawCircleCommand(this.c, this.radius, this.paint);

  final ui.Offset c;
  final double radius;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawCircle(
      c.dx,
      c.dy,
      radius,
      paint.skiaObject,
    );
  }
}

class CkDrawPathCommand extends CkPaintCommand {
  CkDrawPathCommand(this.path, this.paint);

  final CkPath path;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawPath(path.skiaObject, paint.skiaObject);
  }
}

class CkDrawShadowCommand extends CkPaintCommand {
  CkDrawShadowCommand(
      this.path, this.color, this.elevation, this.transparentOccluder);

  final CkPath path;
  final ui.Color color;
  final double elevation;
  final bool transparentOccluder;

  @override
  void apply(SkCanvas canvas) {
    drawSkShadow(canvas, path, color, elevation, transparentOccluder,
        ui.window.devicePixelRatio);
  }
}

class CkDrawImageCommand extends CkPaintCommand {
  CkDrawImageCommand(CkImage ckImage, this.offset, this.paint)
      : image = ckImage.clone();

  final CkImage image;
  final ui.Offset offset;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    final ui.FilterQuality filterQuality = paint.filterQuality;
    if (filterQuality == ui.FilterQuality.high) {
      canvas.drawImageCubic(
        image.skImage,
        offset.dx,
        offset.dy,
        CkCanvas._kMitchellNetravali_B,
        CkCanvas._kMitchellNetravali_C,
        paint.skiaObject,
      );
    } else {
      canvas.drawImageOptions(
        image.skImage,
        offset.dx,
        offset.dy,
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        paint.skiaObject,
      );
    }
  }

  @override
  void dispose() {
    image.dispose();
  }
}

class CkDrawImageRectCommand extends CkPaintCommand {
  CkDrawImageRectCommand(CkImage ckImage, this.src, this.dst, this.paint)
      : image = ckImage.clone();

  final CkImage image;
  final ui.Rect src;
  final ui.Rect dst;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    final ui.FilterQuality filterQuality = paint.filterQuality;
    if (filterQuality == ui.FilterQuality.high) {
      canvas.drawImageRectCubic(
        image.skImage,
        toSkRect(src),
        toSkRect(dst),
        CkCanvas._kMitchellNetravali_B,
        CkCanvas._kMitchellNetravali_C,
        paint.skiaObject,
      );
    } else {
      canvas.drawImageRectOptions(
        image.skImage,
        toSkRect(src),
        toSkRect(dst),
        toSkFilterMode(filterQuality),
        toSkMipmapMode(filterQuality),
        paint.skiaObject,
      );
    }
  }

  @override
  void dispose() {
    image.dispose();
  }
}

class CkDrawImageNineCommand extends CkPaintCommand {
  CkDrawImageNineCommand(CkImage ckImage, this.center, this.dst, this.paint)
      : image = ckImage.clone();

  final CkImage image;
  final ui.Rect center;
  final ui.Rect dst;
  final CkPaint paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawImageNine(
      image.skImage,
      toSkRect(center),
      toSkRect(dst),
      toSkFilterMode(paint.filterQuality),
      paint.skiaObject,
    );
  }

  @override
  void dispose() {
    image.dispose();
  }
}

class CkDrawParagraphCommand extends CkPaintCommand {
  CkDrawParagraphCommand(this.paragraph, this.offset);

  final CkParagraph paragraph;
  final ui.Offset offset;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawParagraph(
      paragraph.skiaObject,
      offset.dx,
      offset.dy,
    );
  }
}

class CkDrawPictureCommand extends CkPaintCommand {
  CkDrawPictureCommand(this.picture);

  final CkPicture picture;

  @override
  void apply(SkCanvas canvas) {
    canvas.drawPicture(picture.skiaObject);
  }
}

class CkSaveLayerCommand extends CkPaintCommand {
  CkSaveLayerCommand(this.bounds, this.paint);

  final ui.Rect bounds;
  final CkPaint? paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.saveLayer(
      paint?.skiaObject,
      toSkRect(bounds),
      null,
      null,
    );
  }
}

class CkSaveLayerWithoutBoundsCommand extends CkPaintCommand {
  CkSaveLayerWithoutBoundsCommand(this.paint);

  final CkPaint? paint;

  @override
  void apply(SkCanvas canvas) {
    canvas.saveLayer(
      paint?.skiaObject,
      null,
      null,
      null,
    );
  }
}

class CkSaveLayerWithFilterCommand extends CkPaintCommand {
  CkSaveLayerWithFilterCommand(this.bounds, this.filter, this.paint);

  final ui.Rect bounds;
  final ui.ImageFilter filter;
  final CkPaint? paint;

  @override
  void apply(SkCanvas canvas) {
    final CkManagedSkImageFilterConvertible convertible;
    if (filter is ui.ColorFilter) {
      convertible = createCkColorFilter(filter as EngineColorFilter)!;
    } else {
      convertible = filter as CkManagedSkImageFilterConvertible;
    }
    convertible.imageFilter((SkImageFilter filter) {
      canvas.saveLayer(
        paint?.skiaObject,
        toSkRect(bounds),
        filter,
        0,
      );
    });
  }
}
