// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A [DisposablePath] implementation backed by CanvasKit's [SkPath].
class CkPath implements DisposablePath {
  CkPath(this.skiaObject);

  final SkPath skiaObject;

  @override
  ui.PathFillType get fillType => fromSkFillType(skiaObject.getFillType());

  @override
  bool contains(ui.Offset point) => skiaObject.contains(point.dx, point.dy);

  @override
  ui.Rect getBounds() => fromSkRect(skiaObject.getBounds());

  // In order to properly clip platform views with paths, we need to be able to get a
  // string representation of them.
  @override
  String toSvgString() => skiaObject.toSVGString();

  bool get isEmpty => skiaObject.isEmpty();

  @override
  DisposablePathMetricIterator getMetricsIterator({bool forceClosed = false}) {
    // The [isEmpty] case is special-cased to avoid booting the WASM machinery just to find out
    // there are no contours.
    return isEmpty ? const CkPathMetricIteratorEmpty() : CkContourMeasureIter(this, forceClosed);
  }

  @override
  void dispose() {
    skiaObject.delete();
  }
}

/// A PathBuilder backed by CanvasKit's [SkPathBuilder].
class CkPathBuilder implements DisposablePathBuilder {
  factory CkPathBuilder() {
    final SkPathBuilder skPathBuilder = SkPathBuilder();
    skPathBuilder.setFillType(toSkFillType(ui.PathFillType.nonZero));
    return CkPathBuilder._(skPathBuilder, ui.PathFillType.nonZero);
  }

  factory CkPathBuilder.fromSkPath(SkPath skPath, ui.PathFillType fillType) {
    final SkPathBuilder skPathBuilder = SkPathBuilder(skPath);
    skPathBuilder.setFillType(toSkFillType(fillType));
    return CkPathBuilder._(skPathBuilder, fillType);
  }

  CkPathBuilder._(SkPathBuilder nativeObject, this._fillType) {
    // TODO: The lifecycle of CkPathBuilder is managed by LazyPath, so there's no need for UniqueRef here.
    _ref = UniqueRef<SkPathBuilder>(this, nativeObject, 'PathBuilder');
  }

  late final UniqueRef<SkPathBuilder> _ref;

  SkPathBuilder get _skiaPathBuilder => _ref.nativeObject;

  @override
  CkPath build() {
    return CkPath(_skiaPathBuilder.snapshot());
  }

  @override
  void dispose() {
    _ref.dispose();
  }

  ui.PathFillType _fillType;

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
  void addPath(DisposablePath path, ui.Offset offset, {Float64List? matrix4}) {
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
    _skiaPathBuilder.addPath(
      (path as CkPath).skiaObject,
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
  void extendWithPath(DisposablePath path, ui.Offset offset, {Float64List? matrix4}) {
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
    _skiaPathBuilder.addPath(
      (path as CkPath).skiaObject,
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
  void shiftInPlace(ui.Offset offset) {
    _skiaPathBuilder.transform(1.0, 0.0, offset.dx, 0.0, 1.0, offset.dy, 0.0, 0.0, 1.0);
  }

  static CkPathBuilder combine(ui.PathOperation operation, CkPath path1, CkPath path2) {
    final SkPath combinedSkPath = canvasKit.Path.MakeFromOp(
      path1.skiaObject,
      path2.skiaObject,
      toSkPathOp(operation),
    );

    final CkPathBuilder combined = CkPathBuilder.fromSkPath(combinedSkPath, path1.fillType);
    combinedSkPath.delete();
    return combined;
  }

  @override
  void transformInPlace(Float64List matrix4) {
    final Float32List m = toSkMatrixFromFloat64(matrix4);
    _skiaPathBuilder.transform(m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8]);
  }

  /// Return `true` if this path builder contains no segments.
  bool get isEmpty {
    return _skiaPathBuilder.isEmpty();
  }
}

class CkPathConstructors implements DisposablePathConstructors {
  @override
  CkPathBuilder createNew() => CkPathBuilder();

  @override
  DisposablePathBuilder fromPath(DisposablePath path) =>
      CkPathBuilder.fromSkPath((path as CkPath).skiaObject, path.fillType);

  @override
  CkPathBuilder combinePaths(
    ui.PathOperation operation,
    DisposablePath path1,
    DisposablePath path2,
  ) {
    return CkPathBuilder.combine(operation, path1 as CkPath, path2 as CkPath);
  }
}
