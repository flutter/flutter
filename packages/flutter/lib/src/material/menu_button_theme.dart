// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'material_state.dart';
import 'menu_bar.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// A [ButtonStyle] theme that overrides the default appearance of [MenuButton]s
/// and [MenuItemButton]s when it's used with [MenuButtonTheme] or with the
/// overall [Theme]'s [ThemeData.menuTheme].
///
/// The [style]'s properties override [MenuItemButton]'s and [MenuButton]'s
/// default style, i.e. the [ButtonStyle] returned by
/// [MenuItemButton.defaultStyleOf] and [MenuButton.defaultStyleOf]. Only the
/// style's non-null property values or resolved non-null
/// [MaterialStateProperty] values are used.
///
/// See also:
///
///  * [MenuButtonTheme], the theme which is configured with this class.
///  * [MenuItemButton.defaultStyleOf] and [MenuButton.defaultStyleOf] which
///    return the default [ButtonStyle]s for menu buttons.
///  * [MenuItemButton.styleFrom] and [MenuButton.styleFrom], which converts
///    simple values into a [ButtonStyle] that's consistent with
///    their respective defaults.
///  * [MaterialStateProperty.resolve], "resolve" a material state property to a
///    simple value based on a set of [MaterialState]s.
///  * [ThemeData.menuButtonTheme], which can be used to override the default
///    [ButtonStyle] for [MenuItemButton]s and [MenuButton]s below the overall
///    [Theme].
@immutable
class MenuButtonThemeData with Diagnosticable {
  /// Creates a [MenuButtonThemeData].
  ///
  /// The [style] may be null.
  const MenuButtonThemeData({ this.style });

  /// Overrides for [MenuButton] and [MenuItemButton]'s default style.
  ///
  /// Non-null properties or non-null resolved [MaterialStateProperty] values
  /// override the [ButtonStyle] returned by [MenuButton.defaultStyleOf] or
  /// [MenuItemButton.defaultStyleOf].
  ///
  /// If [style] is null, then this theme doesn't override anything.
  final ButtonStyle? style;

  /// Linearly interpolate between two menu button themes.
  static MenuButtonThemeData? lerp(MenuButtonThemeData? a, MenuButtonThemeData? b, double t) {
    assert (t != null);
    if (a == null && b == null) {
      return null;
    }
    return MenuButtonThemeData(
      style: ButtonStyle.lerp(a?.style, b?.style, t),
    );
  }

  @override
  int get hashCode => style.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MenuButtonThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

/// Overrides the default [ButtonStyle] of its [MenuItemButton] and [MenuButton]
/// descendants.
///
/// See also:
///
///  * [MenuButtonThemeData], which is used to configure this theme.
///  * [MenuItemButton.defaultStyleOf] and [MenuButton.defaultStyleOf] which
///    return the default [ButtonStyle]s for menu buttons.
///  * [MenuItemButton.styleFrom] and [MenuButton.styleFrom], which converts
///    simple values into a [ButtonStyle] that's consistent with
///    their respective defaults.
///  * [ThemeData.menuButtonTheme], which can be used to override the default
///    [ButtonStyle] for [MenuItemButton]s and [MenuButton]s below the overall
///    [Theme].
class MenuButtonTheme extends InheritedTheme {
  /// Create a [MenuButtonTheme].
  ///
  /// The [data] parameter must not be null.
  const MenuButtonTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// The configuration of this theme.
  final MenuButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [MenuButtonTheme] widget, then
  /// [ThemeData.menuButtonTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MenuButtonThemeData theme = MenuButtonTheme.of(context);
  /// ```
  static MenuButtonThemeData of(BuildContext context) {
    final MenuButtonTheme? buttonTheme = context.dependOnInheritedWidgetOfExactType<MenuButtonTheme>();
    return buttonTheme?.data ?? Theme.of(context).menuButtonTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MenuButtonTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MenuButtonTheme oldWidget) => data != oldWidget.data;
}
