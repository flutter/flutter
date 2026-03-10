// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../lazy_path.dart';
import '../vector_math.dart';
import 'canvaskit_api.dart';
import 'native_memory.dart';
import 'path_metrics.dart';

/// An implementation of [ui.Path] which is backed by an `SkPath`.
///
/// The `SkPath` is required for `CkCanvas` methods which take a path.
class CkPath implements DisposablePath {
  factory CkPath() {
    final skPathBuilder = SkPathBuilder();
    skPathBuilder.setFillType(toSkFillType(ui.PathFillType.nonZero));
    return CkPath._(skPathBuilder, ui.PathFillType.nonZero);
  }

  factory CkPath.from(CkPath other) {
    final SkPath skPath = other.snapshotSkPath();
    final skPathBuilder = SkPathBuilder(skPath);
    skPath.delete();

    return CkPath._(skPathBuilder, other._fillType);
  }

  factory CkPath.fromSkPath(SkPath skPath, ui.PathFillType fillType) {
    final skPathBuilder = SkPathBuilder(skPath);
    skPathBuilder.setFillType(toSkFillType(fillType));
    return CkPath._(skPathBuilder, fillType);
  }

  CkPath._(SkPathBuilder nativeObject, this._fillType) {
    _ref = UniqueRef<SkPathBuilder>(this, nativeObject, 'PathBuilder');
  }

  late final UniqueRef<SkPathBuilder> _ref;

  SkPathBuilder get _skiaPathBuilder => _ref.nativeObject;

  /// Returns an [SkPath] snapshot of the current path state.
  ///
  /// It is the responsibility of the caller to delete the returned [SkPath].
  SkPath snapshotSkPath() => _skiaPathBuilder.snapshot();

  ui.PathFillType _fillType;

  @override
  void dispose() {
    _ref.dispose();
  }

  @override
  ui.PathFillType get fillType => _fillType;

  @override
  set fillType(ui.PathFillType newFillType) {
    if (_fillType == newFillType) {
      return;
    }
    _fillType = newFillType;
    _skiaPathBuilder.setFillType(toSkFillType(newFillType));
  }

  @override
  void addArc(ui.Rect oval, double startAngle, double sweepAngle) {
    const double toDegrees = 180.0 / math.pi;
    _skiaPathBuilder.addArc(toSkRect(oval), startAngle * toDegrees, sweepAngle * toDegrees);
  }

  @override
  void addOval(ui.Rect oval) {
    _skiaPathBuilder.addOval(toSkRect(oval), false, 1);
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    List<double> skMatrix;
    if (matrix4 == null) {
      skMatrix = toSkMatrixFromFloat32(
        Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage,
      );
    } else {
      skMatrix = toSkMatrixFromFloat64(matrix4);
      skMatrix[2] += offset.dx;
      skMatrix[5] += offset.dy;
    }
    final otherPath = path as CkPath;
    final SkPath otherSkPath = otherPath.snapshotSkPath();
    _skiaPathBuilder.addPath(
      otherSkPath,
      skMatrix[0],
      skMatrix[1],
      skMatrix[2],
      skMatrix[3],
      skMatrix[4],
      skMatrix[5],
      skMatrix[6],
      skMatrix[7],
      skMatrix[8],
      false,
    );
    otherSkPath.delete();
  }

  @override
  void addPolygon(List<ui.Offset> points, bool close) {
    final SkFloat32List encodedPoints = toMallocedSkPoints(points);
    _skiaPathBuilder.addPolygon(encodedPoints.toTypedArray(), close);
    free(encodedPoints);
  }

  @override
  void addRRect(ui.RRect rrect) {
    _skiaPathBuilder.addRRect(toSkRRect(rrect), false);
  }

  @override
  void addRSuperellipse(ui.RSuperellipse rsuperellipse) {
    final (ui.Path path, ui.Offset offset) = rsuperellipse.toPathOffset();
    addPath((path as LazyPath).builtPath, offset);
  }

  @override
  void addRect(ui.Rect rect) {
    _skiaPathBuilder.addRect(toSkRect(rect));
  }

  @override
  void arcTo(ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    const double toDegrees = 180.0 / math.pi;
    _skiaPathBuilder.arcToOval(
      toSkRect(rect),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      forceMoveTo,
    );
  }

  @override
  void arcToPoint(
    ui.Offset arcEnd, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    _skiaPathBuilder.arcToRotated(
      radius.x,
      radius.y,
      rotation,
      !largeArc,
      !clockwise,
      arcEnd.dx,
      arcEnd.dy,
    );
  }

