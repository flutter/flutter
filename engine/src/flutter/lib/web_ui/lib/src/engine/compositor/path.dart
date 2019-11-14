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
    _skPath.callMethod('addArc', <dynamic>[
      makeSkRect(oval),
      startAngle,
      sweepAngle,
    ]);
  }

  @override
  void addOval(ui.Rect oval) {
    _skPath.callMethod('addOval', <dynamic>[makeSkRect(oval), true, 0]);
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
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
      false,
    ]);
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
    _skPath.callMethod('arcTo', <dynamic>[
      radius.x,
      radius.y,
      rotation,
      !largeArc,
      !clockwise,
      arcEnd.dx,
      arcEnd.dy,
    ]);
  }

  @override
  void close() {
    _skPath.callMethod('close');
  }

  @override
  ui.PathMetrics computeMetrics({bool forceClosed = false}) {
    return SkPathMetrics(this, forceClosed);
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    _skPath.callMethod('conicTo', <double>[x1, y1, x2, y2, w]);
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
    _skPath.callMethod('rArcTo', <dynamic>[
      radius.x,
      radius.y,
      rotation,
      !largeArc,
      !clockwise,
      arcEndDelta.dx,
      arcEndDelta.dy,
    ]);
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    _skPath.callMethod('rConicTo', <double>[x1, y1, x2, y2, w]);
  }

  @override
  void relativeCubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    _skPath.callMethod('rCubicTo', <double>[x1, y1, x2, y2, x3, y3]);
  }

  @override
  void relativeLineTo(double dx, double dy) {
    _skPath.callMethod('rLineTo', <double>[dx, dy]);
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    _skPath.callMethod('rMoveTo', <double>[dx, dy]);
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _skPath.callMethod('rQuadTo', <double>[x1, y1, x2, y2]);
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

  static SkPath combine(
    ui.PathOperation operation,
    ui.Path uiPath1,
    ui.Path uiPath2,
  ) {
    final SkPath path1 = uiPath1;
    final SkPath path2 = uiPath2;
    js.JsObject pathOp;
    switch (operation) {
      case ui.PathOperation.difference:
        pathOp = canvasKit['PathOp']['Difference'];
        break;
      case ui.PathOperation.intersect:
        pathOp = canvasKit['PathOp']['Intersect'];
        break;
      case ui.PathOperation.union:
        pathOp = canvasKit['PathOp']['Union'];
        break;
      case ui.PathOperation.xor:
        pathOp = canvasKit['PathOp']['XOR'];
        break;
      case ui.PathOperation.reverseDifference:
        pathOp = canvasKit['PathOp']['ReverseDifference'];
        break;
    }
    final js.JsObject newPath = canvasKit.callMethod(
      'MakePathFromOp',
      <js.JsObject>[
        path1._skPath,
        path2._skPath,
        pathOp,
      ],
    );
    return SkPath._fromSkPath(newPath);
  }

  @override
  List<Subpath> get subpaths {
    throw UnimplementedError(
        'Path.subpaths is not used in the CanvasKit backend.');
  }

  @override
  ui.Path transform(Float64List matrix4) {
    final js.JsObject newPath = _skPath.callMethod('copy');
    newPath.callMethod('transform', <js.JsArray>[makeSkMatrix(matrix4)]);
    return SkPath._fromSkPath(newPath);
  }

  @override
  Ellipse get webOnlyPathAsCircle {
    throw new UnimplementedError(
        'webOnlyPathAsCircle is not used in the CanvasKit backend.');
  }

  @override
  ui.Rect get webOnlyPathAsRect {
    throw new UnimplementedError(
        'webOnlyPathAsRect is not used in the CanvasKit backend.');
  }

  @override
  ui.RRect get webOnlyPathAsRoundedRect {
    throw new UnimplementedError(
        'webOnlyPathAsRoundedRect is not used in the CanvasKit backend.');
  }

  @override
  List<dynamic> webOnlySerializeToCssPaint() {
    throw new UnimplementedError(
        'webOnlySerializeToCssPaint is not used in the CanvasKit backend.');
  }
}
