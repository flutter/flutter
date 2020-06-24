// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'colors.dart';

const double _kDefaultIndicatorRadius = 10.0;

// Extracted from iOS 13.2 Beta.
const Color _kActiveTickColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF3C3C44),
  darkColor: Color(0xFFEBEBF5),
);

/// An iOS-style activity indicator that spins clockwise.
///
/// See also:
///
///  * <https://developer.apple.com/ios/human-interface-guidelines/controls/progress-indicators/#activity-indicators>
class CupertinoActivityIndicator extends StatefulWidget {
  /// Creates an iOS-style activity indicator that spins clockwise.
  const CupertinoActivityIndicator({
    Key key,
    this.animating = true,
    this.radius = _kDefaultIndicatorRadius,
  }) : assert(animating != null),
       assert(radius != null),
       assert(radius > 0.0),
       progress = 1.0,
       super(key: key);

  /// Creates a non-animated iOS-style activity indicator that displays
  /// a partial count of ticks based on the value of [progress].
  ///
  /// When provided, the value of [progress] must be between 0.0 (zero ticks
  /// will be shown) and 1.0 (all ticks will be shown) inclusive. Defaults
  /// to 1.0.
  const CupertinoActivityIndicator.partiallyRevealed({
    Key key,
    this.radius = _kDefaultIndicatorRadius,
    this.progress = 1.0,
  }) : assert(radius != null),
       assert(radius > 0.0),
       assert(progress != null),
       assert(progress >= 0.0),
       assert(progress <= 1.0),
       animating = false,
       super(key: key);

  /// Whether the activity indicator is running its animation.
  ///
  /// Defaults to true.
  final bool animating;

  /// Radius of the spinner widget.
  ///
  /// Defaults to 10px. Must be positive and cannot be null.
  final double radius;

  /// Determines the percentage of spinner ticks that will be shown. Typical usage would
  /// display all ticks, however, this allows for more fine-grained control such as
  /// during pull-to-refresh when the drag-down action shows one tick at a time as
  /// the user continues to drag down.
  ///
  /// Defaults to 1.0. Must be between 0.0 and 1.0 inclusive, and cannot be null.
  final double progress;

  @override
  _CupertinoActivityIndicatorState createState() => _CupertinoActivityIndicatorState();
}


class _CupertinoActivityIndicatorState extends State<CupertinoActivityIndicator> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.animating)
      _controller.repeat();
  }

  @override
  void didUpdateWidget(CupertinoActivityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating != oldWidget.animating) {
      if (widget.animating)
        _controller.repeat();
      else
        _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.radius * 2,
      width: widget.radius * 2,
      child: CustomPaint(
        painter: _CupertinoActivityIndicatorPainter(
          position: _controller,
          activeColor: CupertinoDynamicColor.resolve(_kActiveTickColor, context),
          radius: widget.radius,
          progress: widget.progress,
        ),
      ),
    );
  }
}

const double _kTwoPI = math.pi * 2.0;
const int _kTickCount = 12;

// Alpha values extracted from the native component (for both dark and light mode) to
// draw the spinning ticks. The list must have a length of _kTickCount. The order of
// these values is designed to match the first frame of the iOS activity indicator which
// has the most prominent tick at 9 o'clock.
const List<int> _alphaValues = <int>[47, 47, 47, 47, 64, 81, 97, 114, 131, 147, 47, 47];

// The alpha value that is used to draw the partially revealed ticks.
const int _partiallyRevealedAlpha = 147;

class _CupertinoActivityIndicatorPainter extends CustomPainter {
  _CupertinoActivityIndicatorPainter({
    @required this.position,
    @required this.activeColor,
    @required this.radius,
    @required this.progress,
  }) : tickFundamentalRRect = RRect.fromLTRBXY(
         -radius / _kDefaultIndicatorRadius,
         -radius / 2.0,
         radius / _kDefaultIndicatorRadius,
         -radius,
         radius / _kDefaultIndicatorRadius,
         radius / _kDefaultIndicatorRadius,
       ),
       super(repaint: position);

  final Animation<double> position;
  final RRect tickFundamentalRRect;
  final Color activeColor;
  final double radius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    canvas.save();
    canvas.translate(size.width / 2.0, size.height / 2.0);

    final int activeTick = (_kTickCount * position.value).floor();

    for (int i = 0; i < _kTickCount * progress; ++i) {
      final int t = (i - activeTick) % _kTickCount;
      paint.color = activeColor.withAlpha(progress < 1 ? _partiallyRevealedAlpha : _alphaValues[t]);
      canvas.drawRRect(tickFundamentalRRect, paint);
      canvas.rotate(_kTwoPI / _kTickCount);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CupertinoActivityIndicatorPainter oldPainter) {
    return oldPainter.position != position || oldPainter.activeColor != activeColor || oldPainter.progress != progress;
  }
}
