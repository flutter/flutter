// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material_localizations.dart';
import 'scaffold.dart';
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
///  * [Icon], a Material Design icon.
///  * [ThemeData.platform], which specifies the current platform.
class BackButtonIcon extends StatelessWidget {
  /// Creates an icon that shows the appropriate "back" image for
  /// the current platform (as obtained from the [Theme]).
  const BackButtonIcon({ super.key });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WidgetBuilder? iconBuilder = theme.actionIconTheme?.backButtonIconBuilder;
    if (iconBuilder != null) {
      return iconBuilder(context);
    }
    final String? semanticsLabel;
    final IconData data;
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        data = Icons.arrow_back;
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        data = Icons.arrow_back_ios;
        break;
    }
    // This can't use the platform from Theme because it is the Android OS that
    // expects the duplicated tooltip and label.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        semanticsLabel = MaterialLocalizations.of(context).backButtonTooltip;
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsLabel = null;
        break;
    }

    return Icon(data, semanticLabel: semanticsLabel);
  }
}

/// A Material Design back button.
///
/// A [BackButton] is an [IconButton] with a "back" icon appropriate for the
/// current [TargetPlatform]. When pressed, the back button calls
/// [Navigator.maybePop] to return to the previous route unless a custom
/// [onPressed] callback is provided.
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
  const BackButton({ super.key, this.color, this.onPressed });

  /// The color to use for the icon.
  ///
  /// Defaults to the [IconThemeData.color] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final Color? color;

  /// An override callback to perform instead of the default behavior which is
  /// to pop the [Navigator].
  ///
  /// It can, for instance, be used to pop the platform's navigation stack
  /// via [SystemNavigator] instead of Flutter's [Navigator] in add-to-app
  /// situations.
  ///
  /// Defaults to null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const BackButtonIcon(),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
}

/// A "close" icon that's appropriate for the current [TargetPlatform].
///
/// The current platform is determined by querying for the ambient [Theme].
///
/// See also:
///
///  * [CloseButton], an [IconButton] with a [CloseButtonIcon] that calls
///    [Navigator.maybePop] to return to the previous route.
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a Material Design icon.
///  * [ThemeData.platform], which specifies the current platform.
class CloseButtonIcon extends StatelessWidget {
  /// Creates an icon that shows the appropriate "close" image for
  /// the current platform (as obtained from the [Theme]).
  const CloseButtonIcon({ super.key });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WidgetBuilder? iconBuilder = theme.actionIconTheme?.closeButtonIconBuilder;
    if (iconBuilder != null) {
      return iconBuilder(context);
    }
    final String? semanticsLabel;
    // This can't use the platform from Theme because it is the Android OS that
    // expects the duplicated tooltip and label.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        semanticsLabel = MaterialLocalizations.of(context).closeButtonTooltip;
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsLabel = null;
        break;
    }

    return Icon(Icons.close, semanticLabel: semanticsLabel);
  }
}

/// A Material Design close button.
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
///  * [IconButton], to create other Material Design icon buttons.
class CloseButton extends StatelessWidget {
  /// Creates a Material Design close button.
  const CloseButton({ super.key, this.color, this.onPressed });

  /// The color to use for the icon.
  ///
  /// Defaults to the [IconThemeData.color] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final Color? color;

  /// An override callback to perform instead of the default behavior which is
  /// to pop the [Navigator].
  ///
  /// It can, for instance, be used to pop the platform's navigation stack
  /// via [SystemNavigator] instead of Flutter's [Navigator] in add-to-app
  /// situations.
  ///
  /// Defaults to null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const CloseButtonIcon(),
      color: color,
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
}

/// A "drawer" icon that's appropriate for the current [TargetPlatform].
///
/// The current platform is determined by querying for the ambient [Theme].
///
/// See also:
///
///  * [DrawerButton], an [IconButton] with a [DrawerButtonIcon] that calls
///    [ScaffoldState.openDrawer] to open the [Scaffold.drawer].
///  * [EndDrawerButton], an [IconButton] with an [EndDrawerButtonIcon] that
///    calls [ScaffoldState.openEndDrawer] to open the [Scaffold.endDrawer].
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a Material Design icon.
///  * [ThemeData.platform], which specifies the current platform.
class DrawerButtonIcon extends StatelessWidget {
  /// Creates an icon that shows the appropriate "close" image for
  /// the current platform (as obtained from the [Theme]).
  const DrawerButtonIcon({ super.key });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WidgetBuilder? iconBuilder = theme.actionIconTheme?.drawerButtonIconBuilder;
    if (iconBuilder != null) {
      return iconBuilder(context);
    }
    final String? semanticsLabel;
    // This can't use the platform from Theme because it is the Android OS that
    // expects the duplicated tooltip and label.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        semanticsLabel = MaterialLocalizations.of(context).openAppDrawerTooltip;
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsLabel = null;
        break;
    }

    return Icon(Icons.menu, semanticLabel: semanticsLabel);
  }
}

