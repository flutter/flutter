// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/semantics.dart';
///
/// @docImport 'refresh_indicator.dart';
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'color_scheme.dart';
import 'material.dart';
import 'progress_indicator_theme.dart';
import 'theme.dart';

// This value is extracted from
// https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/res/res/anim/progress_indeterminate_material.xml;drc=9cb5b4c2d93acb9d6f5e14167e265c328c487d6b
const int _kIndeterminateLinearDuration = 1800;
// This value is extracted from
// https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/res/res/anim/progress_indeterminate_rotation_material.xml;drc=077b44912b879174cec48a25307f1c19b96c2a78
const int _kIndeterminateCircularDuration = 1333 * 2222;

// The progress value below which the track gap is scaled proportionally to
// prevent a track gap from appearing at 0% progress.
const double _kTrackGapRampDownThreshold = 0.01;

enum _ActivityIndicatorType { material, adaptive }

const String _kValueControllerAssertion =
    'A progress indicator cannot have both a value and a controller.\n'
    'The "value" property is for a determinate indicator with a specific progress, '
    'while the "controller" is for controlling the animation of an indeterminate indicator.\n'
    'To resolve this, provide only one of the two properties.';

/// A base class for Material Design progress indicators.
///
/// This widget cannot be instantiated directly. For a linear progress
/// indicator, see [LinearProgressIndicator]. For a circular progress indicator,
/// see [CircularProgressIndicator].
///
/// See also:
///
///  * <https://material.io/components/progress-indicators>
abstract class ProgressIndicator extends StatefulWidget {
  /// Creates a progress indicator.
  ///
  /// {@template flutter.material.ProgressIndicator.ProgressIndicator}
  /// The [value] argument can either be null for an indeterminate
  /// progress indicator, or a non-null value between 0.0 and 1.0 for a
  /// determinate progress indicator.
  ///
  /// ## Accessibility
  ///
  /// The [semanticsLabel] can be used to identify the purpose of this progress
  /// bar for screen reading software. The [semanticsValue] property may be used
  /// for determinate progress indicators to indicate how much progress has been made.
  /// {@endtemplate}
  const ProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  /// The value will be clamped to be in the range 0.0-1.0.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  final double? value;

  double? get _effectiveValue => value == null ? null : clampDouble(value!, 0.0, 1.0);

  /// The progress indicator's background color.
  ///
  /// It is up to the subclass to implement this in whatever way makes sense
  /// for the given use case. See the subclass documentation for details.
  final Color? backgroundColor;

  /// {@template flutter.progress_indicator.ProgressIndicator.color}
  /// The progress indicator's color.
  ///
  /// This is only used if [ProgressIndicator.valueColor] is null.
  /// If [ProgressIndicator.color] is also null, then the ambient
  /// [ProgressIndicatorThemeData.color] will be used. If that
  /// is null then the current theme's [ColorScheme.primary] will
  /// be used by default.
  /// {@endtemplate}
  final Color? color;

  /// The progress indicator's color as an animated value.
  ///
  /// If null, the progress indicator is rendered with [color]. If that is null,
  /// then it will use the ambient [ProgressIndicatorThemeData.color]. If that
  /// is also null then it defaults to the current theme's [ColorScheme.primary].
  final Animation<Color?>? valueColor;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsLabel}
  /// The [SemanticsProperties.label] for this progress indicator.
  ///
  /// This value indicates the purpose of the progress bar, and will be
  /// read out by screen readers to indicate the purpose of this progress
  /// indicator.
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
  /// {@endtemplate}
  final String? semanticsValue;

  Color _getValueColor(BuildContext context, {Color? defaultColor}) {
    return valueColor?.value ??
        color ??
        ProgressIndicatorTheme.of(context).color ??
        defaultColor ??
        Theme.of(context).colorScheme.primary;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('value', value, showName: false, ifNull: '<indeterminate>'));
  }

  Widget _buildSemanticsWrapper({required BuildContext context, required Widget child}) {
    String? expandedSemanticsValue = semanticsValue;
    if (value != null) {
      expandedSemanticsValue ??= '${(_effectiveValue! * 100).round()}%';
    }
    return Semantics(label: semanticsLabel, value: expandedSemanticsValue, child: child);
  }
}

class _LinearProgressIndicatorPainter extends CustomPainter {
  const _LinearProgressIndicatorPainter({
    required this.trackColor,
    required this.valueColor,
    this.value,
    required this.animationValue,
    required this.textDirection,
    required this.indicatorBorderRadius,
    required this.stopIndicatorColor,
    required this.stopIndicatorRadius,
    required this.trackGap,
  });

  final Color trackColor;
  final Color valueColor;
  final double? value;
  final double animationValue;
  final TextDirection textDirection;
  final BorderRadiusGeometry? indicatorBorderRadius;
  final Color? stopIndicatorColor;
  final double? stopIndicatorRadius;
  final double? trackGap;

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
    final double effectiveTrackGap = trackGap ?? 0.0;

