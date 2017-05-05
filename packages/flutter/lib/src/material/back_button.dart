// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'theme.dart';

/// Signature for callbacks with a BuildContext parameter.
///
/// This type can be useful for widget callbacks. The context passed to the
/// widget's build method can be passed along to callbacks that may need to look
/// up an inherited widget or other context-specific resource.
typedef void BuildContextCallback(BuildContext context);

/// A material design back button.
///
/// A [BackButton] is an [IconButton] with a "back" icon appropriate for the
/// current [TargetPlatform]. When pressed, the back button calls
/// [Navigator.maybePop] to return to the previous route.
///
/// When deciding to display a [BackButton], consider using
/// `ModalRoute.of(context)?.canPop` to check whether the current route can be
/// popped. If that value is false (e.g., because the current route is the
/// initial route), the [BackButton] will not have any effect when pressed,
/// which could frustrate the user.
///
/// The default button pressed behavior can be overridden by specifying
/// [onPressed].
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [AppBar], which automatically uses a [BackButton] in its
///    [AppBar.leading] slot when appropriate.
///  * [IconButton], which is a more general widget for creating buttons with
///    icons.
///  * [CloseButton], an alternative which may be more appropriate for leaf
///    node pages in the navigation tree.
class BackButton extends StatelessWidget {
  /// Creates an [IconButton] with the appropriate "back" icon for the current
  /// target platform.
  const BackButton({ Key key, this.onPressed }) : super(key: key);

  /// If this property is non-null it's called when the back button is pressed.
  /// If it's null then a method that pops that navigator is called:
  /// `Navigator.of(context).maybePop()`.
  final BuildContextCallback onPressed;

  /// Returns tha appropriate "back" icon for the given `platform`.
  static IconData getIconData(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return Icons.arrow_back;
      case TargetPlatform.iOS:
        return Icons.arrow_back_ios;
    }
    assert(false);
    return null;
  }

  void _defaultOnPressed(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return new IconButton(
      icon: new Icon(getIconData(Theme.of(context).platform)),
      tooltip: 'Back', // TODO(ianh): Figure out how to localize this string
      onPressed: () {
        (onPressed ?? _defaultOnPressed)(context);
      }
    );
  }
}

/// A material design close button.
///
/// A [CloseButton] is an [IconButton] with a "close" icon. When pressed, the
/// close button calls [Navigator.maybePop] to return to the previous route.
///
/// Use a [CloseButton] instead of a [BackButton] on fullscreen dialogs or
/// pages that may solicit additional actions to close.
///
/// See also:
///
///  * [AppBar], which automatically uses a [CloseButton] in its
///    [AppBar.leading] slot when appropriate.
///  * [BackButton], which is more appropriate for middle nodes in the
///    navigation tree or where pages can be popped instantaneously with
///    no user data consequence.
///  * [IconButton], to create other material design icon buttons.
class CloseButton extends StatelessWidget {
  /// Creates a Material Design close button.
  const CloseButton({ Key key, this.onPressed }) : super(key: key);

  /// If this property is non-null it's called when the back button is pressed.
  /// If it's null then a method that pops the navigator is called:
  /// `Navigator.of(context).maybePop()`.
  final BuildContextCallback onPressed;

  void _defaultOnPressed(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return new IconButton(
      icon: const Icon(Icons.close),
      tooltip: 'Close', // TODO(ianh): Figure out how to localize this string
      onPressed: () {
        (onPressed ?? _defaultOnPressed)(context);
      },
    );
  }
}
