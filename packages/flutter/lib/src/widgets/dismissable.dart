// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'transitions.dart';
import 'framework.dart';
import 'gesture_detector.dart';

const Duration _kCardDismissDuration = const Duration(milliseconds: 200);
const Duration _kCardResizeDuration = const Duration(milliseconds: 300);
const Curve _kCardResizeTimeCurve = const Interval(0.4, 1.0, curve: Curves.ease);
const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kDismissCardThreshold = 0.4;

typedef void DismissDirectionCallback(DismissDirection direction);

/// The direction in which a [Dismissable] can be dismissed.
enum DismissDirection {
  /// The [Dismissable] can be dismissed by dragging either up or down.
  vertical,

  /// The [Dismissable] can be dismissed by dragging either left or right.
  horizontal,

  /// The [Dismissable] can be dismissed by dragging left only.
  left,

  /// The [Dismissable] can be dismissed by dragging right only.
  right,

  /// The [Dismissable] can be dismissed by dragging up only.
  up,

  /// The [Dismissable] can be dismissed by dragging down only.
  down
}

/// Can be dismissed by dragging in one or more directions.
///
/// The child is draggable in the indicated direction(s). When released (or
/// flung), the child disappears off the edge and the dismissable widget
/// animates its height (or width, whichever is perpendicular to the dismiss
/// direction) to zero.
class Dismissable extends StatefulComponent {
  Dismissable({
    Key key,
    this.child,
    this.onResized,
    this.onDismissed,
    this.direction: DismissDirection.horizontal
  }) : super(key: key);

  final Widget child;

  /// Called when the widget changes size (i.e., when contracting after being dismissed).
  final VoidCallback onResized;

  /// Called when the widget has been dismissed, after finishing resizing.
  final DismissDirectionCallback onDismissed;

  /// The direction in which the widget can be dismissed.
  final DismissDirection direction;

  _DismissableState createState() => new _DismissableState();
}

class _DismissableState extends State<Dismissable> {
  void initState() {
    super.initState();
    _moveController = new AnimationController(duration: _kCardDismissDuration)
      ..addStatusListener(_handleDismissStatusChanged);
    _updateMoveAnimation();
  }

  AnimationController _moveController;
  Animation<FractionalOffset> _moveAnimation;

  AnimationController _resizeController;
  Animation<double> _resizeAnimation;

  double _dragExtent = 0.0;
  bool _dragUnderway = false;

  void dispose() {
    _moveController?.stop();
    _resizeController?.stop();
    super.dispose();
  }

  bool get _directionIsXAxis {
    return config.direction == DismissDirection.horizontal
        || config.direction == DismissDirection.left
        || config.direction == DismissDirection.right;
  }

  bool get _isActive {
    return _dragUnderway || _moveController.isAnimating;
  }

  Size _findSize() {
    RenderBox box = context.findRenderObject();
    assert(box != null);
    assert(box.hasSize);
    return box.size;
  }

  void _handleDragStart(_) {
    _dragUnderway = true;
    if (_moveController.isAnimating) {
      _dragExtent = _moveController.value * _findSize().width * _dragExtent.sign;
      _moveController.stop();
    } else {
      _dragExtent = 0.0;
      _moveController.value = 0.0;
    }
    setState(() {
      _updateMoveAnimation();
    });
  }

  void _handleDragUpdate(double delta) {
    if (!_isActive || _moveController.isAnimating)
      return;

    double oldDragExtent = _dragExtent;
    switch (config.direction) {
      case DismissDirection.horizontal:
      case DismissDirection.vertical:
        _dragExtent += delta;
        break;

      case DismissDirection.up:
      case DismissDirection.left:
        if (_dragExtent + delta < 0)
          _dragExtent += delta;
        break;

      case DismissDirection.down:
      case DismissDirection.right:
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
      _moveController.value = _dragExtent.abs() / (_directionIsXAxis ? _findSize().width : _findSize().height);
    }
  }