    void drawLinearIndicator({
      required double startFraction,
      required double endFraction,
      required Color color,
    }) {
      if (endFraction - startFraction <= 0) {
        return;
      }

      final isLtr = textDirection == TextDirection.ltr;
      final double left = (isLtr ? startFraction : 1 - endFraction) * size.width;
      final double right = (isLtr ? endFraction : 1 - startFraction) * size.width;

      final rect = Rect.fromLTRB(left, 0, right, size.height);
      final paint = Paint()..color = color;

      if (indicatorBorderRadius != null) {
        final RRect rrect = indicatorBorderRadius!.resolve(textDirection).toRRect(rect);
        canvas.drawRRect(rrect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }

    void drawStopIndicator() {
      // Limit the stop indicator to the height of the indicator.
      final double maxRadius = size.height / 2;
      final double radius = math.min(stopIndicatorRadius!, maxRadius);
      final indicatorPaint = Paint()..color = stopIndicatorColor!;
      final Offset position = switch (textDirection) {
        TextDirection.rtl => Offset(maxRadius, maxRadius),
        TextDirection.ltr => Offset(size.width - maxRadius, maxRadius),
      };
      canvas.drawCircle(position, radius, indicatorPaint);
    }

    // Calculates a track gap fraction that is scaled proportionally to a given
    // value.
    // This is used for a smooth transition of the track gap's size, preventing
    // it from appearing or disappearing abruptly. The returned value increases
    // linearly from 0 to the full `trackGapFraction` as `currentValue`
    // increases from 0 to `_kTrackGapRampDownThreshold`.
    double getEffectiveTrackGapFraction(double currentValue, double trackGapFraction) {
      return trackGapFraction *
          clampDouble(currentValue, 0, _kTrackGapRampDownThreshold) /
          _kTrackGapRampDownThreshold;
    }

    final double trackGapFraction = effectiveTrackGap / size.width;
    final double? effectiveValue = value == null ? null : clampDouble(value!, 0.0, 1.0);

    // Determinate progress indicator.
    if (effectiveValue != null) {
      final double trackStartFraction = trackGapFraction > 0
          ? effectiveValue + getEffectiveTrackGapFraction(effectiveValue, trackGapFraction)
          : 0;

      // Draw the track when there is still space.
      if (trackStartFraction < 1) {
        drawLinearIndicator(startFraction: trackStartFraction, endFraction: 1, color: trackColor);
      }

      // Draw the stop indicator.
      if (stopIndicatorRadius != null && stopIndicatorRadius! > 0) {
        drawStopIndicator();
      }

      // Draw the active indicator.
      if (effectiveValue > 0) {
        drawLinearIndicator(startFraction: 0, endFraction: effectiveValue, color: valueColor);
      }

      return;
    }

    // Indeterminate progress indicator.
    // For LTR text direction the `head` is the right endpoint and the `tail` is
    // the left endpoint.
    final double firstLineHead = line1Head.transform(animationValue);
    final double firstLineTail = line1Tail.transform(animationValue);
    final double secondLineHead = line2Head.transform(animationValue);
    final double secondLineTail = line2Tail.transform(animationValue);

    // Draw the track before line 1. Assuming text direction is LTR, this track
    // appears on the right side of line 1.
    if (firstLineHead < 1 - trackGapFraction) {
      final double trackStartFraction = firstLineHead > 0
          ? firstLineHead + getEffectiveTrackGapFraction(firstLineHead, trackGapFraction)
          : 0;
      drawLinearIndicator(startFraction: trackStartFraction, endFraction: 1, color: trackColor);
    }

    // Draw the line 1.
    if (firstLineHead - firstLineTail > 0) {
      drawLinearIndicator(
        startFraction: firstLineTail,
        endFraction: firstLineHead,
        color: valueColor,
      );
    }

    // Draw the track between line 1 and line 2. Assuming text direction is
    // LTR, this track appears on the left side of line 1 and on the right side
    // of line 2.
    if (firstLineTail > trackGapFraction) {
      final double trackStartFraction = secondLineHead > 0
          ? secondLineHead + getEffectiveTrackGapFraction(secondLineHead, trackGapFraction)
          : 0;
      final double trackEndFraction = firstLineTail < 1
          ? firstLineTail - getEffectiveTrackGapFraction(1 - firstLineTail, trackGapFraction)
          : 1;
      drawLinearIndicator(
        startFraction: trackStartFraction,
        endFraction: trackEndFraction,
        color: trackColor,
      );
    }

    // Draw the line 2.
    if (secondLineHead - secondLineTail > 0) {
      drawLinearIndicator(
        startFraction: secondLineTail,
        endFraction: secondLineHead,
        color: valueColor,
      );
    }

    // Draw the track after line 2. Assuming text direction is LTR, this track
    // appears on the left side of line 2.
    if (secondLineTail > trackGapFraction) {
      final double trackEndFraction = secondLineTail < 1
          ? secondLineTail - getEffectiveTrackGapFraction(1 - secondLineTail, trackGapFraction)
          : 1;
      drawLinearIndicator(startFraction: 0, endFraction: trackEndFraction, color: trackColor);
    }
  }

  @override
  bool shouldRepaint(_LinearProgressIndicatorPainter oldPainter) {
    return oldPainter.trackColor != trackColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.animationValue != animationValue ||
        oldPainter.textDirection != textDirection ||
        oldPainter.indicatorBorderRadius != indicatorBorderRadius ||
        oldPainter.stopIndicatorColor != stopIndicatorColor ||
        oldPainter.stopIndicatorRadius != stopIndicatorRadius ||
        oldPainter.trackGap != trackGap;
  }
}

/// A Material Design linear progress indicator, also known as a progress bar.
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
/// {@tool dartpad}
/// This example showcases determinate and indeterminate [LinearProgressIndicator]s.
/// The [LinearProgressIndicator]s will use the ![updated Material 3 Design appearance](https://m3.material.io/components/progress-indicators/overview)
/// when setting the [LinearProgressIndicator.year2023] flag to false.
///
/// ** See code in examples/api/lib/material/progress_indicator/linear_progress_indicator.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows the creation of a [LinearProgressIndicator] with a changing value.
/// When toggling the switch, [LinearProgressIndicator] uses a determinate value.
/// As described in: https://m3.material.io/components/progress-indicators/overview
///
/// ** See code in examples/api/lib/material/progress_indicator/linear_progress_indicator.1.dart **
/// {@end-tool}
///
/// {@macro flutter.material.ProgressIndicator.AnimationSynchronization}
///
/// See the documentation of [CircularProgressIndicator] for an example on this
/// topic.
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
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    this.minHeight,
    super.semanticsLabel,
    super.semanticsValue,
    this.borderRadius,
    this.stopIndicatorColor,
    this.stopIndicatorRadius,
    this.trackGap,
    @Deprecated(
      'Set this flag to false to opt into the 2024 progress indicator appearance. Defaults to true. '
      'In the future, this flag will default to false. Use ProgressIndicatorThemeData to customize individual properties. '
      'This feature was deprecated after v3.26.0-0.1.pre.',
    )
    this.year2023,
    this.controller,
  }) : assert(minHeight == null || minHeight > 0),
       assert(value == null || controller == null, _kValueControllerAssertion);

  /// {@template flutter.material.LinearProgressIndicator.trackColor}
  /// Color of the track being filled by the linear indicator.
  ///
  /// If [LinearProgressIndicator.backgroundColor] is null then the
  /// ambient [ProgressIndicatorThemeData.linearTrackColor] will be used.
  /// If that is null, then the ambient theme's [ColorScheme.background]
  /// will be used to draw the track.
  /// {@endtemplate}
  @override
  Color? get backgroundColor => super.backgroundColor;

  /// {@template flutter.material.LinearProgressIndicator.minHeight}
  /// The minimum height of the line used to draw the linear indicator.
  ///
  /// If [LinearProgressIndicator.minHeight] is null then it will use the
  /// ambient [ProgressIndicatorThemeData.linearMinHeight]. If that is null
  /// it will use 4dp.
  /// {@endtemplate}
  final double? minHeight;

  /// The border radius of both the indicator and the track.
  ///
  /// If null, then the [ProgressIndicatorThemeData.borderRadius] will be used.
  /// If that is also null, then defaults to radius of 2, which produces a
  /// rounded shape with a rounded indicator. If [ThemeData.useMaterial3] is false,
  /// then defaults to [BorderRadius.zero], which produces a rectangular shape
  /// with a rectangular indicator.
  final BorderRadiusGeometry? borderRadius;

  /// The color of the stop indicator.
  ///
  /// If [year2023] is true or [ThemeData.useMaterial3] is false, then no stop
  /// indicator will be drawn.
  ///
  /// If null, then the [ProgressIndicatorThemeData.stopIndicatorColor] will be used.
  /// If that is null, then the [ColorScheme.primary] will be used.
  final Color? stopIndicatorColor;

  /// The radius of the stop indicator.
  ///
  /// If [year2023] is true or [ThemeData.useMaterial3] is false, then no stop
  /// indicator will be drawn.
  ///
  /// Set [stopIndicatorRadius] to 0 to hide the stop indicator.
  ///
  /// If null, then the [ProgressIndicatorThemeData.stopIndicatorRadius] will be used.
  /// If that is null, then defaults to 2.
  final double? stopIndicatorRadius;

  /// The gap between the indicator and the track.
  ///
  /// If [year2023] is true or [ThemeData.useMaterial3] is false, then no track
  /// gap will be drawn.
  ///
  /// Set [trackGap] to 0 to hide the track gap.
  ///
  /// If null, then the [ProgressIndicatorThemeData.trackGap] will be used.
  /// If that is null, then defaults to 4.
  final double? trackGap;

  /// When true, the [LinearProgressIndicator] will use the 2023 Material Design 3
  /// appearance.
  ///
  /// If null, then the [ProgressIndicatorThemeData.year2023] will be used.
  /// If that is null, then defaults to true.
  ///
  /// If this is set to false, the [LinearProgressIndicator] will use the
  /// latest Material Design 3 appearance, which was introduced in December 2023.
  ///
  /// If [ThemeData.useMaterial3] is false, then this property is ignored.
  @Deprecated(
    'Set this flag to false to opt into the 2024 progress indicator appearance. Defaults to true. '
    'In the future, this flag will default to false. Use ProgressIndicatorThemeData to customize individual properties. '
    'This feature was deprecated after v3.27.0-0.1.pre.',
  )
  final bool? year2023;

  /// {@template flutter.material.ProgressIndicator.controller}
  /// An optional [AnimationController] that controls the animation of this
  /// indeterminate progress indicator.
  ///
  /// This controller is only used when the indicator is indeterminate (i.e.,
  /// when [value] is null). If this property is non-null, [value] must be null.
  ///
  /// The controller's value is expected to be a linear progression from 0.0 to
  /// 1.0, which represents one full cycle of the indeterminate animation.
  ///
  /// If this controller is null (and [value] is also null), the widget will
  /// look for a [ProgressIndicatorThemeData.controller]. If that is also null,
  /// the widget will create and manage its own internal [AnimationController]
  /// to drive the default indeterminate animation.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [LinearProgressIndicator.defaultAnimationDuration], default duration
  ///    for one full cycle of the indeterminate animation.
  final AnimationController? controller;

  /// The default duration for one full cycle of the indeterminate animation.
  ///
  /// This duration is used when the widget creates its own [AnimationController]
  /// because no [controller] was provided, either directly or through a
  /// [ProgressIndicatorTheme].
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: _kIndeterminateLinearDuration,
  );

  @override
  State<LinearProgressIndicator> createState() => _LinearProgressIndicatorState();
}

