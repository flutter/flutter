// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Timer;

import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kMinIndicatorExtent = 0.0;
const double _kMaxIndicatorExtent = 64.0;
const double _kMinIndicatorOpacity = 0.0;
const double _kMaxIndicatorOpacity = 0.25;
const Duration _kIndicatorHideDuration = const Duration(milliseconds: 200);
const Duration _kIndicatorTimeoutDuration = const Duration(seconds: 1);
final Tween<double> _kIndicatorOpacity = new Tween<double>(begin: 0.0, end: 0.3);

class _Painter extends CustomPainter {
  _Painter({
    this.scrollDirection,
    this.extent, // Indicator width or height, per scrollDirection.
    this.isLeading, // Similarly true if the indicator appears at the top/left.
    this.color
  });

  final Axis scrollDirection;
  final double extent;
  final bool isLeading;
  final Color color;

  void paintIndicator(Canvas canvas, Size size) {
    final double rectBias = extent / 2.0;
    final double arcBias = extent;

    final Path path = new Path();
    switch(scrollDirection) {
      case Axis.vertical:
        final double width = size.width;
        if (isLeading) {
          path.moveTo(0.0, 0.0);
          path.relativeLineTo(width, 0.0);
          path.relativeLineTo(0.0, rectBias);
          path.relativeQuadraticBezierTo(width / -2.0, arcBias, -width, 0.0);
        } else {
          path.moveTo(0.0, size.height);
          path.relativeLineTo(width, 0.0);
          path.relativeLineTo(0.0, -rectBias);
          path.relativeQuadraticBezierTo(width / -2.0, -arcBias, -width, 0.0);
        }
        break;
      case Axis.horizontal:
        final double height = size.height;
        if (isLeading) {
          path.moveTo(0.0, 0.0);
          path.relativeLineTo(0.0, height);
          path.relativeLineTo(rectBias, 0.0);
          path.relativeQuadraticBezierTo(arcBias, height / -2.0, 0.0, -height);
        } else {
          path.moveTo(size.width, 0.0);
          path.relativeLineTo(0.0, height);
          path.relativeLineTo(-rectBias, 0.0);
          path.relativeQuadraticBezierTo(-arcBias, height / -2.0, 0.0, -height);
        }
        break;
    }
    path.close();

    final Paint paint = new Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (color.alpha == 0)
      return;
    paintIndicator(canvas, size);
  }

  @override
  bool shouldRepaint(_Painter oldPainter) {
    return oldPainter.scrollDirection != scrollDirection
      || oldPainter.extent != extent
      || oldPainter.isLeading != isLeading
      || oldPainter.color != color;
  }
}

/// When the child's Scrollable descendant overscrolls, displays a
/// a translucent arc over the affected edge of the child.
/// If the OverscrollIndicator's child has more than one Scrollable descendant
/// the scrollableKey parameter can be used to identify the one to track.
class OverscrollIndicator extends StatefulWidget {
  /// Creates an overscroll indicator.
  ///
  /// The [child] argument must not be null.
  OverscrollIndicator({
    Key key,
    this.scrollableKey,
    this.child
  }) : super(key: key) {
    assert(child != null);
  }

  /// Identifies the [Scrollable] descendant of child that the overscroll
  /// indicator will track. Can be null if there's only one [Scrollable]
  /// descendant.
  final Key scrollableKey;

  /// The overscroll indicator will be stacked on top of this child. The
  /// indicator will appear when child's [Scrollable] descendant is
  /// over-scrolled.
  final Widget child;

  @override
  _OverscrollIndicatorState createState() => new _OverscrollIndicatorState();
}

class _OverscrollIndicatorState extends State<OverscrollIndicator> {
  final AnimationController _extentAnimation = new AnimationController(
    lowerBound: _kMinIndicatorExtent,
    upperBound: _kMaxIndicatorExtent,
    duration: _kIndicatorHideDuration
  );

  Timer _hideTimer;
  Axis _scrollDirection;
  double _scrollOffset;
  double _minScrollOffset;
  double _maxScrollOffset;

  void _hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _extentAnimation.reverse();
  }

  void _updateState(ScrollableState scrollable) {
    if (scrollable.scrollBehavior is! ExtentScrollBehavior)
      return;
    final ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    _scrollDirection = scrollable.config.scrollDirection;
    _scrollOffset = scrollable.scrollOffset;
    _minScrollOffset = scrollBehavior.minScrollOffset;
    _maxScrollOffset = scrollBehavior.maxScrollOffset;
  }

  void _onScrollStarted(ScrollableState scrollable) {
    _updateState(scrollable);
  }

  void _onScrollUpdated(ScrollableState scrollable) {
    final double value = scrollable.scrollOffset;
    if ((value < _minScrollOffset || value > _maxScrollOffset) &&
        ((value - _scrollOffset).abs() > kPixelScrollTolerance.distance)) {
      _hideTimer?.cancel();
      _hideTimer = new Timer(_kIndicatorTimeoutDuration, _hide);
      // Changing the animation's value causes an implicit setState().
      _extentAnimation.value = value < _minScrollOffset ? _minScrollOffset - value : value - _maxScrollOffset;
    }
    _updateState(scrollable);
  }

  void _onScrollEnded(ScrollableState scrollable) {
    _updateState(scrollable);
    _hide();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (config.scrollableKey == null || config.scrollableKey == notification.scrollable.config.key) {
      final ScrollableState scrollable = notification.scrollable;
      switch(notification.kind) {
        case ScrollNotificationKind.started:
          _onScrollStarted(scrollable);
          break;
        case ScrollNotificationKind.updated:
          _onScrollUpdated(scrollable);
          break;
        case ScrollNotificationKind.ended:
          _onScrollEnded(scrollable);
          break;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _extentAnimation.dispose();
    super.dispose();
  }

  Color get _indicatorColor {
    final Color accentColor = Theme.of(context).accentColor.withOpacity(0.35);
    final double t = (_extentAnimation.value - _kMinIndicatorExtent) / (_kMaxIndicatorExtent - _kMinIndicatorExtent);
    return accentColor.withOpacity(_kIndicatorOpacity.lerp(Curves.easeIn.transform(t)));
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: new AnimatedBuilder(
        animation: _extentAnimation,
        builder: (BuildContext context, Widget child) {
          if (_scrollDirection == null) // Haven't seen a scroll yet.
            return child;
          return new CustomPaint(
            foregroundPainter: new _Painter(
              scrollDirection: _scrollDirection,
              extent: _extentAnimation.value,
              isLeading: _scrollOffset < _minScrollOffset,
              color: _indicatorColor
            ),
            child: child
          );
        },
        child: new ClampOverscrolls(
          child: config.child,
          value: true
        )
      )
    );
  }
}
