// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'material.dart';
import 'theme.dart';

const double _kMinCircularProgressIndicatorSize = 36.0;
const int _kIndeterminateLinearDuration = 1800;
const int _kIndeterminateCircularDuration = 1333 * 2222;

enum _ActivityIndicatorType { material, adaptive }

/// A base class for material design progress indicators.
///
/// This widget cannot be instantiated directly. For a linear progress
/// indicator, see [LinearProgressIndicator]. For a circular progress indicator,
/// see [CircularProgressIndicator].
///
/// See also:
///
///  * <https://material.io/design/components/progress-indicators.html>
abstract class ProgressIndicator extends StatefulWidget {
  /// Creates a progress indicator.
  ///
  /// {@template flutter.material.ProgressIndicator.ProgressIndicator}
  /// The [value] argument can either be null for an indeterminate
  /// progress indicator, or non-null for a determinate progress
  /// indicator.
  ///
  /// ## Accessibility
  ///
  /// The [semanticsLabel] can be used to identify the purpose of this progress
  /// bar for screen reading software. The [semanticsValue] property may be used
  /// for determinate progress indicators to indicate how much progress has been made.
  /// {@endtemplate}
  const ProgressIndicator({
    Key? key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
  }) : super(key: key);

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final double? value;

  /// The progress indicator's background color.
  ///
  /// The current theme's [ThemeData.backgroundColor] by default.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final Color? backgroundColor;