class _LinearProgressIndicatorState extends State<LinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = AnimationController(
      duration: LinearProgressIndicator.defaultAnimationDuration,
      vsync: this,
    );
    _updateControllerAnimatingStatus();
  }

  @override
  void didUpdateWidget(LinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllerAnimatingStatus();
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  AnimationController get _controller =>
      widget.controller ??
      context.getInheritedWidgetOfExactType<ProgressIndicatorTheme>()?.data.controller ??
      context.findAncestorWidgetOfExactType<Theme>()?.data.progressIndicatorTheme.controller ??
      _internalController;

  void _updateControllerAnimatingStatus() {
    if (widget._effectiveValue == null && !_internalController.isAnimating) {
      _internalController.repeat();
    } else if (widget._effectiveValue != null && _internalController.isAnimating) {
      _internalController.stop();
    }
  }

  Widget _buildIndicator(BuildContext context, double animationValue, TextDirection textDirection) {
    final ProgressIndicatorThemeData indicatorTheme = ProgressIndicatorTheme.of(context);
    final bool year2023 = widget.year2023 ?? indicatorTheme.year2023 ?? true;
    final ProgressIndicatorThemeData defaults = switch (Theme.of(context).useMaterial3) {
      true =>
        year2023
            ? _LinearProgressIndicatorDefaultsM3Year2023(context)
            : _LinearProgressIndicatorDefaultsM3(context),
      false => _LinearProgressIndicatorDefaultsM2(context),
    };
    final Color trackColor =
        widget.backgroundColor ?? indicatorTheme.linearTrackColor ?? defaults.linearTrackColor!;
    final double minHeight =
        widget.minHeight ?? indicatorTheme.linearMinHeight ?? defaults.linearMinHeight!;
    final BorderRadiusGeometry? borderRadius =
        widget.borderRadius ?? indicatorTheme.borderRadius ?? defaults.borderRadius;
    final Color? stopIndicatorColor = !year2023
        ? widget.stopIndicatorColor ??
              indicatorTheme.stopIndicatorColor ??
              defaults.stopIndicatorColor
        : null;
    final double? stopIndicatorRadius = !year2023
        ? widget.stopIndicatorRadius ??
              indicatorTheme.stopIndicatorRadius ??
              defaults.stopIndicatorRadius
        : null;
    final double? trackGap = !year2023
        ? widget.trackGap ?? indicatorTheme.trackGap ?? defaults.trackGap
        : null;

    Widget result = ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity, minHeight: minHeight),
      child: CustomPaint(
        painter: _LinearProgressIndicatorPainter(
          trackColor: trackColor,
          valueColor: widget._getValueColor(context, defaultColor: defaults.color),
          value: widget._effectiveValue, // may be null
          animationValue: animationValue, // ignored if widget._effectiveValue is not null
          textDirection: textDirection,
          indicatorBorderRadius: borderRadius,
          stopIndicatorColor: stopIndicatorColor,
          stopIndicatorRadius: stopIndicatorRadius,
          trackGap: trackGap,
        ),
      ),
    );

    // Clip is only needed with indeterminate progress indicators
    if (borderRadius != null && widget._effectiveValue == null) {
      result = ClipRRect(borderRadius: borderRadius, child: result);
    }

    return widget._buildSemanticsWrapper(context: context, child: result);
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    if (widget._effectiveValue != null) {
      return _buildIndicator(context, _controller.value, textDirection);
    }

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
    this.trackColor,
    required this.valueColor,
    required this.value,
    required this.headValue,
    required this.tailValue,
    required this.offsetValue,
    required this.rotationValue,
    required this.strokeWidth,
    required this.strokeAlign,
    this.strokeCap,
    this.trackGap,
    this.year2023 = true,
  }) : arcStart = value != null
           ? _startAngle
           : _startAngle +
                 tailValue * 3 / 2 * math.pi +
                 rotationValue * math.pi * 2.0 +
                 offsetValue * 0.5 * math.pi,
       arcSweep = value != null
           ? clampDouble(value, 0.0, 1.0) * _sweep
           : math.max(headValue * 3 / 2 * math.pi - tailValue * 3 / 2 * math.pi, _epsilon);

  final Color? trackColor;
  final Color valueColor;
  final double? value;
  final double headValue;
  final double tailValue;
  final double offsetValue;
  final double rotationValue;
  final double strokeWidth;
  final double strokeAlign;
  final double arcStart;
  final double arcSweep;
  final StrokeCap? strokeCap;
  final double? trackGap;
  final bool year2023;

  static const double _twoPi = math.pi * 2.0;
  static const double _epsilon = .001;
  // Canvas.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const double _sweep = _twoPi - _epsilon;
  static const double _startAngle = -math.pi / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Use the negative operator as intended to keep the exposed constant value
    // as users are already familiar with.
    final double strokeOffset = strokeWidth / 2 * -strokeAlign;
    final arcBaseOffset = Offset(strokeOffset, strokeOffset);
    final arcActualSize = Size(size.width - strokeOffset * 2, size.height - strokeOffset * 2);
    final bool hasGap = trackGap != null && trackGap! > 0;

    if (trackColor != null) {
      final backgroundPaint = Paint()
        ..color = trackColor!
        ..strokeWidth = strokeWidth
        ..strokeCap = strokeCap ?? StrokeCap.round
        ..style = PaintingStyle.stroke;
      // If hasGap is true, draw the background arc with a gap.
      if (hasGap && value != null && value! > _epsilon) {
        final double arcRadius = arcActualSize.shortestSide / 2;
        final double strokeRadius = strokeWidth / arcRadius;
        final double gapRadius = trackGap! / arcRadius;
        final double startGap = strokeRadius + gapRadius;
        final double endGap = value! < _epsilon ? startGap : startGap * 2;
        final double startSweep = (-math.pi / 2.0) + startGap;
        final double endSweep = math.max(
          0.0,
          _twoPi - clampDouble(value!, 0.0, 1.0) * _twoPi - endGap,
        );
        // Flip the canvas for the background arc.
        canvas.save();
        canvas.scale(-1, 1);
        canvas.translate(-size.width, 0);
        canvas.drawArc(arcBaseOffset & arcActualSize, startSweep, endSweep, false, backgroundPaint);
        // Restore the canvas to draw the foreground arc.
        canvas.restore();
      } else {
        canvas.drawArc(arcBaseOffset & arcActualSize, 0, _sweep, false, backgroundPaint);
      }
    }

    if (year2023) {
      if (value == null && strokeCap == null) {
        // Indeterminate
        paint.strokeCap = StrokeCap.square;
      } else {
        // Butt when determinate (value != null) && strokeCap == null;
        paint.strokeCap = strokeCap ?? StrokeCap.butt;
      }
    } else {
      paint.strokeCap = strokeCap ?? StrokeCap.round;
    }

    canvas.drawArc(arcBaseOffset & arcActualSize, arcStart, arcSweep, false, paint);
  }

  @override
  bool shouldRepaint(_CircularProgressIndicatorPainter oldPainter) {
    return oldPainter.trackColor != trackColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.headValue != headValue ||
        oldPainter.tailValue != tailValue ||
        oldPainter.offsetValue != offsetValue ||
        oldPainter.rotationValue != rotationValue ||
        oldPainter.strokeWidth != strokeWidth ||
        oldPainter.strokeAlign != strokeAlign ||
        oldPainter.strokeCap != strokeCap ||
        oldPainter.trackGap != trackGap ||
        oldPainter.year2023 != year2023;
  }
}

