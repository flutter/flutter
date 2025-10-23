// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

abstract class DisposablePath {
  ui.PathFillType get fillType;
  bool contains(ui.Offset point);
  ui.Rect getBounds();
  DisposablePathMetricIterator getMetricsIterator({bool forceClosed = false});
  void dispose();

  // In order to properly clip platform views with paths, we need to be able to get a
  // string representation of them.
  String toSvgString();
}

abstract class DisposablePathBuilder {
  ui.PathFillType get fillType;
  set fillType(ui.PathFillType value);
  void moveTo(double x, double y);
  void relativeMoveTo(double dx, double dy);
  void lineTo(double x, double y);
  void relativeLineTo(double dx, double dy);
  void quadraticBezierTo(double x1, double y1, double x2, double y2);
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2);
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3);
  void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3);
  void conicTo(double x1, double y1, double x2, double y2, double w);
  void relativeConicTo(double x1, double y1, double x2, double y2, double w);
  void arcTo(ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo);
  void arcToPoint(
    ui.Offset arcEnd, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  });
  void relativeArcToPoint(
    ui.Offset arcEndDelta, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  });
  void addRect(ui.Rect rect);
  void addOval(ui.Rect oval);
  void addArc(ui.Rect oval, double startAngle, double sweepAngle);
  void addPolygon(List<ui.Offset> points, bool close);
  void addRRect(ui.RRect rrect);
  void addRSuperellipse(ui.RSuperellipse rsuperellipse);
  void shiftInPlace(ui.Offset offset);
  void transformInPlace(Float64List matrix4);
  void addPath(DisposablePath path, ui.Offset offset, {Float64List? matrix4});
  void extendWithPath(DisposablePath path, ui.Offset offset, {Float64List? matrix4});
  void close();
  void reset();
  bool contains(ui.Offset point);
  ui.Rect getBounds();

  DisposablePath build();
  void dispose();
}

abstract class DisposablePathMetricIterator implements Iterator<DisposablePathMetric> {
  @override
  DisposablePathMetric get current;

  void dispose();
}

abstract class DisposablePathMetrics {
  DisposablePathMetricIterator get iterator;
}

abstract class DisposablePathMetric {
  DisposablePath extractPath(double start, double end, {bool startWithMoveTo = true});
  ui.Tangent getTangentForOffset(double distance);
  bool get isClosed;
  double get length;
  void dispose();
}

sealed class PathCommand {
  void apply(DisposablePathBuilder path);
}

final class MoveToCommand implements PathCommand {
  MoveToCommand(this.x, this.y);

  final double x;
  final double y;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.moveTo(x, y);
  }
}

final class RelativeMoveToCommand implements PathCommand {
  RelativeMoveToCommand(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.relativeMoveTo(dx, dy);
  }
}

final class LineToCommand implements PathCommand {
  LineToCommand(this.x, this.y);

  final double x;
  final double y;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.lineTo(x, y);
  }
}

final class RelativeLineToCommand implements PathCommand {
  RelativeLineToCommand(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.relativeLineTo(dx, dy);
  }
}

final class QuadraticBezierToCommand implements PathCommand {
  QuadraticBezierToCommand(this.x1, this.y1, this.x2, this.y2);

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.quadraticBezierTo(x1, y1, x2, y2);
  }
}

final class RelativeQuadraticBezierToCommand implements PathCommand {
  RelativeQuadraticBezierToCommand(this.x1, this.y1, this.x2, this.y2);

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.relativeQuadraticBezierTo(x1, y1, x2, y2);
  }
}

final class CubicToCommand implements PathCommand {
  CubicToCommand(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x3;
  final double y3;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.cubicTo(x1, y1, x2, y2, x3, y3);
  }
}

final class RelativeCubicToCommand implements PathCommand {
  RelativeCubicToCommand(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x3;
  final double y3;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.relativeCubicTo(x1, y1, x2, y2, x3, y3);
  }
}

final class ConicToCommand implements PathCommand {
  ConicToCommand(this.x1, this.y1, this.x2, this.y2, this.w);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double w;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.conicTo(x1, y1, x2, y2, w);
  }
}

final class RelativeConicToCommand implements PathCommand {
  RelativeConicToCommand(this.x1, this.y1, this.x2, this.y2, this.w);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double w;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.relativeConicTo(x1, y1, x2, y2, w);
  }
}

final class ArcToCommand implements PathCommand {
  ArcToCommand(this.rect, this.startAngle, this.sweepAngle, this.forceMoveTo);

  final ui.Rect rect;
  final double startAngle;
  final double sweepAngle;
  bool forceMoveTo;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
  }
}

final class ArcToPointCommand implements PathCommand {
  ArcToPointCommand(
    this.arcEnd, {
    required this.radius,
    required this.rotation,
    required this.largeArc,
    required this.clockwise,
  });