  void _updateMoveAnimation() {
    _moveAnimation = new Tween<FractionalOffset>(
      begin: FractionalOffset.zero,
      end: _directionIsXAxis ?
             new FractionalOffset(_dragExtent.sign, 0.0) :
             new FractionalOffset(0.0, _dragExtent.sign)
    ).animate(_moveController);
  }

  bool _isFlingGesture(Velocity velocity) {
    double vx = velocity.pixelsPerSecond.dx;
    double vy = velocity.pixelsPerSecond.dy;
    if (_directionIsXAxis) {
      if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(config.direction) {
        case DismissDirection.horizontal:
          return vx.abs() > _kMinFlingVelocity;
        case DismissDirection.left:
          return -vx > _kMinFlingVelocity;
        default:
          return vx > _kMinFlingVelocity;
      }
    } else {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta)
        return false;
      switch(config.direction) {
        case DismissDirection.vertical:
          return vy.abs() > _kMinFlingVelocity;
        case DismissDirection.up:
          return -vy > _kMinFlingVelocity;
        default:
          return vy > _kMinFlingVelocity;
      }
    }
    return false;
  }

  void _handleDragEnd(Velocity velocity) {
    if (!_isActive || _moveController.isAnimating)
      return;
    _dragUnderway = false;
    if (_moveController.isCompleted) {
      _startResizeAnimation();
    } else if (_isFlingGesture(velocity)) {
      double flingVelocity = _directionIsXAxis ? velocity.pixelsPerSecond.dx : velocity.pixelsPerSecond.dy;
      _dragExtent = flingVelocity.sign;
      _moveController.fling(velocity: flingVelocity.abs() * _kFlingVelocityScale);
    } else if (_moveController.value > _kDismissCardThreshold) {
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
    _resizeController = new AnimationController(duration: _kCardResizeDuration)
      ..addListener(_handleResizeProgressChanged);
    _resizeController.forward();
    setState(() {
      _resizeAnimation = new Tween<double>(
        begin: _directionIsXAxis ? _findSize().height : _findSize().width,
        end: 0.0
      ).animate(new CurvedAnimation(
        parent: _resizeController,
        curve: _kCardResizeTimeCurve
      ));
    });
  }

  void _handleResizeProgressChanged() {
    if (_resizeController.isCompleted) {
      if (config.onDismissed != null) {
        DismissDirection direction;
        if (_directionIsXAxis)
           direction = _dragExtent > 0 ? DismissDirection.right : DismissDirection.left;
        else
           direction = _dragExtent > 0 ? DismissDirection.down : DismissDirection.up;
        config.onDismissed(direction);
      }
    } else {
      if (config.onResized != null)
        config.onResized();
    }
  }

  Widget build(BuildContext context) {
    if (_resizeAnimation != null) {
      // we've been dragged aside, and are now resizing.
      assert(() {
        if (_resizeAnimation.status != AnimationStatus.forward) {
          assert(_resizeAnimation.status == AnimationStatus.completed);
          throw new WidgetError(
            'Dismissable widget completed its resize animation without being removed from the tree.\n'
            'Make sure to implement the onDismissed handler and to immediately remove the Dismissable '
            'widget from the application once that handler has fired.'
          );
        }
        return true;
      });
      return new AnimatedBuilder(
        animation: _resizeAnimation,
        builder: (BuildContext context, Widget child) {
          return new SizedBox(
            width: !_directionIsXAxis ? _resizeAnimation.value : null,
            height: _directionIsXAxis ? _resizeAnimation.value : null
          );
        }
      );
    }

    // we are not resizing. (we may be being dragged aside.)
    return new GestureDetector(
      onHorizontalDragStart: _directionIsXAxis ? _handleDragStart : null,
      onHorizontalDragUpdate: _directionIsXAxis ? _handleDragUpdate : null,
      onHorizontalDragEnd: _directionIsXAxis ? _handleDragEnd : null,
      onVerticalDragStart: _directionIsXAxis ? null : _handleDragStart,
      onVerticalDragUpdate: _directionIsXAxis ? null : _handleDragUpdate,
      onVerticalDragEnd: _directionIsXAxis ? null : _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: new SlideTransition(
        position: _moveAnimation,
        child: config.child
      )
    );
  }
}