  /// The progress indicator's color as an animated value.
  ///
  /// To specify a constant color use: `AlwaysStoppedAnimation<Color>(color)`.
  ///
  /// If null, the progress indicator is rendered with the current theme's
  /// [ThemeData.accentColor].
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final Animation<Color?>? valueColor;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsLabel}
  /// The [SemanticsProperties.label] for this progress indicator.
  ///
  /// This value indicates the purpose of the progress bar, and will be
  /// read out by screen readers to indicate the purpose of this progress
  /// indicator.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  /// {@endtemplate}
  final String? semanticsLabel;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsValue}
  /// The [SemanticsProperties.value] for this progress indicator.
  ///
  /// This will be used in conjunction with the [semanticsLabel] by
  /// screen reading software to identify the widget, and is primarily
  /// intended for use with determinate progress indicators to announce
  /// how far along they are.
  ///
  /// For determinate progress indicators, this will be defaulted to
  /// [ProgressIndicator.value] expressed as a percentage, i.e. `0.1` will
  /// become '10%'.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  /// {@endtemplate}
  final String? semanticsValue;

  Color _getBackgroundColor(BuildContext context) => backgroundColor ?? Theme.of(context).backgroundColor;
  Color _getValueColor(BuildContext context) => valueColor?.value ?? Theme.of(context).accentColor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('value', value, showName: false, ifNull: '<indeterminate>'));
  }

  Widget _buildSemanticsWrapper({
    required BuildContext context,
    required Widget child,
  }) {
    String? expandedSemanticsValue = semanticsValue;
    if (value != null) {
      expandedSemanticsValue ??= '${(value! * 100).round()}%';
    }
    return Semantics(
      label: semanticsLabel,
      value: expandedSemanticsValue,
      child: child,
    );
  }
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    required this.backgroundColor,
    required this.valueColor,
    this.value,
    required this.animationValue,
    required this.textDirection,
  }) : assert(textDirection != null);

  final Color backgroundColor;
  final Color valueColor;
  final double? value;
  final double animationValue;
  final TextDirection textDirection;

  // The indeterminate progress animation displays two lines whose leading (head)
  // and trailing (tail) endpoints are defined by the following four curves.
  static const Curve line1Head = Interval(
    0.0,
    750.0 / _kIndeterminateLinearDuration,
    curve: Cubic(0.2, 0.0, 0.8, 1.0),
  );
  static const Curve line1Tail = Interval(
    333.0 / _kIndeterminateLinearDuration,
    (333.0 + 750.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static const Curve line2Head = Interval(
    1000.0 / _kIndeterminateLinearDuration,
    (1000.0 + 567.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.0, 0.0, 0.65, 1.0),
  );
  static const Curve line2Tail = Interval(
    1267.0 / _kIndeterminateLinearDuration,
    (1267.0 + 533.0) / _kIndeterminateLinearDuration,
    curve: Cubic(0.10, 0.0, 0.45, 1.0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = valueColor;

    void drawBar(double x, double width) {
      if (width <= 0.0)
        return;

      final double left;
      switch (textDirection) {
        case TextDirection.rtl:
          left = size.width - width - x;
          break;
        case TextDirection.ltr:
          left = x;
          break;
      }
      canvas.drawRect(Offset(left, 0.0) & Size(width, size.height), paint);
    }

    if (value != null) {
      drawBar(0.0, value!.clamp(0.0, 1.0) * size.width);
    } else {
      final double x1 = size.width * line1Tail.transform(animationValue);
      final double width1 = size.width * line1Head.transform(animationValue) - x1;

      final double x2 = size.width * line2Tail.transform(animationValue);
      final double width2 = size.width * line2Head.transform(animationValue) - x2;

      drawBar(x1, width1);
      drawBar(x2, width2);
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
/// {@youtube 560 315 https://www.youtube.com/watch?v=O-rhXZLtpv0}
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
/// The indicator line is displayed with [valueColor], an animated value. To
/// specify a constant color value use: `AlwaysStoppedAnimation<Color>(color)`.
///
/// The minimum height of the indicator can be specified using [minHeight].
/// The indicator can be made taller by wrapping the widget with a [SizedBox].
///
/// {@tool dartpad --template=stateful_widget_material_ticker}
///
/// This example shows a [LinearProgressIndicator] with a changing value.
///
/// ```dart
///  late AnimationController controller;
///
///  @override
///  void initState() {
///    controller = AnimationController(
///      vsync: this,
///      duration: const Duration(seconds: 5),
///    )..addListener(() {
///        setState(() {});
///      });
///    controller.repeat(reverse: true);
///    super.initState();
///  }
///
/// @override
/// void dispose() {
///   controller.dispose();
///   super.dispose();
/// }
///
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Padding(
///       padding: const EdgeInsets.all(20.0),
///       child: Column(
///         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
///         children: [
///           Text(
///             'Linear progress indicator with a fixed color',
///             style: const TextStyle(fontSize: 20),
///           ),
///           LinearProgressIndicator(
///             value: controller.value,
///             semanticsLabel: 'Linear progress indicator',
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CircularProgressIndicator], which shows progress along a circular arc.
///  * [RefreshIndicator], which automatically displays a [CircularProgressIndicator]
///    when the underlying vertical scrollable is overscrolled.
///  * <https://material.io/design/components/progress-indicators.html#linear-progress-indicators>
class LinearProgressIndicator extends ProgressIndicator {
  /// Creates a linear progress indicator.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const LinearProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Animation<Color?>? valueColor,
    this.minHeight,
    String? semanticsLabel,
    String? semanticsValue,
  }) : assert(minHeight == null || minHeight > 0),
       super(
        key: key,
        value: value,
        backgroundColor: backgroundColor,
        valueColor: valueColor,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
      );

  /// The minimum height of the line used to draw the indicator.
  ///
  /// This defaults to 4dp.
  final double? minHeight;

  @override
  _LinearProgressIndicatorState createState() => _LinearProgressIndicatorState();
}

class _LinearProgressIndicatorState extends State<LinearProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateLinearDuration),
      vsync: this,
    );
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
    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: widget.minHeight ?? 4.0,
        ),
        child: CustomPaint(
          painter: _LinearProgressIndicatorPainter(
            backgroundColor: widget._getBackgroundColor(context),
            valueColor: widget._getValueColor(context),
            value: widget.value, // may be null
            animationValue: animationValue, // ignored if widget.value is not null
            textDirection: textDirection,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    if (widget.value != null)
      return _buildIndicator(context, _controller.value, textDirection);

    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget? child) {
        return _buildIndicator(context, _controller.value, textDirection);
      },
    );
  }
}

