// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

const Duration _kDismissDuration = const Duration(milliseconds: 200);
const Curve _kResizeTimeCurve = const Interval(0.4, 1.0, curve: Curves.ease);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissThreshold = 0.4;

/// Signature used by [Dismissible] to indicate that it has been dismissed in
/// the given `direction`.
///
/// Used by [Dismissible.onDismissed].
typedef void DismissDirectionCallback(DismissDirection direction);

/// The direction in which a [Dismissible] can be dismissed.
enum DismissDirection {
  /// The [Dismissible] can be dismissed by dragging either up or down.
  vertical,

  /// The [Dismissible] can be dismissed by dragging either left or right.
  horizontal,

  /// The [Dismissible] can be dismissed by dragging in the reverse of the
  /// reading direction (e.g., from right to left in left-to-right languages).
  endToStart,

  /// The [Dismissible] can be dismissed by dragging in the reading direction
  /// (e.g., from left to right in left-to-right languages).
  startToEnd,

  /// The [Dismissible] can be dismissed by dragging up only.
  up,

  /// The [Dismissible] can be dismissed by dragging down only.
  down
}

/// A widget that can be dismissed by dragging in the indicated [direction].
///
/// Dragging or flinging this widget in the [DismissDirection] causes the child
/// to slide out of view. Following the slide animation, if [resizeDuration] is
/// non-null, the Dismissible widget animates its height (or width, whichever is
/// perpendicular to the dismiss direction) to zero over the [resizeDuration].
///
/// Backgrounds can be used to implement the "leave-behind" idiom. If a background
/// is specified it is stacked behind the Dismissible's child and is exposed when
/// the child moves.
///
/// The widget calls the [onDismissed] callback either after its size has
/// collapsed to zero (if [resizeDuration] is non-null) or immediately after
/// the slide animation (if [resizeDuration] is null). If the Dismissible is a
/// list item, it must have a key that distinguishes it from the other items and
/// its [onDismissed] callback must remove the item from the list.
class Dismissible extends StatefulWidget {
  /// Creates a widget that can be dismissed.
  ///
  /// The [key] argument must not be null because [Dismissible]s are commonly
  /// used in lists and removed from the list when dismissed. Without keys, the
  /// default behavior is to sync widgets based on their index in the list,
  /// which means the item after the dismissed item would be synced with the
  /// state of the dismissed item. Using keys causes the widgets to sync
  /// according to their keys and avoids this pitfall.
  const Dismissible({
    @required Key key,
    @required this.child,
    this.background,
    this.secondaryBackground,
    this.onResize,
    this.onDismissed,
    this.direction: DismissDirection.horizontal,
    this.resizeDuration: const Duration(milliseconds: 300),
    this.dismissThresholds: const <DismissDirection, double>{},
  }) : assert(key != null),
       assert(secondaryBackground != null ? background != null : true),
       super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// A widget that is stacked behind the child. If secondaryBackground is also
  /// specified then this widget only appears when the child has been dragged
  /// down or to the right.
  final Widget background;

  /// A widget that is stacked behind the child and is exposed when the child
  /// has been dragged up or to the left. It may only be specified when background
  /// has also been specified.
  final Widget secondaryBackground;

  /// Called when the widget changes size (i.e., when contracting before being dismissed).
  final VoidCallback onResize;

  /// Called when the widget has been dismissed, after finishing resizing.
  final DismissDirectionCallback onDismissed;

  /// The direction in which the widget can be dismissed.
  final DismissDirection direction;

  /// The amount of time the widget will spend contracting before [onDismissed] is called.
  ///
  /// If null, the widget will not contract and [onDismissed] will be called
  /// immediately after the the widget is dismissed.
  final Duration resizeDuration;

  /// The offset threshold the item has to be dragged in order to be considered dismissed.
  ///
  /// Represented as a fraction, e.g. if it is 0.4, then the item has to be dragged at least
  /// 40% towards one direction to be considered dismissed. Clients can define different
  /// thresholds for each dismiss direction. This allows for use cases where item can be
  /// dismissed to end but not to start.
  final Map<DismissDirection, double> dismissThresholds;

  @override
  _DismissibleState createState() => new _DismissibleState();
}

class _DismissibleClipper extends CustomClipper<Rect> {
  _DismissibleClipper({
    @required this.axis,
    @required this.moveAnimation
  }) : super(reclip: moveAnimation) {
    assert(axis != null);
    assert(moveAnimation != null);
  }

