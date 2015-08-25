// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/focus.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/navigator.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/transitions.dart';

typedef Widget DialogBuilder(Navigator navigator);

/// A material design dialog
///
/// <https://www.google.com/design/spec/components/dialogs.html>
class Dialog extends Component {
  Dialog({
    Key key,
    this.title,
    this.content,
    this.actions,
    this.onDismiss
  }): super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  final Widget title;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  final Widget content;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  final List<Widget> actions;

  /// An (optional) callback that is called when the dialog is dismissed.
  final Function onDismiss;

  Color get _color {
    switch (Theme.of(this).brightness) {
      case ThemeBrightness.light:
        return colors.white;
      case ThemeBrightness.dark:
        return colors.Grey[800];
    }
  }

  Widget build() {

    List<Widget> dialogBody = new List<Widget>();

    if (title != null) {
      dialogBody.add(new Padding(
        padding: new EdgeDims(24.0, 24.0, content == null ? 20.0 : 0.0, 24.0),
        child: new DefaultTextStyle(
          style: Theme.of(this).text.title,
          child: title
        )
      ));
    }

    if (content != null) {
      dialogBody.add(new Padding(
        padding: const EdgeDims(20.0, 24.0, 24.0, 24.0),
        child: new DefaultTextStyle(
          style: Theme.of(this).text.subhead,
          child: content
        )
      ));
    }

    if (actions != null)
      dialogBody.add(new Container(
        child: new Row(actions,
          justifyContent: FlexJustifyContent.end
        )
      ));

    return new Stack([
      new Listener(
        child: new Container(
          decoration: const BoxDecoration(
            backgroundColor: const Color(0x7F000000)
          )
        ),
        onGestureTap: (_) => onDismiss()
      ),
      new Center(
        child: new Container(
          margin: new EdgeDims.symmetric(horizontal: 40.0, vertical: 24.0),
          child: new ConstrainedBox(
            constraints: new BoxConstraints(minWidth: 280.0),
            child: new Material(
              level: 4,
              color: _color,
              child: new ShrinkWrapWidth(
                child: new Block(dialogBody)
              )
            )
          )
        )
      )
    ]);

  }
}

class DialogRoute extends RouteBase {
  DialogRoute({ this.completer, this.builder });

  final Completer completer;
  final RouteBuilder builder;

  Widget build(Navigator navigator, RouteBase route) => builder(navigator, route);
  bool get isOpaque => false;

  void popState([dynamic result]) {
    completer.complete(result);
  }

  TransitionBase buildTransition({ Key key }) => new DialogTransition(key: key);
}

const Duration _kTransitionDuration = const Duration(milliseconds: 150);
class DialogTransition extends TransitionBase {
  DialogTransition({
    Key key,
    Widget child,
    Direction direction,
    Function onDismissed,
    Function onCompleted
  }): super(key: key,
            child: child,
            duration: _kTransitionDuration,
            direction: direction,
            onDismissed: onDismissed,
            onCompleted: onCompleted);

  Widget buildWithChild(Widget child) {
    return new FadeTransition(
      performance: performance,
      direction: direction,
      opacity: new AnimatedValue<double>(0.0, end: 1.0, curve: easeOut),
      child: child
    );
  }
}

Future showDialog(Navigator navigator, DialogBuilder builder) {
  Completer completer = new Completer();
  navigator.push(new DialogRoute(
    completer: completer,
    builder: (navigator, route) {
      return new Focus(
        key: new GlobalKey.fromObjectIdentity(route),
        autofocus: true,
        child: builder(navigator)
      );
    }
  ));
  return completer.future;
}
