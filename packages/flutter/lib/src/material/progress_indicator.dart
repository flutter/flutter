// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';
import 'theme.dart';

const double _kLinearProgressIndicatorHeight = 6.0;
const double _kMinCircularProgressIndicatorSize = 36.0;

// TODO(hansmuller): implement the support for buffer indicator

/// A base class for material design progress indicators.
///
/// This widget cannot be instantiated directly. For a linear progress
/// indicator, see [LinearProgressIndicator]. For a circular progress indicator,
/// see [CircularProgressIndicator].
///
/// See also:
///
///  * <https://material.google.com/components/progress-activity.html>
abstract class ProgressIndicator extends StatefulWidget {
  /// Creates a progress indicator.
  ///
  /// The [value] argument can be either null (corresponding to an indeterminate
  /// progress indicator) or non-null (corresponding to a determinate progress
  /// indicator). See [value] for details.
  const ProgressIndicator({
    Key key,
    this.value,
    this.backgroundColor,
    this.valueColor,
  }) : super(key: key);

  /// If non-null, the value of this progress indicator with 0.0 corresponding
  /// to no progress having been made and 1.0 corresponding to all the progress
  /// having been made.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicator how
  /// much actual progress is being made.
  final double value;

  /// The progress indicator's background color. The current theme's
  /// [ThemeData.backgroundColor] by default.
  final Color backgroundColor;

  /// The indicator's color is the animation's value. To specify a constant
  /// color use: `new AlwaysStoppedAnimation<Color>(color)`.
  ///
  /// If null, the progress indicator is rendered with the current theme's
  /// [ThemeData.accentColor].
  final Animation<Color> valueColor;

  Color _getBackgroundColor(BuildContext context) => backgroundColor ?? Theme.of(context).backgroundColor;
  Color _getValueColor(BuildContext context) => valueColor?.value ?? Theme.of(context).accentColor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new PercentProperty('value', value, showName: false, ifNull: '<indeterminate>'));
  }
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    this.backgroundColor,
    this.valueColor,
    this.value,
    this.animationValue,
    @required this.textDirection,
  }) : assert(textDirection != null);

  final Color backgroundColor;
  final Color valueColor;
  final double value;
  final double animationValue;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = valueColor;
    if (value != null) {
      final double width = value.clamp(0.0, 1.0) * size.width;

      double left;
      switch (textDirection) {
        case TextDirection.rtl:
          left = size.width - width;
          break;
        case TextDirection.ltr:
          left = 0.0;
          break;
      }

      canvas.drawRect(new Offset(left, 0.0) & new Size(width, size.height), paint);
    } else {
      final double startX = size.width * (1.5 * animationValue - 0.5);
      final double endX = startX + 0.5 * size.width;
      final double x = startX.clamp(0.0, size.width);
      final double width = endX.clamp(0.0, size.width) - x;

      double left;
      switch (textDirection) {
        case TextDirection.rtl:
          left = size.width - width - x;
          break;
        case TextDirection.ltr:
          left = x;
          break;
      }

      canvas.drawRect(new Offset(left, 0.0) & new Size(width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_LinearProgressIndicatorPainter oldPainter) {
    return oldPainter.backgroundColor != backgroundColor
        || oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.animationValue != animationValue
        || oldPainter.textDirection != textDirection;
  }
}

/// A material design linear progress indicator, also known as a progress bar.
///
/// A widget that shows progress along a line. There are two kinds of linear
/// progress indicators:
///
///  * _Determinate_. Determinate progress indicators have a specific value at
///    each point in time, and the value should increase monotonically from 0.0
///    to 1.0, at which time the indicator is complete. To create a determinate
///    progress indicator, use a non-null [value] between 0.0 and 1.0.
///  * _Indeterminate_. Indeterminate progress indicators do not have a specific
///    value at each point in time and instead indicate that progress is being
///    made without indicating how much progress remains. To create an
///    indeterminate progress indicator, use a null [value].
///
/// See also:
///
///  * [CircularProgressIndicator]
///  * <https://material.google.com/components/progress-activity.html#progress-activity-types-of-indicators>
class LinearProgressIndicator extends ProgressIndicator {
  /// Creates a linear progress indicator.
  ///
  /// The [value] argument can be either null (corresponding to an indeterminate
  /// progress indicator) or non-null (corresponding to a determinate progress
  /// indicator). See [value] for details.
  const LinearProgressIndicator({
    Key key,
    double value,
    Color backgroundColor,
    Animation<Color> valueColor,
  }) : super(key: key, value: value, backgroundColor: backgroundColor, valueColor: valueColor);

  @override
  _LinearProgressIndicatorState createState() => new _LinearProgressIndicatorState();
}

class _LinearProgressIndicatorState extends State<LinearProgressIndicator> with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = new CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

    if (widget.value == null)
      _controller.repeat();
  }

  @override
  void didUpdateWidget(LinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating)
      _controller.repeat();
    else if (widget.value != null && _controller.isAnimating)
      _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(BuildContext context, double animationValue, TextDirection textDirection) {
    return new Container(
      constraints: const BoxConstraints.tightFor(
        width: double.infinity,
        height: _kLinearProgressIndicatorHeight,
      ),
      child: new CustomPaint(
        painter: new _LinearProgressIndicatorPainter(
          backgroundColor: widget._getBackgroundColor(context),
          valueColor: widget._getValueColor(context),
          value: widget.value, // may be null
          animationValue: animationValue, // ignored if widget.value is not null
          textDirection: textDirection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    if (widget.value != null)
      return _buildIndicator(context, _animation.value, textDirection);

    return new AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget child) {
        return _buildIndicator(context, _animation.value, textDirection);
      },
    );
  }
}

