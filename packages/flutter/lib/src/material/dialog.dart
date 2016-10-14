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

/// A material design dialog.
///
/// This dialog widget does not have any opinion about the contents of the
/// dialog. Rather than using this widget directly, consider using [AlertDialog]
/// or [SimpleDialog], which implement specific kinds of material design
/// dialogs.
///
/// See also:
///
///  * [AlertDialog]
///  * [SimpleDialog]
///  * [showDialog]
///  * <https://www.google.com/design/spec/components/dialogs.html>
class Dialog extends StatelessWidget {
  /// Creates a dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  Dialog({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  Color _getColor(BuildContext context) {
    Brightness brightness = Theme.of(context).brightness;
    assert(brightness != null);
    switch (brightness) {
      case Brightness.light:
        return Colors.white;
      case Brightness.dark:
        return Colors.grey[800];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        margin: new EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: new ConstrainedBox(
          constraints: new BoxConstraints(minWidth: 280.0),
          child: new Material(
            elevation: 24,
            color: _getColor(context),
            type: MaterialType.card,
            child: child
          )
        )
      )
    );
  }
}

/// A material design alert dialog.
///
/// An alert dialog informs the user about situations that require
/// acknowledgement. An alert dialog has an optional title and an optional list
/// of actions. The title is displayed above the content and the actions are
/// displayed below the content.
///
/// If the content is too large to fit on the screen vertically, the dialog will
/// display the title and the actions and let the content overflow. Consider
/// using a scrolling widget, such as [Block], for [content] to avoid overflow.
///
/// For dialogs that offer the user a choice between several options, consider
/// using a [SimpleDialog].
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// See also:
///
///  * [SimpleDialog]
///  * [Dialog]
///  * [showDialog]
///  * <https://material.google.com/components/dialogs.html#dialogs-alerts>
class AlertDialog extends StatelessWidget {
  /// Creates an alert dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  AlertDialog({
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
        child: new Padding(
          padding: contentPadding ?? const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          child: new DefaultTextStyle(
            style: Theme.of(context).textTheme.subhead,
            child: content
          )
        )
      ));
    }

    if (actions != null) {
      children.add(new ButtonTheme.bar(
        child: new ButtonBar(
          children: actions
        )
      ));
    }

    return new Dialog(
      child: new IntrinsicWidth(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children
        )
      )
    );
  }
}

/// A simple material design dialog.
///
/// A simple dialog offers the user a choice between several options. A simple
/// dialog has an optional title that is displayed above the choices.
///
/// For dialogs that inform the user about a situation, consider using an
/// [AlertDialog].
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// See also:
///
///  * [AlertDialog]
///  * [Dialog]
///  * [showDialog]
///  * <https://material.google.com/components/dialogs.html#dialogs-simple-dialogs>
class SimpleDialog extends StatelessWidget {
  /// Creates a simple dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  SimpleDialog({
    Key key,
    this.title,
    this.titlePadding,
    this.children,
    this.contentPadding,
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

  /// The (optional) content of the dialog is displayed in a [Block] underneath
  /// the title.
  ///
  /// The children are assumed to have 8.0 pixels of vertical and 24.0 pixels of
  /// horizontal padding internally.
  final List<Widget> children;

  /// Padding around the content.
  ///
  /// Uses material design default if none is supplied.
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = <Widget>[];

    if (title != null) {
      body.add(new Padding(
        padding: titlePadding ?? const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
        child: new DefaultTextStyle(
          style: Theme.of(context).textTheme.title,
          child: title
        )
      ));
    }

    if (children != null) {
      body.add(new Flexible(
        fit: FlexFit.loose,
        child: new Block(
          padding: contentPadding ?? const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
          children: children
        )
      ));
    }

    return new Dialog(
      child: new IntrinsicWidth(
        stepWidth: 56.0,
        child: new ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body
          )
        )
      )
    );
  }
}

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    this.child,
    this.theme,
  });

  final Widget child;
  final ThemeData theme;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  bool get barrierDismissable => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> forwardAnimation) {
    return theme != null ? new Theme(data: theme, child: child) : child;
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
  return Navigator.push(context, new _DialogRoute<dynamic/*=T*/>(
    child: child,
    theme: Theme.of(context, shadowThemeOnly: true),
  ));
}
