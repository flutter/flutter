// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/fling_curve.dart';
import '../fn.dart';
import 'dart:sky' as sky;

abstract class Scrollable extends Component {
  double minOffset;
  double maxOffset;

  double get scrollOffset => _scrollOffset;

  double _scrollOffset = 0.0;
  FlingCurve _flingCurve;
  int _flingAnimationId;

  Scrollable({
    Object key,
    this.minOffset,
    this.maxOffset
  }) : super(key: key) {
    events.listen('gestureflingstart', _handleFlingStart);
    events.listen('gestureflingcancel', _handleFlingCancel);
    events.listen('gesturescrollupdate', _handleScrollUpdate);
    events.listen('wheel', _handleWheel);
  }

  void didUnmount() {
    super.didUnmount();
    _stopFling();
  }

  bool scrollBy(double scrollDelta) {
    var newScrollOffset = _scrollOffset + scrollDelta;
    if (minOffset != null && newScrollOffset < minOffset)
      newScrollOffset = minOffset;
    else if (maxOffset != null && newScrollOffset > maxOffset)
      newScrollOffset = maxOffset;

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

  void _updateFling(double timeStamp) {
    double scrollDelta = _flingCurve.update(timeStamp);
    if (!scrollBy(scrollDelta))
      return _stopFling();
    _scheduleFlingUpdate();
  }

  void _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(-event.dy);
  }

  void _handleFlingStart(sky.GestureEvent event) {
    setState(() {
      _flingCurve = new FlingCurve(-event.velocityY, event.timeStamp);
      _scheduleFlingUpdate();
    });
  }

  void _handleFlingCancel(sky.GestureEvent event) {
    _stopFling();
  }

  void _handleWheel(sky.WheelEvent event) {
    scrollBy(-event.offsetY);
  }
}
