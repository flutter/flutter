// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'input_decorator.dart';
import 'material_state.dart';
import 'theme.dart';

/// Used with [DropdownButton] and [DropdownButtonFormField] to define default
/// property values for descendant [DropdownButton] and [DropdownButtonFormField]
/// widgets.
///
/// Descendant widgets obtain the current [DropdownThemeData] object
/// using `DropdownTheme.of(context)`. Instances of
/// [DropdownThemeData] can be customized with
/// [DropdownThemeData.copyWith].
///
/// A [DropdownThemeData] is often specified as part of the
/// overall [Theme] with [ThemeData.dropdownTheme].
///
/// All [DropdownThemeData] properties are `null` by default.
/// When a theme property is null, the [DropdownButton] and [DropdownButtonFormField]
/// will provide its own default based on the overall [Theme]'s textTheme and
/// colorScheme. See the individual [DropdownButton] and [DropdownButtonFormField]
/// properties for details.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
///  * [DropdownTheme] which overrides the default [DropdownTheme]
///    of its [DropdownButton] and [DropdownButtonFormField] descendants.
///  * [ThemeData.textTheme], text with a color that contrasts with the card
///    and canvas colors.
///  * [ThemeData.colorScheme], the thirteen colors that most Material widget
///    default colors are based on.
@immutable
class DropdownThemeData with Diagnosticable {
  /// Creates a [DropdownThemeData].
  const DropdownThemeData ({
    this.dropdownColor,
    this.style,
    this.iconColor,
    this.focusColor,
    this.menuMaxHeight,
    this.borderRadius,
    this.inputDecorationTheme,
  });

  /// Overrides the default value of [DropdownButton.dropdownColor] and
  /// [DropdownButtonFormField<T>.dropdownColor].
  final Color? dropdownColor;

  /// Overrides the default value of [DropdownButton.style] and
  /// [DropdownButtonFormField<T>.style].
  final TextStyle? style;

  /// Overrides the default value of [DropdownButton.iconEnabledColor],
  /// [DropdownButton.iconDisabledColor], [DropdownButtonFormField<T>.iconEnabledColor]
  /// and [DropdownButtonFormField<T>.iconDisabledColor].
  final MaterialStateProperty<Color?>? iconColor;

  /// Overrides the default value of [DropdownButton.focusColor] and
  /// [DropdownButtonFormField<T>.focusColor].
  final Color? focusColor;

  /// Overrides the default value of [DropdownButton.menuMaxHeight] and
  /// [DropdownButtonFormField<T>.menuMaxHeight].
  final double? menuMaxHeight;

  /// Overrides the default value of [DropdownButton.borderRadius] and
  /// [DropdownButtonFormField<T>.borderRadius].
  final BorderRadius? borderRadius;

  /// Overrides the default input decoration theme for [DropdownButtonFormField].
  ///
  /// If this is null, [DropdownButtonFormField] provides its own default.
  final InputDecorationTheme? inputDecorationTheme;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  DropdownThemeData copyWith({
    Color? dropdownColor,
    TextStyle? style,
    MaterialStateProperty<Color?>? iconColor,
    Color? focusColor,
    double? menuMaxHeight,
    BorderRadius? borderRadius,
    InputDecorationTheme? inputDecorationTheme,
  }) {
    return DropdownThemeData(
      dropdownColor: dropdownColor ?? this.dropdownColor,
      style: style ?? this.style,
      iconColor: iconColor ?? this.iconColor,
      focusColor: focusColor ?? this.focusColor,
      menuMaxHeight: menuMaxHeight ?? this.menuMaxHeight,
      borderRadius: borderRadius ?? this.borderRadius,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
    );
  }

  /// Linearly interpolate between DropdownThemeData objects.
  static DropdownThemeData? lerp(DropdownThemeData? a, DropdownThemeData? b, double t) {
    assert (t != null);
    if (a == null && b == null) {
      return null;
    }
    return DropdownThemeData(
      dropdownColor: Color.lerp(a?.dropdownColor, b?.dropdownColor, t),
      style: TextStyle.lerp(a?.style, b?.style, t),
      iconColor: MaterialStateProperty.lerp<Color?>(a?.iconColor, b?.iconColor, t, Color.lerp),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      menuMaxHeight: lerpDouble(a?.menuMaxHeight, b?.menuMaxHeight, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      inputDecorationTheme: t < 0.5 ? a?.inputDecorationTheme : b?.inputDecorationTheme,
    );
  }

  @override
  int get hashCode {
    return Object.hash(
      dropdownColor,
      style,
      iconColor,
      focusColor,
      menuMaxHeight,
      borderRadius,
      inputDecorationTheme,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DropdownThemeData
      && other.dropdownColor == dropdownColor
      && other.style == style
      && other.iconColor == iconColor
      && other.focusColor == focusColor
      && other.menuMaxHeight == menuMaxHeight
      && other.borderRadius == borderRadius
      && other.inputDecorationTheme == inputDecorationTheme;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('dropdownColor', dropdownColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('iconColor', iconColor, defaultValue: null));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: null));
    properties.add(DoubleProperty('menuMaxHeight', menuMaxHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme, defaultValue: null));
  }
}

/// Overrides the default [DropdownTheme] of its [DropdownButton] and [DropdownButtonFormField]
/// descendants.
///
/// See also:
///
///  * [DropdownThemeData], which is used to configure this theme.
///  * [ThemeData.dropdownTheme], which can be used to override the default
///    [DropdownTheme] for [DropdownButton]s and [DropdownButtonFormField]s below the overall [Theme].
class DropdownTheme extends InheritedTheme {
  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  const DropdownTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(child != null),
       assert(data != null);

  /// Specifies dropdown menu height, and text style values for
  /// descendant [DropdownButton] and [DropdownButtonFormField] widgets.
  final DropdownThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [DropdownTheme] widget, then
  /// [ThemeData.dropdownTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DropdownThemeData theme = DropdownTheme.of(context);
  /// ```
  static DropdownThemeData of(BuildContext context) {
    final DropdownTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<DropdownTheme>();
    return inheritedTheme?.data ?? Theme.of(context).dropdownTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DropdownTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DropdownTheme oldWidget) => data != oldWidget.data;
 }
