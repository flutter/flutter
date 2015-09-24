// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/animation.dart';
import 'package:sky/material.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/focus.dart';
import 'package:sky/src/fn3/framework.dart';
import 'package:sky/src/fn3/gesture_detector.dart';
import 'package:sky/src/fn3/material.dart';
import 'package:sky/src/fn3/navigator.dart';
import 'package:sky/src/fn3/scrollable.dart';
import 'package:sky/src/fn3/theme.dart';
import 'package:sky/src/fn3/transitions.dart';

typedef Widget DialogBuilder(Navigator navigator);

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
    this.actions,
    this.onDismiss
  }): super(key: key);

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

  /// An (optional) callback that is called when the dialog is dismissed.
  final Function onDismiss;

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
        padding = new EdgeDims(24.0, 24.0, content == null ? 20.0 : 0.0, 24.0);
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
        padding = const EdgeDims(20.0, 24.0, 24.0, 24.0);
      dialogBody.add(new Padding(
        padding: padding,
        child: new DefaultTextStyle(
          style: Theme.of(context).text.subhead,
          child: content
        )
      ));
    }

    if (actions != null) {
      dialogBody.add(new Container(
        child: new Row(actions,
          justifyContent: FlexJustifyContent.end
        )
      ));
    }

    return new Stack([
      new GestureDetector(
        onTap: onDismiss,
        child: new Container(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0x7F000000)
          )
        )
      ),
      new Center(
        child: new Container(
          margin: new EdgeDims.symmetric(horizontal: 40.0, vertical: 24.0),
          child: new ConstrainedBox(
            constraints: new BoxConstraints(minWidth: 280.0),
            child: new Material(
              level: 4,
              color: _getColor(context),
              child: new IntrinsicWidth(
                child: new Block(dialogBody)
              )
            )
          )
        )
      )
    ]);

  }
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);

class DialogRoute extends RouteBase {
  DialogRoute({ this.completer, this.builder });

  final Completer completer;
  final RouteBuilder builder;

  Duration get transitionDuration => _kTransitionDuration;
  bool get isOpaque => false;
  Widget build(Key key, NavigatorState navigator, WatchableAnimationPerformance performance) {
    return new FadeTransition(
      performance: performance,
      opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
      child: builder(navigator, this)
    );
  }

  void popState([dynamic result]) {
    completer.complete(result);
  }
}

Future showDialog(NavigatorState navigator, DialogBuilder builder) {
  Completer completer = new Completer();
  navigator.push(new DialogRoute(
    completer: completer,
    builder: (navigator, route) {
      return new Focus(
        key: new GlobalObjectKey(route),
        autofocus: true,
        child: builder(navigator)
      );
    }
  ));
  return completer.future;
}
