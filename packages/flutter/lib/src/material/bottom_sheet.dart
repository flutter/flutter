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
const double _kCloseProgressThreshold = 0.5;
const Color _kTransparent = const Color(0x00000000);
const Color _kBarrierColor = Colors.black54;

class BottomSheet extends StatelessComponent {
  BottomSheet({
    Key key,
    this.performance,
    this.onClosing,
    this.childHeight,
    this.builder
  }) : super(key: key) {
    assert(onClosing != null);
  }

  /// The performance that controls the bottom sheet's position. The BottomSheet
  /// widget will manipulate the position of this performance, it is not just a
  /// passive observer.
  final Performance performance;
  final VoidCallback onClosing;
  final double childHeight;
  final WidgetBuilder builder;

  static Performance createPerformance() {
    return new Performance(
      duration: _kBottomSheetDuration,
      debugLabel: 'BottomSheet'
    );
  }

  bool get _dismissUnderway => performance.direction == AnimationDirection.reverse;

  void _handleDragUpdate(double delta) {
    if (_dismissUnderway)
      return;
    performance.progress -= delta / (childHeight ?? delta);
  }

  void _handleDragEnd(Offset velocity) {
    if (_dismissUnderway)
      return;
    if (velocity.dy > _kMinFlingVelocity) {
      double flingVelocity = -velocity.dy / childHeight;
      performance.fling(velocity: flingVelocity);
      if (flingVelocity < 0.0)
        onClosing();
    } else if (performance.progress < _kCloseProgressThreshold) {
      performance.fling(velocity: -1.0);
      onClosing();
    } else {
      performance.forward();
    }
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: new Material(
        child: builder(context)
      )
    );
  }
}

// PERSISTENT BOTTOM SHEETS

// See scaffold.dart


// MODAL BOTTOM SHEETS

class _ModalBottomSheetLayout extends OneChildLayoutDelegate {
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

class _ModalBottomSheet extends StatefulComponent {
  _ModalBottomSheet({ Key key, this.route }) : super(key: key);

  final _ModalBottomSheetRoute route;

  _ModalBottomSheetState createState() => new _ModalBottomSheetState();
}

class _ModalBottomSheetState extends State<_ModalBottomSheet> {

  final _ModalBottomSheetLayout _layout = new _ModalBottomSheetLayout();

  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () => Navigator.pop(context),
      child: new BuilderTransition(
        performance: config.route.performance,
        variables: <AnimatedValue<double>>[_layout.childTop],
        builder: (BuildContext context) {
          return new ClipRect(
            child: new CustomOneChildLayout(
              delegate: _layout,
              token: _layout.childTop.value,
              child: new BottomSheet(
                performance: config.route.performance,
                onClosing: () => Navigator.pop(context),
                childHeight: _layout.childTop.end,
                builder: config.route.builder
              )
            )
          );
        }
      )
    );
  }
}

class _ModalBottomSheetRoute<T> extends PopupRoute<T> {
  _ModalBottomSheetRoute({
    Completer<T> completer,
    this.builder
  }) : super(completer: completer);

  final WidgetBuilder builder;

  Duration get transitionDuration => _kBottomSheetDuration;
  bool get barrierDismissable => true;
  Color get barrierColor => Colors.black54;

  Performance createPerformance() {
    return BottomSheet.createPerformance();
  }

  Widget buildPage(BuildContext context) {
    return new _ModalBottomSheet(route: this);
  }
}

Future showModalBottomSheet({ BuildContext context, WidgetBuilder builder }) {
  assert(context != null);
  assert(builder != null);
  final Completer completer = new Completer();
  Navigator.push(context, new _ModalBottomSheetRoute(
    completer: completer,
    builder: builder
  ));
  return completer.future;
}
