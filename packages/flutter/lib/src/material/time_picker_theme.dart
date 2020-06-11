// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines the visual properties of the widget displayed with [showTimePicker].
///
/// Descendant widgets obtain the current [TimePickerThemeData] object using
/// `TimePickerTheme.of(context)`. Instances of [TimePickerThemeData]
/// can be customized with [TimePickerThemeData.copyWith].
///
/// Typically a [TimePickerThemeData] is specified as part of the overall
/// [Theme] with [ThemeData.timePickerTheme].
///
/// All [TimePickerThemeData] properties are `null` by default. When null,
/// [showTimePicker] will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
class TimePickerThemeData with Diagnosticable {

  /// Creates a theme that can be used for [TimePickerTheme] or
  /// [ThemeData.timePickerTheme].
  const TimePickerThemeData({
    this.backgroundColor,
    this.hourMinuteSelectedTextColor,
    this.hourMinuteSelectedColor,
    this.hourMinuteUnselectedTextColor,
    this.hourMinuteUnselectedColor,
    this.dayPeriodSelectedTextColor,
    this.dayPeriodSelectedColor,
    this.dayPeriodUnselectedTextColor,
    this.dayPeriodUnselectedColor,
    this.dialHandColor,
    this.dialBackgroundColor,
    this.dayPeriodBorderColor,
    this.hourMinuteTextStyle,
    this.dayPeriodTextStyle,
    this.helpTextStyle,
    this.shape,
    this.hourMinuteShape,
    this.dayPeriodShape,
    this.inputDecorationTheme,
  });

  /// The background color of a time picker.
  ///
  /// If this is null, the time picker defaults to [ColorScheme.background].
  final Color backgroundColor;

  /// The color used for the selected text in the header of a time picker.
  ///
  /// This determines the selected color of the header text that represent
  /// hours and minutes.
  ///
  /// If this is null, the time picker defaults to [ColorScheme.primary].
  final Color hourMinuteSelectedTextColor;

  /// The color used for the selected background in the header of a time picker.
  ///
  /// This determines the selected color of the header segments that represent
  /// hours and minutes.
  ///
  /// If this is null, the time picker defaults to
  /// `ColorScheme.primary.withOpacity(0.12)` if the brightness is light and
  /// `ColorScheme.primary.withOpacity(0.24)` if the brightness is dark.
  final Color hourMinuteSelectedColor;

  /// The color used for the unselected text in the header of a time picker.
  ///
  /// This determines the unselected color of the header text that represent
  /// hours and minutes.
  ///
  /// If this is null, the time picker defaults to [ColorScheme.onSurface].
  final Color hourMinuteUnselectedTextColor;

  /// The color used for the unselected background in the header of a time
  /// picker.
  ///
  /// This determines the unselected color of the header segments that represent
  /// hours and minutes.
  ///
  /// If this is null, the time picker defaults to
  /// `ColorScheme.onSurface.withOpacity(0.12)`.
  final Color hourMinuteUnselectedColor;

  /// The color used for the selected text in the day period of a time picker.
  ///
  /// This determines the selected color of the text that represent AM/PM.
  ///
  /// If this is null, the time picker defaults to [ColorScheme.primary].
  final Color dayPeriodSelectedTextColor;

  /// The color used for the selected background in the day period of a time
  /// picker.
  ///
  /// This determines the selected color of the day period that represent
  /// AM/PM.
  ///
  /// If this is null, the time picker defaults to
  /// `ColorScheme.primary.withOpacity(0.12)` if the brightness is light and
  /// `ColorScheme.primary.withOpacity(0.24)` if the brightness is dark.
  final Color dayPeriodSelectedColor;

  /// The color used for the unselected text in the day period of a time picker.
  ///
  /// This determines the unselected color of the text that represent AM/PM.
  ///
  /// If this is null, the time picker defaults to
  /// `ColorScheme.onSurface.withOpacity(0.60)`.
  final Color dayPeriodUnselectedTextColor;