  final Axis axis;
  final Animation<FractionalOffset> moveAnimation;

  @override
  Rect getClip(Size size) {
    assert(axis != null);
    switch (axis) {
      case Axis.horizontal:
        final double offset = moveAnimation.value.dx * size.width;
        if (offset < 0)
          return new Rect.fromLTRB(size.width + offset, 0.0, size.width, size.height);
        return new Rect.fromLTRB(0.0, 0.0, offset, size.height);
      case Axis.vertical:
        final double offset = moveAnimation.value.dy * size.height;
        if (offset < 0)
          return new Rect.fromLTRB(0.0, size.height + offset, size.width, size.height);
        return new Rect.fromLTRB(0.0, 0.0, size.width, offset);
    }
    return null;
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_DismissibleClipper oldClipper) {
    return oldClipper.axis != axis
        || oldClipper.moveAnimation.value != moveAnimation.value;
  }
}

class _DismissibleState extends State<Dismissible> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _moveController = new AnimationController(duration: _kDismissDuration, vsync: this)
      ..addStatusListener(_handleDismissStatusChanged);
    _updateMoveAnimation();
  }

  AnimationController _moveController;
  Animation<FractionalOffset> _moveAnimation;

  AnimationController _resizeController;
  Animation<double> _resizeAnimation;

  double _dragExtent = 0.0;
  bool _dragUnderway = false;
  Size _sizePriorToCollapse;

  @override
  void dispose() {
    _moveController.dispose();
    _resizeController?.dispose();
    super.dispose();
  }

  bool get _directionIsXAxis {
    return widget.direction == DismissDirection.horizontal
        || widget.direction == DismissDirection.endToStart
        || widget.direction == DismissDirection.startToEnd;
  }

  DismissDirection get _dismissDirection {
    if (_directionIsXAxis)
      return  _dragExtent > 0 ? DismissDirection.startToEnd : DismissDirection.endToStart;
    return _dragExtent > 0 ? DismissDirection.down : DismissDirection.up;
  }

  double get _dismissThreshold {
    return widget.dismissThresholds[_dismissDirection] ?? _kDismissThreshold;
  }

  bool get _isActive {
    return _dragUnderway || _moveController.isAnimating;
  }

  double get _overallDragAxisExtent {
    final Size size = context.size;
    return _directionIsXAxis ? size.width : size.height;
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent = _moveController.value * _overallDragAxisExtent * _dragExtent.sign;
      _moveController.stop();
    } else {
      _dragExtent = 0.0;
      _moveController.value = 0.0;
    }
    setState(() {
      _updateMoveAnimation();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController.isAnimating)
      return;

    final double delta = details.primaryDelta;
    final double oldDragExtent = _dragExtent;
    switch (widget.direction) {
      case DismissDirection.horizontal:
      case DismissDirection.vertical:
        _dragExtent += delta;
        break;

      case DismissDirection.up:
      case DismissDirection.endToStart:
        if (_dragExtent + delta < 0)
          _dragExtent += delta;
        break;

      case DismissDirection.down:
      case DismissDirection.startToEnd:
        if (_dragExtent + delta > 0)
          _dragExtent += delta;
        break;
    }
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    if (!_moveController.isAnimating) {
      _moveController.value = _dragExtent.abs() / _overallDragAxisExtent;
    }
  }

  void _updateMoveAnimation() {
    _moveAnimation = new Tween<FractionalOffset>(
      begin: FractionalOffset.topLeft,
      end: _directionIsXAxis ?
             new FractionalOffset(_dragExtent.sign, 0.0) :
             new FractionalOffset(0.0, _dragExtent.sign)
    ).animate(_moveController);
  }

  bool _isFlingGesture(Velocity velocity) {
    // Cannot fling an item if it cannot be dismissed by drag.
    if (_dismissThreshold >= 1.0)
      return false;
    final double vx = velocity.pixelsPerSecond.dx;
    final double vy = velocity.pixelsPerSecond.dy;
    if (_directionIsXAxis) {
      if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(widget.direction) {
        case DismissDirection.horizontal:
          return vx.abs() > _kMinFlingVelocity;
        case DismissDirection.endToStart:
          return -vx > _kMinFlingVelocity;
        default:
          return vx > _kMinFlingVelocity;
      }
    } else {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(widget.direction) {
        case DismissDirection.vertical:
          return vy.abs() > _kMinFlingVelocity;
        case DismissDirection.up:
          return -vy > _kMinFlingVelocity;
        default:
          return vy > _kMinFlingVelocity;
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isActive || _moveController.isAnimating)
      return;
    _dragUnderway = false;
    if (_moveController.isCompleted) {
      _startResizeAnimation();
    } else if (_isFlingGesture(details.velocity)) {
      final double flingVelocity = _directionIsXAxis ? details.velocity.pixelsPerSecond.dx : details.velocity.pixelsPerSecond.dy;
      _dragExtent = flingVelocity.sign;
      _moveController.fling(velocity: flingVelocity.abs() * _kFlingVelocityScale);
    } else if (_moveController.value > _dismissThreshold) {
      _moveController.forward();
    } else {
      _moveController.reverse();
    }
  }

  void _handleDismissStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_dragUnderway)
      _startResizeAnimation();
  }

  void _startResizeAnimation() {
    assert(_moveController != null);
    assert(_moveController.isCompleted);
    assert(_resizeController == null);
    assert(_sizePriorToCollapse == null);
    if (widget.resizeDuration == null) {
      if (widget.onDismissed != null)
        widget.onDismissed(_dismissDirection);
    } else {
      _resizeController = new AnimationController(duration: widget.resizeDuration, vsync: this)
        ..addListener(_handleResizeProgressChanged);
      _resizeController.forward();
      setState(() {
        _sizePriorToCollapse = context.size;
        _resizeAnimation = new Tween<double>(
          begin: 1.0,
          end: 0.0
        ).animate(new CurvedAnimation(
          parent: _resizeController,
          curve: _kResizeTimeCurve
        ));
      });
    }
  }

  void _handleResizeProgressChanged() {
    if (_resizeController.isCompleted) {
      if (widget.onDismissed != null)
        widget.onDismissed(_dismissDirection);
    } else {
      if (widget.onResize != null)
        widget.onResize();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget background = widget.background;
    if (widget.secondaryBackground != null) {
      final DismissDirection direction = _dismissDirection;
      if (direction == DismissDirection.endToStart || direction == DismissDirection.up)
        background = widget.secondaryBackground;
    }

    if (_resizeAnimation != null) {
      // we've been dragged aside, and are now resizing.
      assert(() {
        if (_resizeAnimation.status != AnimationStatus.forward) {
          assert(_resizeAnimation.status == AnimationStatus.completed);
          throw new FlutterError(
            'A dismissed Dismissible widget is still part of the tree.\n'
            'Make sure to implement the onDismissed handler and to immediately remove the Dismissible\n'
            'widget from the application once that handler has fired.'
          );
        }
        return true;
      });

      return new SizeTransition(
        sizeFactor: _resizeAnimation,
        axis: _directionIsXAxis ? Axis.vertical : Axis.horizontal,
        child: new SizedBox(
          width: _sizePriorToCollapse.width,
          height: _sizePriorToCollapse.height,
          child: background
        )
      );
    }

    Widget content = new SlideTransition(
      position: _moveAnimation,
      child: widget.child
    );

    if (background != null) {
      final List<Widget> children = <Widget>[];

      if (!_moveAnimation.isDismissed) {
        children.add(new Positioned.fill(
          child: new ClipRect(
            clipper: new _DismissibleClipper(
              axis: _directionIsXAxis ? Axis.horizontal : Axis.vertical,
              moveAnimation: _moveAnimation,
            ),
            child: background
          )
        ));
      }

      children.add(content);
      content = new Stack(children: children);
    }

    // We are not resizing but we may be being dragging in widget.direction.
    return new GestureDetector(
      onHorizontalDragStart: _directionIsXAxis ? _handleDragStart : null,
      onHorizontalDragUpdate: _directionIsXAxis ? _handleDragUpdate : null,
      onHorizontalDragEnd: _directionIsXAxis ? _handleDragEnd : null,
      onVerticalDragStart: _directionIsXAxis ? null : _handleDragStart,
      onVerticalDragUpdate: _directionIsXAxis ? null : _handleDragUpdate,
      onVerticalDragEnd: _directionIsXAxis ? null : _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: content
    );
  }
}