class _CircularProgressIndicatorPainter extends CustomPainter {
  static const double _kTwoPI = math.pi * 2.0;
  static const double _kEpsilon = .001;
  // Canvas.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const double _kSweep = _kTwoPI - _kEpsilon;
  static const double _kStartAngle = -math.pi / 2.0;

  _CircularProgressIndicatorPainter({
    this.valueColor,
    this.value,
    this.headValue,
    this.tailValue,
    this.stepValue,
    this.rotationValue,
    this.strokeWidth,
  }) : arcStart = value != null
         ? _kStartAngle
         : _kStartAngle + tailValue * 3 / 2 * math.pi + rotationValue * math.pi * 1.7 - stepValue * 0.8 * math.pi,
       arcSweep = value != null
         ? value.clamp(0.0, 1.0) * _kSweep
         : math.max(headValue * 3 / 2 * math.pi - tailValue * 3 / 2 * math.pi, _kEpsilon);

  final Color valueColor;
  final double value;
  final double headValue;
  final double tailValue;
  final int stepValue;
  final double rotationValue;
  final double strokeWidth;
  final double arcStart;
  final double arcSweep;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (value == null) // Indeterminate
      paint.strokeCap = StrokeCap.square;

    canvas.drawArc(Offset.zero & size, arcStart, arcSweep, false, paint);
  }

  @override
  bool shouldRepaint(_CircularProgressIndicatorPainter oldPainter) {
    return oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.headValue != headValue
        || oldPainter.tailValue != tailValue
        || oldPainter.stepValue != stepValue
        || oldPainter.rotationValue != rotationValue
        || oldPainter.strokeWidth != strokeWidth;
  }
}

/// A material design circular progress indicator, which spins to indicate that
/// the application is busy.
///
/// A widget that shows progress along a circle. There are two kinds of circular
/// progress indicators:
///
///  * _Determinate_. Determinate progress indicators have a specific value at
///    each point in time, and the value should increase monotonically from 0.0
///    to 1.0, at which time the indicator is complete. To create a determinate
///    progress indicator, use a non-null [value] between 0.0 and 1.0.
///  * _Indeterminate_. Indeterminate progress indicators do not have a specific
///    value at each point in time and instead indicate that progress is being
///    made without indicating how much progress remains. To create an
///    indeterminate progress indicator, use a null [value].
///
/// See also:
///
///  * [LinearProgressIndicator]
///  * <https://material.google.com/components/progress-activity.html#progress-activity-types-of-indicators>
class CircularProgressIndicator extends ProgressIndicator {
  /// Creates a circular progress indicator.
  ///
  /// The [value] argument can be either null (corresponding to an indeterminate
  /// progress indicator) or non-null (corresponding to a determinate progress
  /// indicator). See [value] for details.
  const CircularProgressIndicator({
    Key key,
    double value,
    Color backgroundColor,
    Animation<Color> valueColor,
    this.strokeWidth: 4.0,
  }) : super(key: key, value: value, backgroundColor: backgroundColor, valueColor: valueColor);

  /// The width of the line used to draw the circle.
  final double strokeWidth;

  @override
  _CircularProgressIndicatorState createState() => new _CircularProgressIndicatorState();
}

// Tweens used by circular progress indicator
final Animatable<double> _kStrokeHeadTween = new CurveTween(
  curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
).chain(new CurveTween(
  curve: const SawTooth(5),
));

final Animatable<double> _kStrokeTailTween = new CurveTween(
  curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
).chain(new CurveTween(
  curve: const SawTooth(5),
));

final Animatable<int> _kStepTween = new StepTween(begin: 0, end: 5);

final Animatable<double> _kRotationTween = new CurveTween(curve: const SawTooth(5));

