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

  void _handleDragEnd(Offset velocity, BuildContext context) {
    if (_dismissUnderway)
      return;
    if (velocity.dy > _kMinFlingVelocity) {
      performance.fling(velocity: -velocity.dy / childHeight);
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
      onVerticalDragEnd: (Offset velocity) { _handleDragEnd(velocity, context); },
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
      onTap: () { Navigator.of(context).pop(); },
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
                onClosing: () { Navigator.of(context).pop(); },
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

class _ModalBottomSheetRoute extends OverlayRoute {
  _ModalBottomSheetRoute({ this.completer, this.builder });

  final Completer completer;
  final WidgetBuilder builder;
  Performance performance;

  void didPush(OverlayState overlay, OverlayEntry insertionPoint) {
    performance = BottomSheet.createPerformance()
      ..forward();
    super.didPush(overlay, insertionPoint);
  }

  void _finish(dynamic result) {
    super.didPop(result); // clear the overlay entries
    completer.complete(result);
  }

  void didPop(dynamic result) {
    if (performance.isDismissed)
      _finish(result);
    else
      performance.reverse().then((_) { _finish(result); });
  }

  Widget _buildModalBarrier(BuildContext context) {
    return new AnimatedModalBarrier(
      color: new AnimatedColorValue(_kTransparent, end: _kBarrierColor, curve: Curves.ease),
      performance: performance
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return new Focus(
      key: new GlobalObjectKey(this),
      child: new _ModalBottomSheet(route: this)
    );
  }

  List<WidgetBuilder> get builders => <WidgetBuilder>[
    _buildModalBarrier,
    _buildBottomSheet,
  ];

  String get debugLabel => '$runtimeType';
  String toString() => '$runtimeType(performance: $performance)';
}

Future showModalBottomSheet({ BuildContext context, WidgetBuilder builder }) {
  assert(context != null);
  assert(builder != null);
  final Completer completer = new Completer();
  Navigator.of(context).pushEphemeral(new _ModalBottomSheetRoute(
    completer: completer,
    builder: builder
  ));
  return completer.future;
}
