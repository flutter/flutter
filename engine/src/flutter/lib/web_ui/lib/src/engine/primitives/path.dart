// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// A command that represents a path operation to be applied to a
/// [BackendPathBuilder].
sealed class PathCommand {
  /// Applies this path command to the given [builder].
  void apply(BackendPathBuilder builder);
}

/// A path command that moves the current point to ([x], [y]).
final class MoveToCommand implements PathCommand {
  /// Creates a [MoveToCommand] with the given [x] and [y] coordinates.
  MoveToCommand(this.x, this.y);

  /// The target x-coordinate.
  final double x;

  /// The target y-coordinate.
  final double y;

  @override
  void apply(BackendPathBuilder builder) {
    builder.moveTo(x, y);
  }
}

/// A path command that moves the current point by the relative offset ([dx], [dy]).
final class RelativeMoveToCommand implements PathCommand {
  /// Creates a [RelativeMoveToCommand] with the given [dx] and [dy] offsets.
  RelativeMoveToCommand(this.dx, this.dy);

  /// The horizontal offset.
  final double dx;

  /// The vertical offset.
  final double dy;

  @override
  void apply(BackendPathBuilder builder) {
    builder.relativeMoveTo(dx, dy);
  }
}

/// A path command that draws a straight line from the current point to ([x], [y]).
final class LineToCommand implements PathCommand {
  /// Creates a [LineToCommand] with the given [x] and [y] coordinates.
  LineToCommand(this.x, this.y);

  /// The target x-coordinate of the line.
  final double x;

  /// The target y-coordinate of the line.
  final double y;

  @override
  void apply(BackendPathBuilder builder) {
    builder.lineTo(x, y);
  }
}

/// A path command that draws a straight line from the current point to a point
/// shifted by ([dx], [dy]) relative to the current point.
final class RelativeLineToCommand implements PathCommand {
  /// Creates a [RelativeLineToCommand] with the given [dx] and [dy] offsets.
  RelativeLineToCommand(this.dx, this.dy);

  /// The relative horizontal offset of the line's end point.
  final double dx;

  /// The relative vertical offset of the line's end point.
  final double dy;

  @override
  void apply(BackendPathBuilder builder) {
    builder.relativeLineTo(dx, dy);
  }
}

/// A path command that draws a quadratic Bézier curve from the current point to
/// ([x2], [y2]) using the control point ([x1], [y1]).
final class QuadraticBezierToCommand implements PathCommand {
  /// Creates a [QuadraticBezierToCommand] with the control point ([x1], [y1])
  /// and end point ([x2], [y2]).
  QuadraticBezierToCommand(this.x1, this.y1, this.x2, this.y2);

  /// The x-coordinate of the control point.
  final double x1;

  /// The y-coordinate of the control point.
  final double y1;

  /// The x-coordinate of the end point.
  final double x2;

  /// The y-coordinate of the end point.
  final double y2;

  @override
  void apply(BackendPathBuilder builder) {
    builder.quadraticBezierTo(x1, y1, x2, y2);
  }
}

/// A path command that draws a quadratic Bézier curve from the current point
/// using a control point and end point at relative offsets ([x1], [y1]) and
/// ([x2], [y2]) from the current point.
final class RelativeQuadraticBezierToCommand implements PathCommand {
  /// Creates a [RelativeQuadraticBezierToCommand] with the relative control point
  /// ([x1], [y1]) and relative end point ([x2], [y2]).
  RelativeQuadraticBezierToCommand(this.x1, this.y1, this.x2, this.y2);

  /// The relative horizontal offset of the control point.
  final double x1;

  /// The relative vertical offset of the control point.
  final double y1;

  /// The relative horizontal offset of the end point.
  final double x2;

  /// The relative vertical offset of the end point.
  final double y2;

  @override
  void apply(BackendPathBuilder builder) {
    builder.relativeQuadraticBezierTo(x1, y1, x2, y2);
  }
}

/// A path command that draws a cubic Bézier curve from the current point to
/// ([x3], [y3]) using control points ([x1], [y1]) and ([x2], [y2]).
final class CubicToCommand implements PathCommand {
  /// Creates a [CubicToCommand] with control points ([x1], [y1]) and
  /// ([x2], [y2]) and end point ([x3], [y3]).
  CubicToCommand(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);

  /// The x-coordinate of the first control point.
  final double x1;

  /// The y-coordinate of the first control point.
  final double y1;

  /// The x-coordinate of the second control point.
  final double x2;

  /// The y-coordinate of the second control point.
  final double y2;

