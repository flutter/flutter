// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

const Duration _kToggleDuration = const Duration(milliseconds: 200);

// RenderToggleable is a base class for material style toggleable controls with
// toggle animations. It handles storing the current value, dispatching
// ValueChanged on a tap gesture and driving a changed animation. Subclasses are
// responsible for painting.
abstract class RenderToggleable extends RenderConstrainedBox {
  RenderToggleable({
    bool value,
    Size size,
    this.onChanged
  }) : _value = value,
       super(additionalConstraints: new BoxConstraints.tight(size)) {
    _performance = new ValuePerformance<double>(
      variable: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.easeIn, reverseCurve: Curves.easeOut),
      duration: _kToggleDuration,
      progress: _value ? 1.0 : 0.0
    )..addListener(markNeedsPaint);
  }

  bool get value => _value;
  bool _value;
  void set value(bool value) {
    if (value == _value)
      return;
    _value = value;
    performance.play(value ? AnimationDirection.forward : AnimationDirection.reverse);
  }

  ValueChanged<bool> onChanged;

  ValuePerformance<double> get performance => _performance;
  ValuePerformance<double> _performance;

  double get position => _performance.value;

  TapGestureRecognizer _tap;

  void attach() {
    super.attach();
    _tap = new TapGestureRecognizer(
      router: FlutterBinding.instance.pointerRouter,
      onTap: _handleTap
    );
  }

  void detach() {
    _tap.dispose();
    _tap = null;
    super.detach();
  }

  void handleEvent(InputEvent event, BoxHitTestEntry entry) {
    if (event.type == 'pointerdown' && onChanged != null)
      _tap.addPointer(event);
  }

  void _handleTap() {
    if (onChanged != null)
      onChanged(!_value);
  }

  bool hitTestSelf(Point position) => true;
}
