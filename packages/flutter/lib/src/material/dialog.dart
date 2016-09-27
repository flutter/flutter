// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_bar.dart';
import 'colors.dart';
import 'material.dart';
import 'theme.dart';

/// A material design dialog
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// See also:
///
///  * [showDialog]
///  * <https://www.google.com/design/spec/components/dialogs.html>
class Dialog extends StatelessWidget {
  /// Creates a dialog.
  ///
  /// Typically used in conjunction with [showDialog].
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
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Padding around the title.
  ///
  /// Uses material design default if none is supplied. If there is no title, no
  /// padding will be provided.
  final EdgeInsets titlePadding;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically, this is a [Block] containing the contents of the dialog. Using
  /// a [Block] ensures that the contents can scroll if they are too big to fit
  /// on the display.
  final Widget content;

  /// Padding around the content.
  ///
  /// Uses material design default if none is supplied.
  final EdgeInsets contentPadding;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  ///
  /// Typically this is a list of [FlatButton] widgets.
  ///
  /// These widgets will be wrapped in a [ButtonBar].
  final List<Widget> actions;

  Color _getColor(BuildContext context) {
    Brightness brightness = Theme.of(context).brightness;
    switch (brightness) {
      case Brightness.light:
        return Colors.white;
      case Brightness.dark:
        return Colors.grey[800];
    }
    assert(brightness != null);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = new List<Widget>();

    if (title != null) {
      children.add(new Padding(
        padding: titlePadding ?? new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, content == null ? 20.0 : 0.0),
        child: new DefaultTextStyle(
          style: Theme.of(context).textTheme.title,
          child: title
        )
      ));
    }

    if (content != null) {
      children.add(new Flexible(
        fit: FlexFit.loose,
        child: new ScrollableViewport(
          child: new Padding(
            padding: contentPadding ?? const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            child: new DefaultTextStyle(
              style: Theme.of(context).textTheme.subhead,
              child: content
            )
          )
        )
      ));
    }

    if (actions != null) {
      children.add(new ButtonTheme.bar(
        child: new ButtonBar(
          alignment: MainAxisAlignment.end,
          children: actions
        )
      ));
    }

    return new Center(
      child: new Container(
        margin: new EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: new ConstrainedBox(
          constraints: new BoxConstraints(minWidth: 280.0),
          child: new Material(
            elevation: 24,
            color: _getColor(context),
            type: MaterialType.card,
            child: new IntrinsicWidth(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
              )
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

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  bool get barrierDismissable => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation, Widget child) {
    return new FadeTransition(
      opacity: new CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut
      ),
      child: child
    );
  }
}

/// Displays a dialog above the current contents of the app.
///
/// This function typically receives a [Dialog] widget as its child argument.
/// Content below the dialog is dimmed with a [ModalBarrier].
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the dialog was closed.
///
/// See also:
///  * [Dialog]
///  * <https://www.google.com/design/spec/components/dialogs.html>
Future<dynamic/*=T*/> showDialog/*<T>*/({ BuildContext context, Widget child }) {
  Completer<dynamic/*=T*/> completer = new Completer<dynamic/*=T*/>();
  Navigator.push(context, new _DialogRoute<dynamic/*=T*/>(completer: completer, child: child));
  return completer.future;
}
