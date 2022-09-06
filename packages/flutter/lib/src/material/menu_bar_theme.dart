// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'menu_bar.dart';
import 'menu_style.dart';
import 'menu_theme.dart';
import 'theme.dart';

// Examples can assume:
// late Widget child;

/// Defines the visual properties of [MenuBar] widgets.
///
/// Descendant widgets obtain the current [MenuBarThemeData] object using
/// `MenuBarTheme.of(context)`.
///
/// Typically, a [MenuBarThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.menuBarTheme]. Otherwise, [MenuTheme] can be used to
/// configure its own widget subtree.
///
/// All [MenuBarThemeData] properties are `null` by default. If any of these
/// properties are null, the menu bar will provide its own defaults.
///
/// See also:
///
///  * [MenuThemeData], which describes the theme for the submenus of a
///    [MenuBar].
///  * [ThemeData], which describes the overall theme for the application.
class MenuBarThemeData extends MenuThemeData {
  /// Creates a const set of properties used to configure [MenuTheme].
  const MenuBarThemeData({
    super.style,
  });

  /// Linearly interpolate between two text button themes.
  static MenuBarThemeData? lerp(MenuBarThemeData? a, MenuBarThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null) {
      return null;
    }
    return MenuBarThemeData(
      style: MenuStyle.lerp(a?.style, b?.style, t),
    );
  }
}

/// An inherited widget that defines the configuration for the [MenuBar] widget
/// in this widget's descendants.
///
/// Values specified here are used for [MenuBar]'s properties that are not given
/// an explicit non-null value.
///
/// See also:
///  * [MenuStyle], a configuration object that holds attributes of a menu used
///    by this theme.
///  * [MenuTheme], which does the same thing for the menus created by a
///    [MenuButton].
///  * [MenuButton], a button that manages a submenu that uses these properties.
///  * [MenuBar], a widget that creates a menu bar that can use [MenuButton]s.
class MenuBarTheme extends InheritedTheme {
  /// Creates a theme that controls the configurations for [MenuBar] and
  /// [MenuItemButton] in its widget subtree.
  const MenuBarTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// The properties for [MenuBar] and [MenuItemButton] in this widget's
  /// descendants.
  final MenuBarThemeData data;

  /// Returns the closest instance of this class's [data] value that encloses
  /// the given context. If there is no ancestor, it returns
  /// [ThemeData.menuBarTheme]. Applications can assume that the returned
  /// value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return MenuTheme(
  ///     data: const MenuThemeData(
  ///       style: MenuStyle(
  ///         backgroundColor: MaterialStatePropertyAll<Color?>(Colors.red),
  ///       ),
  ///     ),
  ///     child: child,
  ///   );
  /// }
  /// ```
  static MenuBarThemeData of(BuildContext context) {
    final MenuBarTheme? menuBarTheme = context.dependOnInheritedWidgetOfExactType<MenuBarTheme>();
    return menuBarTheme?.data ?? Theme.of(context).menuBarTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MenuBarTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MenuBarTheme oldWidget) => data != oldWidget.data;
}
