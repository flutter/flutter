// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'dropdown_menu.dart';
/// @docImport 'text_field.dart';
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'input_decorator.dart';
import 'menu_style.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// Overrides the default values of visual properties for descendant [DropdownMenu] widgets.
///
/// Descendant widgets obtain the current [DropdownMenuThemeData] object with
/// [DropdownMenuTheme.of]. Instances of [DropdownMenuTheme] can
/// be customized with [DropdownMenuThemeData.copyWith].
///
/// Typically a [DropdownMenuTheme] is specified as part of the overall [Theme] with
/// [ThemeData.dropdownMenuTheme].
///
/// All [DropdownMenuThemeData] properties are null by default. When null, the [DropdownMenu]
/// computes its own default values, typically based on the overall
/// theme's [ThemeData.colorScheme], [ThemeData.textTheme], and [ThemeData.iconTheme].
@immutable
class DropdownMenuThemeData with Diagnosticable {
  /// Creates a [DropdownMenuThemeData] that can be used to override default properties
  /// in a [DropdownMenuTheme] widget.
  const DropdownMenuThemeData({
    this.textStyle,
    // TODO(bleroux): Clean this up once `InputDecorationTheme` is fully normalized.
    Object? inputDecorationTheme,
    this.menuStyle,
    this.disabledColor,
  }) : assert(
         inputDecorationTheme == null ||
             (inputDecorationTheme is InputDecorationTheme ||
                 inputDecorationTheme is InputDecorationThemeData),
       ),
       _inputDecorationTheme = inputDecorationTheme;

  /// Overrides the default value for [DropdownMenu.textStyle].
  final TextStyle? textStyle;

  /// The input decoration theme for the [TextField]s in a [DropdownMenu].
  ///
  /// If this is null, the [DropdownMenu] provides its own defaults.
  // TODO(bleroux): Clean this up once `InputDecorationTheme` is fully normalized.
  InputDecorationThemeData? get inputDecorationTheme {
    if (_inputDecorationTheme == null) {
      return null;
    }
    return _inputDecorationTheme is InputDecorationTheme
        ? _inputDecorationTheme.data
        : _inputDecorationTheme as InputDecorationThemeData;
  }

  final Object? _inputDecorationTheme;

  /// Overrides the menu's default style in a [DropdownMenu].
  ///
  /// Any values not set in the [MenuStyle] will use the menu default for that
  /// property.
  final MenuStyle? menuStyle;

  /// The color used for disabled DropdownMenu.
  /// This color is applied to the text of the selected item on TextField.
  final Color? disabledColor;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  DropdownMenuThemeData copyWith({
    TextStyle? textStyle,
    // TODO(bleroux): Clean this up once `InputDecorationTheme` is fully normalized.
    Object? inputDecorationTheme,
    MenuStyle? menuStyle,
    Color? disabledColor,
  }) {
    return DropdownMenuThemeData(
      textStyle: textStyle ?? this.textStyle,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      menuStyle: menuStyle ?? this.menuStyle,
      disabledColor: disabledColor ?? this.disabledColor,
    );
  }

  /// Linearly interpolates between two dropdown menu themes.
  static DropdownMenuThemeData lerp(DropdownMenuThemeData? a, DropdownMenuThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return DropdownMenuThemeData(
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      inputDecorationTheme: t < 0.5 ? a?.inputDecorationTheme : b?.inputDecorationTheme,
      menuStyle: MenuStyle.lerp(a?.menuStyle, b?.menuStyle, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
    );
  }

  @override
  int get hashCode => Object.hash(textStyle, inputDecorationTheme, menuStyle, disabledColor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DropdownMenuThemeData &&
        other.textStyle == textStyle &&
        other.inputDecorationTheme == inputDecorationTheme &&
        other.menuStyle == menuStyle &&
        other.disabledColor == disabledColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle, defaultValue: null));
    properties.add(
      DiagnosticsProperty<InputDecorationThemeData>(
        'inputDecorationThemeData',
        inputDecorationTheme,
        defaultValue: null,
      ),
    );
    properties.add(DiagnosticsProperty<MenuStyle>('menuStyle', menuStyle, defaultValue: null));
    properties.add(ColorProperty('disabledColor', disabledColor, defaultValue: null));
  }
}

/// An inherited widget that defines the visual properties for [DropdownMenu]s in this widget's subtree.
///
/// Values specified here are used for [DropdownMenu] properties that are not
/// given an explicit non-null value.
class DropdownMenuTheme extends InheritedTheme {
  /// Creates a [DropdownMenuTheme] that controls visual parameters for
  /// descendant [DropdownMenu]s.
  const DropdownMenuTheme({super.key, required this.data, required super.child});

  /// Specifies the visual properties used by descendant [DropdownMenu]
  /// widgets.
  final DropdownMenuThemeData data;

  /// Retrieves the [DropdownMenuThemeData] from the closest ancestor [DropdownMenuTheme].
  ///
  /// If there is no enclosing [DropdownMenuTheme] widget, then
  /// [ThemeData.dropdownMenuTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DropdownMenuThemeData theme = DropdownMenuTheme.of(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], which returns null if it doesn't find a
  ///    [DropdownMenuTheme] ancestor.
  static DropdownMenuThemeData of(BuildContext context) {
    return maybeOf(context) ?? Theme.of(context).dropdownMenuTheme;
  }

  /// The data from the closest instance of this class that encloses the given
  /// context, if any.
  ///
  /// Use this function if you want to allow situations where no
  /// [DropdownMenuTheme] is in scope. Prefer using [DropdownMenuTheme.of]
  /// in situations where a [DropdownMenuThemeData] is expected to be
  /// non-null.
  ///
  /// If there is no [DropdownMenuTheme] in scope, then this function will
  /// return null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DropdownMenuThemeData? theme = DropdownMenuTheme.maybeOf(context);
  /// if (theme == null) {
  ///   // Do something else instead.
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], which will return [ThemeData.dropdownMenuTheme] if it doesn't
  ///    find a [DropdownMenuTheme] ancestor, instead of returning null.
  static DropdownMenuThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DropdownMenuTheme>()?.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DropdownMenuTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DropdownMenuTheme oldWidget) => data != oldWidget.data;
}
