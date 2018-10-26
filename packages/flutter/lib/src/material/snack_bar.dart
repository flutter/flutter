// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'flat_button.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'theme_data.dart';

const double _kSnackBarPadding = 24.0;
const double _kSingleLineVerticalPadding = 14.0;
const Color _kSnackBackground = Color(0xFF323232);

// TODO(ianh): We should check if the given text and actions are going to fit on
// one line or not, and if they are, use the single-line layout, and if not, use
// the multiline layout. See link above.

// TODO(ianh): Implement the Tablet version of snackbar if we're "on a tablet".

const Duration _kSnackBarTransitionDuration = Duration(milliseconds: 250);
const Duration _kSnackBarDisplayDuration = Duration(milliseconds: 4000);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarFadeCurve = Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

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
///   SnackBar( ... )
/// ).closed.then((SnackBarClosedReason reason) {
///    ...
/// });
/// ```
enum SnackBarClosedReason {
  /// The snack bar was closed after the user tapped a [SnackBarAction].
  action,

  /// The snack bar was closed through a [SemanticAction.dismiss].
  dismiss,

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
///  * <https://material.io/design/components/snackbars.html>
class SnackBarAction extends StatefulWidget {
  /// Creates an action for a [SnackBar].
  ///
  /// The [label] and [onPressed] arguments must be non-null.
  const SnackBarAction({
    Key key,
    this.textColor,
    this.disabledTextColor,
    @required this.label,
    @required this.onPressed,
  }) : assert(label != null),
       assert(onPressed != null),
       super(key: key);

  /// The button label color. If not provided, defaults to [accentColor].
  final Color textColor;

  /// The button disabled label color. This color is shown after the
  /// [snackBarAction] is dismissed.
  final Color disabledTextColor;

  /// The button label.
  final String label;

  /// The callback to be called when the button is pressed. Must not be null.
  ///
  /// This callback will be called at most once each time this action is
  /// displayed in a [SnackBar].
  final VoidCallback onPressed;

  @override
  _SnackBarActionState createState() => _SnackBarActionState();
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
    return FlatButton(
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child: Text(widget.label),
      textColor: widget.textColor,
      disabledTextColor: widget.disabledTextColor,
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
/// A SnackBar with an action will not time out when TalkBack or VoiceOver are
/// enabled. This is controlled by [AccessibilityFeatures.accessibleNavigation].
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
///  * <https://material.io/design/components/snackbars.html>
class SnackBar extends StatelessWidget {
  /// Creates a snack bar.
  ///
  /// The [content] argument must be non-null.
  const SnackBar({
    Key key,
    @required this.content,
    this.backgroundColor,
    this.action,
    this.duration = _kSnackBarDisplayDuration,
    this.animation,
  }) : assert(content != null),
       assert(duration != null),
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
  /// Defaults to 4.0s.
  ///
  /// See also:
  ///
  ///  * [ScaffoldState.removeCurrentSnackBar], which abruptly hides the
  ///    currently displayed snack bar, if any, and allows the next to be
  ///    displayed.
  ///  * <https://material.io/design/components/snackbars.html>
  final Duration duration;

  /// The animation driving the entrance and exit of the snack bar.
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    assert(animation != null);
    final ThemeData theme = Theme.of(context);
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      accentColor: theme.accentColor,
      accentColorBrightness: theme.accentColorBrightness,
    );
    final List<Widget> children = <Widget>[
      const SizedBox(width: _kSnackBarPadding),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: _kSingleLineVerticalPadding),
          child: DefaultTextStyle(
            style: darkTheme.textTheme.subhead,
            child: content,
          ),
        ),
      ),
    ];
    if (action != null) {
      children.add(ButtonTheme.bar(
        padding: const EdgeInsets.symmetric(horizontal: _kSnackBarPadding),
        textTheme: ButtonTextTheme.accent,
        child: action,
      ));
    } else {
      children.add(const SizedBox(width: _kSnackBarPadding));
    }
    final CurvedAnimation heightAnimation = CurvedAnimation(parent: animation, curve: _snackBarHeightCurve);
    final CurvedAnimation fadeAnimation = CurvedAnimation(parent: animation, curve: _snackBarFadeCurve, reverseCurve: const Threshold(0.0));
    Widget snackbar = SafeArea(
      top: false,
      child: Row(
        children: children,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
    snackbar = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () {
        Scaffold.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
      },
      child: Dismissible(
        key: const Key('dismissible'),
        direction: DismissDirection.down,
        resizeDuration: null,
        onDismissed: (DismissDirection direction) {
          Scaffold.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.swipe);
        },
        child: Material(
          elevation: 6.0,
          color: backgroundColor ?? _kSnackBackground,
          child: Theme(
            data: darkTheme,
            child: mediaQueryData.accessibleNavigation ? snackbar : FadeTransition(
              opacity: fadeAnimation,
              child: snackbar,
            ),
          ),
        ),
      ),
    );
    return ClipRect(
      child: mediaQueryData.accessibleNavigation ? snackbar : AnimatedBuilder(
        animation: heightAnimation,
        builder: (BuildContext context, Widget child) {
          return Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: heightAnimation.value,
            child: child,
          );
        },
        child: snackbar,
      ),
    );
  }

  // API for Scaffold.addSnackBar():

  /// Creates an animation controller useful for driving a snack bar's entrance and exit animation.
  static AnimationController createAnimationController({ @required TickerProvider vsync }) {
    return AnimationController(
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
    return SnackBar(
      key: key ?? fallbackKey,
      content: content,
      backgroundColor: backgroundColor,
      action: action,
      duration: duration,
      animation: newAnimation,
    );
  }
}
