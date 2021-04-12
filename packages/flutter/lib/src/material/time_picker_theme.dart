// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'input_decorator.dart';
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
///  * [TimePickerTheme], which describes the actual configuration of a time
///    picker theme.
@immutable
class TimePickerThemeData with Diagnosticable {

  /// Creates a theme that can be used for [TimePickerTheme] or
  /// [ThemeData.timePickerTheme].
  const TimePickerThemeData({
    this.backgroundColor,
    this.hourMinuteTextColor,
    this.hourMinuteColor,
    this.dayPeriodTextColor,
    this.dayPeriodColor,
    this.dialHandColor,
    this.dialBackgroundColor,
    this.dialTextColor,
    this.entryModeIconColor,
    this.hourMinuteTextStyle,
    this.dayPeriodTextStyle,
    this.helpTextStyle,
    this.shape,
    this.hourMinuteShape,
    this.dayPeriodShape,
    this.dayPeriodBorderSide,
    this.inputDecorationTheme,
  });

  /// The background color of a time picker.
  ///
  /// If this is null, the time picker defaults to the overall theme's
  /// [ColorScheme.background].
  final Color? backgroundColor;

  /// The color of the header text that represents hours and minutes.
  ///
  /// If [hourMinuteTextColor] is a [MaterialStateColor], then the effective
  /// text color can depend on the [MaterialState.selected] state, i.e. if the
  /// text is selected or not.
  ///
  /// By default the overall theme's [ColorScheme.primary] color is used when
  /// the text is selected and [ColorScheme.onSurface] when it's not selected.
  final Color? hourMinuteTextColor;

  /// The background color of the hour and minutes header segments.
  ///
  /// If [hourMinuteColor] is a [MaterialStateColor], then the effective
  /// background color can depend on the [MaterialState.selected] state, i.e.
  /// if the segment is selected or not.
  ///
  /// By default, if the segment is selected, the overall theme's
  /// `ColorScheme.primary.withOpacity(0.12)` is used when the overall theme's
  /// brightness is [Brightness.light] and
  /// `ColorScheme.primary.withOpacity(0.24)` is used when the overall theme's
  /// brightness is [Brightness.dark].
  /// If the segment is not selected, the overall theme's
  /// `ColorScheme.onSurface.withOpacity(0.12)` is used.
  final Color? hourMinuteColor;

  /// The color of the day period text that represents AM/PM.
  ///
  /// If [dayPeriodTextColor] is a [MaterialStateColor], then the effective
  /// text color can depend on the [MaterialState.selected] state, i.e. if the
  /// text is selected or not.
  ///
  /// By default the overall theme's [ColorScheme.primary] color is used when
  /// the text is selected and `ColorScheme.onSurface.withOpacity(0.60)` when
  /// it's not selected.
  final Color? dayPeriodTextColor;

  /// The background color of the AM/PM toggle.
  ///
  /// If [dayPeriodColor] is a [MaterialStateColor], then the effective
  /// background color can depend on the [MaterialState.selected] state, i.e.
  /// if the segment is selected or not.
  ///
  /// By default, if the segment is selected, the overall theme's
  /// `ColorScheme.primary.withOpacity(0.12)` is used when the overall theme's
  /// brightness is [Brightness.light] and
  /// `ColorScheme.primary.withOpacity(0.24)` is used when the overall theme's
  /// brightness is [Brightness.dark].
  /// If the segment is not selected, [Colors.transparent] is used to allow the
  /// [Dialog]'s color to be used.
  final Color? dayPeriodColor;

  /// The color of the time picker dial's hand.
  ///
  /// If this is null, the time picker defaults to the overall theme's
  /// [ColorScheme.primary].
  final Color? dialHandColor;

  /// The background color of the time picker dial.
  ///
  /// If this is null, the time picker defaults to the overall theme's
  /// [ColorScheme.primary].
  final Color? dialBackgroundColor;

  /// The color of the dial text that represents specific hours and minutes.
  ///
  /// If [dialTextColor] is a [MaterialStateColor], then the effective
  /// text color can depend on the [MaterialState.selected] state, i.e. if the
  /// text is selected or not.
  ///
  /// If this color is null then the dial's text colors are based on the
  /// theme's [ThemeData.colorScheme].
  final Color? dialTextColor;

  /// The color of the entry mode [IconButton].
  ///
  /// If this is null, the time picker defaults to:
  /// ```
  /// Theme.of(context).colorScheme.onSurface.withOpacity(
  ///   Theme.of(context).colorScheme.brightness == Brightness.dark ? 1.0 : 0.6,
  /// )
  /// ```
  final Color? entryModeIconColor;

  /// Used to configure the [TextStyle]s for the hour/minute controls.
  ///
  /// If this is null, the time picker defaults to the overall theme's
  /// [TextTheme.headline3].
  final TextStyle? hourMinuteTextStyle;

