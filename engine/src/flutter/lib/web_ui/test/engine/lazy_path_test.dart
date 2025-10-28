// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class FakePath implements DisposablePath {
  int _apiCallCount = 0;

  int get apiCallCount => _apiCallCount;

  bool isDisposed = false;

  final List<FakePathMetrics> computedMetrics = [];

  @override
  void dispose() {
    isDisposed = true;
  }

  @override
  PathFillType fillType = PathFillType.nonZero;

  @override
  void moveTo(double x, double y) {
    _apiCallCount++;
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    _apiCallCount++;
  }

  @override
  void lineTo(double x, double y) {
    _apiCallCount++;
  }

  @override
  void relativeLineTo(double dx, double dy) {
    _apiCallCount++;
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _apiCallCount++;
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _apiCallCount++;
  }

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _apiCallCount++;
  }

  @override
  void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _apiCallCount++;
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    _apiCallCount++;
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    _apiCallCount++;
  }

  @override
  void arcTo(Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    _apiCallCount++;
  }

  @override
  void arcToPoint(
    Offset arcEnd, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    _apiCallCount++;
  }

  @override
  void relativeArcToPoint(
    Offset arcEndDelta, {
    Radius radius = Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    _apiCallCount++;
  }

  @override
  void addRect(Rect rect) {
    _apiCallCount++;
  }

  @override
  void addOval(Rect oval) {
    _apiCallCount++;
  }

  @override
  void addArc(Rect oval, double startAngle, double sweepAngle) {
    _apiCallCount++;
  }

  @override
  void addPolygon(List<Offset> points, bool close) {
    _apiCallCount++;
  }

  @override
  void addRRect(RRect rrect) {
    _apiCallCount++;
  }

  @override
  void addRSuperellipse(RSuperellipse rsuperellipse) {
    _apiCallCount++;
  }

  @override
  void addPath(Path path, Offset offset, {Float64List? matrix4}) {
    _apiCallCount++;
  }

  @override
  void extendWithPath(Path path, Offset offset, {Float64List? matrix4}) {
    _apiCallCount++;
  }

  @override
  void close() {
    _apiCallCount++;
  }

  @override
  void reset() {
    _apiCallCount++;
  }

  @override
  bool contains(Offset point) {
    return false;
  }

  @override
  Path shift(Offset offset) {
    return this;
  }

  @override
  Path transform(Float64List matrix4) {
    return this;
  }

  @override
  Rect getBounds() {
    return Rect.zero;
  }

  @override
  FakePathMetrics computeMetrics({bool forceClosed = false}) {
    final metrics = FakePathMetrics();
    computedMetrics.add(metrics);
    return metrics;
  }

  @override
  String toSvgString() {
    return '';
  }
}

class FakePathMetrics extends IterableBase<PathMetric> implements DisposablePathMetrics {
  @override
  final FakePathMetricsIterator iterator = FakePathMetricsIterator();
}

class FakePathMetricsIterator implements DisposablePathMetricIterator {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
  }

  @override
  bool moveNext() {
    return false;
  }

  @override
  Never get current {
    throw RangeError('nope');
  }
}

class FakePathConstructors implements DisposablePathConstructors {
  final List<FakePath> createdPaths = [];

  @override
  FakePath createNew() {
    final path = FakePath();
    createdPaths.add(path);
    return path;
  }

  @override
  FakePath combinePaths(PathOperation operation, DisposablePath path1, DisposablePath path2) {
    final path = FakePath();
    createdPaths.add(path);
    return path;
  }
}

void testMain() {
  test('LazyPath lifecycle', () {
    final constructors = FakePathConstructors();
    final LazyPath path = LazyPath(constructors);
    expect(constructors.createdPaths, isEmpty);

    path.moveTo(0, 0);
    path.relativeMoveTo(0, 0);
    path.lineTo(0, 0);
    path.relativeLineTo(0, 0);
    path.quadraticBezierTo(0, 0, 0, 0);
    path.relativeQuadraticBezierTo(0, 0, 0, 0);
    path.cubicTo(0, 0, 0, 0, 0, 0);
    path.relativeCubicTo(0, 0, 0, 0, 0, 0);
    path.conicTo(0, 0, 0, 0, 0);
    path.relativeConicTo(0, 0, 0, 0, 0);
    path.arcTo(Rect.zero, 0, 0, false);
    path.arcToPoint(Offset.zero);
    path.relativeArcToPoint(Offset.zero);
    path.addRect(Rect.zero);
    path.addOval(Rect.zero);
    path.addArc(Rect.zero, 0, 0);
    path.addPolygon([], false);
    path.addRRect(RRect.zero);
    path.addRSuperellipse(RSuperellipse.zero);
    path.close();

    expect(constructors.createdPaths, isEmpty);

    path.getBounds();

    expect(constructors.createdPaths.length, 1);
    final disposablePath = constructors.createdPaths.first;

    expect(disposablePath.isDisposed, false);
    expect(disposablePath.apiCallCount, 20);

    final metrics = path.computeMetrics();
    expect(metrics.iterator.moveNext(), false);
    expect(disposablePath.computedMetrics.length, 1);
    final disposableMetrics = disposablePath.computedMetrics.first;
    expect(disposableMetrics.iterator.isDisposed, false);

    EnginePlatformDispatcher.instance.frameArena.collect();

    expect(constructors.createdPaths.length, 1);
    expect(disposablePath.isDisposed, true);
    expect(disposablePath.computedMetrics.length, 1);
    expect(disposableMetrics.iterator.isDisposed, true);

    path.getBounds();

    expect(constructors.createdPaths.length, 2);
    final resurrectedPath = constructors.createdPaths.last;

    expect(resurrectedPath.isDisposed, false);
    expect(resurrectedPath.apiCallCount, 20);
    expect(metrics.iterator.moveNext(), false);

    EnginePlatformDispatcher.instance.frameArena.collect();
  });
}
