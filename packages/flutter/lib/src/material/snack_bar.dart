// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'flat_button.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'theme_data.dart';

// https://material.google.com/components/snackbars-toasts.html#snackbars-toasts-specs
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
const Duration _kSnackBarDisplayDuration = const Duration(milliseconds: 1500);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarFadeCurve = const Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

/// Specify how a [SnackBar] was closed.
///
/// The [ScaffoldState.showSnackBar] function returns a
/// [ScaffoldFeatureController]. The value of the controller's closed property
/// is a Future that resolves to a SnackBarClosedReason. Applications that need
/// to know how a snackbar was closed can use this value.
///
/// Example:
///
/// ```dart
/// Scaffold.of(context).showSnackBar(
///   new SnackBar( ... )
/// ).closed.then((SnackBarClosedReason reason) {
///    ...
/// });
/// ```
enum SnackBarClosedReason {
  /// The snack bar was closed after the user tapped a [SnackBarAction].
  action,

  /// The snack bar was closed by a user's swipe.
  swipe,

  /// The snack bar was closed by the [ScaffoldFeatureController] close callback
  /// or by calling [ScaffoldState.hideCurrentSnackBar] directly.
  hide,

  /// The snack bar was closed by an call to [ScaffoldState.removeCurrentSnackBar].
  remove,

  /// The snack bar was closed because its timer expired.
  timeout,
}

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
///  * <https://material.google.com/components/snackbars-toasts.html>
class SnackBarAction extends StatefulWidget {
  /// Creates an action for a [SnackBar].
  ///
  /// The [label] and [onPressed] arguments must be non-null.
  const SnackBarAction({
    Key key,
    @required this.label,
    @required this.onPressed
  }) : assert(label != null),
       assert(onPressed != null),
       super(key: key);

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
    widget.onPressed();
    Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
  }

  @override
  Widget build(BuildContext context) {
    return new FlatButton(
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child: new Text(widget.label)
    );
  }
}

/// A lightweight message with an optional action which briefly displays at the
/// bottom of the screen.
///
/// To display a snack bar, call `Scaffold.of(context).showSnackBar()`, passing
/// an instance of [SnackBar] that describes the message.
///
/// To control how long the [SnackBar] remains visible, specify a [duration].
///
/// See also:
///
///  * [Scaffold.of], to obtain the current [ScaffoldState], which manages the
///    display and animation of snack bars.
///  * [ScaffoldState.showSnackBar], which displays a [SnackBar].
///  * [ScaffoldState.removeCurrentSnackBar], which abruptly hides the currently
///    displayed snack bar, if any, and allows the next to be displayed.
///  * [SnackBarAction], which is used to specify an [action] button to show
///    on the snack bar.
///  * <https://material.google.com/components/snackbars-toasts.html>
class SnackBar extends StatelessWidget {
  /// Creates a snack bar.
  ///
  /// The [content] argument must be non-null.
  const SnackBar({
    Key key,
    @required this.content,
    this.backgroundColor,
    this.action,
    this.duration: _kSnackBarDisplayDuration,
    this.animation,
  }) : assert(content != null),
       super(key: key);

  /// The primary content of the snack bar.
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// The Snackbar's background color. By default the color is dark grey.
  final Color backgroundColor;

  /// (optional) An action that the user can take based on the snack bar.
  ///
  /// For example, the snack bar might let the user undo the operation that
  /// prompted the snackbar. Snack bars can have at most one action.
  ///
  /// The action should not be "dismiss" or "cancel".
  final SnackBarAction action;

  /// The amount of time the snack bar should be displayed.
  ///
  /// Defaults to 1.5s.
  ///
  /// See also:
  ///
  ///  * [ScaffoldState.removeCurrentSnackBar], which abruptly hides the
  ///    currently displayed snack bar, if any, and allows the next to be
  ///    displayed.
  ///  * <https://material.google.com/components/snackbars-toasts.html>
  final Duration duration;

  /// The animation driving the entrance and exit of the snack bar.
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    assert(animation != null);
    final ThemeData theme = Theme.of(context);
    final ThemeData darkTheme = new ThemeData(
      brightness: Brightness.dark,
      accentColor: theme.accentColor,
      accentColorBrightness: theme.accentColorBrightness
    );
    final List<Widget> children = <Widget>[
      const SizedBox(width: _kSnackBarPadding),
      new Expanded(
        child: new Container(
          padding: const EdgeInsets.symmetric(vertical: _kSingleLineVerticalPadding),
          child: new DefaultTextStyle(
            style: darkTheme.textTheme.subhead,
            child: content,
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
    final CurvedAnimation heightAnimation = new CurvedAnimation(parent: animation, curve: _snackBarHeightCurve);
    final CurvedAnimation fadeAnimation = new CurvedAnimation(parent: animation, curve: _snackBarFadeCurve, reverseCurve: const Threshold(0.0));
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
          child: new Dismissible(
            key: const Key('dismissible'),
            direction: DismissDirection.down,
            resizeDuration: null,
            onDismissed: (DismissDirection direction) {
              Scaffold.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.swipe);
            },
            child: new Material(
              elevation: 6.0,
              color: backgroundColor ?? _kSnackBackground,
              child: new Theme(
                data: darkTheme,
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
      backgroundColor: backgroundColor,
      action: action,
      duration: duration,
      animation: newAnimation
    );
  }
}