  /// Used to configure the [TextStyle]s for the day period control.
  ///
  /// If this is null, the time picker defaults to the overall theme's
  /// [TextTheme.subtitle1].
  final TextStyle? dayPeriodTextStyle;

  /// Used to configure the [TextStyle]s for the helper text in the header.
  ///
  /// If this is null, the time picker defaults to the overall theme's
  /// [TextTheme.overline].
  final TextStyle? helpTextStyle;

  /// The shape of the [Dialog] that the time picker is presented in.
  ///
  /// If this is null, the time picker defaults to
  /// `RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)))`.
  final ShapeBorder? shape;

  /// The shape of the hour and minute controls that the time picker uses.
  ///
  /// If this is null, the time picker defaults to
  /// `RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)))`.
  final ShapeBorder? hourMinuteShape;

  /// The shape of the day period that the time picker uses.
  ///
  /// If this is null, the time picker defaults to:
  /// ```
  /// RoundedRectangleBorder(
  ///   borderRadius: BorderRadius.all(Radius.circular(4.0)),
  ///   side: BorderSide(),
  /// )
  /// ```
  final OutlinedBorder? dayPeriodShape;

  /// The color and weight of the day period's outline.
  ///
  /// If this is null, the time picker defaults to:
  /// ```
  /// BorderSide(
  ///   color: Color.alphaBlend(colorScheme.onBackground.withOpacity(0.38), colorScheme.surface),
  /// )
  /// ```
  final BorderSide? dayPeriodBorderSide;