/// A Material Design circular progress indicator, which spins to indicate that
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
/// {@tool dartpad}
/// This example showcases determinate and indeterminate [CircularProgressIndicator]s.
/// The [CircularProgressIndicator]s will use the ![updated Material 3 Design appearance](https://m3.material.io/components/progress-indicators/overview)
/// when setting the [CircularProgressIndicator.year2023] flag to false.
///
/// ** See code in examples/api/lib/material/progress_indicator/circular_progress_indicator.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This sample shows the creation of a [CircularProgressIndicator] with a changing value.
/// When toggling the switch, [CircularProgressIndicator] uses a determinate value.
/// As described in: https://m3.material.io/components/progress-indicators/overview
///
/// ** See code in examples/api/lib/material/progress_indicator/circular_progress_indicator.1.dart **
/// {@end-tool}
///
/// {@template flutter.material.ProgressIndicator.AnimationSynchronization}
/// ## Animation synchronization
///
/// When multiple [CircularProgressIndicator]s or [LinearProgressIndicator]s are
/// animating on screen simultaneously (e.g., in a list of loading items), their
/// uncoordinated animations can appear visually cluttered. To address this, the
/// animation of an indicator can be driven by a custom [AnimationController].
///
/// This allows multiple indicators to be synchronized to a single animation
/// source. The most convenient way to achieve this for a group of indicators is
/// by providing a controller via [ProgressIndicatorTheme] (see
/// [ProgressIndicatorThemeData.controller]). All [CircularProgressIndicator]s
/// or [LinearProgressIndicator]s within that theme's subtree will then share
/// the same animation, resulting in a more coordinated and visually pleasing
/// effect.
///
/// Alternatively, a specific [AnimationController] can be passed directly to the
/// [controller] property of an individual indicator.
/// {@endtemplate}
///
/// {@tool dartpad}
/// This sample demonstrates how to synchronize the indeterminate animations
/// of multiple [CircularProgressIndicator]s using a [Theme].
///
/// Tapping the buttons adds or removes indicators. By default, they all
/// share a [ProgressIndicatorThemeData.controller], which keeps their
/// animations in sync.
///
/// Tapping the "Toggle" button sets the theme's controller to null.
/// This forces each indicator to create its own internal controller,
/// causing their animations to become desynchronized.
///
/// ** See code in examples/api/lib/material/progress_indicator/circular_progress_indicator.2.dart **
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
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    this.strokeWidth,
    this.strokeAlign,
    super.semanticsLabel,
    super.semanticsValue,
    this.strokeCap,
    this.constraints,
    this.trackGap,
    @Deprecated(
      'Set this flag to false to opt into the 2024 progress indicator appearance. Defaults to true. '
      'In the future, this flag will default to false. Use ProgressIndicatorThemeData to customize individual properties. '
      'This feature was deprecated after v3.27.0-0.1.pre.',
    )
    this.year2023,
    this.padding,
    this.controller,
  }) : assert(value == null || controller == null, _kValueControllerAssertion),
       _indicatorType = _ActivityIndicatorType.material;

  /// Creates an adaptive progress indicator that is a
  /// [CupertinoActivityIndicator] on [TargetPlatform.iOS] &
  /// [TargetPlatform.macOS] and a [CircularProgressIndicator] in material
  /// theme/non-Apple platforms.
  ///
  /// The [valueColor], [strokeWidth], [strokeAlign], [strokeCap],
  /// [semanticsLabel], [semanticsValue], [trackGap], [year2023] will be
  /// ignored on iOS & macOS.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const CircularProgressIndicator.adaptive({
    super.key,
    super.value,
    super.backgroundColor,
    super.valueColor,
    this.strokeWidth,
    super.semanticsLabel,
    super.semanticsValue,
    this.strokeCap,
    this.strokeAlign,
    this.constraints,
    this.trackGap,
    @Deprecated(
      'Set this flag to false to opt into the 2024 progress indicator appearance. Defaults to true. '
      'In the future, this flag will default to false. Use ProgressIndicatorThemeData to customize individual properties. '
      'This feature was deprecated after v3.27.0-0.2.pre.',
    )
    this.year2023,
    this.padding,
    this.controller,
  }) : assert(value == null || controller == null, _kValueControllerAssertion),
       _indicatorType = _ActivityIndicatorType.adaptive;

  final _ActivityIndicatorType _indicatorType;

  /// {@template flutter.material.CircularProgressIndicator.trackColor}
  /// Color of the circular track being filled by the circular indicator.
  ///
  /// If [CircularProgressIndicator.backgroundColor] is null then the
  /// ambient [ProgressIndicatorThemeData.circularTrackColor] will be used.
  /// If that is null, then the track will not be painted.
  /// {@endtemplate}
  @override
  Color? get backgroundColor => super.backgroundColor;

  /// The width of the line used to draw the circle.
  final double? strokeWidth;

  /// The relative position of the stroke on a [CircularProgressIndicator].
  ///
  /// Values typically range from -1.0 ([strokeAlignInside], inside stroke)
  /// to 1.0 ([strokeAlignOutside], outside stroke),
  /// without any bound constraints (e.g., a value of -2.0 is not typical, but allowed).
  /// A value of 0 ([strokeAlignCenter]) will center the border
  /// on the edge of the widget.
  ///
  /// If [year2023] is true, then the default value is [strokeAlignCenter].
  /// Otherwise, the default value is [strokeAlignInside].
  final double? strokeAlign;

  /// The progress indicator's line ending.
  ///
  /// This determines the shape of the stroke ends of the progress indicator.
  /// By default, [strokeCap] is null.
  /// When [value] is null (indeterminate), the stroke ends are set to
  /// [StrokeCap.square]. When [value] is not null, the stroke
  /// ends are set to [StrokeCap.butt].
  ///
  /// Setting [strokeCap] to [StrokeCap.round] will result in a rounded end.
  /// Setting [strokeCap] to [StrokeCap.butt] with [value] == null will result
  /// in a slightly different indeterminate animation; the indicator completely
  /// disappears and reappears on its minimum value.
  /// Setting [strokeCap] to [StrokeCap.square] with [value] != null will
  /// result in a different display of [value]. The indicator will start
  /// drawing from slightly less than the start, and end slightly after
  /// the end. This will produce an alternative result, as the
  /// default behavior, for example, that a [value] of 0.5 starts at 90 degrees
  /// and ends at 270 degrees. With [StrokeCap.square], it could start 85
  /// degrees and end at 275 degrees.
  final StrokeCap? strokeCap;

  /// Defines minimum and maximum sizes for a [CircularProgressIndicator].
  ///
  /// If null, then the [ProgressIndicatorThemeData.constraints] will be used.
  /// Otherwise, defaults to a minimum width and height of 36 pixels.
  final BoxConstraints? constraints;

  /// The gap between the active indicator and the background track.
  ///
  /// If [year2023] is true or [ThemeData.useMaterial3] is false, then no track
  /// gap will be drawn.
  ///
  /// Set [trackGap] to 0 to hide the track gap.
  ///
  /// If null, then the [ProgressIndicatorThemeData.trackGap] will be used.
  /// If that is null, then defaults to 4.
  final double? trackGap;

  /// When true, the [CircularProgressIndicator] will use the 2023 Material Design 3
  /// appearance.
  ///
  /// If null, then the [ProgressIndicatorThemeData.year2023] will be used.
  /// If that is null, then defaults to true.
  ///
  /// If this is set to false, the [CircularProgressIndicator] will use the
  /// latest Material Design 3 appearance, which was introduced in December 2023.
  ///
  /// If [ThemeData.useMaterial3] is false, then this property is ignored.
  @Deprecated(
    'Set this flag to false to opt into the 2024 progress indicator appearance. Defaults to true. '
    'In the future, this flag will default to false. Use ProgressIndicatorThemeData to customize individual properties. '
    'This feature was deprecated after v3.27.0-0.2.pre.',
  )
  final bool? year2023;

  /// The padding around the indicator track.
  ///
  /// If null, then the [ProgressIndicatorThemeData.circularTrackPadding] will be
  /// used. If that is null and [year2023] is false, then defaults to `EdgeInsets.all(4.0)`
  /// padding. Otherwise, defaults to zero padding.
  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.material.ProgressIndicator.controller}
  ///
  /// See also:
  ///
  ///  * [CircularProgressIndicator.defaultAnimationDuration], default duration
  ///    for one full cycle of the indeterminate animation.
  final AnimationController? controller;

  /// The indicator stroke is drawn fully inside of the indicator path.
  ///
  /// This is a constant for use with [strokeAlign].
  static const double strokeAlignInside = -1.0;

  /// The indicator stroke is drawn on the center of the indicator path,
  /// with half of the [strokeWidth] on the inside, and the other half
  /// on the outside of the path.
  ///
  /// This is a constant for use with [strokeAlign].
  ///
  /// This is the default value for [strokeAlign].
  static const double strokeAlignCenter = 0.0;

  /// The indicator stroke is drawn on the outside of the indicator path.
  ///
  /// This is a constant for use with [strokeAlign].
  static const double strokeAlignOutside = 1.0;

  /// The default duration for one full cycle of the indeterminate animation.
  ///
  /// During this period, the indicator completes several full rotations.
  ///
  /// This duration is used when the widget creates its own [AnimationController]
  /// because no [controller] was provided, either directly or through a
  /// [ProgressIndicatorTheme].
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: _kIndeterminateCircularDuration,
  );

  @override
  State<CircularProgressIndicator> createState() => _CircularProgressIndicatorState();
}

