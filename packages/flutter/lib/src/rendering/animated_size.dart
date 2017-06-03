// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'box.dart';
import 'object.dart';
import 'shifted_box.dart';

/// A render object that animates its size to its child's size over a given
/// [duration] and with a given [curve]. If the child's size itself animates
/// (i.e. if it changes size two frames in a row, as opposed to abruptly
/// changing size in one frame then remaining that size in subsequent frames),
/// this render object sizes itself to fit the child instead of animating
/// itself.
///
/// When the child overflows the current animated size of this render object, it
/// is clipped.
class RenderAnimatedSize extends RenderAligningShiftedBox {
  /// Creates a render object that animates its size to match its child.
  /// The [duration] and [curve] arguments define the animation.
  ///
  /// The [alignment] argument is used to align the child when the parent is not
  /// (yet) the same size as the child.
  ///
  /// The [duration] is required.
  ///
  /// The [vsync] should specify a [TickerProvider] for the animation
  /// controller.
  ///
  /// The arguments [duration], [curve], [alignment], and [vsync] must
  /// not be null.
  RenderAnimatedSize({
    @required TickerProvider vsync,
    @required Duration duration,
    Curve curve: Curves.linear,
    FractionalOffset alignment: FractionalOffset.center,
    RenderBox child,
  }) : assert(vsync != null),
       assert(duration != null),
       assert(curve != null),
       _vsync = vsync,
       super(child: child, alignment: alignment) {
    _controller = new AnimationController(
      vsync: vsync,
      duration: duration,
    )..addListener(() {
      if (_controller.value != _lastValue)
        markNeedsLayout();
    });
    _animation = new CurvedAnimation(
      parent: _controller,
      curve: curve
    );
  }

  AnimationController _controller;
  CurvedAnimation _animation;
  final SizeTween _sizeTween = new SizeTween();
  bool _didChangeTargetSizeLastFrame = false;
  bool _hasVisualOverflow;
  double _lastValue;

  /// The duration of the animation.
  Duration get duration => _controller.duration;
  set duration(Duration value) {
    assert(value != null);
    if (value == _controller.duration)
      return;
    _controller.duration = value;
  }

  /// The curve of the animation.
  Curve get curve => _animation.curve;
  set curve(Curve value) {
    assert(value != null);
    if (value == _animation.curve)
      return;
    _animation.curve = value;
  }

  /// The [TickerProvider] for the [AnimationController] that runs the animation.
  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    assert(value != null);
    if (value == _vsync)
      return;
    _vsync = value;
    _controller.resync(vsync);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_animatedSize != _sizeTween.end && !_controller.isAnimating)
      _controller.forward();
  }

  @override
  void detach() {
    _controller.stop();
    super.detach();
  }

  Size get _animatedSize {
    return _sizeTween.evaluate(_animation);
  }

  @override
  void performLayout() {
    _lastValue = _controller.value;
    _hasVisualOverflow = false;

    if (child == null) {
      size = _sizeTween.begin = _sizeTween.end = constraints.smallest;
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    if (_sizeTween.end != child.size) {
      _sizeTween.begin = _animatedSize ?? child.size;
      _sizeTween.end = child.size;

      if (_didChangeTargetSizeLastFrame) {
        size = child.size;
        _controller.stop();
      } else {
        // Don't register first change as a last-frame change.
        if (_sizeTween.end != _sizeTween.begin)
          _didChangeTargetSizeLastFrame = true;

        _lastValue = 0.0;
        _controller.forward(from: 0.0);

        size = constraints.constrain(_animatedSize);
      }
    } else {
      _didChangeTargetSizeLastFrame = false;

      size = constraints.constrain(_animatedSize);
    }

    alignChild();

    if (size.width < _sizeTween.end.width ||
        size.height < _sizeTween.end.height)
      _hasVisualOverflow = true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && _hasVisualOverflow) {
      final Rect rect = Offset.zero & size;
      context.pushClipRect(needsCompositing, offset, rect, super.paint);
    } else {
      super.paint(context, offset);
    }
  }
}
