// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';

import 'basic.dart';
import 'focus.dart';
import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';
import 'status_transitions.dart';
import 'transitions.dart';

const Color _kTransparent = const Color(0x00000000);

class ModalBarrier extends StatelessComponent {
  ModalBarrier({
    Key key,
    this.color: _kTransparent
  }) : super(key: key);

  final Color color;

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: (_) {
        Navigator.of(context).pop();
      },
      child: new ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: new DecoratedBox(
          decoration: new BoxDecoration(
            backgroundColor: color
          )
        )
      )
    );
  }
}

class AnimatedModalBarrier extends StatelessComponent {
  AnimatedModalBarrier({
    Key key,
    this.color,
    this.performance
  }) : super(key: key);

  final AnimatedColorValue color;
  final PerformanceView performance;

  Widget build(BuildContext context) {
    return new BuilderTransition(
      performance: performance,
      variables: <AnimatedColorValue>[color],
      builder: (BuildContext context) {
        return new IgnorePointer(
          ignoring: performance.status == PerformanceStatus.reverse,
          child: new ModalBarrier(color: color.value)
        );
      }
    );
  }
}

class _ModalScope extends StatusTransitionComponent {
  _ModalScope({
    Key key,
    ModalRoute route,
    this.child
  }) : route = route, super(key: key, performance: route.performance);

  final ModalRoute route;
  final Widget child;

  Widget build(BuildContext context) {
    Widget focus = new Focus(
      key: new GlobalObjectKey(route),
      child: new IgnorePointer(
        ignoring: route.performance.status == PerformanceStatus.reverse,
        child: child
      )
    );
    ModalPosition position = route.position;
    if (position == null)
      return focus;
    return new Positioned(
      top: position.top,
      right: position.right,
      bottom: position.bottom,
      left: position.left,
      child: focus
    );
  }
}

class ModalPosition {
  const ModalPosition({ this.top, this.right, this.bottom, this.left });
  final double top;
  final double right;
  final double bottom;
  final double left;
}

abstract class ModalRoute extends TransitionRoute {
  ModalPosition get position => null;
  Color get barrierColor => _kTransparent;
  Widget buildModalWidget(BuildContext context);

  Widget _buildModalBarrier(BuildContext context) {
    return new AnimatedModalBarrier(
      color: new AnimatedColorValue(_kTransparent, end: barrierColor, curve: Curves.ease),
      performance: performance
    );
  }

  Widget _buildModalScope(BuildContext context) {
    return new _ModalScope(route: this, child: buildModalWidget(context));
  }

  List<WidgetBuilder> get builders => <WidgetBuilder>[ _buildModalBarrier, _buildModalScope ];
}
