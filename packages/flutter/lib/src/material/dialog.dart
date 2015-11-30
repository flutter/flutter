// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material_button.dart';
import 'material.dart';
import 'theme.dart';

typedef Widget DialogBuilder(NavigatorState navigator);

/// A material design dialog
///
/// <https://www.google.com/design/spec/components/dialogs.html>
class Dialog extends StatelessComponent {
  Dialog({
    Key key,
    this.title,
    this.titlePadding,
    this.content,
    this.contentPadding,
    this.actions
  }) : super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  final Widget title;

  // Padding around the title; uses material design default if none is supplied
  // If there is no title, no padding will be provided
  final EdgeDims titlePadding;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  final Widget content;

  // Padding around the content; uses material design default if none is supplied
  final EdgeDims contentPadding;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  final List<Widget> actions;

  Color _getColor(BuildContext context) {
    switch (Theme.of(context).brightness) {
      case ThemeBrightness.light:
        return Colors.white;
      case ThemeBrightness.dark:
        return Colors.grey[800];
    }
  }

  Widget build(BuildContext context) {

    List<Widget> dialogBody = new List<Widget>();

    if (title != null) {
      EdgeDims padding = titlePadding;
      if (padding == null)
        padding = new EdgeDims.TRBL(24.0, 24.0, content == null ? 20.0 : 0.0, 24.0);
      dialogBody.add(new Padding(
        padding: padding,
        child: new DefaultTextStyle(
          style: Theme.of(context).text.title,
          child: title
        )
      ));
    }

    if (content != null) {
      EdgeDims padding = contentPadding;
      if (padding == null)
        padding = const EdgeDims.TRBL(20.0, 24.0, 24.0, 24.0);
      dialogBody.add(new Padding(
        padding: padding,
        child: new DefaultTextStyle(
          style: Theme.of(context).text.subhead,
          child: content
        )
      ));
    }

    if (actions != null) {
      dialogBody.add(new ButtonTheme(
        color: ButtonColor.accent,
        child: new Container(
          child: new Row(actions,
            justifyContent: FlexJustifyContent.end
          )
        )
      ));
    }

    return new Center(
      child: new Container(
        margin: new EdgeDims.symmetric(horizontal: 40.0, vertical: 24.0),
        child: new ConstrainedBox(
          constraints: new BoxConstraints(minWidth: 280.0),
          child: new Material(
            elevation: 24,
            color: _getColor(context),
            type: MaterialType.card,
            child: new IntrinsicWidth(
              child: new Block(dialogBody)
            )
          )
        )
      )
    );
  }
}

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    Completer<T> completer,
    this.child
  }) : super(completer: completer);

  final Widget child;

  Duration get transitionDuration => const Duration(milliseconds: 150);
  bool get barrierDismissable => true;
  Color get barrierColor => Colors.black54;

  Widget buildPage(BuildContext context) => child;

  Widget buildTransition(BuildContext context, PerformanceView performance, Widget child) {
    return new FadeTransition(
      performance: performance,
      opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: Curves.easeOut),
      child: child
    );
  }
}

Future showDialog({ BuildContext context, Widget child }) {
  Completer completer = new Completer();
  Navigator.push(context, new _DialogRoute(completer: completer, child: child));
  return completer.future;
}