class _CircularProgressIndicatorState extends State<CircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  static const int _pathCount = _kIndeterminateCircularDuration ~/ 1333;
  static const int _rotationCount = _kIndeterminateCircularDuration ~/ 2222;

  static final Animatable<double> _strokeHeadTween = CurveTween(
    curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));
  static final Animatable<double> _strokeTailTween = CurveTween(
    curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));
  static final Animatable<double> _offsetTween = CurveTween(curve: const SawTooth(_pathCount));
  static final Animatable<double> _rotationTween = CurveTween(
    curve: const SawTooth(_rotationCount),
  );

  late final AnimationController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = AnimationController(
      duration: CircularProgressIndicator.defaultAnimationDuration,
      vsync: this,
    );
    _updateControllerAnimatingStatus();
  }

  @override
  void didUpdateWidget(CircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllerAnimatingStatus();
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  AnimationController get _controller =>
      widget.controller ??
      context.getInheritedWidgetOfExactType<ProgressIndicatorTheme>()?.data.controller ??
      context.findAncestorWidgetOfExactType<Theme>()?.data.progressIndicatorTheme.controller ??
      _internalController;

  void _updateControllerAnimatingStatus() {
    if (widget._effectiveValue == null && !_internalController.isAnimating) {
      _internalController.repeat();
    } else if (widget._effectiveValue != null && _internalController.isAnimating) {
      _internalController.stop();
    }
  }

  Widget _buildCupertinoIndicator(BuildContext context) {
    final Color? tickColor = widget.backgroundColor;
    final double? value = widget._effectiveValue;
    if (value == null) {
      return CupertinoActivityIndicator(key: widget.key, color: tickColor);
    }
    return CupertinoActivityIndicator.partiallyRevealed(
      key: widget.key,
      color: tickColor,
      progress: value,
    );
  }

  Widget _buildMaterialIndicator(
    BuildContext context,
    double headValue,
    double tailValue,
    double offsetValue,
    double rotationValue,
  ) {
    final ProgressIndicatorThemeData indicatorTheme = ProgressIndicatorTheme.of(context);
    final bool year2023 = widget.year2023 ?? indicatorTheme.year2023 ?? true;
    final ProgressIndicatorThemeData defaults = switch (Theme.of(context).useMaterial3) {
      true =>
        year2023
            ? _CircularProgressIndicatorDefaultsM3Year2023(
                context,
                indeterminate: widget._effectiveValue == null,
              )
            : _CircularProgressIndicatorDefaultsM3(
                context,
                indeterminate: widget._effectiveValue == null,
              ),
      false => _CircularProgressIndicatorDefaultsM2(
        context,
        indeterminate: widget._effectiveValue == null,
      ),
    };
    final Color? trackColor =
        widget.backgroundColor ?? indicatorTheme.circularTrackColor ?? defaults.circularTrackColor;
    final double strokeWidth =
        widget.strokeWidth ?? indicatorTheme.strokeWidth ?? defaults.strokeWidth!;
    final double strokeAlign =
        widget.strokeAlign ?? indicatorTheme.strokeAlign ?? defaults.strokeAlign!;
    final StrokeCap? strokeCap = widget.strokeCap ?? indicatorTheme.strokeCap;
    final BoxConstraints constraints =
        widget.constraints ?? indicatorTheme.constraints ?? defaults.constraints!;
    final double? trackGap = year2023
        ? null
        : widget.trackGap ?? indicatorTheme.trackGap ?? defaults.trackGap;
    final EdgeInsetsGeometry? effectivePadding =
        widget.padding ?? indicatorTheme.circularTrackPadding ?? defaults.circularTrackPadding;

    Widget result = ConstrainedBox(
      constraints: constraints,
      child: CustomPaint(
        painter: _CircularProgressIndicatorPainter(
          trackColor: trackColor,
          valueColor: widget._getValueColor(context, defaultColor: defaults.color),
          value: widget._effectiveValue, // may be null
          headValue:
              headValue, // remaining arguments are ignored if widget._effectiveValue is not null
          tailValue: tailValue,
          offsetValue: offsetValue,
          rotationValue: rotationValue,
          strokeWidth: strokeWidth,
          strokeAlign: strokeAlign,
          strokeCap: strokeCap,
          trackGap: trackGap,
          year2023: year2023,
        ),
      ),
    );

    if (effectivePadding != null) {
      result = Padding(padding: effectivePadding, child: result);
    }

    return widget._buildSemanticsWrapper(context: context, child: result);
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
        if (widget._effectiveValue != null) {
          return _buildMaterialIndicator(context, 0.0, 0.0, 0, 0.0);
        }
        return _buildAnimation();
      case _ActivityIndicatorType.adaptive:
        final ThemeData theme = Theme.of(context);
        switch (theme.platform) {
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            return _buildCupertinoIndicator(context);
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            if (widget._effectiveValue != null) {
              return _buildMaterialIndicator(context, 0.0, 0.0, 0, 0.0);
            }
            return _buildAnimation();
        }
    }
  }
}

