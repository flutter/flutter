// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
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
  final VoidCallback onPressed;

  Widget build(BuildContext context) {
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

class _SnackBar extends StatelessComponent {
  _SnackBar({
    Key key,
    this.content,
    this.actions,
    this.route
  }) : super(key: key) {
    assert(content != null);
  }

  final Widget content;
  final List<SnackBarAction> actions;
  final _SnackBarRoute route;

  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[
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
      performance: route.performance,
      height: new AnimatedValue<double>(
        0.0,
        end: kSnackBarHeight,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut
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

class _SnackBarRoute extends TransitionRoute {
  _SnackBarRoute({ Completer completer }) : super(completer: completer);

  bool get opaque => false;
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

Future showSnackBar({ BuildContext context, GlobalKey<PlaceholderState> placeholderKey, Widget content, List<SnackBarAction> actions }) {
  final Completer completer = new Completer();
  _SnackBarRoute route = new _SnackBarRoute(completer: completer);
  _SnackBar snackBar = new _SnackBar(
    route: route,
    content: content,
    actions: actions
  );

  // TODO(hansmuller): https://github.com/flutter/flutter/issues/374
  assert(placeholderKey.currentState.child == null);

  placeholderKey.currentState.child = snackBar;
  Navigator.of(context).pushEphemeral(route);
  return completer.future.then((_) {
    // If our overlay has been obscured by an opaque OverlayEntry currentState
    // will have been cleared already.
    if (placeholderKey.currentState != null)
      placeholderKey.currentState.child = null;
  });
}
