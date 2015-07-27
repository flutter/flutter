// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:newton/newton.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_simulation.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/theme/view_configuration.dart' as config;
import 'package:sky/widgets/basic.dart';

const double _kMillisecondsPerSecond = 1000.0;

double _velocityForFlingGesture(double eventVelocity) {
  // eventVelocity is pixels/second, config min,max limits are pixels/ms
  return eventVelocity.clamp(-config.kMaxFlingVelocity, config.kMaxFlingVelocity) /
    _kMillisecondsPerSecond;
}

abstract class ScrollClient {
  bool ancestorScrolled(Scrollable ancestor);
}

enum ScrollDirection { vertical, horizontal }

abstract class Scrollable extends StatefulComponent {

  Scrollable({
    Key key,
    this.direction: ScrollDirection.vertical
  }) : super(key: key);

  ScrollDirection direction;

  AnimatedSimulation _toEndAnimation; // See _startToEndAnimation()
  AnimationPerformance _toOffsetAnimation; // Started by scrollTo(offset, duration: d)

  void initState() {
    _toEndAnimation = new AnimatedSimulation(_tickScrollOffset);
    _toOffsetAnimation = new AnimationPerformance()
      ..addListener(() {
        scrollTo(_toOffsetAnimation.variable.value);
      });
  }

  void syncFields(Scrollable source) {
    direction == source.direction;
  }

  double _scrollOffset = 0.0;
  double get scrollOffset => _scrollOffset;

  ScrollBehavior _scrollBehavior;
  ScrollBehavior createScrollBehavior();
  ScrollBehavior get scrollBehavior {
    if (_scrollBehavior == null)
      _scrollBehavior = createScrollBehavior();
    return _scrollBehavior;
  }

  Widget buildContent();

  Widget build() {
    return new Listener(
      child: buildContent(),
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      onGestureFlingStart: _handleFlingStart,
      onGestureFlingCancel: _handleFlingCancel,
      onGestureScrollUpdate: _handleScrollUpdate,
      onWheel: _handleWheel
    );
  }

  List<ScrollClient> _registeredScrollClients;

  void registerScrollClient(ScrollClient notifiee) {
    if (_registeredScrollClients == null)
      _registeredScrollClients = new List<ScrollClient>();
    setState(() {
      _registeredScrollClients.add(notifiee);
    });
  }

  void unregisterScrollClient(ScrollClient notifiee) {
    if (_registeredScrollClients == null)
      return;
    setState(() {
      _registeredScrollClients.remove(notifiee);
    });
  }

  void _startToOffsetAnimation(double newScrollOffset, Duration duration) {
      _stopToEndAnimation();
      _stopToOffsetAnimation();
      _toOffsetAnimation
        ..variable = new AnimatedValue<double>(scrollOffset,
          end: newScrollOffset,
          curve: ease
        )
        ..progress = 0.0
        ..duration = duration
        ..play();
  }

  void _stopToOffsetAnimation() {
    if (_toOffsetAnimation.isAnimating)
      _toOffsetAnimation.stop();
  }

  void _startToEndAnimation({ double velocity: 0.0 }) {
    _stopToEndAnimation();
    _stopToOffsetAnimation();
    Simulation simulation = scrollBehavior.release(scrollOffset, velocity);
    if (simulation != null)
      _toEndAnimation.start(simulation);
  }

  void _stopToEndAnimation() {
    _toEndAnimation.stop();
  }

  void didUnmount() {
    _stopToEndAnimation();
    _stopToOffsetAnimation();
    super.didUnmount();
  }

  bool scrollTo(double newScrollOffset, { Duration duration }) {
    if (newScrollOffset == _scrollOffset)
      return false;

    if (duration == null) {
      setState(() {
        _scrollOffset = newScrollOffset;
      });
    } else {
      _startToOffsetAnimation(newScrollOffset, duration);
    }

    if (_registeredScrollClients != null) {
      var newList = null;
      _registeredScrollClients.forEach((target) {
        if (target.ancestorScrolled(this)) {
          if (newList == null)
            newList = new List<ScrollClient>();
          newList.add(target);
        }
      });
      setState(() {
        _registeredScrollClients = newList;
      });
    }
    return true;
  }

  bool scrollBy(double scrollDelta) {
    var newScrollOffset = scrollBehavior.applyCurve(_scrollOffset, scrollDelta);
    return scrollTo(newScrollOffset);
  }

  void settleScrollOffset() {
    _startToEndAnimation();
  }

  void _tickScrollOffset(double value) {
    scrollTo(value);
  }

  void _handlePointerDown(_) {
    _stopToEndAnimation();
    _stopToOffsetAnimation();
  }

  void _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(direction == ScrollDirection.horizontal ? event.dx : -event.dy);
  }

  void _handleFlingStart(sky.GestureEvent event) {
    double eventVelocity = direction == ScrollDirection.horizontal
      ? -event.velocityX
      : -event.velocityY;
    _startToEndAnimation(velocity: _velocityForFlingGesture(eventVelocity));
  }

  void _maybeSettleScrollOffset() {
    if (!_toEndAnimation.isAnimating && !_toOffsetAnimation.isAnimating)
      settleScrollOffset();
  }

  void _handlePointerUpOrCancel(_) { _maybeSettleScrollOffset(); }

  void _handleFlingCancel(sky.GestureEvent event) { _maybeSettleScrollOffset(); }


  void _handleWheel(sky.WheelEvent event) {
    scrollBy(-event.offsetY);
  }
}
