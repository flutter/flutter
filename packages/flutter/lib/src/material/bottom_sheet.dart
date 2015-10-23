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

class _BottomSheet extends StatefulComponent {
  _BottomSheet({
    Key key,
    this.child,
    this.performance
  }) : super(key: key);

  final Widget child;
  final PerformanceView performance;

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

  Widget build(BuildContext context) {
    return new BuilderTransition(
      performance: config.performance,
      variables: <AnimatedValue<double>>[_layout.childTop],
      builder: (BuildContext context) {
        return new ClipRect(
          child: new CustomOneChildLayout(
            delegate: _layout,
            token: _layout.childTop.value,
            child: new Material(child: config.child)
          )
        );
      }
    );
  }
}

class _ModalBottomSheetRoute extends PerformanceRoute {
  _ModalBottomSheetRoute({ this.completer, this.child });

  final Completer completer;
  final Widget child;

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
            performance: performance,
            child: child
          )
        ])
      )
    );
  }

  void didPop([dynamic result]) {
    completer.complete(result);
    super.didPop(result);
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
