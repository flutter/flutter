// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the visual properties of the widget displayed with [showDatePicker].
///
/// Descendant widgets obtain the current [DatePickerThemeData] object using
/// `DatePickerTheme.of(context)`. Instances of [DatePickerThemeData]
/// can be customized with [DatePickerThemeData.copyWith].
///
/// Typically a [DatePickerThemeData] is specified as part of the overall
/// [Theme] with [ThemeData.datePickerTheme].
///
/// All [DatePickerThemeData] properties are `null` by default. When null,
/// [showDatePicker] will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
///  * [DatePickerTheme], which describes the actual configuration of a date
///    picker theme.
@immutable
class DatePickerThemeData with Diagnosticable {
  /// Creates a theme that can be used for [DatePickerTheme] or
  /// [ThemeData.datePickerTheme].
  const DatePickerThemeData({
    this.backgroundColor,
    this.entryModeIconColor,
    this.helpTextStyle,
    this.shape,
    this.selectedDayDecoration,
    this.disabledDayDecoration,
    this.todayDecoration,
  });

  /// The background color of a date picker.
  ///
  /// If this is null, the date picker defaults to the overall theme's
  /// [ColorScheme.background].
  final Color? backgroundColor;

  /// The color of the entry mode [IconButton].
  ///
  /// If this is null, the date picker defaults to:
  /// ```
  /// Theme.of(context).colorScheme.onSurface.withOpacity(
  ///   Theme.of(context).colorScheme.brightness == Brightness.dark ? 1.0 : 0.6,
  /// )
  /// ```
  final Color? entryModeIconColor;

  /// Used to configure the [TextStyle]s for the helper text in the header.
  ///
  /// If this is null, the date picker defaults to the overall theme's
  /// [TextTheme.overline].
  final TextStyle? helpTextStyle;

  /// The shape of the [Dialog] that the date picker is presented in.
  ///
  /// The default shape is a [RoundedRectangleBorder] with a radius of 4.0
  final ShapeBorder? shape;

  /// The decoration of selected day.
  final Decoration? selectedDayDecoration;

  /// The decoration of disabled day.
  final Decoration? disabledDayDecoration;

  /// The decoration of today; only applied when it is neither selected nor disabled.
  final Decoration? todayDecoration;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  DatePickerThemeData copyWith({
    Color? backgroundColor,
    Color? entryModeIconColor,
    TextStyle? helpTextStyle,
    ShapeBorder? shape,
    Decoration? selectedDayDecoration,
    Decoration? disabledDayDecoration,
    Decoration? todayDecoration,
  }) {
    return DatePickerThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      entryModeIconColor: entryModeIconColor ?? this.entryModeIconColor,
      helpTextStyle: helpTextStyle ?? this.helpTextStyle,
      shape: shape ?? this.shape,
      selectedDayDecoration: selectedDayDecoration ?? this.selectedDayDecoration,
      disabledDayDecoration: disabledDayDecoration ?? this.disabledDayDecoration,
      todayDecoration: todayDecoration ?? this.todayDecoration,
    );
  }

  /// Linearly interpolate between two date picker themes.
  ///
  /// The argument `t` must not be null.
  ///
  static DatePickerThemeData lerp(DatePickerThemeData? a, DatePickerThemeData? b, double t) {
    assert(t != null);
    return DatePickerThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      entryModeIconColor: Color.lerp(a?.entryModeIconColor, b?.entryModeIconColor, t),
      helpTextStyle: TextStyle.lerp(a?.helpTextStyle, b?.helpTextStyle, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      selectedDayDecoration: Decoration.lerp(a?.selectedDayDecoration, b?.selectedDayDecoration, t),
      disabledDayDecoration: Decoration.lerp(a?.disabledDayDecoration, b?.disabledDayDecoration, t),
      todayDecoration: Decoration.lerp(a?.todayDecoration, b?.todayDecoration, t),
    );
  }

  @override
  int get hashCode {
    return Object.hash(
      backgroundColor,
      entryModeIconColor,
      helpTextStyle,
      shape,
      selectedDayDecoration,
      disabledDayDecoration,
      todayDecoration,
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
    return other is DatePickerThemeData &&
        other.backgroundColor == backgroundColor &&
        other.entryModeIconColor == entryModeIconColor &&
        other.helpTextStyle == helpTextStyle &&
        other.shape == shape &&
        other.selectedDayDecoration == selectedDayDecoration &&
        other.disabledDayDecoration == disabledDayDecoration &&
        other.todayDecoration == todayDecoration;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('entryModeIconColor', entryModeIconColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('helpTextStyle', helpTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('selectedDayDecoration', selectedDayDecoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('disabledDayDecoration', disabledDayDecoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('todayDecoration', todayDecoration, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for date pickers
/// displayed using [showDatePicker] in this widget's subtree.
///
/// Values specified here are used for date picker properties that are not
/// given an explicit non-null value.
class DatePickerTheme extends InheritedTheme {
  /// Creates a date picker theme that controls the configurations for
  /// date pickers displayed in its widget subtree.
  const DatePickerTheme({
    super.key,
    required this.data,
    required super.child,
  })  : assert(data != null);

  /// The properties for descendant date picker widgets.
  final DatePickerThemeData data;

  /// The [data] value of the closest [DatePickerTheme] ancestor.
  ///
  /// If there is no ancestor, it returns [ThemeData.datePickerTheme].
  /// Applications can assume that the returned value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DatePickerThemeData theme = DatePickerTheme.of(context);
  /// ```
  static DatePickerThemeData of(BuildContext context) {
    final DatePickerTheme? datePickerTheme = context.dependOnInheritedWidgetOfExactType<DatePickerTheme>();
    return datePickerTheme?.data ?? Theme.of(context).datePickerTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DatePickerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DatePickerTheme oldWidget) => data != oldWidget.data;
}
