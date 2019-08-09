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
  }

  js.JsObject _makeSkRect(ui.Rect rect) {
    return js.JsObject(canvasKit['LTRBRect'],
        <double>[rect.left, rect.top, rect.right, rect.bottom]);
  }

  @override
  ui.PathFillType fillType;

  @override
  void addArc(ui.Rect oval, double startAngle, double sweepAngle) {
    throw 'addArc';
  }

  @override
  void addOval(ui.Rect oval) {
    throw 'addOval';
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
    throw 'addPath';
  }

  @override
  void addPolygon(List<ui.Offset> points, bool close) {
    throw 'addPolygon';
  }

  @override
  void addRRect(ui.RRect rrect) {
    final js.JsObject skRect = _makeSkRect(rrect.outerRect);
    final List<num> radii = <num>[
      rrect.tlRadiusX,
      rrect.tlRadiusY,
      rrect.trRadiusX,
      rrect.trRadiusY,
      rrect.brRadiusX,
      rrect.brRadiusY,
      rrect.blRadiusX,
      rrect.blRadiusY,
    ];
    _skPath.callMethod('addRoundRect', <dynamic>[skRect, radii]);
  }

  @override
  void addRect(ui.Rect rect) {
    throw 'addRect';
  }

  @override
  void arcTo(
      ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    throw 'arcTo';
  }

  @override
  void arcToPoint(ui.Offset arcEnd,
      {ui.Radius radius = ui.Radius.zero,
      double rotation = 0.0,
      bool largeArc = false,
      bool clockwise = true}) {
    throw 'arcToPoint';
  }

  @override
  void close() {
    throw 'close';
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
    throw 'contains';
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    throw 'cubicTo';
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List matrix4}) {
    throw 'extendWithPath';
  }

  @override
  ui.Rect getBounds() {
    throw 'getBounds';
  }

  @override
  void lineTo(double x, double y) {
    throw 'lineTo';
  }

  @override
  void moveTo(double x, double y) {
    throw 'moveTo';
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    throw 'quadraticBezierTo';
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
    throw 'reset';
  }

  @override
  ui.Path shift(ui.Offset offset) {
    throw 'shift';
  }

  @override
  List<Subpath> get subpaths => throw 'subpaths';

  @override
  ui.Path transform(Float64List matrix4) {
    throw 'transform';
  }

  @override
  // TODO: implement webOnlyPathAsCircle
  Ellipse get webOnlyPathAsCircle => null;

  @override
  // TODO: implement webOnlyPathAsRect
  ui.Rect get webOnlyPathAsRect => null;

  @override
  // TODO: implement webOnlyPathAsRoundedRect
  ui.RRect get webOnlyPathAsRoundedRect => null;

  @override
  List webOnlySerializeToCssPaint() {
    // TODO: implement webOnlySerializeToCssPaint
    return null;
  }
}
