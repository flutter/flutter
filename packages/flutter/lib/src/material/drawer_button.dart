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
    final WidgetBuilder? iconBuilder = theme.actionButtonIcons?.drawerButtonIconBuilder;
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
    final WidgetBuilder? iconBuilder = theme.actionButtonIcons?.endDrawerButtonIconBuilder;
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
