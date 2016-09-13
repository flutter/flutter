// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Timer;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kMinIndicatorExtent = 0.0;
const double _kMaxIndicatorExtent = 64.0;
const double _kMinIndicatorOpacity = 0.0;
const double _kMaxIndicatorOpacity = 0.25;

final Tween<double> _kIndicatorOpacity = new Tween<double>(begin: 0.0, end: 0.3);

// If an overscroll gesture lasts longer than this the hide timer will
// cause the indicator to fade-out.
const Duration _kTimeoutDuration = const Duration(milliseconds: 500);

// Fade-out duration if the fade-out was triggered by the timer.
const Duration _kTimeoutHideDuration = const Duration(milliseconds: 2000);

// Fade-out duration if the fade-out was triggered by an input gesture.
const Duration _kNormalHideDuration = const Duration(milliseconds: 600);


class _Painter extends CustomPainter {
  _Painter({
    this.scrollDirection,
    this.extent, // Indicator width or height, per scrollDirection.
    this.dragPosition,
    this.isLeading, // Similarly true if the indicator appears at the top/left.
    this.color
  });

  // See EdgeEffect setSize() in https://github.com/android
  static final double _kSizeToRadius = 0.75 / math.sin(math.PI / 6.0);

  final Axis scrollDirection;
  final double extent;
  final bool isLeading;
  final Color color;
  final Point dragPosition;

  void paintIndicator(Canvas canvas, Size size) {
    final Paint paint = new Paint()..color = color;
    final double width = size.width;
    final double height = size.height;

    switch (scrollDirection) {
      case Axis.vertical:
        final double radius = width * _kSizeToRadius;
        final double centerX = width / 2.0;
        final double centerY = isLeading ? extent - radius : height - extent + radius;
        final double eventX = dragPosition?.x ?? 0.0;
        final double biasX = (0.5 - (1.0 - eventX / width)) * centerX;
        canvas.drawCircle(new Point(centerX + biasX, centerY), radius, paint);
        break;
      case Axis.horizontal:
        final double radius = height * _kSizeToRadius;
        final double centerX = isLeading ? extent - radius : width - extent + radius;
        final double centerY = height / 2.0;
        final double eventY = dragPosition?.y ?? 0.0;
        final double biasY = (0.5 - (1.0 - eventY / height)) * centerY;
        canvas.drawCircle(new Point(centerX, centerY + biasY), radius, paint);
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (color.alpha == 0 || size.isEmpty)
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
    this.edge: ScrollableEdge.both,
    this.child
  }) : super(key: key) {
    assert(child != null);
    assert(edge != null);
  }

  /// Identifies the [Scrollable] descendant of child that the overscroll
  /// indicator will track. Can be null if there's only one [Scrollable]
  /// descendant.
  final Key scrollableKey;

  /// Where the overscroll indicator should appear.
  final ScrollableEdge edge;

  /// The overscroll indicator will be stacked on top of this child. The
  /// indicator will appear when child's [Scrollable] descendant is
  /// over-scrolled.
  final Widget child;

  @override
  _OverscrollIndicatorState createState() => new _OverscrollIndicatorState();
}

class _OverscrollIndicatorState extends State<OverscrollIndicator> with SingleTickerProviderStateMixin {

  AnimationController _extentAnimation;
  bool _scrollUnderway = false;
  Timer _hideTimer;
  Axis _scrollDirection;
  double _scrollOffset;
  double _minScrollOffset;
  double _maxScrollOffset;
  Point _dragPosition;

  @override
  void initState() {
    super.initState();
    _extentAnimation = new AnimationController(
      lowerBound: _kMinIndicatorExtent,
      upperBound: _kMaxIndicatorExtent,
      duration: _kNormalHideDuration,
      vsync: this,
    );
  }

