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
    this.performance
  }) : super(key: key) {
    assert(content != null);
  }

  final Widget content;
  final List<SnackBarAction> actions;
  final Duration duration;
  final PerformanceView performance;

  Widget build(BuildContext context) {
    assert(performance != null);
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
    ThemeData theme = Theme.of(context);
    return new ClipRect(
      child: new AlignTransition(
        performance: performance,
        alignment: new AnimatedValue<FractionalOffset>(const FractionalOffset(0.0, 0.0)),
        heightFactor: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.fastOutSlowIn),
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
                performance: performance,
                opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: _snackBarFadeCurve),
                child: new Row(
                  children,
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

  static Performance createPerformance() {
    return new Performance(
      duration: _kSnackBarTransitionDuration,
      debugLabel: 'SnackBar'
    );
  }

  SnackBar withPerformance(Performance newPerformance, { Key fallbackKey }) {
    return new SnackBar(
      key: key ?? fallbackKey,
      content: content,
      actions: actions,
      duration: duration,
      performance: newPerformance
    );
  }
}
