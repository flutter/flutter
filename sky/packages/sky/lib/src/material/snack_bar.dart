// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'material.dart';
import 'theme.dart';
import 'typography.dart';

const double _kSideMargins = 24.0;
const double _kVerticalPadding = 14.0;
const Color _kSnackBackground = const Color(0xFF323232);

class SnackBarAction extends StatelessComponent {
  SnackBarAction({Key key, this.label, this.onPressed }) : super(key: key) {
    assert(label != null);
  }

  final String label;
  final GestureTapCallback onPressed;

  Widget build(BuildContext) {
    return new GestureDetector(
      onTap: onPressed,
      child: new Container(
        margin: const EdgeDims.only(left: _kSideMargins),
        padding: const EdgeDims.symmetric(vertical: _kVerticalPadding),
        child: new Text(label)
      )
    );
  }
}

class SnackBar extends StatelessComponent {
  SnackBar({
    Key key,
    this.content,
    this.actions,
    this.performance
  }) : super(key: key) {
    assert(content != null);
  }

  final Widget content;
  final List<SnackBarAction> actions;
  final PerformanceView performance;

  Widget build(BuildContext context) {
    List<Widget> children = [
      new Flexible(
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: _kVerticalPadding),
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: content
          )
        )
      )
    ];
    if (actions != null)
      children.addAll(actions);
    return new SquashTransition(
      performance: performance,
      height: new AnimatedValue<double>(
        0.0,
        end: kSnackBarHeight,
        curve: easeIn,
        reverseCurve: easeOut
      ),
      child: new ClipRect(
        child: new OverflowBox(
          minHeight: kSnackBarHeight,
          maxHeight: kSnackBarHeight,
          child: new Material(
            level: 2,
            color: _kSnackBackground,
            child: new Container(
              margin: const EdgeDims.symmetric(horizontal: _kSideMargins),
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

class _SnackBarRoute extends PerformanceRoute {
  _SnackBarRoute({ this.content, this.actions });

  final Widget content;
  final List<SnackBarAction> actions;

  bool get hasContent => false;
  bool get ephemeral => true;
  bool get modal => false;
  Duration get transitionDuration => const Duration(milliseconds: 200);

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) => null;
}

void showSnackBar({ NavigatorState navigator, GlobalKey<PlaceholderState> placeholderKey, Widget content, List<SnackBarAction> actions }) {
  Route route = new _SnackBarRoute();
  SnackBar snackBar = new SnackBar(
    content: content,
    actions: actions,
    performance: route.performance
  );
  placeholderKey.currentState.child = snackBar;
  navigator.push(route);
}
