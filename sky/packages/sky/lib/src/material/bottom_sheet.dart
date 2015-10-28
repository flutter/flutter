// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material.dart';

const Duration _kBottomSheetDuration = const Duration(milliseconds: 200);
const double _kMinFlingVelocity = 700.0;
const double _kFlingVelocityScale = 1.0 / 300.0;

class _BottomSheet extends StatefulComponent {
  _BottomSheet({
    Key key,
    this.child,
    this.performance
  }) : super(key: key);

  final Widget child;
  final Performance performance;

  _BottomSheetState createState() => new _BottomSheetState();
}

class _BottomSheetLayout extends OneChildLayoutDelegate {
  // The distance from the bottom of the parent to the top of the BottomSheet child.
  AnimatedValue<double> childTop = new AnimatedValue<double>(0.0);

  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: constraints.maxHeight * 9.0 / 16.0
    );
  }

  Point getPositionForChild(Size size, Size childSize) {
    childTop.end = childSize.height;
    return new Point(0.0, size.height - childTop.value);
  }
}

class _BottomSheetState extends State<_BottomSheet> {

  final _BottomSheetLayout _layout = new _BottomSheetLayout();
  bool _dragEnabled = false;

  void _handleDragStart(Point position) {
    _dragEnabled = !config.performance.isAnimating;
  }

  void _handleDragUpdate(double delta) {
    if (!_dragEnabled)
      return;
    config.performance.progress -= delta / _layout.childTop.end;
  }

  void _handleDragEnd(Offset velocity) {
    if (!_dragEnabled)
      return;
    if (velocity.dy > _kMinFlingVelocity)
      config.performance.fling(velocity: -velocity.dy * _kFlingVelocityScale);
    else
      config.performance.forward();
  }

  Widget build(BuildContext context) {
    return new BuilderTransition(
      performance: config.performance,
      variables: <AnimatedValue<double>>[_layout.childTop],
      builder: (BuildContext context) {
        return new ClipRect(
          child: new CustomOneChildLayout(
            delegate: _layout,
            token: _layout.childTop.value,
            child: new GestureDetector(
              onVerticalDragStart: _handleDragStart,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              child: new Material(child: config.child)
            )
          )
        );
      }
    );
  }
}

class _ModalBottomSheetRoute extends Route {
  _ModalBottomSheetRoute({ this.completer, this.child }) {
    _performance = new Performance(duration: transitionDuration, debugLabel: 'ModalBottomSheet');
  }

  final Completer completer;
  final Widget child;

  PerformanceView get performance => _performance?.view;
  Performance _performance;

  bool get ephemeral => true;
  bool get modal => true;
  bool get opaque => false;
  Duration get transitionDuration => _kBottomSheetDuration;

  Widget build(RouteArguments args) {
    return new Focus(
      key: new GlobalObjectKey(this),
      autofocus: true,
      child: new GestureDetector(
        onTap: () { navigator.pop(); },
        child: new Stack(<Widget>[
          // mask
          new ColorTransition(
            performance: performance,
            color: new AnimatedColorValue(Colors.transparent, end: Colors.black54),
            child: new Container()
          ),
          // sheet
          new _BottomSheet(
            performance: _performance,
            child: child
          )
        ])
      )
    );
  }

  void didPush(NavigatorState navigator) {
    super.didPush(navigator);
    _performance?.forward();
  }

  void didPop([dynamic result]) {
    completer.complete(result);
    super.didPop(result);
    if (_performance.status != PerformanceStatus.dismissed)
      _performance?.reverse();
  }
}

Future showModalBottomSheet({ BuildContext context, Widget child }) {
  final Completer completer = new Completer();
  Navigator.of(context).push(new _ModalBottomSheetRoute(
    completer: completer,
    child: child
  ));
  return completer.future;
}
