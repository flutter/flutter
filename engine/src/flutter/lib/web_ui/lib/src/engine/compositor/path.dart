// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// An implementation of [ui.Path] which is backed by an `SkPath`.
///
/// The `SkPath` is required for `SkCanvas` methods which take a path.
class SkPath implements ui.Path {
  js.JsObject _skPath;

  SkPath() {
    _skPath = js.JsObject(canvasKit['SkPath']);
    fillType = ui.PathFillType.nonZero;
  }

  SkPath._fromSkPath(js.JsObject skPath) : _skPath = skPath;

  ui.PathFillType _fillType;

  @override
  ui.PathFillType get fillType => _fillType;

  @override
  set fillType(ui.PathFillType newFillType) {
    _fillType = newFillType;

    js.JsObject skFillType;
    switch (newFillType) {
      case ui.PathFillType.nonZero:
        skFillType = canvasKit['FillType']['Winding'];
        break;
      case ui.PathFillType.evenOdd:
        skFillType = canvasKit['FillType']['EvenOdd'];
        break;
    }

    _skPath.callMethod('setFillType', <js.JsObject>[skFillType]);
  }

  @override
  void addArc(ui.Rect oval, double startAngle, double sweepAngle) {
    throw 'addArc';
  }

  @override
  void addOval(ui.Rect oval) {
    // TODO(het): Use `addOval` instead when CanvasKit exposes it.
    // Since CanvasKit doesn't expose `addOval`, use `addArc` instead.
    _skPath.callMethod('addArc', <dynamic>[makeSkRect(oval), 0.0, 360.0]);
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
    throw 'addPath';
  }

  @override
  void addPolygon(List<ui.Offset> points, bool close) {
    // TODO(het): Use `addPoly` once CanvasKit makes it available.
    assert(points != null);
    if (points.isEmpty) {
      return;
    }

    moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final ui.Offset point = points[i];
      lineTo(point.dx, point.dy);
    }
    if (close) {
      this.close();
    }
  }

  @override
  void addRRect(ui.RRect rrect) {
    final js.JsObject skRect = makeSkRect(rrect.outerRect);
    final List<double> radii = <double>[
      rrect.tlRadiusX,
      rrect.tlRadiusY,
      rrect.trRadiusX,
      rrect.trRadiusY,
      rrect.brRadiusX,
      rrect.brRadiusY,
      rrect.blRadiusX,
      rrect.blRadiusY,
    ];
    _skPath.callMethod('addRoundRect',
        <dynamic>[skRect, js.JsArray<double>.from(radii), false]);
  }

  @override
  void addRect(ui.Rect rect) {
    _skPath.callMethod('addRect', <js.JsObject>[makeSkRect(rect)]);
  }

  @override
  void arcTo(
      ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    const double radsToDegrees = 180.0 / math.pi;
    _skPath.callMethod('arcTo', <dynamic>[
      makeSkRect(rect),
      startAngle * radsToDegrees,
      sweepAngle * radsToDegrees,
      forceMoveTo,
    ]);
  }

  @override
  void arcToPoint(ui.Offset arcEnd,
      {ui.Radius radius = ui.Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    assert(rotation == 0.0,
        'Skia backend does not support `arcToPoint` rotation.');
    assert(!largeArc, 'Skia backend does not support `arcToPoint` largeArc.');
    assert(radius.x == radius.y,
        'Skia backend does not support `arcToPoint` with elliptical radius.');

    // TODO(het): Remove asserts above and use the correct override of `arcTo`
    //   when it is available in CanvasKit.
    // The only `arcTo` method exposed in CanvasKit is:
    //   arcTo(x1, y1, x2, y2, radius)
    final ui.Offset lastPoint = _getCurrentPoint();
    _skPath.callMethod('arcTo',
        <double>[lastPoint.dx, lastPoint.dy, arcEnd.dx, arcEnd.dy, radius.x]);
  }

  ui.Offset _getCurrentPoint() {
    final int pointCount = _skPath.callMethod('countPoints');
    final js.JsObject lastPoint =
        _skPath.callMethod('getPoint', <int>[pointCount - 1]);
    return ui.Offset(lastPoint[0], lastPoint[1]);
  }

  @override
  void close() {
    _skPath.callMethod('close');
  }

  @override
  ui.PathMetrics computeMetrics({bool forceClosed = false}) {
    throw 'computeMetrics';
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    throw 'conicTo';
  }

  @override
  bool contains(ui.Offset point) {
    return _skPath.callMethod('contains', <double>[point.dx, point.dy]);
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _skPath.callMethod('cubicTo', <double>[x1, y1, x2, y2, x3, y3]);
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
    List<double> skMatrix;
    if (matrix4 == null) {
      skMatrix = makeSkMatrix(
          Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage);
    } else {
      skMatrix = makeSkMatrix(matrix4);
      skMatrix[2] += offset.dx;
      skMatrix[5] += offset.dy;
    }
    final SkPath otherPath = path;
    _skPath.callMethod('addPath', <dynamic>[
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
    ]);
  }

  @override
  ui.Rect getBounds() {
    final js.JsObject bounds = _skPath.callMethod('getBounds');
    return ui.Rect.fromLTRB(
        bounds['fLeft'], bounds['fTop'], bounds['fRight'], bounds['fBottom']);
  }

  @override
  void lineTo(double x, double y) {
    _skPath.callMethod('lineTo', <double>[x, y]);
  }

  @override
  void moveTo(double x, double y) {
    _skPath.callMethod('moveTo', <double>[x, y]);
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _skPath.callMethod('quadTo', <double>[x1, y1, x2, y2]);
  }

  @override
  void relativeArcToPoint(ui.Offset arcEndDelta,
      {ui.Radius radius = ui.Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    throw 'relativeArcToPoint';
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    throw 'relativeConicTo';
  }

  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    throw 'relativeCubicTo';
  }

  @override
  void relativeLineTo(double dx, double dy) {
    throw 'relativeLineTo';
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    throw 'relativeMoveTo';
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    throw 'relativeQuadraticBezierTo';
  }

  @override
  void reset() {
    _skPath.callMethod('reset');
  }

  @override
  ui.Path shift(ui.Offset offset) {
    // Since CanvasKit does not expose `SkPath.offset`, create a copy of this
    // path and call `transform` on it.
    final js.JsObject newPath = _skPath.callMethod('copy');
    newPath.callMethod('transform',
        <double>[1.0, 0.0, offset.dx, 0.0, 1.0, offset.dy, 0.0, 0.0, 0.0]);
    return SkPath._fromSkPath(newPath);
  }

  @override
  List<Subpath> get subpaths => throw 'subpaths';

  @override
  ui.Path transform(Float64List matrix4) {
    throw 'transform';
  }

  // TODO(het): Remove these.
  @override
  Ellipse get webOnlyPathAsCircle => null;

  @override
  ui.Rect get webOnlyPathAsRect => null;

  @override
  ui.RRect get webOnlyPathAsRoundedRect => null;

  @override
  List<dynamic> webOnlySerializeToCssPaint() {
    return null;
  }
}