  ui.Offset arcEnd;
  ui.Radius radius;
  double rotation;
  bool largeArc;
  bool clockwise;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.arcToPoint(
      arcEnd,
      radius: radius,
      rotation: rotation,
      largeArc: largeArc,
      clockwise: clockwise,
    );
  }
}

final class RelativeArcToPointCommand implements PathCommand {
  RelativeArcToPointCommand(
    this.arcEndDelta, {
    required this.radius,
    required this.rotation,
    required this.largeArc,
    required this.clockwise,
  });

  ui.Offset arcEndDelta;
  ui.Radius radius;
  double rotation;
  bool largeArc;
  bool clockwise;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.relativeArcToPoint(
      arcEndDelta,
      radius: radius,
      rotation: rotation,
      largeArc: largeArc,
      clockwise: clockwise,
    );
  }
}

final class AddRectCommand implements PathCommand {
  AddRectCommand(this.rect);

  final ui.Rect rect;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addRect(rect);
  }
}

final class AddOvalCommand implements PathCommand {
  AddOvalCommand(this.oval);

  final ui.Rect oval;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addOval(oval);
  }
}

final class AddArcCommand implements PathCommand {
  AddArcCommand(this.oval, this.startAngle, this.sweepAngle);

  final ui.Rect oval;
  final double startAngle;
  final double sweepAngle;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addArc(oval, startAngle, sweepAngle);
  }
}

final class AddPolygonCommand implements PathCommand {
  AddPolygonCommand(this.points, this.close);

  final List<ui.Offset> points;
  final bool close;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addPolygon(points, close);
  }
}

final class AddRRectCommand implements PathCommand {
  AddRRectCommand(this.rrect);

  final ui.RRect rrect;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addRRect(rrect);
  }
}

final class AddRSuperellipseCommand implements PathCommand {
  AddRSuperellipseCommand(this.rSuperellipse);

  final ui.RSuperellipse rSuperellipse;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addRSuperellipse(rSuperellipse);
  }
}

final class ShiftInPlaceCommand implements PathCommand {
  ShiftInPlaceCommand(this.offset);

  final ui.Offset offset;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.shiftInPlace(offset);
  }
}

final class TransformInPlaceCommand implements PathCommand {
  TransformInPlaceCommand(this.matrix4);

  final Float64List matrix4;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.transformInPlace(matrix4);
  }
}

final class AddPathCommand implements PathCommand {
  AddPathCommand(this.path, this.offset, {this.matrix4});

  final LazyPath path;
  final ui.Offset offset;
  final Float64List? matrix4;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.addPath(path.builtPath, offset, matrix4: matrix4);
  }
}

final class ExtendWithPathCommand implements PathCommand {
  ExtendWithPathCommand(this.path, this.offset, {this.matrix4});

  final LazyPath path;
  final ui.Offset offset;
  final Float64List? matrix4;

  @override
  void apply(DisposablePathBuilder builder) {
    builder.extendWithPath(path.builtPath, offset, matrix4: matrix4);
  }
}

final class ClosePathCommand implements PathCommand {
  @override
  void apply(DisposablePathBuilder builder) {
    builder.close();
  }
}

abstract class DisposablePathConstructors {
  DisposablePathBuilder createNew();
  DisposablePathBuilder fromPath(DisposablePath path);
  DisposablePathBuilder combinePaths(
    ui.PathOperation operation,
    DisposablePath path1,
    DisposablePath path2,
  );
}

class LazyPath implements ui.Path, Collectable {
  factory LazyPath(DisposablePathConstructors constructors) =>
      LazyPath._(constructors, ui.PathFillType.nonZero, () => constructors.createNew());
  LazyPath._(this.constructors, this._fillType, this.initializer) : _commands = [];
  LazyPath.fromLazyPath(LazyPath other)
    : _fillType = other._fillType,
      constructors = other.constructors,
      initializer = other.initializer,
      _commands = List.from(other._commands);
  factory LazyPath.combined(ui.PathOperation operation, LazyPath path1, LazyPath path2) {
    final pathCopy1 = LazyPath.fromLazyPath(path1);
    final pathCopy2 = LazyPath.fromLazyPath(path2);
    return LazyPath._(
      pathCopy1.constructors,
      pathCopy1._fillType,
      () =>
          pathCopy1.constructors.combinePaths(operation, pathCopy1.builtPath, pathCopy2.builtPath),
    );
  }
  LazyPath extracted(
    LazyPathMetric pathMetric,
    double start,
    double end, {
    bool startWithMoveTo = true,
  }) {
    return LazyPath._(constructors, pathMetric.iterator.path._fillType, () {
      // The extracted path is only needed temporarily to create the path builder. It can be disposed
      // immediately after the path builder is created.
      final DisposablePath path = pathMetric.buildExtractedPath(
        start,
        end,
        startWithMoveTo: startWithMoveTo,
      );
      final DisposablePathBuilder pathBuilder = constructors.fromPath(path);
      path.dispose();
      return pathBuilder;
    });
  }