class _CircularProgressIndicatorPainter extends CustomPainter {
  _CircularProgressIndicatorPainter({
    this.backgroundColor,
    required this.valueColor,
    required this.value,
    required this.headValue,
    required this.tailValue,
    required this.offsetValue,
    required this.rotationValue,
    required this.strokeWidth,
  }) : arcStart = value != null
         ? _startAngle
         : _startAngle + tailValue * 3 / 2 * math.pi + rotationValue * math.pi * 2.0 + offsetValue * 0.5 * math.pi,
       arcSweep = value != null
         ? value.clamp(0.0, 1.0) * _sweep
         : math.max(headValue * 3 / 2 * math.pi - tailValue * 3 / 2 * math.pi, _epsilon);

  final Color? backgroundColor;
  final Color valueColor;
  final double? value;
  final double headValue;
  final double tailValue;
  final double offsetValue;
  final double rotationValue;
  final double strokeWidth;
  final double arcStart;
  final double arcSweep;

  static const double _twoPi = math.pi * 2.0;
  static const double _epsilon = .001;
  // Canvas.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const double _sweep = _twoPi - _epsilon;
  static const double _startAngle = -math.pi / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    if (backgroundColor != null) {
      final Paint backgroundPaint = Paint()
        ..color = backgroundColor!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Offset.zero & size, 0, _sweep, false, backgroundPaint);
    }

    if (value == null) // Indeterminate
      paint.strokeCap = StrokeCap.square;

    canvas.drawArc(Offset.zero & size, arcStart, arcSweep, false, paint);
  }

  @override
  bool shouldRepaint(_CircularProgressIndicatorPainter oldPainter) {
    return oldPainter.backgroundColor != backgroundColor
        || oldPainter.valueColor != valueColor
        || oldPainter.value != value
        || oldPainter.headValue != headValue
        || oldPainter.tailValue != tailValue
        || oldPainter.offsetValue != offsetValue
        || oldPainter.rotationValue != rotationValue
        || oldPainter.strokeWidth != strokeWidth;
  }
}

/// A material design circular progress indicator, which spins to indicate that
/// the application is busy.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=O-rhXZLtpv0}
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
/// The indicator arc is displayed with [valueColor], an animated value. To
/// specify a constant color use: `AlwaysStoppedAnimation<Color>(color)`.
///
/// {@tool dartpad --template=stateful_widget_material_ticker}
///
/// This example shows a [CircularProgressIndicator] with a changing value.
///
/// ```dart
///  late AnimationController controller;
///
///  @override
///  void initState() {
///    controller = AnimationController(
///      vsync: this,
///      duration: const Duration(seconds: 5),
///    )..addListener(() {
///        setState(() {});
///      });
///    controller.repeat(reverse: true);
///    super.initState();
///  }
///
/// @override
/// void dispose() {
///   controller.dispose();
///   super.dispose();
/// }
///
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Padding(
///       padding: const EdgeInsets.all(20.0),
///       child: Column(
///         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
///         children: [
///           Text(
///             'Linear progress indicator with a fixed color',
///             style: Theme.of(context).textTheme.headline6,
///           ),
///           CircularProgressIndicator(
///             value: controller.value,
///             semanticsLabel: 'Linear progress indicator',
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [LinearProgressIndicator], which displays progress along a line.
///  * [RefreshIndicator], which automatically displays a [CircularProgressIndicator]
///    when the underlying vertical scrollable is overscrolled.
///  * <https://material.io/design/components/progress-indicators.html#circular-progress-indicators>
class CircularProgressIndicator extends ProgressIndicator {
  /// Creates a circular progress indicator.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const CircularProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Animation<Color?>? valueColor,
    this.strokeWidth = 4.0,
    String? semanticsLabel,
    String? semanticsValue,
  }) : _indicatorType = _ActivityIndicatorType.material,
       super(
         key: key,
         value: value,
         backgroundColor: backgroundColor,
         valueColor: valueColor,
         semanticsLabel: semanticsLabel,
         semanticsValue: semanticsValue,
       );

  /// Creates an adaptive progress indicator that is a
  /// [CupertinoActivityIndicator] in iOS and [CircularProgressIndicator] in
  /// material theme/non-iOS.
  ///
  /// The [value], [backgroundColor], [valueColor], [strokeWidth],
  /// [semanticsLabel], and [semanticsValue] will be ignored in iOS.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const CircularProgressIndicator.adaptive({
    Key? key,
    double? value,
    Color? backgroundColor,
    Animation<Color?>? valueColor,
    this.strokeWidth = 4.0,
    String? semanticsLabel,
    String? semanticsValue,
  }) : _indicatorType = _ActivityIndicatorType.adaptive,
       super(
         key: key,
         value: value,
         backgroundColor: backgroundColor,
         valueColor: valueColor,
         semanticsLabel: semanticsLabel,
         semanticsValue: semanticsValue,
       );

  final _ActivityIndicatorType _indicatorType;

  /// The width of the line used to draw the circle.
  ///
  /// This property is ignored if used in an adaptive constructor inside an iOS
  /// environment.
  final double strokeWidth;

  @override
  _CircularProgressIndicatorState createState() => _CircularProgressIndicatorState();
}

