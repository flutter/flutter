// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// An implementation of [ui.Path] which is backed by an `SkPath`.
///
/// The `SkPath` is required for `CkCanvas` methods which take a path.
class CkPath implements ui.Path {
  final SkPath _skPath;

  CkPath() : _skPath = SkPath(), _fillType = ui.PathFillType.nonZero {
    _skPath.setFillType(toSkFillType(_fillType));
  }

  CkPath.from(CkPath other) : _skPath = SkPath(other._skPath), _fillType = other.fillType {
    _skPath.setFillType(toSkFillType(_fillType));
  }

  CkPath._fromSkPath(SkPath skPath, this._fillType) : _skPath = skPath {
    _skPath.setFillType(toSkFillType(_fillType));
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
    _skPath.setFillType(toSkFillType(newFillType));
  }

  @override
  void addArc(ui.Rect oval, double startAngle, double sweepAngle) {
    const double toDegrees = 180.0 / math.pi;
    _skPath.addArc(
      toSkRect(oval),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
    );
  }

  @override
  void addOval(ui.Rect oval) {
    _skPath.addOval(toSkRect(oval), false, 1);
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    List<double> skMatrix;
    if (matrix4 == null) {
      skMatrix = toSkMatrixFromFloat32(
          Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage);
    } else {
      skMatrix = toSkMatrixFromFloat64(matrix4);
      skMatrix[2] += offset.dx;
      skMatrix[5] += offset.dy;
    }
    final CkPath otherPath = path as CkPath;
    _skPath.addPath(
      otherPath._skPath,
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
    assert(points != null); // ignore: unnecessary_null_comparison
    final SkFloat32List encodedPoints = toMallocedSkPoints(points);
    _skPath.addPoly(encodedPoints.toTypedArray(), close);
    freeFloat32List(encodedPoints);
  }

  @override
  void addRRect(ui.RRect rrect) {
    final SkFloat32List skRadii = mallocFloat32List(8);
    final Float32List radii = skRadii.toTypedArray();
    radii[0] = rrect.tlRadiusX;
    radii[1] = rrect.tlRadiusY;
    radii[2] = rrect.trRadiusX;
    radii[3] = rrect.trRadiusY;
    radii[4] = rrect.brRadiusX;
    radii[5] = rrect.brRadiusY;
    radii[6] = rrect.blRadiusX;
    radii[7] = rrect.blRadiusY;
    _skPath.addRoundRect(
      toOuterSkRect(rrect),
      radii,
      false,
    );
    freeFloat32List(skRadii);
  }

  @override
  void addRect(ui.Rect rect) {
    _skPath.addRect(toSkRect(rect));
  }

  @override
  void arcTo(
      ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    const double toDegrees = 180.0 / math.pi;
    _skPath.arcToOval(
      toSkRect(rect),
      startAngle * toDegrees,
      sweepAngle * toDegrees,
      forceMoveTo,
    );
  }

  @override
  void arcToPoint(ui.Offset arcEnd,
      {ui.Radius radius = ui.Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    _skPath.arcToRotated(
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
    _skPath.close();
  }

  @override
  ui.PathMetrics computeMetrics({bool forceClosed = false}) {
    return CkPathMetrics(this, forceClosed);
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    _skPath.conicTo(x1, y1, x2, y2, w);
  }

  @override
  bool contains(ui.Offset point) {
    return _skPath.contains(point.dx, point.dy);
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _skPath.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    List<double> skMatrix;
    if (matrix4 == null) {
      skMatrix = toSkMatrixFromFloat32(
          Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage);
    } else {
      skMatrix = toSkMatrixFromFloat64(matrix4);
      skMatrix[2] += offset.dx;
      skMatrix[5] += offset.dy;
    }
    final CkPath otherPath = path as CkPath;
    _skPath.addPath(
      otherPath._skPath,
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
  ui.Rect getBounds() => _skPath.getBounds().toRect();

  @override
  void lineTo(double x, double y) {
    _skPath.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    _skPath.moveTo(x, y);
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _skPath.quadTo(x1, y1, x2, y2);
  }

  @override
  void relativeArcToPoint(ui.Offset arcEndDelta,
      {ui.Radius radius = ui.Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    _skPath.rArcTo(
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
    _skPath.rConicTo(x1, y1, x2, y2, w);
  }

  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _skPath.rCubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void relativeLineTo(double dx, double dy) {
    _skPath.rLineTo(dx, dy);
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    _skPath.rMoveTo(dx, dy);
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _skPath.rQuadTo(x1, y1, x2, y2);
  }

  @override
  void reset() {
    _skPath.reset();
  }

  @override
  ui.Path shift(ui.Offset offset) {
    // Since CanvasKit does not expose `SkPath.offset`, create a copy of this
    // path and call `transform` on it.
    final SkPath newPath = _skPath.copy();
    newPath.transform(1.0, 0.0, offset.dx, 0.0, 1.0, offset.dy, 0.0, 0.0, 0.0);
    return CkPath._fromSkPath(newPath, _fillType);
  }

  static CkPath combine(
    ui.PathOperation operation,
    ui.Path uiPath1,
    ui.Path uiPath2,
  ) {
    final CkPath path1 = uiPath1 as CkPath;
    final CkPath path2 = uiPath2 as CkPath;
    final SkPath newPath = canvasKit.MakePathFromOp(
      path1._skPath,
      path2._skPath,
      toSkPathOp(operation),
    );
    return CkPath._fromSkPath(newPath, path1._fillType);
  }

  @override
  ui.Path transform(Float64List matrix4) {
    final SkPath newPath = _skPath.copy();
    final Float32List m = toSkMatrixFromFloat64(matrix4);
    newPath.transform(
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
    return CkPath._fromSkPath(newPath, _fillType);
  }

  String? toSvgString() {
    return _skPath.toSVGString();
  }

  /// Return `true` if this path contains no segments.
  bool get isEmpty {
    return _skPath.isEmpty();
  }
}
