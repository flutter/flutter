// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon_button.dart';
import 'icons.dart';
import 'theme.dart';

/// A "back" icon that's appropriate for the current [TargetPlatform].
///
/// See also:
///
///  * [BackButton], an [IconButton] with a [BackButtonIcon] that calls
///    [Navigator.maybePop] to return to the previous route.
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a material design icon.
class BackButtonIcon extends StatelessWidget {
  const BackButtonIcon({ Key key }) : super(key: key);

  /// Returns tha appropriate "back" icon for the given `platform`.
  static IconData _getIconData(TargetPlatform platform) {
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

  @override
  Widget build(BuildContext context) => new Icon(_getIconData(Theme.of(context).platform));
}

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
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [AppBar], which automatically uses a [BackButton] in its
///    [AppBar.leading] slot when appropriate.
///  * [BackButtonIcon], which is useful if you need to create a back button
///    that responds differently to being pressed.
///  * [IconButton], which is a more general widget for creating buttons with
///    icons.
///  * [CloseButton], an alternative which may be more appropriate for leaf
///    node pages in the navigation tree.
class BackButton extends StatelessWidget {
  /// Creates an [IconButton] with the appropriate "back" icon for the current
  /// target platform.
  const BackButton({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new IconButton(
      icon: const BackButtonIcon(),
      tooltip: 'Back', // TODO(ianh): Figure out how to localize this string
      onPressed: () {
        Navigator.of(context).maybePop();
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
  const CloseButton({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new IconButton(
      icon: const Icon(Icons.close),
      tooltip: 'Close', // TODO(ianh): Figure out how to localize this string
      onPressed: () {
        Navigator.of(context).maybePop();
      },
    );
  }
}