class _CircularProgressIndicatorState extends State<CircularProgressIndicator> with SingleTickerProviderStateMixin {
  static const int _pathCount = _kIndeterminateCircularDuration ~/ 1333;
  static const int _rotationCount = _kIndeterminateCircularDuration ~/ 2222;

  static final Animatable<double> _strokeHeadTween = CurveTween(
    curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(
    curve: const SawTooth(_pathCount),
  ));
  static final Animatable<double> _strokeTailTween = CurveTween(
    curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(
    curve: const SawTooth(_pathCount),
  ));
  static final Animatable<double> _offsetTween = CurveTween(curve: const SawTooth(_pathCount));
  static final Animatable<double> _rotationTween = CurveTween(curve: const SawTooth(_rotationCount));

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateCircularDuration),
      vsync: this,
    );
    if (widget.value == null)
      _controller.repeat();
  }

  @override
  void didUpdateWidget(CircularProgressIndicator oldWidget) {
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

  Widget _buildCupertinoIndicator(BuildContext context) {
    return CupertinoActivityIndicator(key: widget.key);
  }

  Widget _buildMaterialIndicator(BuildContext context, double headValue, double tailValue, double offsetValue, double rotationValue) {
    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: _kMinCircularProgressIndicatorSize,
          minHeight: _kMinCircularProgressIndicatorSize,
        ),
        child: CustomPaint(
          painter: _CircularProgressIndicatorPainter(
            backgroundColor: widget.backgroundColor,
            valueColor: widget._getValueColor(context),
            value: widget.value, // may be null
            headValue: headValue, // remaining arguments are ignored if widget.value is not null
            tailValue: tailValue,
            offsetValue: offsetValue,
            rotationValue: rotationValue,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return _buildMaterialIndicator(
          context,
          _strokeHeadTween.evaluate(_controller),
          _strokeTailTween.evaluate(_controller),
          _offsetTween.evaluate(_controller),
          _rotationTween.evaluate(_controller),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget._indicatorType) {
      case _ActivityIndicatorType.material:
        if (widget.value != null)
          return _buildMaterialIndicator(context, 0.0, 0.0, 0, 0.0);
        return _buildAnimation();
      case _ActivityIndicatorType.adaptive:
        final ThemeData theme = Theme.of(context);
        assert(theme.platform != null);
        switch (theme.platform) {
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            return _buildCupertinoIndicator(context);
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            if (widget.value != null)
              return _buildMaterialIndicator(context, 0.0, 0.0, 0, 0.0);
            return _buildAnimation();
        }
    }
  }
}

class _RefreshProgressIndicatorPainter extends _CircularProgressIndicatorPainter {
  _RefreshProgressIndicatorPainter({
    required Color valueColor,
    required double? value,
    required double headValue,
    required double tailValue,
    required double offsetValue,
    required double rotationValue,
    required double strokeWidth,
    required this.arrowheadScale,
  }) : super(
    valueColor: valueColor,
    value: value,
    headValue: headValue,
    tailValue: tailValue,
    offsetValue: offsetValue,
    rotationValue: rotationValue,
    strokeWidth: strokeWidth,
  );

  final double arrowheadScale;

  void paintArrowhead(Canvas canvas, Size size) {
    // ux, uy: a unit vector whose direction parallels the base of the arrowhead.
    // (So ux, -uy points in the direction the arrowhead points.)
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

    final Path path = Path()
      ..moveTo(radius + ux * innerRadius, radius + uy * innerRadius)
      ..lineTo(radius + ux * outerRadius, radius + uy * outerRadius)
      ..lineTo(arrowheadPointX, arrowheadPointY)
      ..close();
    final Paint paint = Paint()
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
/// The indicator arc is displayed with [valueColor], an animated value. To
/// specify a constant color use: `AlwaysStoppedAnimation<Color>(color)`.
///
/// See also:
///
///  * [RefreshIndicator], which automatically displays a [CircularProgressIndicator]
///    when the underlying vertical scrollable is overscrolled.
class RefreshProgressIndicator extends CircularProgressIndicator {
  /// Creates a refresh progress indicator.
  ///
  /// Rather than creating a refresh progress indicator directly, consider using
  /// a [RefreshIndicator] together with a [Scrollable] widget.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const RefreshProgressIndicator({
    Key? key,
    double? value,
    Color? backgroundColor,
    Animation<Color?>? valueColor,
    double strokeWidth = 2.0, // Different default than CircularProgressIndicator.
    String? semanticsLabel,
    String? semanticsValue,
  }) : super(
    key: key,
    value: value,
    backgroundColor: backgroundColor,
    valueColor: valueColor,
    strokeWidth: strokeWidth,
    semanticsLabel: semanticsLabel,
    semanticsValue: semanticsValue,
  );

  @override
  _RefreshProgressIndicatorState createState() => _RefreshProgressIndicatorState();
}

class _RefreshProgressIndicatorState extends _CircularProgressIndicatorState {
  static const double _indicatorSize = 40.0;

  // Always show the indeterminate version of the circular progress indicator.
  // When value is non-null the sweep of the progress indicator arrow's arc
  // varies from 0 to about 270 degrees. When value is null the arrow animates
  // starting from wherever we left it.
  @override
  Widget build(BuildContext context) {
    if (widget.value != null)
      _controller.value = widget.value! * (1333 / 2 / _kIndeterminateCircularDuration);
    else if (!_controller.isAnimating)
      _controller.repeat();
    return _buildAnimation();
  }

  @override
  Widget _buildMaterialIndicator(BuildContext context, double headValue, double tailValue, double offsetValue, double rotationValue) {
    final double arrowheadScale = widget.value == null ? 0.0 : (widget.value! * 2.0).clamp(0.0, 1.0);
    return widget._buildSemanticsWrapper(
      context: context,
      child: Container(
        width: _indicatorSize,
        height: _indicatorSize,
        margin: const EdgeInsets.all(4.0), // accommodate the shadow
        child: Material(
          type: MaterialType.circle,
          color: widget.backgroundColor ?? Theme.of(context).canvasColor,
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CustomPaint(
              painter: _RefreshProgressIndicatorPainter(
                valueColor: widget._getValueColor(context),
                value: null, // Draw the indeterminate progress indicator.
                headValue: headValue,
                tailValue: tailValue,
                offsetValue: offsetValue,
                rotationValue: rotationValue,
                strokeWidth: widget.strokeWidth,
                arrowheadScale: arrowheadScale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
