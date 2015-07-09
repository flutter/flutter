// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../animation/animation_performance.dart';
import '../animation/curves.dart';
import '../theme/shadows.dart';
import 'animated_component.dart';
import 'animated_container.dart';
import 'basic.dart';
import 'theme.dart';

// TODO(eseidel): Draw width should vary based on device size:
// http://www.google.com/design/spec/layout/structure.html#structure-side-nav

// Mobile:
// Width = Screen width − 56 dp
// Maximum width: 320dp
// Maximum width applies only when using a left nav. When using a right nav,
// the panel can cover the full width of the screen.

// Desktop/Tablet:
// Maximum width for a left nav is 400dp.
// The right nav can vary depending on content.

const double _kWidth = 304.0;
const double _kMinFlingVelocity = 0.4;
const Duration _kBaseSettleDuration = const Duration(milliseconds: 246);
// TODO(mpcomplete): The curve must be linear if we want the drawer to track
// the user's finger. Odeon remedies this by attaching spring forces to the
// initial timeline when animating (so it doesn't look linear).
const Curve _kAnimationCurve = linear;

typedef void DrawerStatusChangeHandler (bool showing);

class DrawerController {
  DrawerController(this.onStatusChange) {
    container = new AnimatedContainer()
      ..position = new AnimatedType<Point>(
          new Point(-_kWidth, 0.0), end: Point.origin, curve: _kAnimationCurve);
    performance = container.createPerformance([container.position],
                                              duration: _kBaseSettleDuration)
        ..addListener(_checkValue);
  }
  final DrawerStatusChangeHandler onStatusChange;

  AnimationPerformance performance;
  AnimatedContainer container;

  double get xPosition => container.position.value.x;

  bool _oldClosedState = true;
  void _checkValue() {
    var newClosedState = isClosed;
    if (onStatusChange != null && _oldClosedState != newClosedState) {
      onStatusChange(!newClosedState);
      _oldClosedState = newClosedState;
    }
  }

  bool get isClosed => performance.isDismissed;
  bool get _isMostlyClosed => xPosition <= -_kWidth/2;

  void open() => performance.play();

  void close() => performance.reverse();

  void _settle() => _isMostlyClosed ? close() : open();

  void handleMaskTap(_) => close();

  // TODO(mpcomplete): Figure out how to generalize these handlers on a
  // "PannableThingy" interface.
  void handlePointerDown(_) => performance.stop();

  void handlePointerMove(sky.PointerEvent event) {
    if (performance.isAnimating)
      return;
    performance.progress += event.dx / _kWidth;
  }

  void handlePointerUp(_) {
    if (!performance.isAnimating)
      _settle();
  }

  void handlePointerCancel(_) {
    if (!performance.isAnimating)
      _settle();
  }

  void handleFlingStart(event) {
    double velocityX = event.velocityX / 1000;
    if (velocityX.abs() >= _kMinFlingVelocity)
      performance.fling(velocity: velocityX / _kWidth);
  }
}

class Drawer extends AnimatedComponent {
  Drawer({
    String key,
    this.controller,
    this.children,
    this.level: 0
  }) : super(key: key) {
    watchPerformance(controller.performance);
  }

  List<Widget> children;
  int level;
  DrawerController controller;

  void syncFields(Drawer source) {
    children = source.children;
    level = source.level;
    controller = source.controller;
    super.syncFields(source);
  }

  // TODO(mpcomplete): the animation system should handle building, maybe? Or
  // at least setting the transform. Figure out how this could work for things
  // like fades, slides, rotates, pinch, etc.
  Widget build() {
    // TODO(mpcomplete): animate as a fade-in.
    double scaler = controller.performance.progress;
    Color maskColor = new Color.fromARGB((0x7F * scaler).floor(), 0, 0, 0);

    var mask = new Listener(
      child: new Container(decoration: new BoxDecoration(backgroundColor: maskColor)),
      onGestureTap: controller.handleMaskTap
    );

    Widget content = controller.container.build(
      new Container(
        decoration: new BoxDecoration(
          backgroundColor: Theme.of(this).canvasColor,
          boxShadow: shadows[level]),
        width: _kWidth,
        child: new Block(children)
      ));

    return new Listener(
      child: new Stack([ mask, content ]),
      onPointerDown: controller.handlePointerDown,
      onPointerMove: controller.handlePointerMove,
      onPointerUp: controller.handlePointerUp,
      onPointerCancel: controller.handlePointerCancel,
      onGestureFlingStart: controller.handleFlingStart
    );
  }

}