  /// The x-coordinate of the end point.
  final double x3;

  /// The y-coordinate of the end point.
  final double y3;

  @override
  void apply(BackendPathBuilder builder) {
    builder.cubicTo(x1, y1, x2, y2, x3, y3);
  }
}

/// A path command that draws a cubic Bézier curve from the current point
/// using control points and an end point at relative offsets ([x1], [y1]),
/// ([x2], [y2]), and ([x3], [y3]) from the current point.
final class RelativeCubicToCommand implements PathCommand {
  /// Creates a [RelativeCubicToCommand] with relative control points ([x1], [y1])
  /// and ([x2], [y2]) and a relative end point ([x3], [y3]).
  RelativeCubicToCommand(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3);

  /// The relative horizontal offset of the first control point.
  final double x1;

  /// The relative vertical offset of the first control point.
  final double y1;

  /// The relative horizontal offset of the second control point.
  final double x2;

  /// The relative vertical offset of the second control point.
  final double y2;

  /// The relative horizontal offset of the end point.
  final double x3;

  /// The relative vertical offset of the end point.
  final double y3;

  @override
  void apply(BackendPathBuilder builder) {
    builder.relativeCubicTo(x1, y1, x2, y2, x3, y3);
  }
}

/// A path command that draws a conic curve from the current point to ([x2], [y2])
/// with control point ([x1], [y1]) and weight [w].
final class ConicToCommand implements PathCommand {
  /// Creates a [ConicToCommand] with control point ([x1], [y1]), end point
  /// ([x2], [y2]), and weight [w].
  ConicToCommand(this.x1, this.y1, this.x2, this.y2, this.w);

  /// The x-coordinate of the control point.
  final double x1;

  /// The y-coordinate of the control point.
  final double y1;

  /// The x-coordinate of the end point.
  final double x2;

  /// The y-coordinate of the end point.
  final double y2;

  /// The weight of the conic curve.
  final double w;

  @override
  void apply(BackendPathBuilder builder) {
    builder.conicTo(x1, y1, x2, y2, w);
  }
}

/// A path command that draws a conic curve from the current point using control
/// point and end point at relative offsets ([x1], [y1]) and ([x2], [y2]) with
/// weight [w].
final class RelativeConicToCommand implements PathCommand {
  /// Creates a [RelativeConicToCommand] with relative control point ([x1], [y1]),
  /// relative end point ([x2], [y2]), and weight [w].
  RelativeConicToCommand(this.x1, this.y1, this.x2, this.y2, this.w);

  /// The relative horizontal offset of the control point.
  final double x1;

  /// The relative vertical offset of the control point.
  final double y1;

  /// The relative horizontal offset of the end point.
  final double x2;

  /// The relative vertical offset of the end point.
  final double y2;

  /// The weight of the conic curve.
  final double w;

  @override
  void apply(BackendPathBuilder builder) {
    builder.relativeConicTo(x1, y1, x2, y2, w);
  }
}

/// A path command that adds an arc of an ellipse defined by [rect] from
/// [startAngle] to [startAngle] + [sweepAngle].
final class ArcToCommand implements PathCommand {
  /// Creates an [ArcToCommand] with the bounding [rect], [startAngle] in radians,
  /// [sweepAngle] in radians, and a flag [forceMoveTo] to determine whether a
  /// line segment is added before the arc.
  ArcToCommand(this.rect, this.startAngle, this.sweepAngle, this.forceMoveTo);

  /// The bounding rectangle that defines the ellipse.
  final ui.Rect rect;

  /// The angle in radians where the arc starts.
  final double startAngle;

  /// The sweep of the arc in radians.
  final double sweepAngle;

  /// Whether to begin the arc with a move-to command rather than drawing a line
  /// to the start of the arc.
  final bool forceMoveTo;

  @override
  void apply(BackendPathBuilder builder) {
    builder.arcTo(rect, startAngle, sweepAngle, forceMoveTo);
  }
}

/// A path command that draws an arc from the current point to [arcEnd] with the
/// given [radius], [rotation], [largeArc], and [clockwise] parameters.
final class ArcToPointCommand implements PathCommand {
  /// Creates an [ArcToPointCommand] ending at [arcEnd] with the given [radius],
  /// [rotation] in radians, and flags for [largeArc] and [clockwise].
  ArcToPointCommand(
    this.arcEnd, {
    required this.radius,
    required this.rotation,
    required this.largeArc,
    required this.clockwise,
  });

  /// The target coordinates of the arc's end point.
  final ui.Offset arcEnd;

  /// The radii of the ellipse used to draw the arc.
  final ui.Radius radius;

