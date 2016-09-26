// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'button.dart';
import 'flat_button.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme_data.dart';
import 'theme.dart';
import 'typography.dart';

// https://www.google.com/design/spec/components/snackbars-toasts.html#snackbars-toasts-specs
const double _kSnackBarPadding = 24.0;
const double _kSingleLineVerticalPadding = 14.0;
const double _kMultiLineVerticalTopPadding = 24.0;
const double _kMultiLineVerticalSpaceBetweenTextAndButtons = 10.0;
const Color _kSnackBackground = const Color(0xFF323232);

// TODO(ianh): We should check if the given text and actions are going to fit on
// one line or not, and if they are, use the single-line layout, and if not, use
// the multiline layout. See link above.

// TODO(ianh): Implement the Tablet version of snackbar if we're "on a tablet".

const Duration _kSnackBarTransitionDuration = const Duration(milliseconds: 250);
const Duration _kSnackBarShortDisplayDuration = const Duration(milliseconds: 1500);
const Duration _kSnackBarMediumDisplayDuration = const Duration(milliseconds: 2750);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarFadeCurve = const Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

/// A button for a [SnackBar], known as an "action".
///
/// Snack bar actions are always enabled. If you want to disable a snack bar
/// action, simply don't include it in the snack bar.
///
/// Snack bar actions can only be pressed once. Subsequent presses are ignored.
///
/// See also:
///
///  * [SnackBar]
///  * <https://www.google.com/design/spec/components/snackbars-toasts.html>
class SnackBarAction extends StatefulWidget {
  /// Creates an action for a [SnackBar].
  ///
  /// The [label] and [onPressed] arguments must be non-null.
  SnackBarAction({
    Key key,
    this.label,
    @required this.onPressed
  }) : super(key: key) {
    assert(label != null);
    assert(onPressed != null);
  }

  /// The button label.
  final String label;

  /// The callback to be called when the button is pressed. Must not be null.
  ///
  /// This callback will be called at most once each time this action is
  /// displayed in a [SnackBar].
  final VoidCallback onPressed;

  @override
  _SnackBarActionState createState() => new _SnackBarActionState();
}

class _SnackBarActionState extends State<SnackBarAction> {
  bool _haveTriggeredAction = false;

  void _handlePressed() {
    if (_haveTriggeredAction)
      return;
    setState(() {
      _haveTriggeredAction = true;
    });
    config.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return new FlatButton(
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child: new Text(config.label)
    );
  }
}

/// A lightweight message with an optional action which briefly displays at the
/// bottom of the screen.
///
/// Displayed with the Scaffold.of().showSnackBar() API.
///
/// See also:
///
///  * [Scaffold.of] and [ScaffoldState.showSnackBar]
///  * [SnackBarAction]
///  * <https://www.google.com/design/spec/components/snackbars-toasts.html>
class SnackBar extends StatelessWidget {
  /// Creates a snack bar.
  ///
  /// The [content] argument must be non-null.
  SnackBar({
    Key key,
    this.content,
    this.action,
    this.duration: _kSnackBarShortDisplayDuration,
    this.animation
  }) : super(key: key) {
    assert(content != null);
  }

  /// The primary content of the snack bar.
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// (optional) An action that the user can take based on the snack bar.
  ///
  /// For example, the snack bar might let the user undo the operation that
  /// prompted the snackbar. Snack bars can have at most one action.
  final SnackBarAction action;

  /// The amount of time the snack bar should be displayed.
  final Duration duration;

  /// The animation driving the entrance and exit of the snack bar.
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    assert(animation != null);
    List<Widget> children = <Widget>[
      const SizedBox(width: _kSnackBarPadding),
      new Flexible(
        child: new Container(
          padding: const EdgeInsets.symmetric(vertical: _kSingleLineVerticalPadding),
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: content
          )
        )
      )
    ];
    if (action != null) {
      children.add(new ButtonTheme.bar(
        padding: const EdgeInsets.symmetric(horizontal: _kSnackBarPadding),
        textTheme: ButtonTextTheme.accent,
        child: action
      ));
    } else {
      children.add(const SizedBox(width: _kSnackBarPadding));
    }
    CurvedAnimation heightAnimation = new CurvedAnimation(parent: animation, curve: _snackBarHeightCurve);
    CurvedAnimation fadeAnimation = new CurvedAnimation(parent: animation, curve: _snackBarFadeCurve, reverseCurve: const Threshold(0.0));
    ThemeData theme = Theme.of(context);
    return new ClipRect(
      child: new AnimatedBuilder(
        animation: heightAnimation,
        builder: (BuildContext context, Widget child) {
          return new Align(
            alignment: FractionalOffset.topLeft,
            heightFactor: heightAnimation.value,
            child: child
          );
        },
        child: new Semantics(
          container: true,
          child: new Dismissable(
            key: new Key('dismissable'),
            direction: DismissDirection.down,
            resizeDuration: null,
            onDismissed: (DismissDirection direction) {
              Scaffold.of(context).removeCurrentSnackBar();
            },
            child: new Material(
              elevation: 6,
              color: _kSnackBackground,
              child: new Theme(
                data: new ThemeData(
                  brightness: Brightness.dark,
                  accentColor: theme.accentColor,
                  accentColorBrightness: theme.accentColorBrightness,
                  textTheme: Typography.white
                ),
                child: new FadeTransition(
                  opacity: fadeAnimation,
                  child: new Row(
                    children: children,
                    crossAxisAlignment: CrossAxisAlignment.center
                  )
                )
              )
            )
          )
        )
      )
    );
  }

  // API for Scaffold.addSnackBar():

  /// Creates an animation controller useful for driving a snack bar's entrance and exit animation.
  static AnimationController createAnimationController({ @required TickerProvider vsync }) {
    return new AnimationController(
      duration: _kSnackBarTransitionDuration,
      debugLabel: 'SnackBar',
      vsync: vsync,
    );
  }

  /// Creates a copy of this snack bar but with the animation replaced with the given animation.
  ///
  /// If the original snack bar lacks a key, the newly created snack bar will
  /// use the given fallback key.
  SnackBar withAnimation(Animation<double> newAnimation, { Key fallbackKey }) {
    return new SnackBar(
      key: key ?? fallbackKey,
      content: content,
      action: action,
      duration: duration,
      animation: newAnimation
    );
  }
}
