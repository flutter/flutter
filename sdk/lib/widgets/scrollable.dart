// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import '../animation/generators.dart';
import '../animation/mechanics.dart';
import '../animation/scroll_behavior.dart';
import '../theme/view_configuration.dart' as config;
import 'basic.dart';
import 'material.dart';

const double _kMillisecondsPerSecond = 1000.0;

double _velocityForFlingGesture(double eventVelocity) {
  return eventVelocity.clamp(-config.kMaxFlingVelocity, config.kMaxFlingVelocity) /
    _kMillisecondsPerSecond;
}

abstract class ScrollClient {
  bool ancestorScrolled(Scrollable ancestor);
}

enum ScrollDirection { vertical, horizontal }

abstract class Scrollable extends StatefulComponent {

  Scrollable({
   String key,
   this.backgroundColor,
   this.direction: ScrollDirection.vertical
  }) : super(key: key);

  Color backgroundColor;
  ScrollDirection direction;

  void syncFields(Scrollable source) {
    backgroundColor = source.backgroundColor;
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

  Simulation _simulation;

  Widget buildContent();

  Widget build() {
    return new Listener(
      child: new Material(
        type: MaterialType.canvas,
        child: buildContent(),
        color: backgroundColor
      ),
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

  bool scrollTo(double newScrollOffset) {
    if (newScrollOffset == _scrollOffset)
      return false;
    setState(() {
      _scrollOffset = newScrollOffset;
    });
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

  void didUnmount() {
    _stopSimulation();
    super.didUnmount();
  }

  void _stopSimulation() {
    if (_simulation == null)
      return;
    _simulation.cancel();
    _simulation = null;
  }

  void _startSimulation(Particle particle) {
    _stopSimulation();
    _simulation = scrollBehavior.release(particle);
    if (_simulation == null)
      return;
    _simulation.onTick.listen((_) => scrollTo(particle.position));
  }

  Particle _createParticle([double velocity = 0.0]) {
    return new Particle(position: _scrollOffset, velocity: velocity);
  }

  void _handlePointerDown(_) {
    _stopSimulation();
  }

  void _handlePointerUpOrCancel(_) {
    if (_simulation == null)
      _startSimulation(_createParticle());
  }

  void _handleScrollUpdate(sky.GestureEvent event) {
    scrollBy(direction == ScrollDirection.horizontal ? event.dx : -event.dy);
  }

  void _handleFlingStart(sky.GestureEvent event) {
    double eventVelocity = direction == ScrollDirection.horizontal
      ? -event.velocityX
      : -event.velocityY;
    _startSimulation(_createParticle(_velocityForFlingGesture(eventVelocity)));
  }

  void _handleFlingCancel(sky.GestureEvent event) {
    _startSimulation(_createParticle());
  }

  void _handleWheel(sky.WheelEvent event) {
    scrollBy(-event.offsetY);
  }

}
