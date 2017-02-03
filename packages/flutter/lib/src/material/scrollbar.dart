// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

class Scrollbar2 extends StatefulWidget {
  Scrollbar2({
    Key key,
    this.child,
  }) : super(key: key);

  /// The subtree to place inside the [Scrollbar2]. This should include
  /// a source of [ScrollNotification2] notifications, typically a [Scrollable2]
  /// widget.
  final Widget child;

  @override
  _Scrollbar2State createState() => new _Scrollbar2State();
}

class _Scrollbar2State extends State<Scrollbar2> with TickerProviderStateMixin {
  _ScrollbarController _controller;

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    _controller ??= new _ScrollbarController(this);
    _controller.color = Theme.of(context).highlightColor;
  }

  bool _handleScrollNotification(ScrollNotification2 notification) {
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification)
      _controller.update(notification.metrics, notification.axisDirection);
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification2>(
      onNotification: _handleScrollNotification,
      // TODO(ianh): Maybe we should try to collapse out these repaint
      // boundaries when the scroll bars are invisible.
      child: new RepaintBoundary(
        child: new CustomPaint(
          foregroundPainter: new _ScrollbarPainter(_controller),
          child: new RepaintBoundary(
            child: config.child,
          ),
        ),
      ),
    );
  }
}

class _ScrollbarController extends ChangeNotifier {
  _ScrollbarController(TickerProvider vsync) {
    assert(vsync != null);
    _fadeController = new AnimationController(duration: _kThumbFadeDuration, vsync: vsync);
    _opacity = new CurvedAnimation(parent: _fadeController, curve: Curves.fastOutSlowIn)
      ..addListener(notifyListeners);
  }

  // animation of the main axis direction
  AnimationController _fadeController;
  Animation<double> _opacity;

  // fade-out timer
  Timer _fadeOut;

  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(value != null);
    if (color == value)
      return;
    _color = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _fadeOut?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  ScrollableMetrics _lastMetrics;
  AxisDirection _lastAxisDirection;

  static const double _kMinThumbExtent = 18.0;
  static const double _kThumbGirth = 6.0;
  static const Duration _kThumbFadeDuration = const Duration(milliseconds: 300);
  static const Duration _kFadeOutTimeout = const Duration(milliseconds: 600);

  void update(ScrollableMetrics metrics, AxisDirection axisDirection) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    if (_fadeController.status == AnimationStatus.completed) {
      notifyListeners();
    } else if (_fadeController.status != AnimationStatus.forward) {
      _fadeController.forward();
    }
    _fadeOut?.cancel();
    _fadeOut = new Timer(_kFadeOutTimeout, startFadeOut);
  }

  void startFadeOut() {
    _fadeOut = null;
    _fadeController.reverse();
  }

  Paint get _paint => new Paint()..color = color.withOpacity(_opacity.value);

  void _paintVerticalThumb(Canvas canvas, Size size, double thumbOffset, double thumbExtent) {
    final Point thumbOrigin = new Point(size.width - _kThumbGirth, thumbOffset);
    final Size thumbSize = new Size(_kThumbGirth, thumbExtent);
    canvas.drawRect(thumbOrigin & thumbSize, _paint);
  }

  void _paintHorizontalThumb(Canvas canvas, Size size, double thumbOffset, double thumbExtent) {
    final Point thumbOrigin = new Point(thumbOffset, size.height - _kThumbGirth);
    final Size thumbSize = new Size(thumbExtent, _kThumbGirth);
    canvas.drawRect(thumbOrigin & thumbSize, _paint);
  }

  void _paintThumb(double before, double inside, double after, double viewport, Canvas canvas, Size size,
                   void painter(Canvas canvas, Size size, double thumbOffset, double thumbExtent)) {
    final double thumbExtent = math.max(math.min(viewport, _kMinThumbExtent), viewport * inside / (before + inside + after));
    final double thumbOffset = before * (viewport - thumbExtent) / (before + after);
    painter(canvas, size, thumbOffset, thumbExtent);
  }

  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null || _lastMetrics == null || _opacity.value == 0.0)
      return;
    switch (_lastAxisDirection) {
      case AxisDirection.down:
        _paintThumb(_lastMetrics.extentBefore, _lastMetrics.extentInside, _lastMetrics.extentAfter, size.height, canvas, size, _paintVerticalThumb);
        break;
      case AxisDirection.up:
        _paintThumb(_lastMetrics.extentAfter, _lastMetrics.extentInside, _lastMetrics.extentBefore, size.height, canvas, size, _paintVerticalThumb);
        break;
      case AxisDirection.right:
        _paintThumb(_lastMetrics.extentBefore, _lastMetrics.extentInside, _lastMetrics.extentAfter, size.width, canvas, size, _paintHorizontalThumb);
        break;
      case AxisDirection.left:
        _paintThumb(_lastMetrics.extentAfter, _lastMetrics.extentInside, _lastMetrics.extentBefore, size.width, canvas, size, _paintHorizontalThumb);
        break;
    }
  }
}

class _ScrollbarPainter extends CustomPainter {
  _ScrollbarPainter(this.controller) : super(repaint: controller);

  final _ScrollbarController controller;

  @override
  void paint(Canvas canvas, Size size) {
    controller.paint(canvas, size);
  }