  /// The rotation in radians of the ellipse's x-axis relative to the coordinate system.
  final double rotation;

  /// Whether to use the large arc alternative.
  final bool largeArc;

  /// Whether the arc should be drawn clockwise (positive angle sweep) or
  /// counter-clockwise (negative angle sweep).
  final bool clockwise;

  @override
  void apply(BackendPathBuilder builder) {
    builder.arcToPoint(
      arcEnd,
      radius: radius,
      rotation: rotation,
      largeArc: largeArc,
      clockwise: clockwise,
    );
  }
}

/// A path command that draws an arc from the current point to a point shifted
/// by [arcEndDelta] with the given [radius], [rotation], [largeArc], and
/// [clockwise] parameters.
final class RelativeArcToPointCommand implements PathCommand {
  /// Creates a [RelativeArcToPointCommand] ending at [arcEndDelta] offset from
  /// the current point, with the given [radius], [rotation] in radians, and
  /// flags for [largeArc] and [clockwise].
  RelativeArcToPointCommand(
    this.arcEndDelta, {
    required this.radius,
    required this.rotation,
    required this.largeArc,
    required this.clockwise,
  });

  /// The relative offset of the arc's end point.
  final ui.Offset arcEndDelta;

  /// The radii of the ellipse used to draw the arc.
  final ui.Radius radius;

  /// The rotation in radians of the ellipse's x-axis relative to the coordinate system.
  final double rotation;

  /// Whether to use the large arc alternative.
  final bool largeArc;

  /// Whether the arc should be drawn clockwise (positive angle sweep) or
  /// counter-clockwise (negative angle sweep).
  final bool clockwise;

  @override
  void apply(BackendPathBuilder builder) {
    builder.relativeArcToPoint(
      arcEndDelta,
      radius: radius,
      rotation: rotation,
      largeArc: largeArc,
      clockwise: clockwise,
    );
  }
}

/// A path command that adds a closed rectangle [rect] to the path.
final class AddRectCommand implements PathCommand {
  /// Creates an [AddRectCommand] with the given [rect].
  AddRectCommand(this.rect);

  /// The rectangle to add.
  final ui.Rect rect;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addRect(rect);
  }
}

/// A path command that adds a closed ellipse [oval] to the path.
final class AddOvalCommand implements PathCommand {
  /// Creates an [AddOvalCommand] with the given [oval].
  AddOvalCommand(this.oval);

  /// The bounding rectangle of the ellipse to add.
  final ui.Rect oval;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addOval(oval);
  }
}

/// A path command that adds an arc of the ellipse defined by [oval] from
/// [startAngle] to [startAngle] + [sweepAngle] as a new closed contour.
final class AddArcCommand implements PathCommand {
  /// Creates an [AddArcCommand] with the bounding [oval], [startAngle] in
  /// radians, and [sweepAngle] in radians.
  AddArcCommand(this.oval, this.startAngle, this.sweepAngle);

  /// The bounding rectangle of the ellipse defining the arc.
  final ui.Rect oval;

  /// The angle in radians where the arc starts.
  final double startAngle;

  /// The sweep of the arc in radians.
  final double sweepAngle;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addArc(oval, startAngle, sweepAngle);
  }
}

/// A path command that adds a polygon defined by [points] to the path.
final class AddPolygonCommand implements PathCommand {
  /// Creates an [AddPolygonCommand] with the given [points] and a flag [close]
  /// to determine whether to automatically close the polygon.
  AddPolygonCommand(List<ui.Offset> points, this.close) : points = List<ui.Offset>.of(points);

  /// The vertices of the polygon.
  final List<ui.Offset> points;

  /// Whether to close the polygon by drawing a line back to the first point.
  final bool close;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addPolygon(points, close);
  }
}

/// A path command that adds a rounded rectangle [rrect] to the path.
final class AddRRectCommand implements PathCommand {
  /// Creates an [AddRRectCommand] with the given [rrect].
  AddRRectCommand(this.rrect);

  /// The rounded rectangle to add.
  final ui.RRect rrect;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addRRect(rrect);
  }
}

/// A path command that adds a rounded superellipse [rSuperellipse] to the path.
final class AddRSuperellipseCommand implements PathCommand {
  /// Creates an [AddRSuperellipseCommand] with the given [rSuperellipse].
  AddRSuperellipseCommand(this.rSuperellipse);

  /// The rounded superellipse to add.
  final ui.RSuperellipse rSuperellipse;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addRSuperellipse(rSuperellipse);
  }
}

