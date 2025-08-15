// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

const double _kDefaultIndicatorRadius = 10.0;

// Extracted from iOS 13.2 Beta.
const Color _kActiveTickColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF3C3C44),
  darkColor: Color(0xFFEBEBF5),
);

/// A base class for Cupertino progress indicators.
///
/// This widget cannot be instantiated directly. For a linear activity
/// indicator, see [CupertinoLinearActivityIndicator]. For a circular activity
/// indicator, see [CupertinoActivityIndicator].
abstract class CupertinoProgressIndicator extends ProgressIndicator {
  /// A base class for Cupertino progress indicators.
  ///
  /// This widget cannot be instantiated directly. For a linear activity
  /// indicator, see [CupertinoLinearActivityIndicator]. For a circular activity
  /// indicator, see [CupertinoActivityIndicator].
  const CupertinoProgressIndicator({
    super.key,
    double progress = 1,
    super.semanticsLabel,
    super.semanticsValue,
    this.color,
  }) : super(value: progress);

  /// Color of the activity indicator.
  ///
  /// Defaults to color extracted from native iOS.
  final Color? color;

  /// Determines the percentage of spinner ticks that will be shown. Typical usage would
  /// display all ticks, however, this allows for more fine-grained control such as
  /// during pull-to-refresh when the drag-down action shows one tick at a time as
  /// the user continues to drag down.
  ///
  /// Defaults to one. Must be between zero and one, inclusive.
  @override
  double get value => super.value!;
}

/// An iOS-style activity indicator that spins clockwise.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=AENVH-ZqKDQ}
///
/// {@tool dartpad}
/// This example shows how [CupertinoActivityIndicator] can be customized.
///
/// ** See code in examples/api/lib/cupertino/activity_indicator/cupertino_activity_indicator.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CupertinoLinearActivityIndicator], which displays progress along a line.
///  * <https://developer.apple.com/design/human-interface-guidelines/progress-indicators/>
class CupertinoActivityIndicator extends CupertinoProgressIndicator {
  /// Creates an iOS-style activity indicator that spins clockwise.
  const CupertinoActivityIndicator({
    super.key,
    super.color,
    this.animating = true,
    this.radius = _kDefaultIndicatorRadius,
  }) : assert(radius > 0.0);

  /// Creates a non-animated iOS-style activity indicator that displays
  /// a partial count of ticks based on the value of [progress].
  ///
  /// When provided, the value of [progress] must be between 0.0 (zero ticks
  /// will be shown) and 1.0 (all ticks will be shown) inclusive. Defaults
  /// to 1.0.
  const CupertinoActivityIndicator.partiallyRevealed({
    super.key,
    super.color,
    this.radius = _kDefaultIndicatorRadius,
    super.progress,
  }) : assert(radius > 0.0),
       assert(progress >= 0.0),
       assert(progress <= 1.0),
       animating = false;

  /// Whether the activity indicator is running its animation.
  ///
  /// Defaults to true.
  final bool animating;

  /// Radius of the spinner widget.
  ///
  /// Defaults to 10 pixels. Must be positive.
  final double radius;

  @override
  State<CupertinoActivityIndicator> createState() => _CupertinoActivityIndicatorState();

  @protected
  @override
  Color getValueColor(BuildContext context, {Color? defaultColor}) {
    return color ?? CupertinoDynamicColor.resolve(_kActiveTickColor, context);
  }
}

class _CupertinoActivityIndicatorState extends State<CupertinoActivityIndicator>
    with
        SingleTickerProviderStateMixin<CupertinoActivityIndicator>,
        ProgressIndicatorMixin<CupertinoActivityIndicator> {
  @override
  bool get animating => widget.animating;

  @override
  Duration get duration => const Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return buildSemanticsWrapper(
      context: context,
      child: SizedBox(
        height: widget.radius * 2,
        width: widget.radius * 2,
        child: CustomPaint(
          painter: _CupertinoActivityIndicatorPainter(
            position: controller,
            activeColor: widget.color ?? CupertinoDynamicColor.resolve(_kActiveTickColor, context),
            radius: widget.radius,
            progress: widget.value,
          ),
        ),
      ),
    );
  }
}

const double _kTwoPI = math.pi * 2.0;

/// Alpha values extracted from the native component (for both dark and light mode) to
/// draw the spinning ticks.
const List<int> _kAlphaValues = <int>[47, 47, 47, 47, 72, 97, 122, 147];

/// The alpha value that is used to draw the partially revealed ticks.
const int _partiallyRevealedAlpha = 147;

class _CupertinoActivityIndicatorPainter extends CustomPainter {
  _CupertinoActivityIndicatorPainter({
    required this.position,
    required this.activeColor,
    required this.radius,
    required this.progress,
  }) : tickFundamentalShape = RRect.fromLTRBXY(
         -radius / _kDefaultIndicatorRadius,
         -radius / 3.0,
         radius / _kDefaultIndicatorRadius,
         -radius,
         radius / _kDefaultIndicatorRadius,
         radius / _kDefaultIndicatorRadius,
       ),
       super(repaint: position);

