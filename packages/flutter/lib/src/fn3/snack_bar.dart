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
const double kSnackHeight = 52.0;
const double kSideMargins = 24.0;
const double kVerticalPadding = 14.0;
const Color kSnackBackground = const Color(0xFF323232);

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
        margin: const EdgeDims.only(left: kSideMargins),
        padding: const EdgeDims.symmetric(vertical: kVerticalPadding),
        child: new Text(label)
      )
    );
  }
}

class SnackBar extends AnimatedComponent {
  SnackBar({
    Key key,
    this.content,
    this.actions,
    bool showing,
    this.onDismissed
  }) : super(key: key, direction: showing ? Direction.forward : Direction.reverse, duration: _kSlideInDuration) {
    assert(content != null);
  }

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
          margin: const EdgeDims.symmetric(vertical: kVerticalPadding),
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: config.content
          )
        )
      )
    ];
    if (config.actions != null)
      children.addAll(config.actions);
    return new SquashTransition(
      performance: performance.view,
      height: new AnimatedValue<double>(
        0.0,
        end: kSnackHeight,
        curve: easeIn,
        reverseCurve: easeOut
      ),
      child: new ClipRect(
        child: new OverflowBox(
          height: kSnackHeight,
          child: new Material(
            level: 2,
            color: kSnackBackground,
            type: MaterialType.canvas,
            child: new Container(
              margin: const EdgeDims.symmetric(horizontal: kSideMargins),
              child: new DefaultTextStyle(
                style: new TextStyle(color: Theme.of(context).accentColor),
                child: new Row(children)
              )
            )
          )
        )
      )
    );
  }
}
