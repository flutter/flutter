// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:sky/animation.dart';
import 'package:sky/painting.dart';
import 'package:sky/material.dart';
import 'package:sky/src/fn3/animated_component.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';
import 'package:sky/src/fn3/material.dart';
import 'package:sky/src/fn3/theme.dart';
import 'package:sky/src/fn3/transitions.dart';

typedef void SnackBarDismissedCallback();

const Duration _kSlideInDuration = const Duration(milliseconds: 200);
// TODO(ianh): factor out some of the constants below

class SnackBarAction extends StatelessComponent {
  SnackBarAction({Key key, this.label, this.onPressed }) : super(key: key) {
    assert(label != null);
  }

  final String label;
  final Function onPressed;

  Widget build(BuildContext) {
    return new GestureDetector(
      onTap: onPressed,
      child: new Container(
        margin: const EdgeDims.only(left: 24.0),
        padding: const EdgeDims.only(top: 14.0, bottom: 14.0),
        child: new Text(label)
      )
    );
  }
}

class SnackBar extends AnimatedComponent {
  SnackBar({
    Key key,
    this.transitionKey,
    this.content,
    this.actions,
    bool showing,
    this.onDismissed
  }) : super(key: key, direction: showing ? Direction.forward : Direction.reverse, duration: _kSlideInDuration) {
    assert(content != null);
  }

  final Key transitionKey;
  final Widget content;
  final List<SnackBarAction> actions;
  final SnackBarDismissedCallback onDismissed;

  SnackBarState createState() => new SnackBarState();
}

class SnackBarState extends AnimatedState<SnackBar> {
  void handleDismissed() {
    if (config.onDismissed != null)
      config.onDismissed();
  }

  Widget build(BuildContext context) {
    List<Widget> children = [
      new Flexible(
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: 14.0),
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: config.content
          )
        )
      )
    ];
    if (config.actions != null)
      children.addAll(config.actions);
    return new SlideTransition(
      key: config.transitionKey,
      performance: performance.view,
      position: new AnimatedValue<Point>(
        Point.origin,
        end: const Point(0.0, -52.0),
        curve: easeIn,
        reverseCurve: easeOut
      ),
      child: new Material(
        level: 2,
        color: const Color(0xFF323232),
        type: MaterialType.canvas,
        child: new Container(
          margin: const EdgeDims.symmetric(horizontal: 24.0),
          child: new DefaultTextStyle(
            style: new TextStyle(color: Theme.of(context).accentColor),
            child: new Row(children)
          )
        )
      )
    );
  }
}