  final Animation<double> position;
  final Color activeColor;
  final double radius;
  final double progress;

  // Use a RRect instead of RSuperellipse since this shape is really small
  // and should make little visual difference.
  final RRect tickFundamentalShape;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final int tickCount = _kAlphaValues.length;

    canvas.save();
    canvas.translate(size.width / 2.0, size.height / 2.0);

    final int activeTick = (tickCount * position.value).floor();

    for (int i = 0; i < tickCount * progress; ++i) {
      final int t = (i - activeTick) % tickCount;
      paint.color = activeColor.withAlpha(
        progress < 1 ? _partiallyRevealedAlpha : _kAlphaValues[t],
      );
      canvas.drawRRect(tickFundamentalShape, paint);
      canvas.rotate(_kTwoPI / tickCount);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CupertinoActivityIndicatorPainter oldPainter) {
    return oldPainter.position != position ||
        oldPainter.activeColor != activeColor ||
        oldPainter.progress != progress;
  }
}

/// An iOS-style linear activity indicator.
///
/// The [CupertinoLinearActivityIndicator] is a linear progress bar that
/// displays a colored bar to indicate the progress of an ongoing task.
///
/// {@tool dartpad}
/// This example shows how [CupertinoLinearActivityIndicator] can be customized.
///
/// ** See code in examples/api/lib/cupertino/activity_indicator/cupertino_linear_activity_indicator.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CupertinoActivityIndicator], which is an iOS-style activity indicator that spins clockwise.
///  * <https://developer.apple.com/design/human-interface-guidelines/progress-indicators/>
class CupertinoLinearActivityIndicator extends CupertinoProgressIndicator {
  /// Creates a linear iOS-style activity indicator.
  const CupertinoLinearActivityIndicator({
    super.key,
    required this.progress,
    this.height = 4.5,
    this.color,
  }) : assert(height > 0),
       assert(progress >= 0.0 && progress <= 1.0);

  /// The current progress of the linear activity indicator.
  ///
  /// This value must be between 0.0 and 1.0. A value of 0.0 means no progress
  /// and 1.0 means that progress is complete.
  final double progress;

  /// The height of the line used to draw the linear activity indicator.
  ///
  /// Defaults to 4.5 units. Must be positive.
  final double height;

  /// The color of the progress bar.
  ///
  /// This color represents the portion of the bar that indicates progress.
  ///
  /// Defaults to [CupertinoColors.activeBlue] if no color is specified.
  @override
  final Color? color;

  @override
  State<CupertinoLinearActivityIndicator> createState() => _CupertinoLinearActivityIndicatorState();

  @override
  Color getValueColor(BuildContext context, {Color? defaultColor}) {
    return color ?? CupertinoColors.activeBlue;
  }
}

class _CupertinoLinearActivityIndicatorState extends State<CupertinoLinearActivityIndicator>
    with
        SingleTickerProviderStateMixin<CupertinoLinearActivityIndicator>,
        ProgressIndicatorMixin<CupertinoLinearActivityIndicator> {
  @override
  Widget build(BuildContext context) {
    return buildSemanticsWrapper(
      context: context,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.height, minWidth: double.infinity),
        child: CustomPaint(
          painter: _CupertinoLinearActivityIndicator(
            progress: widget.progress,
            color: widget.getValueColor(context),
          ),
        ),
      ),
    );
  }

  @override
  bool get animating => false;

  @override
  Duration get duration => Duration.zero;
}

class _CupertinoLinearActivityIndicator extends CustomPainter {
  _CupertinoLinearActivityIndicator({required this.progress, required this.color})
    : _backgroundPaint = Paint()
        ..color = CupertinoColors.systemFill
        ..style = PaintingStyle.fill,
      _progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

  final double progress;

  final Color color;

  /// The background paint used to draw the full width of the progress bar.
  ///
  /// This paint object is created once and reused to fill the background
  /// with a system fill color.
  final Paint _backgroundPaint;

  /// The paint used to draw the progress portion of the progress bar.
  ///
  /// This paint object is created once and reused to fill the progress area.
  final Paint _progressPaint;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the background of the progress bar.
    canvas.drawRRect(
      BorderRadius.all(Radius.circular(size.height / 2)).toRRect(Offset.zero & size),
      _backgroundPaint,
    );

    // Draw the progress portion of the bar.
    if (progress > 0) {
      canvas.drawRRect(
        BorderRadius.all(
          Radius.circular(size.height / 2),
        ).toRRect(Offset.zero & Size(clampDouble(progress, 0.0, 1.0) * size.width, size.height)),
        _progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CupertinoLinearActivityIndicator old) =>
      old.progress != progress || old.color != color;
}
