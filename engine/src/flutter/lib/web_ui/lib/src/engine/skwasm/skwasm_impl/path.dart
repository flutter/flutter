// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

enum PathDirection {
  clockwise,
  counterClockwise,
}

enum PathArcSize {
  small,
  large,
}

class SkwasmPath implements ui.Path {
  factory SkwasmPath() {
    return SkwasmPath.fromHandle(pathCreate());
  }

  factory SkwasmPath.from(SkwasmPath source) {
    return SkwasmPath.fromHandle(pathCopy(source._handle));
  }

  SkwasmPath.fromHandle(this._handle);
  final PathHandle _handle;

  PathHandle get handle => _handle;

  void delete() {
    pathDestroy(_handle);
  }

  @override
  ui.PathFillType get fillType => ui.PathFillType.values[pathGetFillType(_handle)];

  @override
  set fillType(ui.PathFillType fillType) => pathSetFillType(_handle, fillType.index);

  @override
  void moveTo(double x, double y) => pathMoveTo(_handle, x, y);

  @override
  void relativeMoveTo(double x, double y) => pathRelativeMoveTo(_handle, x, y);

  @override
  void lineTo(double x, double y) => pathLineTo(_handle, x, y);

  @override
  void relativeLineTo(double x, double y) => pathRelativeMoveTo(_handle, x, y);

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) =>
    pathQuadraticBezierTo(_handle, x1, y1, x2, y2);

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) =>
    pathRelativeQuadraticBezierTo(_handle, x1, y1, x2, y2);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3) =>
    pathCubicTo(_handle, x1, y1, x2, y2, x3, y3);

  @override
  void relativeCubicTo(
      double x1,
      double y1,
      double x2,
      double y2,
      double x3,
      double y3) =>
    pathRelativeCubicTo(_handle, x1, y1, x2, y2, x3, y3);

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) =>
    pathConicTo(_handle, x1, y1, x2, y2, w);

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) =>
    pathRelativeConicTo(_handle, x1, y1, x2, y2, w);

  @override
  void arcTo(
      ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    withStackScope((StackScope s) {
      pathArcToOval(
          _handle,
          s.convertRectToNative(rect),
          ui.toDegrees(startAngle),
          ui.toDegrees(sweepAngle),
          forceMoveTo
      );
    });
  }

  @override
  void arcToPoint(
    ui.Offset arcEnd, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    final PathArcSize arcSize =
        largeArc ? PathArcSize.large : PathArcSize.small;
    final PathDirection pathDirection =
        clockwise ? PathDirection.clockwise : PathDirection.counterClockwise;
    pathArcToRotated(
        _handle,
        radius.x,
        radius.y,
        ui.toDegrees(rotation),
        arcSize.index,
        pathDirection.index,
        arcEnd.dx,
        arcEnd.dy
    );
  }

  @override
  void relativeArcToPoint(
    ui.Offset arcEndDelta, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    final PathArcSize arcSize =
        largeArc ? PathArcSize.large : PathArcSize.small;
    final PathDirection pathDirection =
        clockwise ? PathDirection.clockwise : PathDirection.counterClockwise;
    pathRelativeArcToRotated(
        _handle,
        radius.x,
        radius.y,
        ui.toDegrees(rotation),
        arcSize.index,
        pathDirection.index,
        arcEndDelta.dx,
        arcEndDelta.dy
    );
  }

  @override
  void addRect(ui.Rect rect) {
    withStackScope((StackScope s) {
      pathAddRect(_handle, s.convertRectToNative(rect));
    });
  }

  @override
  void addOval(ui.Rect rect) {
    withStackScope((StackScope s) {
      pathAddOval(_handle, s.convertRectToNative(rect));
    });
  }

  @override
  void addArc(ui.Rect rect, double startAngle, double sweepAngle) {
    withStackScope((StackScope s) {
      pathAddArc(
        _handle,
        s.convertRectToNative(rect),
        ui.toDegrees(startAngle),
        ui.toDegrees(sweepAngle)
      );
    });
  }

  @override
  void addPolygon(List<ui.Offset> points, bool close) {
    withStackScope((StackScope s) {
      pathAddPolygon(_handle, s.convertPointArrayToNative(points), points.length, close);
    });
  }

  @override
  void addRRect(ui.RRect rrect) {
    withStackScope((StackScope s) {
      pathAddRRect(_handle, s.convertRRectToNative(rrect));
    });
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    _addPath(path, offset, false, matrix4: matrix4);
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    _addPath(path, offset, true, matrix4: matrix4);
  }

  void _addPath(ui.Path path, ui.Offset offset, bool extend, {Float64List? matrix4}) {
    assert(path is SkwasmPath);
    withStackScope((StackScope s) {
      final Pointer<Float> convertedMatrix =
          s.convertMatrix4toSkMatrix(matrix4 ?? Matrix4.identity().toFloat64());
      convertedMatrix[2] += offset.dx;
      convertedMatrix[5] += offset.dy;
      pathAddPath(_handle, (path as SkwasmPath)._handle, convertedMatrix, extend);
    });
  }

  @override
  void close() => pathClose(_handle);

  @override
  void reset() => pathReset(_handle);

  @override
  bool contains(ui.Offset point) => pathContains(_handle, point.dx, point.dy);

  @override
  ui.Path shift(ui.Offset offset) =>
    transform(Matrix4.translationValues(offset.dx, offset.dy, 0.0).toFloat64());

  @override
  ui.Path transform(Float64List matrix4) {
    return withStackScope((StackScope s) {
      final PathHandle newPathHandle = pathCopy(_handle);
      pathTransform(newPathHandle, s.convertMatrix4toSkMatrix(matrix4));
      return SkwasmPath.fromHandle(newPathHandle);
    });
  }

  @override
  ui.Rect getBounds() {
    return withStackScope((StackScope s) {
      final Pointer<Float> rectBuffer = s.allocFloatArray(4);
      pathGetBounds(_handle, rectBuffer);
      return s.convertRectFromNative(rectBuffer);
    });
  }

  static SkwasmPath combine(
    ui.PathOperation operation,
    SkwasmPath path1,
    SkwasmPath path2) =>
    SkwasmPath.fromHandle(pathCombine(
        operation.index, path1._handle, path2._handle));

  @override
  ui.PathMetrics computeMetrics({bool forceClosed = false}) {
    return SkwasmPathMetrics(path: this, forceClosed: forceClosed);
  }
}