  /// The color used for the unselected background in the day period of a time
  /// picker.
  ///
  /// This determines the unselected color of the day period that represent
  /// AM/PM.
  ///
  /// If this is null, the time picker defaults to [Colors.transparent] to
  /// allow the [Dialog]'s color to be used.
  final Color dayPeriodUnselectedColor;

  /// The color of the time picker dial's hand.
  ///
  /// If this is null, the time picker defaults to [ColorScheme.primary].
  final Color dialHandColor;

  /// The background color of the time picker dial.
  ///
  /// If this is null, the time picker defaults to [ColorScheme.primary].
  final Color dialBackgroundColor;

  /// The color of the day period border.
  ///
  /// If this is null, the time picker defaults to:
  /// ```
  /// Color.alphaBlend(colorScheme.onBackground.withOpacity(0.38), colorScheme.surface)
  /// ```
  final Color dayPeriodBorderColor;

  /// Used to configure the [TextStyle]s for the hour/minute controls.
  ///
  /// If this is null, the time picker defaults to [TextTheme.headline3].
  final TextStyle hourMinuteTextStyle;

  /// Used to configure the [TextStyle]s for the day period control.
  ///
  /// If this is null, the time picker defaults to [TextTheme.subtitle1].
  final TextStyle dayPeriodTextStyle;

  /// Used to configure the [TextStyle]s for the helper text in the header.
  ///
  /// If this is null, the time picker defaults to [TextTheme.overline].
  final TextStyle helpTextStyle;

  /// The shape of the [Dialog] that the time picker is presented in.
  ///
  /// If this is null, the time picker defaults to
  /// `RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)))`.
  final ShapeBorder shape;

  /// The shape of the hour and minute controls that the time picker uses.
  ///
  /// If this is null, the time picker defaults to
  /// `RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)))`.
  final ShapeBorder hourMinuteShape;

  /// The shape of the day period that the time picker uses.
  ///
  /// If this is null, the time picker defaults to:
  /// ```
  /// RoundedRectangleBorder(
  ///   borderRadius: BorderRadius.all(Radius.circular(4.0)),
  ///   side: BorderSide(),
  /// )
  /// ```
  final ShapeBorder dayPeriodShape;

