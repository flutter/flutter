// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'flat_button.dart';
import 'material.dart';
import 'material_button.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'typography.dart';

// https://www.google.com/design/spec/components/snackbars-toasts.html#snackbars-toasts-specs
const double _kSideMargins = 24.0;
const double _kSingleLineVerticalPadding = 14.0;
const double _kMultiLineVerticalTopPadding = 24.0;
const double _kMultiLineVerticalSpaceBetweenTextAndButtons = 10.0;
const Color _kSnackBackground = const Color(0xFF323232);

// TODO(ianh): We should check if the given text and actions are going to fit on
// one line or not, and if they are, use the single-line layout, and if not, use
// the multiline layout. See link above.

// TODO(ianh): Implement the Tablet version of snackbar if we're "on a tablet".

const Duration _kSnackBarTransitionDuration = const Duration(milliseconds: 250);
const Duration kSnackBarShortDisplayDuration = const Duration(milliseconds: 1500);
const Duration kSnackBarMediumDisplayDuration = const Duration(milliseconds: 2750);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarFadeCurve = const Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

class SnackBarAction extends StatelessComponent {
  SnackBarAction({Key key, this.label, this.onPressed }) : super(key: key) {
    assert(label != null);
  }

  final String label;
  final VoidCallback onPressed;

  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeDims.only(left: _kSideMargins),
      child: new FlatButton(
        onPressed: onPressed,
        textTheme: ButtonColor.accent,
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
    this.duration: kSnackBarShortDisplayDuration,
    this.animation
  }) : super(key: key) {
    assert(content != null);
  }

  final Widget content;
  final List<SnackBarAction> actions;
  final Duration duration;
  final Animated<double> animation;

  Widget build(BuildContext context) {
    assert(animation != null);
    List<Widget> children = <Widget>[
      new Flexible(
        child: new Container(
          margin: const EdgeDims.symmetric(vertical: _kSingleLineVerticalPadding),
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: content
          )
        )
      )
    ];
    if (actions != null)
      children.addAll(actions);
    CurvedAnimation heightAnimation = new CurvedAnimation(parent: animation, curve: _snackBarHeightCurve);
    CurvedAnimation fadeAnimation = new CurvedAnimation(parent: animation, curve: _snackBarFadeCurve);
    ThemeData theme = Theme.of(context);
    return new ClipRect(
      child: new AnimatedBuilder(
        animation: heightAnimation,
        builder: (BuildContext context, Widget child) {
          return new Align(
            alignment: const FractionalOffset(0.0, 0.0),
            heightFactor: heightAnimation.value,
            child: child
          );
        },
        child: new Material(
          elevation: 6,
          color: _kSnackBackground,
          child: new Container(
            margin: const EdgeDims.symmetric(horizontal: _kSideMargins),
            child: new Theme(
              data: new ThemeData(
                brightness: ThemeBrightness.dark,
                accentColor: theme.accentColor,
                accentColorBrightness: theme.accentColorBrightness,
                text: Typography.white
              ),
              child: new FadeTransition(
                opacity: fadeAnimation,
                child: new Row(
                  children: children,
                  alignItems: FlexAlignItems.center
                )
              )
            )
          )
        )
      )
    );
  }

  // API for Scaffold.addSnackBar():

  static AnimationController createAnimationController() {
    return new AnimationController(
      duration: _kSnackBarTransitionDuration,
      debugLabel: 'SnackBar'
    );
  }

  SnackBar withAnimation(Animated<double> newAnimation, { Key fallbackKey }) {
    return new SnackBar(
      key: key ?? fallbackKey,
      content: content,
      actions: actions,
      duration: duration,
      animation: newAnimation
    );
  }
}
