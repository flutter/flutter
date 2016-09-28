// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'progress_indicator.dart';

// The over-scroll distance that moves the indicator to its maximum
// displacement, as a percentage of the scrollable's container extent.
const double _kDragContainerExtentPercentage = 0.25;

// How much the scroll's drag gesture can overshoot the RefreshIndicator's
// displacement; max displacement = _kDragSizeFactorLimit * displacement.
const double _kDragSizeFactorLimit = 1.5;

// How far the indicator must be dragged to trigger the refresh callback.
const double _kDragThresholdFactor = 0.75;

// When the scroll ends, the duration of the refresh indicator's animation
// to the RefreshIndicator's displacment.
const Duration _kIndicatorSnapDuration = const Duration(milliseconds: 150);

// The duration of the ScaleTransition that starts when the refresh action
// has completed.
const Duration _kIndicatorScaleDuration = const Duration(milliseconds: 200);

/// The signature for a function that's called when the user has dragged the
/// refresh indicator far enough to demonstrate that they want the app to
/// refresh. The returned Future must complete when the refresh operation
/// is finished.
typedef Future<Null> RefreshCallback();

/// Where the refresh indicator appears: top for over-scrolls at the
/// start of the scrollable, bottom for over-scrolls at the end.
enum RefreshIndicatorLocation {
  /// The refresh indicator will appear at the top of the scrollable.
  top,

  /// The refresh indicator will appear at the bottom of the scrollable.
  bottom,

  /// The refresh indicator will appear at both ends of the scrollable.
  both
}

// The state machine moves through these modes only when the scrollable
// identified by scrollableKey has been scrolled to its min or max limit.
enum _RefreshIndicatorMode {
  drag,   // Pointer is down.
  armed,  // Dragged far enough that an up event will run the refresh callback.
  snap,   // Animating to the indicator's final "displacement".
  refresh, // Running the refresh callback.
  dismiss  // Animating the indicator's fade-out.
}

enum _DismissTransition {
  shrink, // Refresh callback completed, scale the indicator to 0.
  slide // No refresh, translate the indicator out of view.
}

/// A widget that supports the Material "swipe to refresh" idiom.
///
/// When the child's vertical Scrollable descendant overscrolls, an
/// animated circular progress indicator is faded into view. When the scroll
/// ends, if the indicator has been dragged far enough for it to become
/// completely opaque, the refresh callback is called. The callback is
/// expected to update the scrollable's contents and then complete the Future
/// it returns. The refresh indicator disappears after the callback's
/// Future has completed.
///
/// The required [scrollableKey] parameter identifies the scrollable widget
/// whose scrollOffset is monitored by this RefreshIndicator. The same
/// scrollableKey must also be set on the scrollable. See [Block.scrollableKey],
/// [ScrollableList.scrollableKey], etc.
///
/// See also:
///
///  * <https://www.google.com/design/spec/patterns/swipe-to-refresh.html>
///  * [RefreshIndicatorState], can be used to programatically show the refresh indicator.
///  * [RefreshProgressIndicator].
class RefreshIndicator extends StatefulWidget {
  /// Creates a refresh indicator.
  ///
  /// The [refresh] and [child] arguments must be non-null. The default
  /// [displacement] is 40.0 logical pixels.
  RefreshIndicator({
    Key key,
    this.scrollableKey,
    this.child,
    this.displacement: 40.0,
    this.refresh,
    this.location: RefreshIndicatorLocation.top,
    this.color,
    this.backgroundColor
  }) : super(key: key) {
    assert(child != null);
    assert(refresh != null);
    assert(location != null);
  }

  /// Identifies the [Scrollable] descendant of child that will cause the
  /// refresh indicator to appear.
  final GlobalKey<ScrollableState> scrollableKey;

  /// The refresh indicator will be stacked on top of this child. The indicator
  /// will appear when child's Scrollable descendant is over-scrolled.
  final Widget child;

  /// The distance from the child's top or bottom edge to where the refresh indicator
  /// will settle. During the drag that exposes the refresh indicator, its actual
  /// displacement may significantly exceed this value.
  final double displacement;

  /// A function that's called when the user has dragged the refresh indicator
  /// far enough to demonstrate that they want the app to refresh. The returned
  /// Future must complete when the refresh operation is finished.
  final RefreshCallback refresh;

  /// Where the refresh indicator should appear, [RefreshIndicatorLocation.top]
  /// by default.
  final RefreshIndicatorLocation location;

  /// The progress indicator's foreground color. The current theme's
  /// [ThemeData.accentColor] by default.
  final Color color;

  /// The progress indicator's background color. The current theme's
  /// [ThemeData.canvasColor] by default.
  final Color backgroundColor;