/// A path command that shifts all coordinates in the path by [offset] in-place.
final class ShiftInPlaceCommand implements PathCommand {
  /// Creates a [ShiftInPlaceCommand] with the given [offset].
  ShiftInPlaceCommand(this.offset);

  /// The offset by which to shift the path.
  final ui.Offset offset;

  @override
  void apply(BackendPathBuilder builder) {
    builder.shiftInPlace(offset);
  }
}

/// A path command that applies a 4x4 matrix transformation [matrix4] in-place.
final class TransformInPlaceCommand implements PathCommand {
  /// Creates a [TransformInPlaceCommand] with the given 4x4 [matrix4] transform.
  TransformInPlaceCommand(Float64List matrix4) : matrix4 = Float64List.fromList(matrix4);

  /// The 4x4 transformation matrix.
  final Float64List matrix4;

  @override
  void apply(BackendPathBuilder builder) {
    builder.transformInPlace(matrix4);
  }
}

/// A path command that appends another [path] shifted by [offset] to the path.
final class AddPathCommand implements PathCommand {
  /// Creates an [AddPathCommand] appending [path] at [offset], optionally
  /// transformed by [matrix4].
  AddPathCommand(this.path, this.offset, {Float64List? matrix4})
    : matrix4 = matrix4 != null ? Float64List.fromList(matrix4) : null;

  /// The path to append.
  final EnginePath path;

  /// The offset to apply to the appended path.
  final ui.Offset offset;

  /// The optional 4x4 transformation matrix.
  final Float64List? matrix4;

  @override
  void apply(BackendPathBuilder builder) {
    builder.addPath(path.backendPath, offset, matrix4: matrix4);
  }
}

/// A path command that extends the path with another [path] shifted by [offset].
final class ExtendWithPathCommand implements PathCommand {
  /// Creates an [ExtendWithPathCommand] extending this path with [path] at
  /// [offset], optionally transformed by [matrix4].
  ExtendWithPathCommand(this.path, this.offset, {Float64List? matrix4})
    : matrix4 = matrix4 != null ? Float64List.fromList(matrix4) : null;

  /// The path to extend this path with.
  final EnginePath path;

  /// The offset to apply to the extending path.
  final ui.Offset offset;

  /// The optional 4x4 transformation matrix.
  final Float64List? matrix4;

  @override
  void apply(BackendPathBuilder builder) {
    builder.extendWithPath(path.backendPath, offset, matrix4: matrix4);
  }
}

/// A path command that closes the current contour of the path.
final class ClosePathCommand implements PathCommand {
  @override
  void apply(BackendPathBuilder builder) {
    builder.close();
  }
}

/// A source tuple for combining paths, consisting of the [ui.PathOperation],
/// and the two source [EnginePath]s.
typedef PathCombineSource = (ui.PathOperation, EnginePath, EnginePath);

/// A source tuple for extracting a path segment, consisting of the
/// [EnginePathMetric], start distance, end distance, and whether to start
/// with a move-to command.
typedef PathExtractSource = (
  EnginePathMetric metric,
  double start,
  double end,
  bool startWithMoveTo,
);

/// An implementation of [ui.Path] used by the Web engine.
///
/// An [EnginePath] accumulates path commands and defers building the underlying
/// [backendPath] until it is needed for rendering, hit testing, or calculations.
class EnginePath implements ui.Path, Collectable {
  /// Creates an empty [EnginePath] using the specified [constructors].
  factory EnginePath(BackendPathConstructors constructors) =>
      EnginePath._(constructors, ui.PathFillType.nonZero, []);

  EnginePath._(
    this.constructors,
    this._fillType,
    this._commands, {
    PathCombineSource? combineSource,
    PathExtractSource? extractSource,
  }) : _combineSource = combineSource,
       _extractSource = extractSource;

  /// Creates a copy of [other] as a new [EnginePath].
  EnginePath.fromEnginePath(EnginePath other)
    : _fillType = other._fillType,
      constructors = other.constructors,
      _combineSource = other._combineSource,
      _extractSource = other._extractSource,
      _commands = List.from(other._commands);

  /// Creates an [EnginePath] by combining two other paths ([path1] and [path2])
  /// using the specified [operation].
  factory EnginePath.combined(ui.PathOperation operation, EnginePath path1, EnginePath path2) {
    final pathCopy1 = EnginePath.fromEnginePath(path1);
    final pathCopy2 = EnginePath.fromEnginePath(path2);
    return EnginePath._(
      pathCopy1.constructors,
      pathCopy1._fillType,
      [],
      combineSource: (operation, pathCopy1, pathCopy2),
    );
  }