  void _hide([Duration duration=_kTimeoutHideDuration]) {
    _scrollUnderway = false;
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!_extentAnimation.isAnimating) {
      _extentAnimation.duration = duration;
      _extentAnimation.reverse();
    }
  }

  void _updateState(ScrollableState scrollable) {
    if (scrollable.scrollBehavior is! ExtentScrollBehavior)
      return;
    final ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    _scrollDirection = scrollable.config.scrollDirection;
    _scrollOffset = scrollable.virtualScrollOffset;
    _minScrollOffset = scrollBehavior.minScrollOffset;
    _maxScrollOffset = scrollBehavior.maxScrollOffset;
  }

  void _onScrollStarted(ScrollableState scrollable) {
    assert(_scrollUnderway == false);
    _scrollUnderway = true;
    _updateState(scrollable);
  }

  void _onScrollUpdated(ScrollableState scrollable, DragUpdateDetails details) {
    if (!_scrollUnderway) // The hide timer has run.
      return;

    final double value = scrollable.virtualScrollOffset;
    if (_isOverscroll(value)) {
      _refreshHideTimer();
      // Hide the indicator as soon as user starts scrolling in the reverse direction of overscroll.
      if (_isReverseScroll(value)) {
        _hide(_kNormalHideDuration);
      } else if (_isMatchingOverscrollEdge(value)) {
        // Changing the animation's value causes an implicit setState().
        _dragPosition = details?.globalPosition ?? Point.origin;
        _extentAnimation.value = value < _minScrollOffset ? _minScrollOffset - value : value - _maxScrollOffset;
      } else {
        _hide(_kNormalHideDuration);
      }
    }
    _updateState(scrollable);
  }

  void _onScrollEnded(ScrollableState scrollable) {
    if (!_scrollUnderway) // The hide timer has run.
      return;

    _updateState(scrollable);
    _hide(_kNormalHideDuration);
  }

  void _refreshHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = new Timer(_kTimeoutDuration, _hide);
  }

  bool _isOverscroll(double scrollOffset) {
    return (scrollOffset < _minScrollOffset || scrollOffset > _maxScrollOffset) &&
      ((scrollOffset - _scrollOffset).abs() > kPixelScrollTolerance.distance);
  }

  bool _isMatchingOverscrollEdge(double scrollOffset) {
    switch (config.edge) {
      case ScrollableEdge.both:
        return true;
      case ScrollableEdge.leading:
        return scrollOffset < _minScrollOffset;
      case ScrollableEdge.trailing:
        return scrollOffset > _maxScrollOffset;
      case ScrollableEdge.none:
        return false;
    }
    return false;
  }

  bool _isReverseScroll(double scrollOffset) {
    final double delta = _scrollOffset - scrollOffset;
    return scrollOffset < _minScrollOffset ? delta < 0.0 : delta > 0.0;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (config.scrollableKey == null) {
        if (notification.depth != 0)
          return false;
    } else if (config.scrollableKey != notification.scrollable.config.key) {
      return false;
    }

    final ScrollableState scrollable = notification.scrollable;
    switch (notification.kind) {
      case ScrollNotificationKind.started:
        _onScrollStarted(scrollable);
        break;
      case ScrollNotificationKind.updated:
        _onScrollUpdated(scrollable, notification.dragUpdateDetails);
        break;
      case ScrollNotificationKind.ended:
        _onScrollEnded(scrollable);
        break;
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
          // We keep the same widget hierarchy here, even when we're not
          // painting anything, to avoid rebuilding the children.
          return new CustomPaint(
            foregroundPainter: _scrollDirection == null ? null : new _Painter(
              scrollDirection: _scrollDirection,
              extent: _extentAnimation.value,
              dragPosition: _dragPosition,
              isLeading: _scrollOffset < _minScrollOffset,
              color: _indicatorColor
            ),
            child: child
          );
        },
        child: new ClampOverscrolls.inherit(
          context: context,
          edge: config.edge,
          child: config.child,
        )
      )
    );
  }
}