  @override
  bool shouldRepaint(_ScrollbarPainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}

////////////////////////////////////////////////////////////////////////////////
// DELETE EVERYTHING BELOW THIS LINE WHEN REMOVING LEGACY SCROLLING CODE
////////////////////////////////////////////////////////////////////////////////

const double _kMinScrollbarThumbExtent = 18.0;
const double _kScrollbarThumbGirth = 6.0;
const Duration _kScrollbarThumbFadeDuration = const Duration(milliseconds: 300);

class _Painter extends CustomPainter {
  _Painter({
    this.scrollOffset,
    this.scrollDirection,
    this.contentExtent,
    this.containerExtent,
    this.color
  });

  final double scrollOffset;
  final Axis scrollDirection;
  final double contentExtent;
  final double containerExtent;
  final Color color;

  void paintScrollbar(Canvas canvas, Size size) {
    Point thumbOrigin;
    Size thumbSize;

    switch (scrollDirection) {
      case Axis.vertical:
        double thumbHeight = size.height * containerExtent / contentExtent;
        thumbHeight = thumbHeight.clamp(_kMinScrollbarThumbExtent, size.height);
        final double maxThumbTop = size.height - thumbHeight;
        double thumbTop = (scrollOffset / (contentExtent - containerExtent)) * maxThumbTop;
        thumbTop = thumbTop.clamp(0.0, maxThumbTop);
        thumbOrigin = new Point(size.width - _kScrollbarThumbGirth, thumbTop);
        thumbSize = new Size(_kScrollbarThumbGirth, thumbHeight);
        break;
      case Axis.horizontal:
        double thumbWidth = size.width * containerExtent / contentExtent;
        thumbWidth = thumbWidth.clamp(_kMinScrollbarThumbExtent, size.width);
        final double maxThumbLeft = size.width - thumbWidth;
        double thumbLeft = (scrollOffset / (contentExtent - containerExtent)) * maxThumbLeft;
        thumbLeft = thumbLeft.clamp(0.0, maxThumbLeft);
        thumbOrigin = new Point(thumbLeft, size.height - _kScrollbarThumbGirth);
        thumbSize = new Size(thumbWidth, _kScrollbarThumbGirth);
        break;
    }

    final Paint paint = new Paint()..color = color;
    canvas.drawRect(thumbOrigin & thumbSize, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (scrollOffset == null || color.alpha == 0)
      return;
    paintScrollbar(canvas, size);
  }

  @override
  bool shouldRepaint(_Painter oldPainter) {
    return oldPainter.scrollOffset != scrollOffset
        || oldPainter.scrollDirection != scrollDirection
        || oldPainter.contentExtent != contentExtent
        || oldPainter.containerExtent != containerExtent
        || oldPainter.color != color;
  }
}

/// Displays a scrollbar that tracks the scrollOffset of its child's [Scrollable]
/// descendant. If the Scrollbar's child has more than one Scrollable descendant
/// the scrollableKey parameter can be used to identify the one the Scrollbar
/// should track.
class Scrollbar extends StatefulWidget {
  /// Creates a scrollbar.
  ///
  /// The child argument must not be null.
  Scrollbar({ Key key, this.scrollableKey, this.child }) : super(key: key) {
    assert(child != null);
  }

  /// Identifies the [Scrollable] descendant of child that the scrollbar will
  /// track. Can be null if there's only one [Scrollable] descendant.
  final Key scrollableKey;

  /// The scrollbar will be stacked on top of this child. The scrollbar will
  /// display when child's [Scrollable] descendant is scrolled.
  final Widget child;

  @override
  _ScrollbarState createState() => new _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> with SingleTickerProviderStateMixin {
  AnimationController _fade;
  CurvedAnimation _opacity;
  double _scrollOffset;
  Axis _scrollDirection;
  double _containerExtent;
  double _contentExtent;

  @override
  void initState() {
    super.initState();
    _fade = new AnimationController(duration: _kScrollbarThumbFadeDuration, vsync: this);
    _opacity = new CurvedAnimation(parent: _fade, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _fade.stop();
    super.dispose();
  }

  void _updateState(ScrollableState scrollable) {
    if (scrollable.scrollBehavior is! ExtentScrollBehavior)
      return;
    if (_scrollOffset != scrollable.scrollOffset)
      setState(() { _scrollOffset = scrollable.scrollOffset; });
    if (_scrollDirection != scrollable.config.scrollDirection)
      setState(() { _scrollDirection = scrollable.config.scrollDirection; });
    final ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    if (_contentExtent != scrollBehavior.contentExtent)
      setState(() { _contentExtent = scrollBehavior.contentExtent; });
    if (_containerExtent != scrollBehavior.containerExtent)
      setState(() { _containerExtent = scrollBehavior.containerExtent; });
  }

  void _onScrollStarted(ScrollableState scrollable) {
    _updateState(scrollable);
  }

  void _onScrollUpdated(ScrollableState scrollable) {
    _updateState(scrollable);
    if (_fade.status != AnimationStatus.completed)
      _fade.forward();
  }

  void _onScrollEnded(ScrollableState scrollable) {
    _updateState(scrollable);
    _fade.reverse();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (config.scrollableKey == null) {
      if (notification.depth != 0)
        return false;
    } else if (config.scrollableKey != notification.scrollable.config.key) {
      return false;
    }

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
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: new AnimatedBuilder(
        animation: _opacity,
        builder: (BuildContext context, Widget child) {
          return new CustomPaint(
            foregroundPainter: new _Painter(
              scrollOffset: _scrollOffset,
              scrollDirection: _scrollDirection,
              containerExtent: _containerExtent,
              contentExtent: _contentExtent,
              color: Theme.of(context).highlightColor.withOpacity(_opacity.value)
            ),
            child: child
          );
        },
        child: config.child
      )
    );
  }
}
