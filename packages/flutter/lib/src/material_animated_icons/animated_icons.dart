// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of material_animated_icons;

// The code for drawing animated icons is kept in a private API, as we are not
// yet ready for exposing a public API for (partial) vector graphics support.
// See: https://github.com/flutter/flutter/issues/1831 for details regarding
// generic vector graphics support in Flutter.

/// Shows an animated icon at a given animation [progress].
///
/// The available icons are specified in [AnimatedIcons].
class AnimatedIcon extends AnimatedWidget {

  /// Creates an AnimatedIcon.
  ///
  /// [progress], [color], and [icon] cannot be null.
  const AnimatedIcon({
    Key key,
    @required Animation<double> progress,
    @required this.color,
    @required this.icon,
    this.semanticLabel,
    this.textDirection,
    // TODO(amirh): add a parameter for controlling scaling behavior.
  }) : assert(progress != null),
       assert(color != null),
       assert(icon != null),
       super(key: key, listenable: progress);

  /// The animation progress for the animated icon.
  /// The value is clamped to be between 0 and 1.
  ///
  /// This determines the actual frame that is displayed.
  Animation<double> get progress => listenable;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the current [IconTheme] color, if any.
  ///
  /// The given color will be adjusted by the opacity of the current
  /// [IconTheme], if any.
  ///
  /// If no [IconTheme]s are specified, icons will default to black.
  ///
  /// In material apps, if there is a [Theme] without any [IconTheme]s
  /// specified, icon colors default to white if the theme is dark
  /// and black if the theme is light.
  /// See [Theme] to set the current theme and [ThemeData.brightness]
  /// for setting the current theme's brightness.
  final Color color;

  /// The icon to display. Available icons are listed in [AnimatedIcons].
  final AnimatedIconData icon;

  /// Semantic label for the icon.
  ///
  /// This would be read out in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  ///
  /// See also:
  ///
  ///  * [Semantics.label], which is set to [semanticLabel] in the underlying
  ///    [Semantics] widget.
  final String semanticLabel;

  /// The text direction to use for rendering the icon.
  ///
  /// If this is null, the ambient [Directionality] is used instead.
  ///
  /// Some icons follow the reading direction. For example, "back" buttons point
  /// left in left-to-right environments and right in right-to-left
  /// environments. Such icons have their [IconData.matchTextDirection] field
  /// set to true, and the [Icon] widget uses the [textDirection] to determine
  /// the orientation in which to draw the icon.
  ///
  /// This property has no effect if the [icon]'s [IconData.matchTextDirection]
  /// field is false, but for consistency a text direction value must always be
  /// specified, either directly using this property or using [Directionality].
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    // TODO(amirh): implement semantics, text direction, scaling.
    final _AnimatedIconData iconData = icon;
    return new CustomPaint(
      size: iconData.size,
      painter: new _AnimatedIconPainter(
        iconData.paths,
        progress.value,
        color,
        () => new ui.Path(),
      ),
    );
  }
}

typedef ui.Path _UiPathFactory();

class _AnimatedIconPainter extends CustomPainter {
  final List<_PathFrames> paths;
  final double progress;
  final Color color;
  final _UiPathFactory uiPathFactory;

  const _AnimatedIconPainter(
    this.paths,
    this.progress,
    this.color,
    this.uiPathFactory
  );

  @override
  void paint(ui.Canvas canvas, Size size) {
    for (_PathFrames path in paths)
      path.paint(canvas, color, uiPathFactory, progress);
  }

  @override
  bool shouldRepaint(_AnimatedIconPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }

}

class _PathFrames {
  const _PathFrames({
    @required this.commands,
    @required this.opacities
  });

  final List<_PathCommand> commands;
  final List<double> opacities;

  void paint(ui.Canvas canvas, Color color, _UiPathFactory uiPathFactory, double progress) {
    final double opacity = _interpolate(opacities, progress, lerpDouble);
    final ui.Paint paint = new ui.Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(opacity);
    final ui.Path path = uiPathFactory();
    for (_PathCommand command in commands)
      command.apply(path, progress);
    canvas.drawPath(path, paint);
  }
}

abstract class _PathCommand {
  const _PathCommand();

  void apply(ui.Path path, double progress);
}

class _PathMoveTo extends _PathCommand {
  const _PathMoveTo(this.points);

  final List<Offset> points;

  @override
  void apply(Path path, double progress) {
    final Offset offset = _interpolate(points, progress, Offset.lerp);
    path.moveTo(offset.dx, offset.dy);
  }
}

class _PathCubicTo extends _PathCommand {
  const _PathCubicTo(this.controlPoints1, this.controlPoints2, this.targetPoints);

  final List<Offset> controlPoints2;
  final List<Offset> controlPoints1;
  final List<Offset> targetPoints;

  @override
  void apply(Path path, double progress) {
    final Offset controlPoint1 = _interpolate(controlPoints1, progress, Offset.lerp);
    final Offset controlPoint2 = _interpolate(controlPoints2, progress, Offset.lerp);
    final Offset targetPoint = _interpolate(targetPoints, progress, Offset.lerp);
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      targetPoint.dx, targetPoint.dy
    );
  }
}

class _PathLineTo extends _PathCommand {
  const _PathLineTo(this.points);

  final List<Offset> points;

  @override
  void apply(Path path, double progress) {
    final Offset point = _interpolate(points, progress, Offset.lerp);
    path.lineTo(point.dx, point.dy);
  }
}

class _PathClose extends _PathCommand {
  const _PathClose();

  @override
  void apply(Path path, double progress) {
    path.close();
  }
}

// Interpolates a value given a set of values equally spaced in time.
//
// [interpolator] is the interpolation function used to  interpolate between 2
// points of type T.
//
// This is currently done with linear interpolation between every 2 consecutive 
// points. Linear interpolation was smooth enough with the limited set of
// animations we have tested, so we use it for simplicity. If we find this to
// not be smooth enough we can try applying spline instead.
//
// [progress] must be between 0 and 1.
T _interpolate<T>(List<T> values, double progress, _Interpolator<T> interpolator) {
  assert(progress >= 0.0);
  assert(progress <= 1.0);
  if (values.length == 1)
    return values[0];
  final double targetIdx = lerpDouble(0, values.length -1, progress);
  final int lowIdx = targetIdx.floor();
  final int highIdx = targetIdx.ceil();
  final double t = targetIdx - lowIdx;
  return interpolator(values[lowIdx], values[highIdx], t);
}

typedef T _Interpolator<T>(T a, T b, double progress);
