// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'colors.dart';

/// An iOS-style activity indicator.
///
/// See also:
///
///  * <https://developer.apple.com/ios/human-interface-guidelines/controls/progress-indicators/#activity-indicators>
class CupertinoActivityIndicator extends StatefulWidget {
  /// Creates an iOS-style activity indicator.
  const CupertinoActivityIndicator({
    Key key,
    this.animating: true,
  }) : assert(animating != null),
       super(key: key);

  /// Whether the activity indicator is running its animation.
  ///
  /// Defaults to true.
  final bool animating;

  @override
  _CupertinoActivityIndicatorState createState() => new _CupertinoActivityIndicatorState();
}

const double _kIndicatorWidth = 20.0;
const double _kIndicatorHeight = 20.0;

class _CupertinoActivityIndicatorState extends State<CupertinoActivityIndicator> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
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
    return new SizedBox(
      width: _kIndicatorWidth,
      height: _kIndicatorHeight,
      child: new CustomPaint(
        painter: new _CupertinoActivityIndicatorPainter(
          position: _controller,
        ),
      ),
    );
  }
}

const double _kTwoPI = math.pi * 2.0;
const int _kTickCount = 12;
const int _kHalfTickCount = _kTickCount ~/ 2;
const Color _kTickColor = CupertinoColors.lightBackgroundGray;
const Color _kActiveTickColor = const Color(0xFF9D9D9D);
final RRect _kTickFundamentalRRect = new RRect.fromLTRBXY(-10.0, 1.0, -5.0, -1.0, 1.0, 1.0);

class _CupertinoActivityIndicatorPainter extends CustomPainter {
  _CupertinoActivityIndicatorPainter({
    this.position,
  }) : super(repaint: position);

  final Animation<double> position;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint();

    canvas.save();
    canvas.translate(size.width / 2.0, size.height / 2.0);

    final int activeTick = (_kTickCount * position.value).floor();

    for (int i = 0; i < _kTickCount; ++ i) {
      final double t = (((i + activeTick) % _kTickCount) / _kHalfTickCount).clamp(0.0, 1.0);
      paint.color = Color.lerp(_kActiveTickColor, _kTickColor, t);
      canvas.drawRRect(_kTickFundamentalRRect, paint);
      canvas.rotate(-_kTwoPI / _kTickCount);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CupertinoActivityIndicatorPainter oldPainter) {
    return oldPainter.position != position;
  }
}
