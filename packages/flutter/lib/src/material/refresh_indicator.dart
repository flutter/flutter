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

/// A widget that supports the Material "swipe to refresh" idiom.
///
/// When the child's vertical Scrollable descendant overscrolls, an
/// animated circular progress indicator is faded into view. When the scroll
/// ends, if the indicator has been dragged far enough for it to become
/// completely opaque, the refresh callback is called. The callback is
/// expected to udpate the scrollback and then complete the Future it
/// returns. The refresh indicator disappears after the callback's
/// Future has completed.
///
/// The required [scrollableKey] parameter identifies the scrollable widget
/// whose scrollOffset is monitored by this RefreshIndicator. The same
/// scrollableKey must also be set on the scrollable. See [Block.scrollableKey]
/// [ScrollableList.scrollableKey], etc.
///
/// See also:
///
///  * <https://www.google.com/design/spec/patterns/swipe-to-refresh.html>
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
    this.location: RefreshIndicatorLocation.top
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

  /// Where the refresh indicator should appear, RefreshIndicatorLocation.top
  /// by default.
  final RefreshIndicatorLocation location;

  @override
  _RefreshIndicatorState createState() => new _RefreshIndicatorState();
}

class _RefreshIndicatorState extends State<RefreshIndicator> {
  final AnimationController _sizeController = new AnimationController();
  final AnimationController _scaleController = new AnimationController();
  Animation<double> _sizeFactor;
  Animation<double> _scaleFactor;
  Animation<double> _value;
  Animation<Color> _valueColor;

  double _scrollOffset;
  double _containerExtent;
  double _minScrollOffset;
  double _maxScrollOffset;
  bool _isIndicatorAtTop = true;
  _RefreshIndicatorMode _mode;
  Future<Null> _pendingRefreshFuture;

  @override
  void initState() {
    super.initState();
    _sizeFactor = new Tween<double>(begin: 0.0, end: _kDragSizeFactorLimit).animate(_sizeController);
    _scaleFactor = new Tween<double>(begin: 1.0, end: 0.0).animate(_scaleController);

    final ThemeData theme = Theme.of(context);

    // The "value" of the circular progress indicator during a drag.
    _value = new Tween<double>(
      begin: 0.0,
      end: 0.75
    )
    .animate(_sizeController);

    // Fully opaque when we've reached config.displacement.
    _valueColor = new ColorTween(
      begin: theme.primaryColor.withOpacity(0.0),
      end: theme.primaryColor.withOpacity(1.0)
    )
    .animate(new CurvedAnimation(
      parent: _sizeController,
      curve: new Interval(0.0, 1.0 / _kDragSizeFactorLimit)
    ));

  }

  @override
  void dispose() {
    _sizeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _updateState(ScrollableState scrollable) {
    final Axis axis = scrollable.config.scrollDirection;
    if (axis != Axis.vertical || scrollable.scrollBehavior is! ExtentScrollBehavior)
      return;
    final ExtentScrollBehavior scrollBehavior = scrollable.scrollBehavior;
    _scrollOffset = scrollable.scrollOffset;
    _containerExtent = scrollBehavior.containerExtent;
    _minScrollOffset = scrollBehavior.minScrollOffset;
    _maxScrollOffset = scrollBehavior.maxScrollOffset;
  }

  void _handlePointerDown(PointerDownEvent event) {
    final ScrollableState scrollable = config.scrollableKey?.currentState;
    if (scrollable == null)
      return;

    _updateState(scrollable);
    _scaleController.value = 0.0;
    _sizeController.value = 0.0;
    setState(() {
      _mode = _RefreshIndicatorMode.drag;
    });
  }

  double _overscrollDistance() {
    final ScrollableState scrollable = config.scrollableKey?.currentState;
    if (scrollable == null)
      return 0.0;

    final double oldOffset = _scrollOffset;
    final double newOffset = scrollable.scrollOffset;
    _updateState(scrollable);

    if ((newOffset - oldOffset).abs() < kPixelScrollTolerance.distance)
      return 0.0;

    switch (config.location) {
      case RefreshIndicatorLocation.top:
        return newOffset < _minScrollOffset ? _minScrollOffset - newOffset : 0.0;

      case RefreshIndicatorLocation.bottom:
        return newOffset > _maxScrollOffset ? newOffset - _maxScrollOffset : 0.0;

      case RefreshIndicatorLocation.both: {
        if (newOffset < _minScrollOffset)
          return _minScrollOffset - newOffset;
        else if (newOffset > _maxScrollOffset)
          return newOffset - _maxScrollOffset;
        else
          return 0.0;
      }
    }
    return 0.0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final double overscroll = _overscrollDistance();
    if (overscroll > 0.0) {
      final double newValue = overscroll / (_containerExtent * _kDragContainerExtentPercentage);
      _sizeController.value = newValue.clamp(0.0, 1.0);

      final bool newIsAtTop = _scrollOffset < _minScrollOffset;
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
  Future<Null> _dismiss() async {
    setState(() {
      _mode = _RefreshIndicatorMode.dismiss;
    });
    await _scaleController.animateTo(1.0, duration: _kIndicatorScaleDuration);
    if (mounted && _mode == _RefreshIndicatorMode.dismiss) {
      setState(() {
        _mode = null;
      });
    }
  }

  Future<Null> _doHandlePointerUp(PointerUpEvent event) async {
    if (_mode == _RefreshIndicatorMode.armed) {
      _mode = _RefreshIndicatorMode.snap;
      await _sizeController.animateTo(1.0 / _kDragSizeFactorLimit, duration: _kIndicatorSnapDuration);
      if (mounted && _mode == _RefreshIndicatorMode.snap) {
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
          _dismiss();
      }
    } else if (_mode == _RefreshIndicatorMode.drag) {
      _dismiss();
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _doHandlePointerUp(event);
  }

  @override
  Widget build(BuildContext context) {
    final bool showIndeterminateIndicator =
      _mode == _RefreshIndicatorMode.refresh || _mode == _RefreshIndicatorMode.dismiss;
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: new Stack(
        children: <Widget>[
          new ClampOverscrolls(
            child: config.child,
            value: true
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
                child: new Align(
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
                          valueColor: _valueColor
                        );
                      }
                    )
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
