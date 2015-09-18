// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:sky/animation.dart';
import 'package:sky/painting.dart';
import 'package:sky/material.dart';
import 'package:sky/src/widgets/animated_component.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/default_text_style.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/gesture_detector.dart';
import 'package:sky/src/widgets/material.dart';
import 'package:sky/src/widgets/theme.dart';
import 'package:sky/src/widgets/transitions.dart';

typedef void SnackBarDismissedCallback();

const Duration _kSlideInDuration = const Duration(milliseconds: 200);
// TODO(ianh): factor out some of the constants below

class SnackBarAction extends Component {
  SnackBarAction({Key key, this.label, this.onPressed }) : super(key: key) {
    assert(label != null);
  }

  final String label;
  final Function onPressed;

  Widget build() {
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

  Key transitionKey;
  Widget content;
  List<SnackBarAction> actions;
  SnackBarDismissedCallback onDismissed;

  void syncConstructorArguments(SnackBar source) {
    transitionKey = source.transitionKey;
    content = source.content;
    actions = source.actions;
    onDismissed = source.onDismissed;
    super.syncConstructorArguments(source);
  }

  void handleDismissed() {
    if (onDismissed != null)
      onDismissed();
  }

  Widget build() {
    List<Widget> children = [
      new Flexible(
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: 14.0),
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: content
          )
        )
      )
    ];
    if (actions != null)
      children.addAll(actions);
    return new SlideTransition(
      key: transitionKey,
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
            style: new TextStyle(color: Theme.of(this).accentColor),
            child: new Row(children)
          )
        )
      )
    );
  }
}
