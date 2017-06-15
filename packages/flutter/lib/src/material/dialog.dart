// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'button_bar.dart';
import 'colors.dart';
import 'ink_well.dart';
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
///  * [AlertDialog], for dialogs that have a message and some buttons.
///  * [SimpleDialog], for dialogs that offer a variety of options.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * <https://material.google.com/components/dialogs.html>
class Dialog extends StatelessWidget {
  /// Creates a dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  const Dialog({
    Key key,
    this.child,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  Color _getColor(BuildContext context) {
    return Theme.of(context).dialogBackgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: new ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280.0),
          child: new Material(
            elevation: 24.0,
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
/// using a scrolling widget, such as [ListView], for [content] to avoid
/// overflow.
///
/// For dialogs that offer the user a choice between several options, consider
/// using a [SimpleDialog].
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// See also:
///
///  * [SimpleDialog], which handles the scrolling of the contents but has no [actions].
///  * [Dialog], on which [AlertDialog] and [SimpleDialog] are based.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * <https://material.google.com/components/dialogs.html#dialogs-alerts>
class AlertDialog extends StatelessWidget {
  /// Creates an alert dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  const AlertDialog({
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
  /// Typically, this is a [ListView] containing the contents of the dialog.
  /// Using a [ListView] ensures that the contents can scroll if they are too
  /// big to fit on the display.
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
    final List<Widget> children = <Widget>[];

    if (title != null) {
      children.add(new Padding(
        padding: titlePadding ?? new EdgeInsets.fromLTRB(24.0, 24.0, 24.0, content == null ? 20.0 : 0.0),
        child: new DefaultTextStyle(
          style: Theme.of(context).textTheme.title,
          child: title,
        ),
      ));
    }

    if (content != null) {
      children.add(new Flexible(
        child: new Padding(
          padding: contentPadding ?? const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          child: new DefaultTextStyle(
            style: Theme.of(context).textTheme.subhead,
            child: content,
          ),
        ),
      ));
    }

    if (actions != null) {
      children.add(new ButtonTheme.bar(
        child: new ButtonBar(
          children: actions,
        ),
      ));
    }

    return new Dialog(
      child: new IntrinsicWidth(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// An option used in a [SimpleDialog].
///
/// A simple dialog offers the user a choice between several options. This
/// widget is commonly used to represent each of the options. If the user
/// selects this option, the widget will call the [onPressed] callback, which
/// typically uses [Navigator.pop] to close the dialog.
///
/// See also:
///
///  * [SimpleDialog], for a dialog in which to use this widget.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * [FlatButton], which are commonly used as actions in other kinds of
///    dialogs, such as [AlertDialog]s.
///  * <https://material.google.com/components/dialogs.html#dialogs-simple-dialogs>
class SimpleDialogOption extends StatelessWidget {
  /// Creates an option for a [SimpleDialog].
  const SimpleDialogOption({
    Key key,
    this.onPressed,
    this.child,
  }) : super(key: key);

  /// The callback that is called when this option is selected.
  ///
  /// If this is set to null, the option cannot be selected.
  final VoidCallback onPressed;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      onTap: onPressed,
      child: new Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
        child: child
      ),
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
///  * [SimpleDialogOption], which are options used in this type of dialog.
///  * [AlertDialog], for dialogs that have a row of buttons below the body.
///  * [Dialog], on which [SimpleDialog] and [AlertDialog] are based.
///  * [showDialog], which actually displays the dialog and returns its result.
///  * <https://material.google.com/components/dialogs.html#dialogs-simple-dialogs>
class SimpleDialog extends StatelessWidget {
  /// Creates a simple dialog.
  ///
  /// Typically used in conjunction with [showDialog].
  const SimpleDialog({
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

  /// The (optional) content of the dialog is displayed in a
  /// [SingleChildScrollView] underneath the title.
  ///
  /// Typically a list of [SimpleDialogOption]s.
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
        child: new SingleChildScrollView(
          padding: contentPadding ?? const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
          child: new ListBody(children: children),
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
            children: body,
          )
        )
      )
    );
  }
}

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    @required this.theme,
    bool barrierDismissible: true,
    @required this.child,
  }) : assert(barrierDismissible != null),
       _barrierDismissible = barrierDismissible;

  final Widget child;
  final ThemeData theme;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return theme != null ? new Theme(data: theme, child: child) : child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the dialog was closed.
///
/// See also:
///  * [AlertDialog], for dialogs that have a row of buttons below a body.
///  * [SimpleDialog], which handles the scrolling of the contents and does
///    not show buttons below its body.
///  * [Dialog], on which [SimpleDialog] and [AlertDialog] are based.
///  * <https://material.google.com/components/dialogs.html>
Future<T> showDialog<T>({
  @required BuildContext context,
  bool barrierDismissible: true,
  @required Widget child,
}) {
  return Navigator.push(context, new _DialogRoute<T>(
    child: child,
    theme: Theme.of(context, shadowThemeOnly: true),
    barrierDismissible: barrierDismissible,
  ));
}