  /// Creates an [EnginePath] by extracting a segment of another [path]
  /// defined by [metric] starting from [start] and ending at [end].
  ///
  /// If [startWithMoveTo] is true, the extracted segment will begin with a move-to command.
  factory EnginePath.extracted(
    EnginePath path,
    EnginePathMetric metric,
    double start,
    double end, {
    bool startWithMoveTo = true,
  }) {
    return EnginePath._(
      path.constructors,
      path._fillType,
      [],
      extractSource: (metric, start, end, startWithMoveTo),
    );
  }

  /// The constructors used to instantiate backend-specific path and builder implementations.
  BackendPathConstructors constructors;

  ui.PathFillType _fillType;

  @override
  ui.PathFillType get fillType => _fillType;

  @override
  set fillType(ui.PathFillType fillType) {
    _fillType = fillType;
    _cachedBuilder?.fillType = fillType;
    _invalidateCachedPath();
  }

  PathCombineSource? _combineSource;
  PathExtractSource? _extractSource;

  BackendPath? _cachedPath;
  BackendPathBuilder? _cachedBuilder;
  final List<PathCommand> _commands;

  BackendPathBuilder get _builtPathBuilder {
    assert(
      _combineSource == null || _extractSource == null,
      'An EnginePath cannot have both a combine source and an extract source.',
    );

    if (_cachedBuilder != null) {
      return _cachedBuilder!;
    }

    final BackendPathBuilder builder;
    if (_combineSource != null) {
      final (ui.PathOperation op, EnginePath path1, EnginePath path2) = _combineSource!;
      builder = constructors.combinePaths(op, path1.backendPath, path2.backendPath);
    } else if (_extractSource != null) {
      final (EnginePathMetric metric, double start, double end, bool startWithMoveTo) =
          _extractSource!;
      builder = metric.buildExtractedPath(start, end, startWithMoveTo: startWithMoveTo);
    } else {
      builder = constructors.createNew();
    }

    builder.fillType = _fillType;
    for (final PathCommand command in _commands) {
      command.apply(builder);
    }

    _cachedBuilder = builder;
    EnginePlatformDispatcher.instance.frameArena.add(this);
    return builder;
  }

  /// Returns the underlying [BackendPath] built from this path's commands.
  BackendPath get backendPath {
    _cachedPath ??= _builtPathBuilder.build();
    return _cachedPath!;
  }

  void _invalidateCachedPath() {
    _cachedPath?.dispose();
    _cachedPath = null;
  }

  void _addCommand(PathCommand command) {
    _commands.add(command);
    if (_cachedBuilder != null) {
      command.apply(_cachedBuilder!);
    }
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
    _addCommand(
      AddPathCommand(EnginePath.fromEnginePath(path as EnginePath), offset, matrix4: matrix4),
    );
  }

  @override
  void extendWithPath(ui.Path path, ui.Offset offset, {Float64List? matrix4}) {
    _addCommand(
      ExtendWithPathCommand(
        EnginePath.fromEnginePath(path as EnginePath),
        offset,
        matrix4: matrix4,
      ),
    );
  }

  @override
  void close() {
    _addCommand(ClosePathCommand());
  }

  @override
  void reset() {
    _commands.clear();
    _fillType = ui.PathFillType.nonZero;
    _combineSource = null;
    collect();
  }

  @override
  bool contains(ui.Offset point) {
    return _builtPathBuilder.contains(point);
  }

  @override
  EnginePath shift(ui.Offset offset) {
    return EnginePath.fromEnginePath(this).._shiftInPlace(offset);
  }

  void _shiftInPlace(ui.Offset offset) {
    _addCommand(ShiftInPlaceCommand(offset));
  }

  @override
  ui.Path transform(Float64List matrix4) {
    return EnginePath.fromEnginePath(this).._transformInPlace(matrix4);
  }

  void _transformInPlace(Float64List matrix4) {
    _addCommand(TransformInPlaceCommand(matrix4));
  }

  @override
  ui.Rect getBounds() {
    return _builtPathBuilder.getBounds();
  }

  @override
  EnginePathMetrics computeMetrics({bool forceClosed = false}) {
    return EnginePathMetrics(path: EnginePath.fromEnginePath(this), forceClosed: forceClosed);
  }

  @override
  void collect() {
    _cachedPath?.dispose();
    if (!identical(_cachedBuilder, _cachedPath)) {
      _cachedBuilder?.dispose();
    }
    _cachedPath = null;
    _cachedBuilder = null;
  }
}
