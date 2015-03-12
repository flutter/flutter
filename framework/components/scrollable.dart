// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/curves.dart';
import '../animation/fling_curve.dart';
import '../animation/generator.dart';
import '../animation/scroll_curve.dart';
import '../fn.dart';
import 'dart:sky' as sky;

abstract class Scrollable extends Component {
  ScrollCurve scrollCurve;
  double get scrollOffset => _scrollOffset;

  double _scrollOffset = 0.0;
  FlingCurve _flingCurve;
  int _flingAnimationId;
  AnimationGenerator _scrollAnimation;

  Scrollable({Object key, this.scrollCurve}) : super(key: key) {
    events.listen('pointerdown', _handlePointerDown);
    events.listen('pointerup', _handlePointerUpOrCancel);
    events.listen('pointercancel', _handlePointerUpOrCancel);
    events.listen('gestureflingstart', _handleFlingStart);
    events.listen('gestureflingcancel', _handleFlingCancel);
    events.listen('gesturescrollupdate', _handleScrollUpdate);
    events.listen('wheel', _handleWheel);
  }

  void didUnmount() {
    super.didUnmount();
    _stopFling();
    _stopScrollAnimation();
  }

  bool scrollBy(double scrollDelta) {
    var newScrollOffset = scrollCurve.apply(_scrollOffset, scrollDelta);
    if (newScrollOffset == _scrollOffset)
      return false;
    setState(() {
      _scrollOffset = newScrollOffset;
    });
    return true;
  }

  void animateScrollTo(double targetScrollOffset, {
      double initialDelay: 0.0,
      double duration: 0.0,
      Curve curve: linear}) {
    _stopScrollAnimation();
    _scrollAnimation = new AnimationGenerator(
        duration: duration,
        begin: _scrollOffset,
        end: targetScrollOffset,
        initialDelay: initialDelay,
        curve: curve);
    _scrollAnimation.onTick.listen((newScrollOffset) {
      if (!scrollBy(newScrollOffset - _scrollOffset))
        _stopScrollAnimation();
    }, onDone: () {
      _scrollAnimation = null;
    });
  }

  void _scheduleFlingUpdate() {
    _flingAnimationId = sky.window.requestAnimationFrame(_updateFling);
  }

  void _stopFling() {
    if (_flingAnimationId == null)
      return;
    sky.window.cancelAnimationFrame(_flingAnimationId);
    _flingCurve = null;
    _flingAnimationId = null;
  }

  void _stopScrollAnimation() {
    if (_scrollAnimation == null)
      return;
    _scrollAnimation.cancel();
    _scrollAnimation = null;
  }

  void _updateFling(double timeStamp) {
    double scrollDelta = _flingCurve.update(timeStamp);
    if (!scrollBy(scrollDelta))
      return _settle();
    _scheduleFlingUpdate();
  }

  void _settle() {
    _stopFling();
    if (_scrollOffset < 0.0)
      animateScrollTo(0.0, duration: 200.0, curve: easeOut);
  }

  void _handlePointerDown(_) {
    _stopFling();
    _stopScrollAnimation();
  }

  void _handlePointerUpOrCancel(_) {
    if (_flingCurve == null)
      _settle();
  }

  void _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(-event.dy);
  }

  void _handleFlingStart(sky.GestureEvent event) {
    _stopScrollAnimation();
    _flingCurve = new FlingCurve(-event.velocityY, event.timeStamp);
    _scheduleFlingUpdate();
  }

  void _handleFlingCancel(sky.GestureEvent event) {
    _settle();
  }

  void _handleWheel(sky.WheelEvent event) {
    scrollBy(-event.offsetY);
  }
}
