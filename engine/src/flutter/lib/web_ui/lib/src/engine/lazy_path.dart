// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

abstract class DisposablePath implements ui.Path {
  void dispose();
}

sealed class PathCommand {
  void apply(DisposablePath path);
}

final class MoveToCommand implements PathCommand {
  MoveToCommand(this.x, this.y);

  final double x;
  final double y;

  @override
  void apply(DisposablePath path) {
    path.moveTo(x, y);
  }
}

final class RelativeMoveToCommand implements PathCommand {
  RelativeMoveToCommand(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  void apply(DisposablePath path) {
    path.relativeMoveTo(dx, dy);
  }
}

final class LineToCommand implements PathCommand {
  LineToCommand(this.x, this.y);

  final double x;
  final double y;

  @override
  void apply(DisposablePath path) {
    path.lineTo(x, y);
  }
}

final class RelativeLineToCommand implements PathCommand {
  RelativeLineToCommand(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  void apply(DisposablePath path) {
    path.relativeLineTo(dx, dy);
  }
}

final class QuadraticBezierToCommand implements PathCommand {
  QuadraticBezierToCommand(this.x1, this.y1, this.x2, this.y2);

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  @override
  void apply(DisposablePath path) {
    path.quadraticBezierTo(x1, y1, x2, y2);
  }
}

final class RelativeQuadraticBezierToCommand implements PathCommand {
  RelativeQuadraticBezierToCommand(this.x1, this.y1, this.x2, this.y2);

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  @override
  void apply(DisposablePath path) {
    path.relativeQuadraticBezierTo(x1, y1, x2, y2);
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
  void apply(DisposablePath path) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
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
  void apply(DisposablePath path) {
    path.relativeCubicTo(x1, y1, x2, y2, x3, y3);
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
  void apply(DisposablePath path) {
    path.conicTo(x1, y1, x2, y2, w);
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
  void apply(DisposablePath path) {
    path.relativeConicTo(x1, y1, x2, y2, w);
  }
}

final class ArcToCommand implements PathCommand {
  ArcToCommand(this.rect, this.startAngle, this.sweepAngle, this.forceMoveTo);

  final ui.Rect rect;
  final double startAngle;
  final double sweepAngle;
  bool forceMoveTo;

  @override
  void apply(DisposablePath path) {
    path.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
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
  void apply(DisposablePath path) {
    path.arcToPoint(
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
  void apply(DisposablePath path) {
    path.relativeArcToPoint(
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
  void apply(DisposablePath path) {
    path.addRect(rect);
  }
}

final class AddOvalCommand implements PathCommand {
  AddOvalCommand(this.oval);

  final ui.Rect oval;

  @override
  void apply(DisposablePath path) {
    path.addOval(oval);
  }
}

final class AddArcCommand implements PathCommand {
  AddArcCommand(this.oval, this.startAngle, this.sweepAngle);

  final ui.Rect oval;
  final double startAngle;
  final double sweepAngle;

  @override
  void apply(DisposablePath path) {
    path.addArc(oval, startAngle, sweepAngle);
  }
}

final class AddPolygonCommand implements PathCommand {
  AddPolygonCommand(this.points, this.close);

  final List<ui.Offset> points;
  final bool close;

  @override
  void apply(DisposablePath path) {
    path.addPolygon(points, close);
  }
}

final class AddRRectCommand implements PathCommand {
  AddRRectCommand(this.rrect);

  final ui.RRect rrect;

  @override
  void apply(DisposablePath path) {
    path.addRRect(rrect);
  }
}

final class AddRSuperellipseCommand implements PathCommand {
  AddRSuperellipseCommand(this.rSuperellipse);

  final ui.RSuperellipse rSuperellipse;

  @override
  void apply(DisposablePath path) {
    path.addRSuperellipse(rSuperellipse);
  }
}

final class AddPathCommand implements PathCommand {
  AddPathCommand(this.path, this.offset, {this.matrix4});

  final LazyPath path;
  final ui.Offset offset;
  final Float64List? matrix4;

  @override
  void apply(DisposablePath p) {
    p.addPath(path.builtPath, offset, matrix4: matrix4);
  }
}

final class ExtendWithPathCommand implements PathCommand {
  ExtendWithPathCommand(this.path, this.offset, {this.matrix4});

  final LazyPath path;
  final ui.Offset offset;
  final Float64List? matrix4;

  @override
  void apply(DisposablePath p) {
    p.extendWithPath(path.builtPath, offset, matrix4: matrix4);
  }
}

final class ClosePathCommand implements PathCommand {
  @override
  void apply(DisposablePath path) {
    path.close();
  }
}

abstract class DisposablePathConstructors {
  DisposablePath createNew();
  DisposablePath combinePaths(
    ui.PathOperation operation,
    DisposablePath path1,
    DisposablePath path2,
  );
}

class LazyPath implements ui.Path, Collectable {
  factory LazyPath(DisposablePathConstructors constructors) =>
      LazyPath._(constructors, () => constructors.createNew());
  LazyPath._(this.constructors, this.initializer)
    : fillType = ui.PathFillType.nonZero,
      _commands = [];
  LazyPath.fromLazyPath(LazyPath other)
    : fillType = other.fillType,
      constructors = other.constructors,
      initializer = other.initializer,
      _commands = List.from(other._commands);
  factory LazyPath.shifted(LazyPath basePath, ui.Offset offset) {
    final pathCopy = LazyPath.fromLazyPath(basePath);
    return LazyPath._(
      pathCopy.constructors,
      () => pathCopy.builtPath.shift(offset) as DisposablePath,
    );
  }
  factory LazyPath.transformed(LazyPath basePath, Float64List matrix4) {
    final pathCopy = LazyPath.fromLazyPath(basePath);
    return LazyPath._(
      pathCopy.constructors,
      () => pathCopy.builtPath.transform(matrix4) as DisposablePath,
    );
  }
  factory LazyPath.combined(ui.PathOperation operation, LazyPath path1, LazyPath path2) {
    final pathCopy1 = LazyPath.fromLazyPath(path1);
    final pathCopy2 = LazyPath.fromLazyPath(path2);
    return LazyPath._(
      pathCopy1.constructors,
      () =>
          pathCopy1.constructors.combinePaths(operation, pathCopy1.builtPath, pathCopy2.builtPath),
    );
  }

  DisposablePathConstructors constructors;
  DisposablePath Function() initializer;

  @override
  ui.PathFillType fillType;

  DisposablePath? _cachedPath;
  final List<PathCommand> _commands;

  DisposablePath get builtPath {
    if (_cachedPath != null) {
      return _cachedPath!;
    }
    final DisposablePath path = initializer();
    for (final command in _commands) {
      command.apply(path);
    }

    _cachedPath = path;
    renderer.frameArena.add(this);
    return path;
  }

  void _addCommand(PathCommand command) {
    _commands.add(command);
    if (_cachedPath != null) {
      command.apply(_cachedPath!);
    }
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
    _addCommand(AddPathCommand(path as LazyPath, offset));
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    _addCommand(ExtendWithPathCommand(path as LazyPath, offset));
  }

  @override
  void close() {
    _addCommand(ClosePathCommand());
  }

  @override
  void reset() {
    _commands.clear();
    fillType = ui.PathFillType.nonZero;
    _cachedPath?.dispose();
    initializer = constructors.createNew;
  }

  @override
  bool contains(ui.Offset point) {
    return builtPath.contains(point);
  }

  @override
  ui.Path shift(ui.Offset offset) {
    return LazyPath.shifted(this, offset);
  }

  @override
  ui.Path transform(Float64List matrix4) {
    return LazyPath.transformed(this, matrix4);
  }

  @override
  ui.Rect getBounds() {
    return builtPath.getBounds();
  }

  @override
  ui.PathMetrics computeMetrics({bool forceClosed = false}) {
    return builtPath.computeMetrics(forceClosed: forceClosed);
  }

  @override
  void collect() {
    _cachedPath?.dispose();
    _cachedPath = null;
  }
}
