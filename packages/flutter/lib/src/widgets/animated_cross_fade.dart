// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'animated_size.dart';
import 'basic.dart';
import 'framework.dart';
import 'transitions.dart';

/// Specifies which of the children to show. See [AnimatedCrossFade].
///
/// The child that is shown will fade in, and while the other will fade out.
enum CrossFadeState {
  /// Show the first child and hide the second.
  showFirst,
  /// Show the second child and hide the first.
  showSecond
}

/// A widget that cross-fades between two children and animates tself between
/// their sizes. The animation is controlled through the [crossFadeState]
/// parameter. [firstCurve] and [secondCurve] represent the opacity curves of
/// the two children, and will typically be [Interval] objects. Note that
/// [firstCurve] is inverted, i.e. it fades out when providing a growing curve
/// like [Curves.linear]. [sizeCurve] is the curve used to animated between the
/// size of the fading out child and the size of the fading in child.
///
/// In the case where the two children have different sizes, the animation crops
/// overflowing children during the animation by aligning them to the top left.
/// This means that the bottom and right will be clipped.
class AnimatedCrossFade extends StatefulWidget {
  /// Creates a cross fade animation widget.
  ///
  /// The [duration] of the animation is the same for all components (fade in,
  /// fade out, and size), and you can pass [Interval]s instead of [Curve]s in
  /// order to have finer control.
  AnimatedCrossFade({
    Key key,
    this.firstChild,
    this.secondChild,
    this.animationAxis: Axis.vertical,
    this.firstCurve: Curves.linear,
    this.secondCurve: Curves.linear,
    this.sizeCurve: Curves.linear,
    @required this.crossFadeState,
    @required this.duration
  }) : super(key: key) {
    assert(this.firstCurve != null);
    assert(this.secondCurve != null);
    assert(this.animationAxis != null);
    assert(this.sizeCurve != null);
  }

  /// The first child. It fades in an out according to [crossFadeState].
  final Widget firstChild;

  /// The second child. It fades in an out according to [crossFadeState].
  final Widget secondChild;

  /// The state towards which the widget is animating.
  final CrossFadeState crossFadeState;

  /// The axis where size animation is performed.
  ///
  /// Since children are always aligned to the top left, the size animation will
  /// always happen either on the bottom edge or right edge of the widget.
  final Axis animationAxis;

  /// The duration of the whole orchestrated animation.
  final Duration duration;

  /// The fade curve of the first child. This curve is inverted, i.e. the first
  /// widget is visible when this curve provides the value 0.0, and is hidden
  /// when the curve provides the value 1.0.
  final Curve firstCurve;

  /// The fade curve of the second child.
  final Curve secondCurve;

  /// The curve of the animation between the two children's sizes.
  final Curve sizeCurve;

  @override
  _AnimatedCrossFadeState createState() => new _AnimatedCrossFadeState();
}

class _AnimatedCrossFadeState extends State<AnimatedCrossFade> {
  _AnimatedCrossFadeState() : super();

  AnimationController _controller;
  Animation<double> _firstAnimation;
  Animation<double> _secondAnimation;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: config.duration);
    _firstAnimation = new Tween<double>(
      begin: 1.0,
      end: 0.0
    ).animate(
      new CurvedAnimation(
        parent: _controller,
        curve: config.firstCurve
      )
    );
    _secondAnimation = new CurvedAnimation(
      parent: _controller,
      curve: config.secondCurve
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateConfig(AnimatedCrossFade oldConfig) {
    super.didUpdateConfig(oldConfig);

    switch (config.crossFadeState) {
      case CrossFadeState.showFirst:
        _controller.reverse();
        break;
      case CrossFadeState.showSecond:
        _controller.forward();
        break;
    }

    if (config.duration != oldConfig.duration)
      _controller.duration = config.duration;
    if (config.firstCurve != oldConfig.firstCurve) {
      _firstAnimation = new Tween<double>(
        begin: 1.0,
        end: 0.0
      ).animate(
        new CurvedAnimation(
          parent: _controller,
          curve: config.firstCurve
        )
      );
    }
    if (config.secondCurve != oldConfig.secondCurve) {
      _secondAnimation = new CurvedAnimation(
        parent: _controller,
        curve: config.secondCurve
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Stack stack;

    if (_controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward) {
      stack = new Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          new FadeTransition(
            opacity: _secondAnimation,
            child: config.secondChild
          ),
          new Positioned(
            // TODO(dragostis): Add a way to crop from top right for
            // right-to-left languages.
            left: 0.0,
            top: 0.0,
            right: config.animationAxis == Axis.vertical ? 0.0 : null,
            bottom: config.animationAxis == Axis.horizontal ? 0.0 : null,
            child: new FadeTransition(
              opacity: _firstAnimation,
              child: config.firstChild
            )
          )
        ]
      );
    } else {
      stack = new Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          new FadeTransition(
            opacity: _firstAnimation,
            child: config.firstChild
          ),
          new Positioned(
            // TODO(dragostis): Add a way to crop from top right for
            // right-to-left languages.
            left: 0.0,
            top: 0.0,
            right: config.animationAxis == Axis.vertical ? 0.0 : null,
            bottom: config.animationAxis == Axis.horizontal ? 0.0 : null,
            child: new FadeTransition(
              opacity: _secondAnimation,
              child: config.secondChild
            )
          )
        ]
      );
    }

    return new ClipRect(
      child: new AnimatedSize(
        key: new ValueKey<Key>(config.key),
        alignment: FractionalOffset.topCenter,
        duration: config.duration,
        curve: config.sizeCurve,
        child: stack
      )
    );
  }
}