class _RefreshProgressIndicatorPainter extends _CircularProgressIndicatorPainter {
  _RefreshProgressIndicatorPainter({
    required super.valueColor,
    required super.value,
    required super.headValue,
    required super.tailValue,
    required super.offsetValue,
    required super.rotationValue,
    required super.strokeWidth,
    required super.strokeAlign,
    required this.arrowheadScale,
    required super.strokeCap,
  });

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
    final double arrowheadPointY = radius + uy * radius + ux * strokeWidth * 2.0 * arrowheadScale;
    final double arrowheadRadius = strokeWidth * 2.0 * arrowheadScale;
    final double innerRadius = radius - arrowheadRadius;
    final double outerRadius = radius + arrowheadRadius;

    final path = Path()
      ..moveTo(radius + ux * innerRadius, radius + uy * innerRadius)
      ..lineTo(radius + ux * outerRadius, radius + uy * outerRadius)
      ..lineTo(arrowheadPointX, arrowheadPointY)
      ..close();

    final paint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    if (arrowheadScale > 0.0) {
      paintArrowhead(canvas, size);
    }
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
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    super.strokeWidth = defaultStrokeWidth, // Different default than CircularProgressIndicator.
    super.strokeAlign,
    super.semanticsLabel,
    super.semanticsValue,
    super.strokeCap,
    this.elevation = 2.0,
    this.indicatorMargin = const EdgeInsets.all(4.0),
    this.indicatorPadding = const EdgeInsets.all(12.0),
  });

  /// {@macro flutter.material.material.elevation}
  final double elevation;

  /// The amount of space by which to inset the whole indicator.
  /// It accommodates the [elevation] of the indicator.
  final EdgeInsetsGeometry indicatorMargin;

  /// The amount of space by which to inset the inner refresh indicator.
  final EdgeInsetsGeometry indicatorPadding;

  /// Default stroke width.
  static const double defaultStrokeWidth = 2.5;

  /// {@template flutter.material.RefreshProgressIndicator.backgroundColor}
  /// Background color of that fills the circle under the refresh indicator.
  ///
  /// If [RefreshIndicator.backgroundColor] is null then the
  /// ambient [ProgressIndicatorThemeData.refreshBackgroundColor] will be used.
  /// If that is null, then the ambient theme's [ThemeData.canvasColor]
  /// will be used.
  /// {@endtemplate}
  @override
  Color? get backgroundColor => super.backgroundColor;

  @override
  State<CircularProgressIndicator> createState() => _RefreshProgressIndicatorState();
}