class _CircularProgressIndicatorState extends State<CircularProgressIndicator> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 6666),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(BuildContext context, double headValue, double tailValue, int stepValue, double rotationValue) {
    return new Container(
      constraints: const BoxConstraints(
        minWidth: _kMinCircularProgressIndicatorSize,
        minHeight: _kMinCircularProgressIndicatorSize,
      ),
      child: new CustomPaint(
        painter: new _CircularProgressIndicatorPainter(
          valueColor: widget._getValueColor(context),
          value: widget.value, // may be null
          headValue: headValue, // remaining arguments are ignored if widget.value is not null
          tailValue: tailValue,
          stepValue: stepValue,
          rotationValue: rotationValue,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return new AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        return _buildIndicator(
          context,
          _kStrokeHeadTween.evaluate(_controller),
          _kStrokeTailTween.evaluate(_controller),
          _kStepTween.evaluate(_controller),
          _kRotationTween.evaluate(_controller),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null)
      return _buildIndicator(context, 0.0, 0.0, 0, 0.0);
    return _buildAnimation();
  }
}

class _RefreshProgressIndicatorPainter extends _CircularProgressIndicatorPainter {
  _RefreshProgressIndicatorPainter({
    Color valueColor,
    double value,
    double headValue,
    double tailValue,
    int stepValue,
    double rotationValue,
    double strokeWidth,
    this.arrowheadScale,
  }) : super(
    valueColor: valueColor,
    value: value,
    headValue: headValue,
    tailValue: tailValue,
    stepValue: stepValue,
    rotationValue: rotationValue,
    strokeWidth: strokeWidth,
  );

  final double arrowheadScale;

  void paintArrowhead(Canvas canvas, Size size) {
    // ux, uy: a unit vector whose direction parallels the base of the arrowhead.
    // Note that ux, -uy points in the direction the arrowhead points.
    final double arcEnd = arcStart + arcSweep;
    final double ux = math.cos(arcEnd);
    final double uy = math.sin(arcEnd);

    assert(size.width == size.height);
    final double radius = size.width / 2.0;
    final double arrowheadPointX = radius + ux * radius + -uy * strokeWidth * 2.0 * arrowheadScale;
    final double arrowheadPointY = radius + uy * radius +  ux * strokeWidth * 2.0 * arrowheadScale;
    final double arrowheadRadius = strokeWidth * 1.5 * arrowheadScale;
    final double innerRadius = radius - arrowheadRadius;
    final double outerRadius = radius + arrowheadRadius;

    final Path path = new Path()
      ..moveTo(radius + ux * innerRadius, radius + uy * innerRadius)
      ..lineTo(radius + ux * outerRadius, radius + uy * outerRadius)
      ..lineTo(arrowheadPointX, arrowheadPointY)
      ..close();
    final Paint paint = new Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    if (arrowheadScale > 0.0)
      paintArrowhead(canvas, size);
  }
}

/// An indicator for the progress of refreshing the contents of a widget.
///
/// Typically used for swipe-to-refresh interactions. See [RefreshIndicator] for
/// a complete implementation of swipe-to-refresh driven by a [Scrollable]
/// widget.
///
/// See also:
///
///  * [RefreshIndicator]
class RefreshProgressIndicator extends CircularProgressIndicator {
  /// Creates a refresh progress indicator.
  ///
  /// Rather than creating a refresh progress indicator directly, consider using
  /// a [RefreshIndicator] together with a [Scrollable] widget.
  const RefreshProgressIndicator({
    Key key,
    double value,
    Color backgroundColor,
    Animation<Color> valueColor,
    double strokeWidth: 2.0, // Different default than CircularProgressIndicator.
  }) : super(
    key: key,
    value: value,
    backgroundColor: backgroundColor,
    valueColor: valueColor,
    strokeWidth: strokeWidth,
  );

  @override
  _RefreshProgressIndicatorState createState() => new _RefreshProgressIndicatorState();
}

class _RefreshProgressIndicatorState extends _CircularProgressIndicatorState {
  static const double _kIndicatorSize = 40.0;

  // Always show the indeterminate version of the circular progress indicator.
  // When value is non-null the sweep of the progress indicator arrow's arc
  // varies from 0 to about 270 degrees. When value is null the arrow animates
  // starting from wherever we left it.
  @override
  Widget build(BuildContext context) {
    if (widget.value != null)
      _controller.value = widget.value / 10.0;
    else
      _controller.forward();
    return _buildAnimation();
  }

  @override
  Widget _buildIndicator(BuildContext context, double headValue, double tailValue, int stepValue, double rotationValue) {
    final double arrowheadScale = widget.value == null ? 0.0 : (widget.value * 2.0).clamp(0.0, 1.0);
    return new Container(
      width: _kIndicatorSize,
      height: _kIndicatorSize,
      margin: const EdgeInsets.all(4.0), // accommodate the shadow
      child: new Material(
        type: MaterialType.circle,
        color: widget.backgroundColor ?? Theme.of(context).canvasColor,
        elevation: 2.0,
        child: new Padding(
          padding: const EdgeInsets.all(12.0),
          child: new CustomPaint(
            painter: new _RefreshProgressIndicatorPainter(
              valueColor: widget._getValueColor(context),
              value: null, // Draw the indeterminate progress indicator.
              headValue: headValue,
              tailValue: tailValue,
              stepValue: stepValue,
              rotationValue: rotationValue,
              strokeWidth: widget.strokeWidth,
              arrowheadScale: arrowheadScale,
            ),
          ),
        ),
      ),
    );
  }
}