  DisposablePathConstructors constructors;
  DisposablePathBuilder Function() initializer;

  ui.PathFillType _fillType;

  @override
  ui.PathFillType get fillType => _fillType;

  @override
  set fillType(ui.PathFillType fillType) {
    _fillType = fillType;
    _invalidateCachedPath();
  }

  DisposablePath? _cachedPath;
  final List<PathCommand> _commands;

  DisposablePath get builtPath {
    if (_cachedPath != null) {
      return _cachedPath!;
    }

    final DisposablePathBuilder builder = _createPathBuilder();
    _cachedPath = builder.build();
    // Immediately dispose the builder as it's no longer needed.
    builder.dispose();

    EnginePlatformDispatcher.instance.frameArena.add(this);
    return _cachedPath!;
  }

  void _invalidateCachedPath() {
    _cachedPath?.dispose();
    _cachedPath = null;
  }

  /// Creates a [DisposablePathBuilder] and replays all recorded commands on it.
  DisposablePathBuilder _createPathBuilder() {
    final DisposablePathBuilder builder = initializer();
    builder.fillType = _fillType;
    for (final command in _commands) {
      command.apply(builder);
    }
    return builder;
  }

  void _addCommand(PathCommand command) {
    _commands.add(command);
    _invalidateCachedPath();
  }

  @override
  void moveTo(double x, double y) {
    _addCommand(MoveToCommand(x, y));
  }

  @override
  void relativeMoveTo(double dx, double dy) {
    _addCommand(RelativeMoveToCommand(dx, dy));
  }

  @override
  void lineTo(double x, double y) {
    _addCommand(LineToCommand(x, y));
  }

  @override
  void relativeLineTo(double dx, double dy) {
    _addCommand(RelativeLineToCommand(dx, dy));
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    _addCommand(QuadraticBezierToCommand(x1, y1, x2, y2));
  }

  @override
  void relativeQuadraticBezierTo(double x1, double y1, double x2, double y2) {
    _addCommand(RelativeQuadraticBezierToCommand(x1, y1, x2, y2));
  }

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _addCommand(CubicToCommand(x1, y1, x2, y2, x3, y3));
  }

  @override
  void relativeCubicTo(double x1, double y1, double x2, double y2, double x3, double y3) {
    _addCommand(RelativeCubicToCommand(x1, y1, x2, y2, x3, y3));
  }

  @override
  void conicTo(double x1, double y1, double x2, double y2, double w) {
    _addCommand(ConicToCommand(x1, y1, x2, y2, w));
  }

  @override
  void relativeConicTo(double x1, double y1, double x2, double y2, double w) {
    _addCommand(RelativeConicToCommand(x1, y1, x2, y2, w));
  }

  @override
  void arcTo(ui.Rect rect, double startAngle, double sweepAngle, bool forceMoveTo) {
    _addCommand(ArcToCommand(rect, startAngle, sweepAngle, forceMoveTo));
  }

  @override
  void arcToPoint(
    ui.Offset arcEnd, {
    ui.Radius radius = ui.Radius.zero,
    double rotation = 0.0,
    bool largeArc = false,
    bool clockwise = true,
  }) {
    _addCommand(
      ArcToPointCommand(
        arcEnd,
        radius: radius,
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise,
      ),
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
    _addCommand(
      RelativeArcToPointCommand(
        arcEndDelta,
        radius: radius,
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise,
      ),
    );
  }

  @override
  void addRect(ui.Rect rect) {
    _addCommand(AddRectCommand(rect));
  }

  @override
  void addOval(ui.Rect oval) {
    _addCommand(AddOvalCommand(oval));
  }

  @override
  void addArc(ui.Rect oval, double startAngle, double sweepAngle) {
    _addCommand(AddArcCommand(oval, startAngle, sweepAngle));
  }

  @override
  void addPolygon(List<ui.Offset> points, bool close) {
    _addCommand(AddPolygonCommand(points, close));
  }

  @override
  void addRRect(ui.RRect rrect) {
    _addCommand(AddRRectCommand(rrect));
  }

  @override
  void addRSuperellipse(ui.RSuperellipse rSuperellipse) {
    _addCommand(AddRSuperellipseCommand(rSuperellipse));
  }

  @override
  void addPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    // TODO(jacksongardner): Shouldn't we store a copy of `path` here? The `path` may change between
    //                       now and when this command is executed later.
    _addCommand(AddPathCommand(path as LazyPath, offset, matrix4: matrix4));
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    // TODO(jacksongardner): Shouldn't we store a copy of `path` here? The `path` may change between
    //                       now and when this command is executed later.
    _addCommand(ExtendWithPathCommand(path as LazyPath, offset, matrix4: matrix4));
  }

  @override
  void close() {
    _addCommand(ClosePathCommand());
  }

  @override
  void reset() {
    _commands.clear();
    _fillType = ui.PathFillType.nonZero;
    _cachedPath?.dispose();
    _cachedPath = null;
    initializer = constructors.createNew;
  }

  @override
  bool contains(ui.Offset point) {
    // TODO: Can be done without creating the path. Creating the path builder is enough.
    return builtPath.contains(point);
  }

  @override
  LazyPath shift(ui.Offset offset) {
    return LazyPath.fromLazyPath(this).._shiftInPlace(offset);
  }

  void _shiftInPlace(ui.Offset offset) {
    _addCommand(ShiftInPlaceCommand(offset));
  }

  @override
  ui.Path transform(Float64List matrix4) {
    return LazyPath.fromLazyPath(this).._transformInPlace(matrix4);
  }

  void _transformInPlace(Float64List matrix4) {
    _addCommand(TransformInPlaceCommand(matrix4));
  }

  @override
  ui.Rect getBounds() {
    // TODO: Can be done without creating the path. Creating the path builder is enough.
    return builtPath.getBounds();
  }

  @override
  LazyPathMetrics computeMetrics({bool forceClosed = false}) {
    return LazyPathMetrics(path: this, forceClosed: forceClosed);
  }

  @override
  void collect() {
    dispose();
  }

  void dispose() {
    _cachedPath?.dispose();
    _cachedPath = null;
  }

  // String toSvgString() {
  //   return builtPath.toSvgString();
  // }
}

