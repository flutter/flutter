// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Overrides the default values of visual properties for descendant [ComboBox] widgets.
///
/// Descendant widgets obtain the current [ComboBoxThemeData] object with
/// [ComboBoxTheme.of]. Instances of [ComboBoxTheme] can
/// be customized with [ComboBoxThemeData.copyWith].
///
/// Typically a [ComboBoxTheme] is specified as part of the overall [Theme] with
/// [ThemeData.comboBoxTheme].
///
/// All [ComboBoxThemeData] properties are null by default. When null, the [ComboBox]
/// computes its own default values, typically based on the overall
/// theme's [ThemeData.colorScheme], [ThemeData.textTheme], and [ThemeData.iconTheme].
@immutable
class ComboBoxThemeData with Diagnosticable {
  /// Creates a [ComboBoxThemeData] that can be used to override default properties
  /// in a [ComboBoxTheme] widget.
  const ComboBoxThemeData({
    this.textStyle,
    this.inputDecorationTheme,
    this.menuStyle,
  });

  /// Overrides the default value for [ComboBox.textStyle].
  final TextStyle? textStyle;

  /// The input decoration theme for the [TextField]s in the [ComboBox].
  ///
  /// If this is null, the [ComboBox] provides its own defaults.
  final InputDecorationTheme? inputDecorationTheme;

  /// Overrides the menu's default style in the [ComboBox].
  ///
  /// Any values not set in the [MenuStyle] will use the menu default for that
  /// property.
  final MenuStyle? menuStyle;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  ComboBoxThemeData copyWith({
    TextStyle? textStyle,
    InputDecorationTheme? inputDecorationTheme,
    MenuStyle? menuStyle,
  }) {
    return ComboBoxThemeData(
      textStyle: textStyle ?? this.textStyle,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      menuStyle: menuStyle ?? this.menuStyle,
    );
  }

  /// Linearly interpolates between two combo box themes.
  static ComboBoxThemeData lerp(ComboBoxThemeData? a, ComboBoxThemeData? b, double t) {
    return ComboBoxThemeData(
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      inputDecorationTheme: t < 0.5 ? a?.inputDecorationTheme : b?.inputDecorationTheme,
      menuStyle: MenuStyle.lerp(a?.menuStyle, b?.menuStyle, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    textStyle,
    inputDecorationTheme,
    menuStyle,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ComboBoxThemeData
        && other.textStyle == textStyle
        && other.inputDecorationTheme == inputDecorationTheme
        && other.menuStyle == menuStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<MenuStyle>('menuStyle', menuStyle, defaultValue: null));
  }
}

/// An inherited widget that defines the visual properties for [ComboBox]s in this widget's subtree.
///
/// Values specified here are used for [ComboBox] properties that are not
/// given an explicit non-null value.
class ComboBoxTheme extends InheritedTheme {
  /// Creates a [ComboBoxTheme] that controls visual parameters for
  /// descendant [ComboBox]s.
  const ComboBoxTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// Specifies the visual properties used by descendant [ComboBox]
  /// widgets.
  final ComboBoxThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [ComboBoxTheme] widget, then
  /// [ThemeData.comboBoxTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ComboBoxThemeData theme = ComboBoxTheme.of(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], which returns null if it doesn't find a
  ///    [ComboBoxTheme] ancestor.
  static ComboBoxThemeData of(BuildContext context) {
    return maybeOf(context) ?? Theme.of(context).comboBoxTheme;
  }

  /// The data from the closest instance of this class that encloses the given
  /// context, if any.
  ///
  /// Use this function if you want to allow situations where no
  /// [ComboBoxTheme] is in scope. Prefer using [ComboBoxTheme.of]
  /// in situations where a [ComboBoxThemeData] is expected to be
  /// non-null.
  ///
  /// If there is no [ComboBoxTheme] in scope, then this function will
  /// return null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ComboBoxThemeData? theme = ComboBoxTheme.maybeOf(context);
  /// if (theme == null) {
  ///   // Do something else instead.
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], which will return [ThemeData.comboBoxTheme] if it doesn't
  ///    find a [ComboBoxTheme] ancestor, instead of returning null.
  static ComboBoxThemeData? maybeOf(BuildContext context) {
    assert(context != null);
    return context.dependOnInheritedWidgetOfExactType<ComboBoxTheme>()?.data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return ComboBoxTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ComboBoxTheme oldWidget) => data != oldWidget.data;
}
