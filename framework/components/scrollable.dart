// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/curves.dart';
import '../animation/fling_curve.dart';
import '../animation/generator.dart';
import '../animation/scroll_curve.dart';
import '../animation/mechanics.dart';
import '../animation/simulation.dart';
import '../fn.dart';
import 'dart:sky' as sky;

abstract class Scrollable extends Component {
  ScrollCurve scrollCurve;
  double get scrollOffset => _scrollOffset;

  double _scrollOffset = 0.0;
  FlingCurve _flingCurve;
  int _flingAnimationId;
  Simulation _simulation;

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
    _stopSimulation();
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

  void _stopSimulation() {
    if (_simulation == null)
      return;
    _simulation.cancel();
    _simulation = null;
  }

  void _updateFling(double timeStamp) {
    double scrollDelta = _flingCurve.update(timeStamp);
    if (!scrollBy(scrollDelta))
      return _settle();
    _scheduleFlingUpdate();
  }

  void _settle() {
    _stopFling();
    Particle particle = new Particle(position: scrollOffset);
    _simulation = scrollCurve.release(particle);
    if (_simulation == null)
      return;
    _simulation.onTick.listen((_) {
      setState(() {
        _scrollOffset = particle.position;
      });
    });
  }

  void _handlePointerDown(_) {
    _stopFling();
    _stopSimulation();
  }

  void _handlePointerUpOrCancel(_) {
    if (_flingCurve == null)
      _settle();
  }

  void _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(-event.dy);
  }

  void _handleFlingStart(sky.GestureEvent event) {
    _stopSimulation();
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