class LazyPathMetrics extends IterableBase<ui.PathMetric> implements ui.PathMetrics {
  LazyPathMetrics({required LazyPath path, required bool forceClosed})
    : iterator = LazyPathMetricIterator(path, forceClosed);

  @override
  final LazyPathMetricIterator iterator;
}

class LazyPathMetricIterator implements Iterator<ui.PathMetric>, Collectable {
  LazyPathMetricIterator(this.path, this.forceClosed);

  final LazyPath path;
  final bool forceClosed;
  int _nextIndex = 0;
  DisposablePathMetricIterator? _cachedIterator;
  final List<DisposablePathMetric> _metrics = [];
  bool _isAtEnd = false;

  @override
  ui.PathMetric get current {
    if (_nextIndex == 0 || _isAtEnd) {
      throw RangeError(
        'PathMetricIterator is not pointing to a PathMetric. This can happen in two situations:\n'
        '- The iteration has not started yet. If so, call "moveNext" to start iteration.\n'
        '- The iterator ran out of elements. If so, check that "moveNext" returns true prior to calling "current".',
      );
    }
    return LazyPathMetric(this, _nextIndex - 1);
  }

  @override
  bool moveNext() {
    if (_isAtEnd) {
      return false;
    }
    buildIterator();
    assert(_cachedIterator != null);
    assert(_nextIndex == _metrics.length);
    _nextIndex++;
    if (_cachedIterator!.moveNext()) {
      _metrics.add(_cachedIterator!.current);
      return true;
    } else {
      _isAtEnd = true;
      return false;
    }
  }

  @override
  void collect() {
    _cachedIterator?.dispose();
    _cachedIterator = null;

    for (final metric in _metrics) {
      metric.dispose();
    }
    _metrics.clear();
  }

  void buildIterator() {
    if (_cachedIterator != null) {
      return;
    }
    _cachedIterator = path.builtPath.getMetricsIterator(forceClosed: forceClosed);
    for (int i = 0; i < _nextIndex; i++) {
      if (_cachedIterator!.moveNext()) {
        _metrics.add(_cachedIterator!.current);
      } else {
        break;
      }
    }
    EnginePlatformDispatcher.instance.frameArena.add(this);
  }

  DisposablePathMetric builtMetricAtIndex(int index) {
    buildIterator();
    return _metrics[index];
  }
}

class LazyPathMetric implements ui.PathMetric {
  LazyPathMetric(this.iterator, this.contourIndex);

  final LazyPathMetricIterator iterator;

  @override
  final int contourIndex;

  DisposablePathMetric get builtMetric => iterator.builtMetricAtIndex(contourIndex);

  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    return iterator.path.extracted(this, start, end, startWithMoveTo: startWithMoveTo);
  }

  DisposablePath buildExtractedPath(double start, double end, {required bool startWithMoveTo}) {
    return builtMetric.extractPath(start, end, startWithMoveTo: startWithMoveTo);
  }

  @override
  ui.Tangent? getTangentForOffset(double distance) {
    return builtMetric.getTangentForOffset(distance);
  }

  @override
  bool get isClosed => builtMetric.isClosed;

  @override
  double get length => builtMetric.length;
}