  /// The input decoration theme for the [TextField]s in the time picker.
  ///
  /// If this is null, the time picker provides its own defaults.
  final InputDecorationTheme inputDecorationTheme;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  TimePickerThemeData copyWith({
    Color backgroundColor,
    Color hourMinuteSelectedTextColor,
    Color hourMinuteSelectedColor,
    Color hourMinuteUnselectedTextColor,
    Color hourMinuteUnselectedColor,
    Color dayPeriodSelectedTextColor,
    Color dayPeriodSelectedColor,
    Color dayPeriodUnselectedTextColor,
    Color dayPeriodUnselectedColor,
    Color dialHandColor,
    Color dialBackgroundColor,
    Color dayPeriodBorderColor,
    TextStyle hourMinuteTextStyle,
    TextStyle dayPeriodTextStyle,
    TextStyle helpTextStyle,
    ShapeBorder shape,
    ShapeBorder hourMinuteShape,
    ShapeBorder dayPeriodShape,
    InputDecorationTheme inputDecorationTheme,
  }) {
    return TimePickerThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hourMinuteSelectedTextColor: hourMinuteSelectedTextColor ?? this.hourMinuteSelectedTextColor,
      hourMinuteSelectedColor: hourMinuteSelectedColor ?? this.hourMinuteSelectedColor,
      hourMinuteUnselectedTextColor: hourMinuteUnselectedTextColor ?? this.hourMinuteUnselectedTextColor,
      hourMinuteUnselectedColor: hourMinuteUnselectedColor ?? this.hourMinuteUnselectedColor,
      dayPeriodSelectedTextColor: dayPeriodSelectedTextColor ?? this.dayPeriodSelectedTextColor,
      dayPeriodSelectedColor: dayPeriodSelectedColor ?? this.dayPeriodSelectedColor,
      dayPeriodUnselectedTextColor: dayPeriodUnselectedTextColor ?? this.dayPeriodUnselectedTextColor,
      dayPeriodUnselectedColor: dayPeriodUnselectedColor ?? this.dayPeriodUnselectedColor,
      dialHandColor: dialHandColor ?? this.dialHandColor,
      dialBackgroundColor: dialBackgroundColor ?? this.dialBackgroundColor,
      dayPeriodBorderColor: dayPeriodBorderColor ?? this.dayPeriodBorderColor,
      hourMinuteTextStyle: hourMinuteTextStyle ?? this.hourMinuteTextStyle,
      dayPeriodTextStyle: dayPeriodTextStyle ?? this.dayPeriodTextStyle,
      helpTextStyle: helpTextStyle ?? this.helpTextStyle,
      shape: shape ?? this.shape,
      hourMinuteShape: hourMinuteShape ?? this.hourMinuteShape,
      dayPeriodShape: dayPeriodShape ?? this.dayPeriodShape,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
    );
  }

  /// Linearly interpolate between two time picker themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TimePickerThemeData lerp(TimePickerThemeData a, TimePickerThemeData b, double t) {
    assert(t != null);
    return TimePickerThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      hourMinuteSelectedTextColor: Color.lerp(a?.hourMinuteSelectedTextColor, b?.hourMinuteSelectedTextColor, t),
      hourMinuteSelectedColor: Color.lerp(a?.hourMinuteSelectedColor, b?.hourMinuteSelectedColor, t),
      hourMinuteUnselectedTextColor: Color.lerp(a?.hourMinuteUnselectedTextColor, b?.hourMinuteUnselectedTextColor, t),
      hourMinuteUnselectedColor: Color.lerp(a?.hourMinuteUnselectedColor, b?.hourMinuteUnselectedColor, t),
      dayPeriodSelectedTextColor: Color.lerp(a?.dayPeriodSelectedTextColor, b?.dayPeriodSelectedTextColor, t),
      dayPeriodSelectedColor: Color.lerp(a?.dayPeriodSelectedColor, b?.dayPeriodSelectedColor, t),
      dayPeriodUnselectedTextColor: Color.lerp(a?.dayPeriodUnselectedTextColor, b?.dayPeriodUnselectedTextColor, t),
      dayPeriodUnselectedColor: Color.lerp(a?.dayPeriodUnselectedColor, b?.dayPeriodUnselectedColor, t),
      dialHandColor: Color.lerp(a?.dialHandColor, b?.dialHandColor, t),
      dialBackgroundColor: Color.lerp(a?.dialBackgroundColor, b?.dialBackgroundColor, t),
      dayPeriodBorderColor: Color.lerp(a?.dayPeriodBorderColor, b?.dayPeriodBorderColor, t),
      hourMinuteTextStyle: TextStyle.lerp(a?.hourMinuteTextStyle, b?.hourMinuteTextStyle, t),
      dayPeriodTextStyle: TextStyle.lerp(a?.dayPeriodTextStyle, b?.dayPeriodTextStyle, t),
      helpTextStyle: TextStyle.lerp(a?.helpTextStyle, b?.helpTextStyle, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      hourMinuteShape: ShapeBorder.lerp(a?.hourMinuteShape, b?.hourMinuteShape, t),
      dayPeriodShape: ShapeBorder.lerp(a?.dayPeriodShape, b?.dayPeriodShape, t),
      inputDecorationTheme: t < 0.5 ? a.inputDecorationTheme : b.inputDecorationTheme,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      hourMinuteSelectedTextColor,
      hourMinuteSelectedColor,
      hourMinuteUnselectedTextColor,
      hourMinuteUnselectedColor,
      dayPeriodSelectedTextColor,
      dayPeriodSelectedColor,
      dayPeriodUnselectedTextColor,
      dayPeriodUnselectedColor,
      dialHandColor,
      dialBackgroundColor,
      dayPeriodBorderColor,
      hourMinuteTextStyle,
      dayPeriodTextStyle,
      helpTextStyle,
      shape,
      hourMinuteShape,
      dayPeriodShape,
      inputDecorationTheme,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is TimePickerThemeData
        && other.backgroundColor == backgroundColor
        && other.hourMinuteSelectedTextColor == hourMinuteSelectedTextColor
        && other.hourMinuteSelectedColor == hourMinuteSelectedColor
        && other.hourMinuteUnselectedTextColor == hourMinuteUnselectedTextColor
        && other.hourMinuteUnselectedColor == hourMinuteUnselectedColor
        && other.dayPeriodSelectedTextColor == dayPeriodSelectedTextColor
        && other.dayPeriodSelectedColor == dayPeriodSelectedColor
        && other.dayPeriodUnselectedTextColor == dayPeriodUnselectedTextColor
        && other.dayPeriodUnselectedColor == dayPeriodUnselectedColor
        && other.dialHandColor == dialHandColor
        && other.dialBackgroundColor == dialBackgroundColor
        && other.dayPeriodBorderColor == dayPeriodBorderColor
        && other.hourMinuteTextStyle == hourMinuteTextStyle
        && other.dayPeriodTextStyle == dayPeriodTextStyle
        && other.helpTextStyle == helpTextStyle
        && other.shape == shape
        && other.hourMinuteShape == hourMinuteShape
        && other.dayPeriodShape == dayPeriodShape
        && other.inputDecorationTheme == inputDecorationTheme;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('hourMinuteSelectedTextColor', hourMinuteSelectedTextColor, defaultValue: null));
    properties.add(ColorProperty('hourMinuteSelectedColor', hourMinuteSelectedColor, defaultValue: null));
    properties.add(ColorProperty('hourMinuteUnselectedTextColor', hourMinuteUnselectedTextColor, defaultValue: null));
    properties.add(ColorProperty('hourMinuteUnselectedColor', hourMinuteUnselectedColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodSelectedTextColor', dayPeriodSelectedTextColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodSelectedColor', dayPeriodSelectedColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodUnselectedTextColor', dayPeriodUnselectedTextColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodUnselectedColor', dayPeriodUnselectedColor, defaultValue: null));
    properties.add(ColorProperty('dialHandColor', dialHandColor, defaultValue: null));
    properties.add(ColorProperty('dialBackgroundColor', dialBackgroundColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodBorderColor', dayPeriodBorderColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('hourMinuteTextStyle', hourMinuteTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('dayPeriodTextStyle', dayPeriodTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('helpTextStyle', helpTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('hourMinuteShape', hourMinuteShape, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('dayPeriodShape', dayPeriodShape, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for time pickers
/// displayed in this widget's subtree.
///
/// Values specified here are used for time picker properties that are not
/// given an explicit non-null value.
class TimePickerTheme extends InheritedTheme {
  /// Creates a time picker theme that controls the configurations for
  /// time pickers displayed in its widget subtree.
  const TimePickerTheme({
    Key key,
    this.data,
    Widget child,
  }) : super(key: key, child: child);

  /// The properties for descendant time picker widgets.
  final TimePickerThemeData data;

  /// The closest instance of this class's [data] value that encloses the given
  /// context.
  ///
  /// If there is no ancestor, it returns [ThemeData.timePickerTheme].
  /// Applications can assume that the returned value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TimePickerThemeData theme = TimePickerTheme.of(context);
  /// ```
  static TimePickerThemeData of(BuildContext context) {
    final TimePickerTheme timePickerTheme = context.dependOnInheritedWidgetOfExactType<TimePickerTheme>();
    return timePickerTheme?.data ?? Theme.of(context).timePickerTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final TimePickerTheme ancestorTheme = context.findAncestorWidgetOfExactType<TimePickerTheme>();
    return identical(this, ancestorTheme) ? child : TimePickerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(TimePickerTheme oldWidget) => data != oldWidget.data;
}