  @override
  void close() {
    _skiaPathBuilder.close();
  }

  @override
  CkPathMetrics computeMetrics({bool forceClosed = false}) {
    return CkPathMetrics(this, forceClosed);
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    _skiaPathBuilder.conicTo(x1, y1, x2, y2, w);
  }

  @override
  bool contains(ui.Offset point) {
    return _skiaPathBuilder.contains(point.dx, point.dy);
  }

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _skiaPathBuilder.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    List<double> skMatrix;
    if (matrix4 == null) {
      skMatrix = toSkMatrixFromFloat32(
        Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage,
      );
    } else {
      skMatrix = toSkMatrixFromFloat64(matrix4);
      skMatrix[2] += offset.dx;
      skMatrix[5] += offset.dy;
    }
    final SkPath otherSkPath = (path as CkPath).snapshotSkPath();
    _skiaPathBuilder.addPath(
      otherSkPath,
      skMatrix[0],
      skMatrix[1],
      skMatrix[2],
      skMatrix[3],
      skMatrix[4],
      skMatrix[5],
      skMatrix[6],
      skMatrix[7],
      skMatrix[8],
      true,
    );
    otherSkPath.delete();
  }

  @override
  ui.Rect getBounds() => fromSkRect(_skiaPathBuilder.getBounds());

  @override
  void lineTo(double x, double y) {
    _skiaPathBuilder.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    _skiaPathBuilder.moveTo(x, y);
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _skiaPathBuilder.quadTo(x1, y1, x2, y2);
  }

  @override
  void relativeArcToPoint(
    ui.Offset arcEndDelta, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    _skiaPathBuilder.rArcTo(
      radius.x,
      radius.y,
      rotation,
      !largeArc,
      !clockwise,
      arcEndDelta.dx,
      arcEndDelta.dy,
    );
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    _skiaPathBuilder.rConicTo(x1, y1, x2, y2, w);
  }

  @override
  void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _skiaPathBuilder.rCubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void relativeLineTo(double dx, double dy) {
    _skiaPathBuilder.rLineTo(dx, dy);
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    _skiaPathBuilder.rMoveTo(dx, dy);
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _skiaPathBuilder.rQuadTo(x1, y1, x2, y2);
  }

  @override
  void reset() {
    // Only reset the local field. Skia will reset its internal state via
    // SkPathBuilder.reset() below.
    _fillType = ui.PathFillType.nonZero;
    _skiaPathBuilder.reset();
  }

  @override
  CkPath shift(ui.Offset offset) {
    final shiftedPath = CkPath.from(this);
    shiftedPath._skiaPathBuilder.transform(1.0, 0.0, offset.dx, 0.0, 1.0, offset.dy, 0.0, 0.0, 1.0);
    return shiftedPath;
  }

  static CkPath combine(ui.PathOperation operation, ui.Path uiPath1, ui.Path uiPath2) {
    final path1 = uiPath1 as CkPath;
    final path2 = uiPath2 as CkPath;

    final SkPath skPath1 = path1.snapshotSkPath();
    final SkPath skPath2 = path2.snapshotSkPath();

    final SkPath combinedSkPath = canvasKit.Path.MakeFromOp(
      skPath1,
      skPath2,
      toSkPathOp(operation),
    );

    final combinedPath = CkPath.fromSkPath(combinedSkPath, path1._fillType);

    skPath1.delete();
    skPath2.delete();
    combinedSkPath.delete();

    return combinedPath;
  }

  @override
  CkPath transform(Float64List matrix4) {
    final transformedPath = CkPath.from(this);

    final Float32List m = toSkMatrixFromFloat64(matrix4);
    transformedPath._skiaPathBuilder.transform(
      m[0],
      m[1],
      m[2],
      m[3],
      m[4],
      m[5],
      m[6],
      m[7],
      m[8],
    );
    return transformedPath;
  }

  @override
  String toSvgString() {
    final SkPath skPath = snapshotSkPath();
    final String result = skPath.toSVGString();
    skPath.delete();
    return result;
  }

  /// Return `true` if this path contains no segments.
  bool get isEmpty {
    return _skiaPathBuilder.isEmpty();
  }
}

class CkPathConstructors implements DisposablePathConstructors {
  @override
  CkPath createNew() => CkPath();

  @override
  CkPath combinePaths(ui.PathOperation operation, DisposablePath path1, DisposablePath path2) {
    return CkPath.combine(operation, path1 as CkPath, path2 as CkPath);
  }
}