  /// The input decoration theme for the [TextField]s in the time picker.
  ///
  /// If this is null, the time picker provides its own defaults.
  final InputDecorationTheme? inputDecorationTheme;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  TimePickerThemeData copyWith({
    Color? backgroundColor,
    Color? hourMinuteTextColor,
    Color? hourMinuteColor,
    Color? dayPeriodTextColor,
    Color? dayPeriodColor,
    Color? dialHandColor,
    Color? dialBackgroundColor,
    Color? dialTextColor,
    Color? entryModeIconColor,
    TextStyle? hourMinuteTextStyle,
    TextStyle? dayPeriodTextStyle,
    TextStyle? helpTextStyle,
    ShapeBorder? shape,
    ShapeBorder? hourMinuteShape,
    OutlinedBorder? dayPeriodShape,
    BorderSide? dayPeriodBorderSide,
    InputDecorationTheme? inputDecorationTheme,
  }) {
    return TimePickerThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hourMinuteTextColor: hourMinuteTextColor ?? this.hourMinuteTextColor,
      hourMinuteColor: hourMinuteColor ?? this.hourMinuteColor,
      dayPeriodTextColor: dayPeriodTextColor ?? this.dayPeriodTextColor,
      dayPeriodColor: dayPeriodColor ?? this.dayPeriodColor,
      dialHandColor: dialHandColor ?? this.dialHandColor,
      dialBackgroundColor: dialBackgroundColor ?? this.dialBackgroundColor,
      dialTextColor: dialTextColor ?? this.dialTextColor,
      entryModeIconColor: entryModeIconColor ?? this.entryModeIconColor,
      hourMinuteTextStyle: hourMinuteTextStyle ?? this.hourMinuteTextStyle,
      dayPeriodTextStyle: dayPeriodTextStyle ?? this.dayPeriodTextStyle,
      helpTextStyle: helpTextStyle ?? this.helpTextStyle,
      shape: shape ?? this.shape,
      hourMinuteShape: hourMinuteShape ?? this.hourMinuteShape,
      dayPeriodShape: dayPeriodShape ?? this.dayPeriodShape,
      dayPeriodBorderSide: dayPeriodBorderSide ?? this.dayPeriodBorderSide,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
    );
  }

  /// Linearly interpolate between two time picker themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TimePickerThemeData lerp(TimePickerThemeData? a, TimePickerThemeData? b, double t) {
    assert(t != null);

    // Workaround since BorderSide's lerp does not allow for null arguments.
    BorderSide? lerpedBorderSide;
    if (a?.dayPeriodBorderSide == null && b?.dayPeriodBorderSide == null) {
      lerpedBorderSide = null;
    } else if (a?.dayPeriodBorderSide == null) {
      lerpedBorderSide = b?.dayPeriodBorderSide;
    } else if (b?.dayPeriodBorderSide == null) {
      lerpedBorderSide = a?.dayPeriodBorderSide;
    } else {
      lerpedBorderSide = BorderSide.lerp(a!.dayPeriodBorderSide!, b!.dayPeriodBorderSide!, t);
    }
    return TimePickerThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      hourMinuteTextColor: Color.lerp(a?.hourMinuteTextColor, b?.hourMinuteTextColor, t),
      hourMinuteColor: Color.lerp(a?.hourMinuteColor, b?.hourMinuteColor, t),
      dayPeriodTextColor: Color.lerp(a?.dayPeriodTextColor, b?.dayPeriodTextColor, t),
      dayPeriodColor: Color.lerp(a?.dayPeriodColor, b?.dayPeriodColor, t),
      dialHandColor: Color.lerp(a?.dialHandColor, b?.dialHandColor, t),
      dialBackgroundColor: Color.lerp(a?.dialBackgroundColor, b?.dialBackgroundColor, t),
      dialTextColor: Color.lerp(a?.dialTextColor, b?.dialTextColor, t),
      entryModeIconColor: Color.lerp(a?.entryModeIconColor, b?.entryModeIconColor, t),
      hourMinuteTextStyle: TextStyle.lerp(a?.hourMinuteTextStyle, b?.hourMinuteTextStyle, t),
      dayPeriodTextStyle: TextStyle.lerp(a?.dayPeriodTextStyle, b?.dayPeriodTextStyle, t),
      helpTextStyle: TextStyle.lerp(a?.helpTextStyle, b?.helpTextStyle, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      hourMinuteShape: ShapeBorder.lerp(a?.hourMinuteShape, b?.hourMinuteShape, t),
      dayPeriodShape: ShapeBorder.lerp(a?.dayPeriodShape, b?.dayPeriodShape, t) as OutlinedBorder?,
      dayPeriodBorderSide: lerpedBorderSide,
      inputDecorationTheme: t < 0.5 ? a?.inputDecorationTheme : b?.inputDecorationTheme,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      hourMinuteTextColor,
      hourMinuteColor,
      dayPeriodTextColor,
      dayPeriodColor,
      dialHandColor,
      dialBackgroundColor,
      dialTextColor,
      entryModeIconColor,
      hourMinuteTextStyle,
      dayPeriodTextStyle,
      helpTextStyle,
      shape,
      hourMinuteShape,
      dayPeriodShape,
      dayPeriodBorderSide,
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
        && other.hourMinuteTextColor == hourMinuteTextColor
        && other.hourMinuteColor == hourMinuteColor
        && other.dayPeriodTextColor == dayPeriodTextColor
        && other.dayPeriodColor == dayPeriodColor
        && other.dialHandColor == dialHandColor
        && other.dialBackgroundColor == dialBackgroundColor
        && other.dialTextColor == dialTextColor
        && other.entryModeIconColor == entryModeIconColor
        && other.hourMinuteTextStyle == hourMinuteTextStyle
        && other.dayPeriodTextStyle == dayPeriodTextStyle
        && other.helpTextStyle == helpTextStyle
        && other.shape == shape
        && other.hourMinuteShape == hourMinuteShape
        && other.dayPeriodShape == dayPeriodShape
        && other.dayPeriodBorderSide == dayPeriodBorderSide
        && other.inputDecorationTheme == inputDecorationTheme;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('hourMinuteTextColor', hourMinuteTextColor, defaultValue: null));
    properties.add(ColorProperty('hourMinuteColor', hourMinuteColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodTextColor', dayPeriodTextColor, defaultValue: null));
    properties.add(ColorProperty('dayPeriodColor', dayPeriodColor, defaultValue: null));
    properties.add(ColorProperty('dialHandColor', dialHandColor, defaultValue: null));
    properties.add(ColorProperty('dialBackgroundColor', dialBackgroundColor, defaultValue: null));
    properties.add(ColorProperty('dialTextColor', dialTextColor, defaultValue: null));
    properties.add(ColorProperty('entryModeIconColor', entryModeIconColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('hourMinuteTextStyle', hourMinuteTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('dayPeriodTextStyle', dayPeriodTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('helpTextStyle', helpTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('hourMinuteShape', hourMinuteShape, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('dayPeriodShape', dayPeriodShape, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderSide>('dayPeriodBorderSide', dayPeriodBorderSide, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for time pickers
/// displayed using [showTimePicker] in this widget's subtree.
///
/// Values specified here are used for time picker properties that are not
/// given an explicit non-null value.
class TimePickerTheme extends InheritedTheme {
  /// Creates a time picker theme that controls the configurations for
  /// time pickers displayed in its widget subtree.
  const TimePickerTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : assert(data != null),
       super(key: key, child: child);

  /// The properties for descendant time picker widgets.
  final TimePickerThemeData data;

  /// The [data] value of the closest [TimePickerTheme] ancestor.
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
    final TimePickerTheme? timePickerTheme = context.dependOnInheritedWidgetOfExactType<TimePickerTheme>();
    return timePickerTheme?.data ?? Theme.of(context).timePickerTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return TimePickerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(TimePickerTheme oldWidget) => data != oldWidget.data;
}