class _RefreshProgressIndicatorState extends _CircularProgressIndicatorState {
  static const double _indicatorSize = 41.0;

  /// Interval for arrow head to fully grow.
  static const double _strokeHeadInterval = 0.33;

  late final Animatable<double> _convertTween = CurveTween(
    curve: const Interval(0.1, _strokeHeadInterval),
  );

  late final Animatable<double> _additionalRotationTween = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      // Makes arrow to expand a little bit earlier, to match the Android look.
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.1, end: -0.2),
        weight: _strokeHeadInterval,
      ),
      // Additional rotation after the arrow expanded
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.2, end: 1.35),
        weight: 1 - _strokeHeadInterval,
      ),
    ],
  );

  // Last value received from the widget before null.
  double? _lastValue;

  /// Force casting the widget as [RefreshProgressIndicator].
  @override
  RefreshProgressIndicator get widget => super.widget as RefreshProgressIndicator;

  // Always show the indeterminate version of the circular progress indicator.
  //
  // When value is non-null the sweep of the progress indicator arrow's arc
  // varies from 0 to about 300 degrees.
  //
  // When value is null the arrow animation starting from wherever we left it.
  @override
  Widget build(BuildContext context) {
    final double? value = widget._effectiveValue;
    if (value != null) {
      _lastValue = value;
      _controller.value =
          _convertTween.transform(value) * (1333 / 2 / _kIndeterminateCircularDuration);
    }
    return _buildAnimation();
  }

  @override
  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return _buildMaterialIndicator(
          context,
          // Lengthen the arc a little
          1.05 * _CircularProgressIndicatorState._strokeHeadTween.transform(_controller.value),
          _CircularProgressIndicatorState._strokeTailTween.transform(_controller.value),
          _CircularProgressIndicatorState._offsetTween.transform(_controller.value),
          _CircularProgressIndicatorState._rotationTween.transform(_controller.value),
        );
      },
    );
  }

  @override
  Widget _buildMaterialIndicator(
    BuildContext context,
    double headValue,
    double tailValue,
    double offsetValue,
    double rotationValue,
  ) {
    final double? value = widget._effectiveValue;
    final double arrowheadScale = value == null
        ? 0.0
        : const Interval(0.1, _strokeHeadInterval).transform(value);
    final double rotation;

    if (value == null && _lastValue == null) {
      rotation = 0.0;
    } else {
      rotation = math.pi * _additionalRotationTween.transform(value ?? _lastValue!);
    }

    Color valueColor = widget._getValueColor(context);
    final double opacity = valueColor.opacity;
    valueColor = valueColor.withOpacity(1.0);

    final ProgressIndicatorThemeData defaults = switch (Theme.of(context).useMaterial3) {
      true => _CircularProgressIndicatorDefaultsM3Year2023(context, indeterminate: value == null),
      false => _CircularProgressIndicatorDefaultsM2(context, indeterminate: value == null),
    };
    final ProgressIndicatorThemeData indicatorTheme = ProgressIndicatorTheme.of(context);
    final Color backgroundColor =
        widget.backgroundColor ??
        indicatorTheme.refreshBackgroundColor ??
        Theme.of(context).canvasColor;
    final double strokeWidth =
        widget.strokeWidth ?? indicatorTheme.strokeWidth ?? defaults.strokeWidth!;
    final double strokeAlign =
        widget.strokeAlign ?? indicatorTheme.strokeAlign ?? defaults.strokeAlign!;
    final StrokeCap? strokeCap = widget.strokeCap ?? indicatorTheme.strokeCap;

    return widget._buildSemanticsWrapper(
      context: context,
      child: Padding(
        padding: widget.indicatorMargin,
        child: SizedBox.fromSize(
          size: const Size.square(_indicatorSize),
          child: Material(
            type: MaterialType.circle,
            color: backgroundColor,
            elevation: widget.elevation,
            child: Padding(
              padding: widget.indicatorPadding,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: rotation,
                  child: CustomPaint(
                    painter: _RefreshProgressIndicatorPainter(
                      valueColor: valueColor,
                      value: null, // Draw the indeterminate progress indicator.
                      headValue: headValue,
                      tailValue: tailValue,
                      offsetValue: offsetValue,
                      rotationValue: rotationValue,
                      strokeWidth: strokeWidth,
                      strokeAlign: strokeAlign,
                      arrowheadScale: arrowheadScale,
                      strokeCap: strokeCap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Hand coded defaults based on Material Design 2.
class _CircularProgressIndicatorDefaultsM2 extends ProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM2(this.context, {required this.indeterminate});

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  final bool indeterminate;

  @override
  Color get color => _colors.primary;

  @override
  double? get strokeWidth => 4.0;

  @override
  double? get strokeAlign => CircularProgressIndicator.strokeAlignCenter;

  @override
  BoxConstraints get constraints => const BoxConstraints(minWidth: 36.0, minHeight: 36.0);
}

class _LinearProgressIndicatorDefaultsM2 extends ProgressIndicatorThemeData {
  _LinearProgressIndicatorDefaultsM2(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color get color => _colors.primary;

  @override
  Color get linearTrackColor => _colors.background;

  @override
  double get linearMinHeight => 4.0;
}

class _CircularProgressIndicatorDefaultsM3Year2023 extends ProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM3Year2023(this.context, {required this.indeterminate});

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  final bool indeterminate;

  @override
  Color get color => _colors.primary;

  @override
  double get strokeWidth => 4.0;

  @override
  double? get strokeAlign => CircularProgressIndicator.strokeAlignCenter;

  @override
  BoxConstraints get constraints => const BoxConstraints(minWidth: 36.0, minHeight: 36.0);
}

class _LinearProgressIndicatorDefaultsM3Year2023 extends ProgressIndicatorThemeData {
  _LinearProgressIndicatorDefaultsM3Year2023(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color get color => _colors.primary;

  @override
  Color get linearTrackColor => _colors.secondaryContainer;

  @override
  double get linearMinHeight => 4.0;
}

// BEGIN GENERATED TOKEN PROPERTIES - ProgressIndicator

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _CircularProgressIndicatorDefaultsM3 extends ProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM3(this.context, { required this.indeterminate });

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  final bool indeterminate;

  @override
  Color get color => _colors.primary;

  @override
  Color? get circularTrackColor => indeterminate ? null : _colors.secondaryContainer;

  @override
  double get strokeWidth => 4.0;

  @override
  double? get strokeAlign => CircularProgressIndicator.strokeAlignInside;

  @override
  BoxConstraints get constraints => const BoxConstraints(
    minWidth: 40.0,
    minHeight: 40.0,
  );

  @override
  double? get trackGap => 4.0;

  @override
  EdgeInsetsGeometry? get circularTrackPadding => const EdgeInsets.all(4.0);
}

class _LinearProgressIndicatorDefaultsM3 extends ProgressIndicatorThemeData {
  _LinearProgressIndicatorDefaultsM3(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color get color => _colors.primary;

  @override
  Color get linearTrackColor => _colors.secondaryContainer;

  @override
  double get linearMinHeight => 4.0;

  @override
  BorderRadius get borderRadius => BorderRadius.circular(4.0 / 2);

  @override
  Color get stopIndicatorColor => _colors.primary;

  @override
  double? get stopIndicatorRadius => 4.0 / 2;

  @override
  double? get trackGap => 4.0;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - ProgressIndicator