  @override
  RefreshIndicatorState createState() => new RefreshIndicatorState();
}

/// Contains the state for a [RefreshIndicator]. This class can be used to
/// programmatically show the refresh indicator, see the [show] method.
class RefreshIndicatorState extends State<RefreshIndicator> with TickerProviderStateMixin {
  AnimationController _sizeController;
  AnimationController _scaleController;
  Animation<double> _sizeFactor;
  Animation<double> _scaleFactor;
  Animation<double> _value;
  Animation<Color> _valueColor;

  double _dragOffset;
  bool _isIndicatorAtTop = true;
  _RefreshIndicatorMode _mode;
  Future<Null> _pendingRefreshFuture;

  @override
  void initState() {
    super.initState();

    _sizeController = new AnimationController(vsync: this);
    _sizeFactor = new Tween<double>(begin: 0.0, end: _kDragSizeFactorLimit).animate(_sizeController);
    _value = new Tween<double>( // The "value" of the circular progress indicator during a drag.
      begin: 0.0,
      end: 0.75
    ).animate(_sizeController);

    _scaleController = new AnimationController(vsync: this);
    _scaleFactor = new Tween<double>(begin: 1.0, end: 0.0).animate(_scaleController);
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  bool _isValidScrollable(ScrollableState scrollable) {
    if (scrollable == null)
      return false;
    final Axis axis = scrollable.config.scrollDirection;
    return axis == Axis.vertical && scrollable.scrollBehavior is ExtentScrollBehavior;
  }

  bool _isScrolledToLimit(ScrollableState scrollable) {
    final double minScrollOffset = scrollable.scrollBehavior.minScrollOffset;
    final double maxScrollOffset = scrollable.scrollBehavior.maxScrollOffset;
    final double scrollOffset = scrollable.scrollOffset;
    switch (config.location) {
      case RefreshIndicatorLocation.top:
        return scrollOffset <= minScrollOffset;
      case RefreshIndicatorLocation.bottom:
        return scrollOffset >= maxScrollOffset;
      case RefreshIndicatorLocation.both:
        return scrollOffset <= minScrollOffset || scrollOffset >= maxScrollOffset;
    }
    return false;
  }

  double _overscrollDistance(ScrollableState scrollable) {
    final double minScrollOffset = scrollable.scrollBehavior.minScrollOffset;
    final double maxScrollOffset = scrollable.scrollBehavior.maxScrollOffset;
    final double scrollOffset = scrollable.scrollOffset;
    switch (config.location) {
      case RefreshIndicatorLocation.top:
        return  scrollOffset <= minScrollOffset ? -_dragOffset : 0.0;
      case RefreshIndicatorLocation.bottom:
        return scrollOffset >= maxScrollOffset ? _dragOffset : 0.0;
      case RefreshIndicatorLocation.both: {
        if (scrollOffset <= minScrollOffset)
          return -_dragOffset;
        else if (scrollOffset >= maxScrollOffset)
          return _dragOffset;
        else
          return 0.0;
      }
    }
    return 0.0;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_mode != null)
      return;

    final ScrollableState scrollable = config.scrollableKey.currentState;
    if (!_isValidScrollable(scrollable) || !_isScrolledToLimit(scrollable))
      return;

    _dragOffset = 0.0;
    _scaleController.value = 0.0;
    _sizeController.value = 0.0;
    setState(() {
      _mode = _RefreshIndicatorMode.drag;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_mode != _RefreshIndicatorMode.drag && _mode != _RefreshIndicatorMode.armed)
      return;

    final ScrollableState scrollable = config.scrollableKey?.currentState;
    if (!_isValidScrollable(scrollable))
      return;

    final double dragOffsetDelta = scrollable.pixelOffsetToScrollOffset(event.delta.dy);
    _dragOffset += dragOffsetDelta / 2.0;
    if (_dragOffset.abs() < kPixelScrollTolerance.distance)
      return;

    final double containerExtent = scrollable.scrollBehavior.containerExtent;
    final double overscroll = _overscrollDistance(scrollable);
    if (overscroll > 0.0) {
      final double newValue = overscroll / (containerExtent * _kDragContainerExtentPercentage);
      _sizeController.value = newValue.clamp(0.0, 1.0);

      final bool newIsAtTop = _dragOffset < 0;
      if (_isIndicatorAtTop != newIsAtTop) {
        setState(() {
          _isIndicatorAtTop = newIsAtTop;
        });
      }
    }
    // No setState() here because this doesn't cause a visual change.
    _mode = _valueColor.value.alpha == 0xFF ? _RefreshIndicatorMode.armed : _RefreshIndicatorMode.drag;
  }

  // Stop showing the refresh indicator
  Future<Null> _dismiss(_DismissTransition transition) async {
    setState(() {
      _mode = _RefreshIndicatorMode.dismiss;
    });
    switch(transition) {
      case _DismissTransition.shrink:
        await _sizeController.animateTo(0.0, duration: _kIndicatorScaleDuration);
        break;
      case _DismissTransition.slide:
        await _scaleController.animateTo(1.0, duration: _kIndicatorScaleDuration);
        break;
    }
    if (mounted && _mode == _RefreshIndicatorMode.dismiss) {
      setState(() {
        _mode = null;
      });
    }
  }

  Future<Null> _show() async {
    _mode = _RefreshIndicatorMode.snap;
    await _sizeController.animateTo(1.0 / _kDragSizeFactorLimit, duration: _kIndicatorSnapDuration);
    if (mounted && _mode == _RefreshIndicatorMode.snap) {
      assert(config.refresh != null);
      setState(() {
        _mode = _RefreshIndicatorMode.refresh; // Show the indeterminate progress indicator.
      });

      // Only one refresh callback is allowed to run at a time. If the user
      // attempts to start a refresh while one is still running ("pending") we
      // just continue to wait on the pending refresh.
      if (_pendingRefreshFuture == null)
        _pendingRefreshFuture = config.refresh();
      await _pendingRefreshFuture;
      bool completed = _pendingRefreshFuture != null;
      _pendingRefreshFuture = null;

      if (mounted && completed && _mode == _RefreshIndicatorMode.refresh)
        _dismiss(_DismissTransition.slide);
    }
  }

  Future<Null> _doHandlePointerUp(PointerUpEvent event) async {
    if (_mode == _RefreshIndicatorMode.armed)
      _show();
    else if (_mode == _RefreshIndicatorMode.drag)
      _dismiss(_DismissTransition.shrink);
  }

  void _handlePointerUp(PointerEvent event) {
    _doHandlePointerUp(event);
  }

  /// Show the refresh indicator and run the refresh callback as if it had
  /// been started interactively. If this method is called while the refresh
  /// callback is running, it quietly does nothing.
  ///
  /// Creating the RefreshIndicator with a [GlobalKey<RefreshIndicatorState>]
  /// makes it possible to refer to the [RefreshIndicatorState].
  Future<Null> show() async {
    if (_mode != _RefreshIndicatorMode.refresh) {
      _sizeController.value = 0.0;
      _scaleController.value = 0.0;
      await _show();
    }
  }

  ScrollableEdge get _clampOverscrollsEdge {
    switch (config.location) {
      case RefreshIndicatorLocation.top:
        return ScrollableEdge.leading;
      case RefreshIndicatorLocation.bottom:
        return ScrollableEdge.trailing;
      case RefreshIndicatorLocation.both:
        return ScrollableEdge.both;
    }
    return ScrollableEdge.none;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool showIndeterminateIndicator =
      _mode == _RefreshIndicatorMode.refresh || _mode == _RefreshIndicatorMode.dismiss;

    // Fully opaque when we've reached config.displacement.
    _valueColor = new ColorTween(
      begin: (config.color ?? theme.accentColor).withOpacity(0.0),
      end: (config.color ?? theme.accentColor).withOpacity(1.0)
    )
    .animate(new CurvedAnimation(
      parent: _sizeController,
      curve: new Interval(0.0, 1.0 / _kDragSizeFactorLimit)
    ));

    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: new Stack(
        children: <Widget>[
          new ClampOverscrolls.inherit(
            context: context,
            edge: _clampOverscrollsEdge,
            child: config.child,
          ),
          new Positioned(
            top: _isIndicatorAtTop ? 0.0 : null,
            bottom: _isIndicatorAtTop ? null : 0.0,
            left: 0.0,
            right: 0.0,
            child: new SizeTransition(
              axisAlignment: _isIndicatorAtTop ? 1.0 : 0.0,
              sizeFactor: _sizeFactor,
              child: new Container(
                padding: _isIndicatorAtTop
                  ? new EdgeInsets.only(top: config.displacement)
                  : new EdgeInsets.only(bottom: config.displacement),
                alignment: _isIndicatorAtTop
                  ? FractionalOffset.bottomCenter
                  : FractionalOffset.topCenter,
                child: new ScaleTransition(
                  scale: _scaleFactor,
                  child: new AnimatedBuilder(
                    animation: _sizeController,
                    builder: (BuildContext context, Widget child) {
                      return new RefreshProgressIndicator(
                        value: showIndeterminateIndicator ? null : _value.value,
                        valueColor: _valueColor,
                        backgroundColor: config.backgroundColor
                      );
                    }
                  )
                )
              )
            )
          )
        ]
      )
    );
  }
}
