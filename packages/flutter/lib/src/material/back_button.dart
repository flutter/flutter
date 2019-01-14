// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material_localizations.dart';
import 'theme.dart';

/// A "back" icon that's appropriate for the current [TargetPlatform].
///
/// The current platform is determined by querying for the ambient [Theme].
///
/// See also:
///
///  * [BackButton], an [IconButton] with a [BackButtonIcon] that calls
///    [Navigator.maybePop] to return to the previous route.
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a material design icon.
///  * [ThemeData.platform], which specifies the current platform.
class BackButtonIcon extends StatelessWidget {
  /// Creates an icon that shows the appropriate "back" image for
  /// the current platform (as obtained from the [Theme]).
  const BackButtonIcon({ Key key }) : super(key: key);

  /// Returns the appropriate "back" icon for the given `platform`.
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
  Widget build(BuildContext context) => Icon(_getIconData(Theme.of(context).platform));
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
///    [AppBar.leading] slot when the [Scaffold] has no [Drawer] and the
///    current [Route] is not the [Navigator]'s first route.
///  * [BackButtonIcon], which is useful if you need to create a back button
///    that responds differently to being pressed.
///  * [IconButton], which is a more general widget for creating buttons with
///    icons.
///  * [CloseButton], an alternative which may be more appropriate for leaf
///    node pages in the navigation tree.
class BackButton extends StatelessWidget {
  /// Creates an [IconButton] with the appropriate "back" icon for the current
  /// target platform.
  const BackButton({ Key key, this.color }) : super(key: key);

  /// The color to use for the icon.
  ///
  /// Defaults to the [IconThemeData.color] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final Color color;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const BackButtonIcon(),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        Navigator.maybePop(context);
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
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const Icon(Icons.close),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () {
        Navigator.maybePop(context);
      },
    );
  }
}