/// A Material Design drawer button.
///
/// A [DrawerButton] is an [IconButton] with a "drawer" icon. When pressed, the
/// close button calls [ScaffoldState.openDrawer] to the [Scaffold.drawer].
///
/// See also:
///
///  * [EndDrawerButton], an [IconButton] with an [EndDrawerButtonIcon] that
///    calls [ScaffoldState.openEndDrawer] to open the [Scaffold.endDrawer].
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a Material Design icon.
///  * [ThemeData.platform], which specifies the current platform.
class DrawerButton extends StatelessWidget {
  /// Creates a Material Design drawer button.
  const DrawerButton({ super.key, this.color, this.onPressed, this.iconSize });

  /// The color to use for the icon.
  ///
  /// Defaults to the [IconThemeData.color] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final Color? color;

  /// An override callback to perform instead of the default behavior which is
  /// to open the [Scaffold.drawer].
  ///
  /// Defaults to null.
  final VoidCallback? onPressed;

  /// The size to use for the icon.
  ///
  /// Defaults to the [IconThemeData.size] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const DrawerButtonIcon(),
      color: color,
      iconSize: iconSize,
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Scaffold.of(context).openDrawer();
        }
      },
    );
  }
}

/// A "end drawer" icon that's appropriate for the current [TargetPlatform].
///
/// The current platform is determined by querying for the ambient [Theme].
///
/// See also:
///
///  * [DrawerButton], an [IconButton] with a [DrawerButtonIcon] that calls
///    [ScaffoldState.openDrawer] to open the [Scaffold.drawer].
///  * [EndDrawerButton], an [IconButton] with an [EndDrawerButtonIcon] that
///    calls [ScaffoldState.openEndDrawer] to open the [Scaffold.endDrawer]
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a Material Design icon.
///  * [ThemeData.platform], which specifies the current platform.
class EndDrawerButtonIcon extends StatelessWidget {
  /// Creates an icon that shows the appropriate "end drawer" image for
  /// the current platform (as obtained from the [Theme]).
  const EndDrawerButtonIcon({ super.key });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WidgetBuilder? iconBuilder = theme.actionIconTheme?.endDrawerButtonIconBuilder;
    if (iconBuilder != null) {
      return iconBuilder(context);
    }
    final String? semanticsLabel;
    // This can't use the platform from Theme because it is the Android OS that
    // expects the duplicated tooltip and label.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        semanticsLabel = MaterialLocalizations.of(context).openAppDrawerTooltip;
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        semanticsLabel = null;
        break;
    }

    return Icon(Icons.menu, semanticLabel: semanticsLabel);
  }
}

/// A Material Design drawer button.
///
/// A [EndDrawerButton] is an [IconButton] with a "drawer" icon. When pressed, the
/// end drawer button calls [ScaffoldState.openEndDrawer] to open the [Scaffold.endDrawer].
///
/// See also:
///
///  * [DrawerButton], an [IconButton] with a [DrawerButtonIcon] that calls
///    [ScaffoldState.openDrawer] to open a drawer.
///  * [IconButton], which is a more general widget for creating buttons
///    with icons.
///  * [Icon], a Material Design icon.
///  * [ThemeData.platform], which specifies the current platform.
class EndDrawerButton extends StatelessWidget {
  /// Creates a Material Design end-drawer button.
  const EndDrawerButton({ super.key, this.color, this.onPressed, this.iconSize });

  /// The color to use for the icon.
  ///
  /// Defaults to the [IconThemeData.color] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final Color? color;

  /// An override callback to perform instead of the default behavior which is
  /// to open the [Scaffold.endDrawer].
  ///
  /// Defaults to null.
  final VoidCallback? onPressed;

  /// The size to use for the icon.
  ///
  /// Defaults to the [IconThemeData.size] specified in the ambient [IconTheme],
  /// which usually matches the ambient [Theme]'s [ThemeData.iconTheme].
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return IconButton(
      icon: const EndDrawerButtonIcon(),
      color: color,
      iconSize: iconSize,
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Scaffold.of(context).openEndDrawer();
        }
      },
    );
  }
}
