// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'calendar_date_picker.dart';
/// @docImport 'date_picker.dart';
/// @docImport 'dialog.dart';
/// @docImport 'input_date_picker_form_field.dart';
/// @docImport 'material.dart';
/// @docImport 'scaffold.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'input_decorator.dart';
import 'text_button.dart';
import 'text_theme.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// Overrides the default values of visual properties for descendant
/// [DatePickerDialog] widgets.
///
/// Descendant widgets obtain the current [DatePickerThemeData] object with
/// [DatePickerTheme.of]. Instances of [DatePickerThemeData] can
/// be customized with [DatePickerThemeData.copyWith].
///
/// Typically a [DatePickerTheme] is specified as part of the overall
/// [Theme] with [ThemeData.datePickerTheme].
///
/// All [DatePickerThemeData] properties are null by default. When null,
/// the [DatePickerDialog] computes its own default values, typically based on
/// the overall theme's [ThemeData.colorScheme], [ThemeData.textTheme], and
/// [ThemeData.iconTheme].
@immutable
class DatePickerThemeData with Diagnosticable {
  /// Creates a [DatePickerThemeData] that can be used to override default properties
  /// in a [DatePickerTheme] widget.
  const DatePickerThemeData({
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.headerBackgroundColor,
    this.headerForegroundColor,
    this.headerHeadlineStyle,
    this.headerHelpStyle,
    this.weekdayStyle,
    this.dayStyle,
    this.dayForegroundColor,
    this.dayBackgroundColor,
    this.dayOverlayColor,
    this.dayShape,
    this.todayForegroundColor,
    this.todayBackgroundColor,
    this.todayBorder,
    this.yearStyle,
    this.yearForegroundColor,
    this.yearBackgroundColor,
    this.yearOverlayColor,
    this.yearShape,
    this.rangePickerBackgroundColor,
    this.rangePickerElevation,
    this.rangePickerShadowColor,
    this.rangePickerSurfaceTintColor,
    this.rangePickerShape,
    this.rangePickerHeaderBackgroundColor,
    this.rangePickerHeaderForegroundColor,
    this.rangePickerHeaderHeadlineStyle,
    this.rangePickerHeaderHelpStyle,
    this.rangeSelectionBackgroundColor,
    this.rangeSelectionOverlayColor,
    this.dividerColor,
    // TODO(bleroux): Clean this up once `InputDecorationTheme` is fully normalized.
    Object? inputDecorationTheme,
    this.cancelButtonStyle,
    this.confirmButtonStyle,
    this.locale,
    this.toggleButtonTextStyle,
    this.subHeaderForegroundColor,
  }) : assert(
         inputDecorationTheme == null ||
             (inputDecorationTheme is InputDecorationTheme ||
                 inputDecorationTheme is InputDecorationThemeData),
       ),
       _inputDecorationTheme = inputDecorationTheme;

  /// Overrides the default value of [Dialog.backgroundColor].
  final Color? backgroundColor;

  /// Overrides the default value of [Dialog.elevation].
  ///
  /// See also:
  ///   [Material.elevation], which explains how elevation is related to a component's shadow.
  final double? elevation;

  /// Overrides the default value of [Dialog.shadowColor].
  ///
  /// See also:
  ///   [Material.shadowColor], which explains how the shadow is rendered.
  final Color? shadowColor;

  /// Overrides the default value of [Dialog.surfaceTintColor].
  ///
  /// See also:
  ///   [Material.surfaceTintColor], which explains how this color is related to
  ///   [elevation] and [backgroundColor].
  final Color? surfaceTintColor;

  /// Overrides the default value of [Dialog.shape].
  ///
  /// If [elevation] is greater than zero then a shadow is shown and the shadow's
  /// shape mirrors the shape of the dialog.
  final ShapeBorder? shape;

  /// Overrides the header's default background fill color.
  ///
  /// The dialog's header displays the currently selected date.
  final Color? headerBackgroundColor;

  /// Overrides the header's default color used for text labels and icons.
  ///
  /// The dialog's header displays the currently selected date.
  ///
  /// This is used instead of the [TextStyle.color] property of [headerHeadlineStyle]
  /// and [headerHelpStyle].
  final Color? headerForegroundColor;

  /// Overrides the header's default headline text style.
  ///
  /// The dialog's header displays the currently selected date.
  ///
  /// The [TextStyle.color] of the [headerHeadlineStyle] is not used,
  /// [headerForegroundColor] is used instead.
  final TextStyle? headerHeadlineStyle;

  /// Overrides the header's default help text style.
  ///
  /// The help text (also referred to as "supporting text" in the Material
  /// spec) is usually a prompt to the user at the top of the header
  /// (i.e. 'Select date').
  ///
  /// The [TextStyle.color] of the [headerHelpStyle] is not used,
  /// [headerForegroundColor] is used instead.
  ///
  /// See also:
  ///   [DatePickerDialog.helpText], which specifies the help text.
  final TextStyle? headerHelpStyle;

  /// Overrides the default text style used for the row of weekday
  /// labels at the top of the date picker grid.
  final TextStyle? weekdayStyle;

  /// Overrides the default text style used for each individual day
  /// label in the grid of the date picker.
  ///
  /// The [TextStyle.color] of the [dayStyle] is not used,
  /// [dayForegroundColor] is used instead.
  final TextStyle? dayStyle;

  /// Overrides the default color used to paint the day labels in the
  /// grid of the date picker.
  ///
  /// This will be used instead of the color provided in [dayStyle].
  ///
  /// This supports different colors based on the [WidgetState]s of
  /// the day button, such as `WidgetState.selected`, `WidgetState.hovered`,
  /// `WidgetState.focused`, and `WidgetState.disabled`.
  ///
  /// ```dart
  /// dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
  ///   if (states.contains(WidgetState.selected)) {
  ///     return Theme.of(context).colorScheme.primary;
  ///   }
  ///   return null; // Use the default color.
  /// })
  /// ```
  ///
  /// See also:
  ///   * [dayOverlayColor] which applies an overlay over the day labels depending on the [WidgetState].
  final WidgetStateProperty<Color?>? dayForegroundColor;

  /// Overrides the default color used to paint the background of the
  /// day labels in the grid of the date picker.
  ///
  /// This supports different colors based on the [WidgetState]s of
  /// the day button, such as `WidgetState.selected`, `WidgetState.hovered`,
  /// `WidgetState.focused`, and `WidgetState.disabled`.
  ///
  /// ```dart
  /// dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
  ///   if (states.contains(WidgetState.selected)) {
  ///     return Theme.of(context).colorScheme.primary;
  ///   }
  ///   return null; // Use the default color.
  /// })
  /// ```
  /// See also:
  ///   * [dayOverlayColor] which applies an overlay over the day labels depending on the [WidgetState].
  final WidgetStateProperty<Color?>? dayBackgroundColor;

  /// Overrides the default highlight color that's typically used to
  /// indicate that a day in the grid is focused, hovered, or pressed.
  ///
  /// This supports different colors based on the [WidgetState]s of
  /// the day button. The overlay color is usually used with an opacity to
  /// create hover, focus, and press effects.
  ///
  /// ```dart
  /// dayOverlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
  ///   if (states.contains(WidgetState.pressed)) {
  ///     return Colors.blue.withValues(alpha: 0.12);
  ///   }
  ///   if (states.contains(WidgetState.hovered)) {
  ///     return Colors.blue.withValues(alpha: 0.08);
  ///   }
  ///   if (states.contains(WidgetState.focused)) {
  ///     return Colors.blue.withValues(alpha: 0.12);
  ///   }
  ///   return null; // Use the default color.
  /// })
  /// ```
  final WidgetStateProperty<Color?>? dayOverlayColor;

  /// Overrides the default shape used to paint the shape decoration of the
  /// day labels in the grid of the date picker.
  ///
  /// If the selected day is the current day, the provided shape with the
  /// value of [todayBackgroundColor] is used to paint the shape decoration of
  /// the day label and the value of [todayBorder] and [todayForegroundColor] is
  /// used to paint the border.
  ///
  /// If the selected day is not the current day, the provided shape with the
  /// value of [dayBackgroundColor] is used to paint the shape decoration of
  /// the day label.
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how to customize the day selector shape decoration
  /// using the [dayShape], [todayForegroundColor], [todayBackgroundColor], and
  /// [todayBorder] properties.
  ///
  /// ** See code in examples/api/lib/material/date_picker/date_picker_theme_day_shape.0.dart **
  /// {@end-tool}
  final WidgetStateProperty<OutlinedBorder?>? dayShape;

  /// Overrides the default color used to paint the
  /// [DatePickerDialog.currentDate] label in the grid of the dialog's
  /// [CalendarDatePicker] and the corresponding year in the dialog's
  /// [YearPicker].
  ///
  /// This will be used instead of the [TextStyle.color] provided in [dayStyle].
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how to customize the day selector shape decoration
  /// using the [dayShape], [todayForegroundColor], [todayBackgroundColor], and
  /// [todayBorder] properties.
  ///
  /// ** See code in examples/api/lib/material/date_picker/date_picker_theme_day_shape.0.dart **
  /// {@end-tool}
  final WidgetStateProperty<Color?>? todayForegroundColor;

  /// Overrides the default color used to paint the background of the
  /// [DatePickerDialog.currentDate] label in the grid of the date picker.
  final WidgetStateProperty<Color?>? todayBackgroundColor;

  /// Overrides the border used to paint the
  /// [DatePickerDialog.currentDate] label in the grid of the date
  /// picker.
  ///
  /// The border side's [BorderSide.color] is not used,
  /// [todayForegroundColor] is used instead.
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how to customize the day selector shape decoration
  /// using the [dayShape], [todayForegroundColor], [todayBackgroundColor], and
  /// [todayBorder] properties.
  ///
  /// ** See code in examples/api/lib/material/date_picker/date_picker_theme_day_shape.0.dart **
  /// {@end-tool}
  final BorderSide? todayBorder;

  /// Overrides the default text style used to paint each of the year
  /// entries in the year selector of the date picker.
  ///
  /// The [TextStyle.color] of the [yearStyle] is not used,
  /// [yearForegroundColor] is used instead.
  final TextStyle? yearStyle;

  /// Overrides the default color used to paint the year labels in the year
  /// selector of the date picker.
  ///
  /// This will be used instead of the color provided in [yearStyle].
  final WidgetStateProperty<Color?>? yearForegroundColor;

  /// Overrides the default color used to paint the background of the
  /// year labels in the year selector of the of the date picker.
  final WidgetStateProperty<Color?>? yearBackgroundColor;

  /// Overrides the default highlight color that's typically used to
  /// indicate that a year in the year selector is focused, hovered,
  /// or pressed.
  final WidgetStateProperty<Color?>? yearOverlayColor;

  /// Overrides the default shape used to paint the shape decoration of the
  /// year labels in the list of the year picker.
  ///
  /// If the selected year is the current year, the provided shape with the
  /// value of [todayBackgroundColor] is used to paint the shape decoration of
  /// the year label and the value of [todayBorder] and [todayForegroundColor] is
  /// used to paint the border.
  ///
  /// If the selected year is not the current year, the provided shape with the
  /// value of [yearBackgroundColor] is used to paint the shape decoration of
  /// the year label.
  final WidgetStateProperty<OutlinedBorder?>? yearShape;

  /// Overrides the default [Scaffold.backgroundColor] for
  /// [DateRangePickerDialog].
  final Color? rangePickerBackgroundColor;

  /// Overrides the default elevation of the full screen
  /// [DateRangePickerDialog].
  ///
  /// See also:
  ///   [Material.elevation], which explains how elevation is related to a component's shadow.
  final double? rangePickerElevation;

  /// Overrides the color of the shadow painted below a full screen
  /// [DateRangePickerDialog].
  ///
  /// See also:
  ///   [Material.shadowColor], which explains how the shadow is rendered.
  final Color? rangePickerShadowColor;

  /// Overrides the default color of the surface tint overlay applied
  /// to the [backgroundColor] of a full screen
  /// [DateRangePickerDialog]'s to indicate elevation.
  ///
  /// This is not recommended for use. [Material 3 spec](https://m3.material.io/styles/color/the-color-system/color-roles)
  /// introduced a set of tone-based surfaces and surface containers in its [ColorScheme],
  /// which provide more flexibility. The intention is to eventually remove surface tint color from
  /// the framework.
  ///
  /// See also:
  ///   [Material.surfaceTintColor], which explains how this color is related to
  ///   [elevation].
  final Color? rangePickerSurfaceTintColor;

  /// Overrides the default overall shape of a full screen
  /// [DateRangePickerDialog].
  ///
  /// If [elevation] is greater than zero then a shadow is shown and the shadow's
  /// shape mirrors the shape of the dialog.
  ///
  ///   [Material.surfaceTintColor], which explains how this color is related to
  ///   [elevation].
  final ShapeBorder? rangePickerShape;

  /// Overrides the default background fill color for [DateRangePickerDialog].
  ///
  /// The dialog's header displays the currently selected date range.
  final Color? rangePickerHeaderBackgroundColor;

  /// Overrides the default color used for text labels and icons in
  /// the header of a full screen [DateRangePickerDialog]
  ///
  /// The dialog's header displays the currently selected date range.
  ///
  /// This is used instead of any colors provided by
  /// [rangePickerHeaderHeadlineStyle] or [rangePickerHeaderHelpStyle].
  final Color? rangePickerHeaderForegroundColor;

  /// Overrides the default text style used for the headline text in
  /// the header of a full screen [DateRangePickerDialog].
  ///
  /// The dialog's header displays the currently selected date range.
  ///
  /// The [TextStyle.color] of [rangePickerHeaderHeadlineStyle] is not used,
  /// [rangePickerHeaderForegroundColor] is used instead.
  final TextStyle? rangePickerHeaderHeadlineStyle;

  /// Overrides the default text style used for the help text of the
  /// header of a full screen [DateRangePickerDialog].
  ///
  /// The help text (also referred to as "supporting text" in the Material
  /// spec) is usually a prompt to the user at the top of the header
  /// (i.e. 'Select date').
  ///
  /// The [TextStyle.color] of the [rangePickerHeaderHelpStyle] is not used,
  /// [rangePickerHeaderForegroundColor] is used instead.
  ///
  /// See also:
  ///   [DateRangePickerDialog.helpText], which specifies the help text.
  final TextStyle? rangePickerHeaderHelpStyle;

  /// Overrides the default background color used to paint days
  /// selected between the start and end dates in a
  /// [DateRangePickerDialog].
  final Color? rangeSelectionBackgroundColor;

  /// Overrides the default highlight color that's typically used to
  /// indicate that a date in the selected range of a
  /// [DateRangePickerDialog] is focused, hovered, or pressed.
  final WidgetStateProperty<Color?>? rangeSelectionOverlayColor;

  /// Overrides the default color used to paint the horizontal divider
  /// below the header text when dialog is in portrait orientation
  /// and vertical divider when the dialog is in landscape orientation.
  final Color? dividerColor;

  /// Overrides the [InputDatePickerFormField]'s input decoration theme.
  /// If this is null, [ThemeData.inputDecorationTheme] is used instead.
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

  /// Overrides the default style of the cancel button of a [DatePickerDialog].
  final ButtonStyle? cancelButtonStyle;

  /// Overrides the default style of the confirm (OK) button of a [DatePickerDialog].
  final ButtonStyle? confirmButtonStyle;

  /// An optional [locale] argument can be used to set the locale for the date
  /// picker. It defaults to the ambient locale provided by [Localizations].
  final Locale? locale;

  /// Overrides the default text style used for the text of toggle mode button.
  ///
  /// If no [TextStyle.color] is given, [subHeaderForegroundColor] will be used.
  final TextStyle? toggleButtonTextStyle;

  /// Overrides the default color used for text labels and icons of sub header foreground.
  ///
  /// This is used in [TextStyle.color] property of [toggleButtonTextStyle] if no color is given.
  final Color? subHeaderForegroundColor;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  DatePickerThemeData copyWith({
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Color? headerBackgroundColor,
    Color? headerForegroundColor,
    TextStyle? headerHeadlineStyle,
    TextStyle? headerHelpStyle,
    TextStyle? weekdayStyle,
    TextStyle? dayStyle,
    WidgetStateProperty<Color?>? dayForegroundColor,
    WidgetStateProperty<Color?>? dayBackgroundColor,
    WidgetStateProperty<Color?>? dayOverlayColor,
    WidgetStateProperty<OutlinedBorder?>? dayShape,
    WidgetStateProperty<Color?>? todayForegroundColor,
    WidgetStateProperty<Color?>? todayBackgroundColor,
    BorderSide? todayBorder,
    TextStyle? yearStyle,
    WidgetStateProperty<Color?>? yearForegroundColor,
    WidgetStateProperty<Color?>? yearBackgroundColor,
    WidgetStateProperty<Color?>? yearOverlayColor,
    WidgetStateProperty<OutlinedBorder?>? yearShape,
    Color? rangePickerBackgroundColor,
    double? rangePickerElevation,
    Color? rangePickerShadowColor,
    Color? rangePickerSurfaceTintColor,
    ShapeBorder? rangePickerShape,
    Color? rangePickerHeaderBackgroundColor,
    Color? rangePickerHeaderForegroundColor,
    TextStyle? rangePickerHeaderHeadlineStyle,
    TextStyle? rangePickerHeaderHelpStyle,
    Color? rangeSelectionBackgroundColor,
    WidgetStateProperty<Color?>? rangeSelectionOverlayColor,
    Color? dividerColor,
    InputDecorationTheme? inputDecorationTheme,
    ButtonStyle? cancelButtonStyle,
    ButtonStyle? confirmButtonStyle,
    Locale? locale,
    TextStyle? toggleButtonTextStyle,
    Color? subHeaderForegroundColor,
  }) {
    return DatePickerThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shape: shape ?? this.shape,
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
      headerHeadlineStyle: headerHeadlineStyle ?? this.headerHeadlineStyle,
      headerHelpStyle: headerHelpStyle ?? this.headerHelpStyle,
      weekdayStyle: weekdayStyle ?? this.weekdayStyle,
      dayStyle: dayStyle ?? this.dayStyle,
      dayForegroundColor: dayForegroundColor ?? this.dayForegroundColor,
      dayBackgroundColor: dayBackgroundColor ?? this.dayBackgroundColor,
      dayOverlayColor: dayOverlayColor ?? this.dayOverlayColor,
      dayShape: dayShape ?? this.dayShape,
      todayForegroundColor: todayForegroundColor ?? this.todayForegroundColor,
      todayBackgroundColor: todayBackgroundColor ?? this.todayBackgroundColor,
      todayBorder: todayBorder ?? this.todayBorder,
      yearStyle: yearStyle ?? this.yearStyle,
      yearForegroundColor: yearForegroundColor ?? this.yearForegroundColor,
      yearBackgroundColor: yearBackgroundColor ?? this.yearBackgroundColor,
      yearOverlayColor: yearOverlayColor ?? this.yearOverlayColor,
      yearShape: yearShape ?? this.yearShape,
      rangePickerBackgroundColor: rangePickerBackgroundColor ?? this.rangePickerBackgroundColor,
      rangePickerElevation: rangePickerElevation ?? this.rangePickerElevation,
      rangePickerShadowColor: rangePickerShadowColor ?? this.rangePickerShadowColor,
      rangePickerSurfaceTintColor: rangePickerSurfaceTintColor ?? this.rangePickerSurfaceTintColor,
      rangePickerShape: rangePickerShape ?? this.rangePickerShape,
      rangePickerHeaderBackgroundColor:
          rangePickerHeaderBackgroundColor ?? this.rangePickerHeaderBackgroundColor,
      rangePickerHeaderForegroundColor:
          rangePickerHeaderForegroundColor ?? this.rangePickerHeaderForegroundColor,
      rangePickerHeaderHeadlineStyle:
          rangePickerHeaderHeadlineStyle ?? this.rangePickerHeaderHeadlineStyle,
      rangePickerHeaderHelpStyle: rangePickerHeaderHelpStyle ?? this.rangePickerHeaderHelpStyle,
      rangeSelectionBackgroundColor:
          rangeSelectionBackgroundColor ?? this.rangeSelectionBackgroundColor,
      rangeSelectionOverlayColor: rangeSelectionOverlayColor ?? this.rangeSelectionOverlayColor,
      dividerColor: dividerColor ?? this.dividerColor,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      cancelButtonStyle: cancelButtonStyle ?? this.cancelButtonStyle,
      confirmButtonStyle: confirmButtonStyle ?? this.confirmButtonStyle,
      locale: locale ?? this.locale,
      toggleButtonTextStyle: toggleButtonTextStyle ?? this.toggleButtonTextStyle,
      subHeaderForegroundColor: subHeaderForegroundColor ?? this.subHeaderForegroundColor,
    );
  }

  /// Linearly interpolates between two [DatePickerThemeData].
  static DatePickerThemeData lerp(DatePickerThemeData? a, DatePickerThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return DatePickerThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      headerBackgroundColor: Color.lerp(a?.headerBackgroundColor, b?.headerBackgroundColor, t),
      headerForegroundColor: Color.lerp(a?.headerForegroundColor, b?.headerForegroundColor, t),
      headerHeadlineStyle: TextStyle.lerp(a?.headerHeadlineStyle, b?.headerHeadlineStyle, t),
      headerHelpStyle: TextStyle.lerp(a?.headerHelpStyle, b?.headerHelpStyle, t),
      weekdayStyle: TextStyle.lerp(a?.weekdayStyle, b?.weekdayStyle, t),
      dayStyle: TextStyle.lerp(a?.dayStyle, b?.dayStyle, t),
      dayForegroundColor: WidgetStateProperty.lerp<Color?>(
        a?.dayForegroundColor,
        b?.dayForegroundColor,
        t,
        Color.lerp,
      ),
      dayBackgroundColor: WidgetStateProperty.lerp<Color?>(
        a?.dayBackgroundColor,
        b?.dayBackgroundColor,
        t,
        Color.lerp,
      ),
      dayOverlayColor: WidgetStateProperty.lerp<Color?>(
        a?.dayOverlayColor,
        b?.dayOverlayColor,
        t,
        Color.lerp,
      ),
      dayShape: WidgetStateProperty.lerp<OutlinedBorder?>(
        a?.dayShape,
        b?.dayShape,
        t,
        OutlinedBorder.lerp,
      ),
      todayForegroundColor: WidgetStateProperty.lerp<Color?>(
        a?.todayForegroundColor,
        b?.todayForegroundColor,
        t,
        Color.lerp,
      ),
      todayBackgroundColor: WidgetStateProperty.lerp<Color?>(
        a?.todayBackgroundColor,
        b?.todayBackgroundColor,
        t,
        Color.lerp,
      ),
      todayBorder: _lerpBorderSide(a?.todayBorder, b?.todayBorder, t),
      yearStyle: TextStyle.lerp(a?.yearStyle, b?.yearStyle, t),
      yearForegroundColor: WidgetStateProperty.lerp<Color?>(
        a?.yearForegroundColor,
        b?.yearForegroundColor,
        t,
        Color.lerp,
      ),
      yearBackgroundColor: WidgetStateProperty.lerp<Color?>(
        a?.yearBackgroundColor,
        b?.yearBackgroundColor,
        t,
        Color.lerp,
      ),
      yearOverlayColor: WidgetStateProperty.lerp<Color?>(
        a?.yearOverlayColor,
        b?.yearOverlayColor,
        t,
        Color.lerp,
      ),
      yearShape: WidgetStateProperty.lerp<OutlinedBorder?>(
        a?.yearShape,
        b?.yearShape,
        t,
        OutlinedBorder.lerp,
      ),
      rangePickerBackgroundColor: Color.lerp(
        a?.rangePickerBackgroundColor,
        b?.rangePickerBackgroundColor,
        t,
      ),
      rangePickerElevation: lerpDouble(a?.rangePickerElevation, b?.rangePickerElevation, t),
      rangePickerShadowColor: Color.lerp(a?.rangePickerShadowColor, b?.rangePickerShadowColor, t),
      rangePickerSurfaceTintColor: Color.lerp(
        a?.rangePickerSurfaceTintColor,
        b?.rangePickerSurfaceTintColor,
        t,
      ),
      rangePickerShape: ShapeBorder.lerp(a?.rangePickerShape, b?.rangePickerShape, t),
      rangePickerHeaderBackgroundColor: Color.lerp(
        a?.rangePickerHeaderBackgroundColor,
        b?.rangePickerHeaderBackgroundColor,
        t,
      ),
      rangePickerHeaderForegroundColor: Color.lerp(
        a?.rangePickerHeaderForegroundColor,
        b?.rangePickerHeaderForegroundColor,
        t,
      ),
      rangePickerHeaderHeadlineStyle: TextStyle.lerp(
        a?.rangePickerHeaderHeadlineStyle,
        b?.rangePickerHeaderHeadlineStyle,
        t,
      ),
      rangePickerHeaderHelpStyle: TextStyle.lerp(
        a?.rangePickerHeaderHelpStyle,
        b?.rangePickerHeaderHelpStyle,
        t,
      ),
      rangeSelectionBackgroundColor: Color.lerp(
        a?.rangeSelectionBackgroundColor,
        b?.rangeSelectionBackgroundColor,
        t,
      ),
      rangeSelectionOverlayColor: WidgetStateProperty.lerp<Color?>(
        a?.rangeSelectionOverlayColor,
        b?.rangeSelectionOverlayColor,
        t,
        Color.lerp,
      ),
      dividerColor: Color.lerp(a?.dividerColor, b?.dividerColor, t),
      inputDecorationTheme: t < 0.5 ? a?.inputDecorationTheme : b?.inputDecorationTheme,
      cancelButtonStyle: ButtonStyle.lerp(a?.cancelButtonStyle, b?.cancelButtonStyle, t),
      confirmButtonStyle: ButtonStyle.lerp(a?.confirmButtonStyle, b?.confirmButtonStyle, t),
      locale: t < 0.5 ? a?.locale : b?.locale,
      toggleButtonTextStyle: TextStyle.lerp(a?.toggleButtonTextStyle, b?.toggleButtonTextStyle, t),
      subHeaderForegroundColor: Color.lerp(
        a?.subHeaderForegroundColor,
        b?.subHeaderForegroundColor,
        t,
      ),
    );
  }

  static BorderSide? _lerpBorderSide(BorderSide? a, BorderSide? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return BorderSide.lerp(BorderSide(width: 0, color: b!.color.withAlpha(0)), b, t);
    }
    return BorderSide.lerp(a, BorderSide(width: 0, color: a.color.withAlpha(0)), t);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    elevation,
    shadowColor,
    surfaceTintColor,
    shape,
    headerBackgroundColor,
    headerForegroundColor,
    headerHeadlineStyle,
    headerHelpStyle,
    weekdayStyle,
    dayStyle,
    dayForegroundColor,
    dayBackgroundColor,
    dayOverlayColor,
    dayShape,
    todayForegroundColor,
    todayBackgroundColor,
    todayBorder,
    yearStyle,
    yearForegroundColor,
    yearBackgroundColor,
    yearOverlayColor,
    yearShape,
    rangePickerBackgroundColor,
    rangePickerElevation,
    rangePickerShadowColor,
    rangePickerSurfaceTintColor,
    rangePickerShape,
    rangePickerHeaderBackgroundColor,
    rangePickerHeaderForegroundColor,
    rangePickerHeaderHeadlineStyle,
    rangePickerHeaderHelpStyle,
    rangeSelectionBackgroundColor,
    rangeSelectionOverlayColor,
    dividerColor,
    inputDecorationTheme,
    cancelButtonStyle,
    confirmButtonStyle,
    locale,
    toggleButtonTextStyle,
    subHeaderForegroundColor,
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DatePickerThemeData &&
        other.backgroundColor == backgroundColor &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.surfaceTintColor == surfaceTintColor &&
        other.shape == shape &&
        other.headerBackgroundColor == headerBackgroundColor &&
        other.headerForegroundColor == headerForegroundColor &&
        other.headerHeadlineStyle == headerHeadlineStyle &&
        other.headerHelpStyle == headerHelpStyle &&
        other.weekdayStyle == weekdayStyle &&
        other.dayStyle == dayStyle &&
        other.dayForegroundColor == dayForegroundColor &&
        other.dayBackgroundColor == dayBackgroundColor &&
        other.dayOverlayColor == dayOverlayColor &&
        other.dayShape == dayShape &&
        other.todayForegroundColor == todayForegroundColor &&
        other.todayBackgroundColor == todayBackgroundColor &&
        other.todayBorder == todayBorder &&
        other.yearStyle == yearStyle &&
        other.yearForegroundColor == yearForegroundColor &&
        other.yearBackgroundColor == yearBackgroundColor &&
        other.yearOverlayColor == yearOverlayColor &&
        other.yearShape == yearShape &&
        other.rangePickerBackgroundColor == rangePickerBackgroundColor &&
        other.rangePickerElevation == rangePickerElevation &&
        other.rangePickerShadowColor == rangePickerShadowColor &&
        other.rangePickerSurfaceTintColor == rangePickerSurfaceTintColor &&
        other.rangePickerShape == rangePickerShape &&
        other.rangePickerHeaderBackgroundColor == rangePickerHeaderBackgroundColor &&
        other.rangePickerHeaderForegroundColor == rangePickerHeaderForegroundColor &&
        other.rangePickerHeaderHeadlineStyle == rangePickerHeaderHeadlineStyle &&
        other.rangePickerHeaderHelpStyle == rangePickerHeaderHelpStyle &&
        other.rangeSelectionBackgroundColor == rangeSelectionBackgroundColor &&
        other.rangeSelectionOverlayColor == rangeSelectionOverlayColor &&
        other.dividerColor == dividerColor &&
        other.inputDecorationTheme == inputDecorationTheme &&
        other.cancelButtonStyle == cancelButtonStyle &&
        other.confirmButtonStyle == confirmButtonStyle &&
        other.locale == locale &&
        other.toggleButtonTextStyle == toggleButtonTextStyle &&
        other.subHeaderForegroundColor == subHeaderForegroundColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
    properties.add(ColorProperty('surfaceTintColor', surfaceTintColor, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(
      ColorProperty('headerBackgroundColor', headerBackgroundColor, defaultValue: null),
    );
    properties.add(
      ColorProperty('headerForegroundColor', headerForegroundColor, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>(
        'headerHeadlineStyle',
        headerHeadlineStyle,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>('headerHelpStyle', headerHelpStyle, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>('weekDayStyle', weekdayStyle, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<TextStyle>('dayStyle', dayStyle, defaultValue: null));
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'dayForegroundColor',
        dayForegroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'dayBackgroundColor',
        dayBackgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'dayOverlayColor',
        dayOverlayColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<OutlinedBorder?>>(
        'dayShape',
        dayShape,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'todayForegroundColor',
        todayForegroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'todayBackgroundColor',
        todayBackgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<BorderSide?>('todayBorder', todayBorder, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<TextStyle>('yearStyle', yearStyle, defaultValue: null));
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'yearForegroundColor',
        yearForegroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'yearBackgroundColor',
        yearBackgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'yearOverlayColor',
        yearOverlayColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<OutlinedBorder?>>(
        'yearShape',
        yearShape,
        defaultValue: null,
      ),
    );
    properties.add(
      ColorProperty('rangePickerBackgroundColor', rangePickerBackgroundColor, defaultValue: null),
    );
    properties.add(
      DoubleProperty('rangePickerElevation', rangePickerElevation, defaultValue: null),
    );
    properties.add(
      ColorProperty('rangePickerShadowColor', rangePickerShadowColor, defaultValue: null),
    );
    properties.add(
      ColorProperty('rangePickerSurfaceTintColor', rangePickerSurfaceTintColor, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<ShapeBorder>('rangePickerShape', rangePickerShape, defaultValue: null),
    );
    properties.add(
      ColorProperty(
        'rangePickerHeaderBackgroundColor',
        rangePickerHeaderBackgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      ColorProperty(
        'rangePickerHeaderForegroundColor',
        rangePickerHeaderForegroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>(
        'rangePickerHeaderHeadlineStyle',
        rangePickerHeaderHeadlineStyle,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextStyle>(
        'rangePickerHeaderHelpStyle',
        rangePickerHeaderHelpStyle,
        defaultValue: null,
      ),
    );
    properties.add(
      ColorProperty(
        'rangeSelectionBackgroundColor',
        rangeSelectionBackgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'rangeSelectionOverlayColor',
        rangeSelectionOverlayColor,
        defaultValue: null,
      ),
    );
    properties.add(ColorProperty('dividerColor', dividerColor, defaultValue: null));
    properties.add(
      DiagnosticsProperty<InputDecorationThemeData>(
        'inputDecorationTheme',
        inputDecorationTheme,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<ButtonStyle>('cancelButtonStyle', cancelButtonStyle, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<ButtonStyle>(
        'confirmButtonStyle',
        confirmButtonStyle,
        defaultValue: null,
      ),
    );
    properties.add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(
      DiagnosticsProperty<TextStyle>(
        'toggleButtonTextStyle',
        toggleButtonTextStyle,
        defaultValue: null,
      ),
    );
    properties.add(
      ColorProperty('subHeaderForegroundColor', subHeaderForegroundColor, defaultValue: null),
    );
  }
}

/// An inherited widget that defines the visual properties for
/// [DatePickerDialog]s in this widget's subtree.
///
/// Values specified here are used for [DatePickerDialog] properties that are not
/// given an explicit non-null value.
class DatePickerTheme extends InheritedTheme {
  /// Creates a [DatePickerTheme] that controls visual parameters for
  /// descendent [DatePickerDialog]s.
  const DatePickerTheme({super.key, required this.data, required super.child});

  /// Specifies the visual properties used by descendant [DatePickerDialog]
  /// widgets.
  final DatePickerThemeData data;

  /// The [data] from the closest instance of this class that encloses the given
  /// context.
  ///
  /// If there is no [DatePickerTheme] in scope, this will return
  /// [ThemeData.datePickerTheme] from the ambient [Theme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DatePickerThemeData theme = DatePickerTheme.of(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], which returns null if it doesn't find a
  ///    [DatePickerTheme] ancestor.
  ///  * [defaults], which will return the default properties used when no
  ///    other [DatePickerTheme] has been provided.
  static DatePickerThemeData of(BuildContext context) {
    return maybeOf(context) ?? Theme.of(context).datePickerTheme;
  }

  /// The data from the closest instance of this class that encloses the given
  /// context, if any.
  ///
  /// Use this function if you want to allow situations where no
  /// [DatePickerTheme] is in scope. Prefer using [DatePickerTheme.of]
  /// in situations where a [DatePickerThemeData] is expected to be
  /// non-null.
  ///
  /// If there is no [DatePickerTheme] in scope, then this function will
  /// return null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DatePickerThemeData? theme = DatePickerTheme.maybeOf(context);
  /// if (theme == null) {
  ///   // Do something else instead.
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], which will return the data from [ThemeData.datePickerTheme] if
  ///    it doesn't find a [DatePickerTheme] ancestor, instead of returning null.
  ///  * [defaults], which will return the default properties used when no
  ///    other [DatePickerTheme] has been provided.
  static DatePickerThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DatePickerTheme>()?.data;
  }

  /// A DatePickerThemeData used as the default properties for date pickers.
  ///
  /// This is only used for properties not already specified in the ambient
  /// [DatePickerTheme.of].
  ///
  /// See also:
  ///
  ///  * [of], which will return the data from [ThemeData.datePickerTheme] if
  ///    it doesn't find a [DatePickerTheme] ancestor, instead of returning null.
  ///  * [maybeOf], which returns null if it doesn't find a
  ///    [DatePickerTheme] ancestor.
  static DatePickerThemeData defaults(BuildContext context) {
    return Theme.of(context).useMaterial3
        ? _DatePickerDefaultsM3(context)
        : _DatePickerDefaultsM2(context);
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DatePickerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DatePickerTheme oldWidget) => data != oldWidget.data;
}

// Hand coded defaults based on Material Design 2.
class _DatePickerDefaultsM2 extends DatePickerThemeData {
  _DatePickerDefaultsM2(this.context)
    : super(
        elevation: 24.0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))),
        dayShape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
        yearShape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        rangePickerElevation: 0.0,
        rangePickerShape: const RoundedRectangleBorder(),
      );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;
  late final bool _isDark = _colors.brightness == Brightness.dark;

  @override
  Color? get headerBackgroundColor => _isDark ? _colors.surface : _colors.primary;

  @override
  Color? get subHeaderForegroundColor => _colors.onSurface.withOpacity(0.60);

  @override
  TextStyle? get toggleButtonTextStyle =>
      _textTheme.titleSmall?.apply(color: subHeaderForegroundColor);

  @override
  ButtonStyle get cancelButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  ButtonStyle get confirmButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  Color? get headerForegroundColor => _isDark ? _colors.onSurface : _colors.onPrimary;

  @override
  TextStyle? get headerHeadlineStyle => _textTheme.headlineSmall;

  @override
  TextStyle? get headerHelpStyle => _textTheme.labelSmall;

  @override
  TextStyle? get weekdayStyle =>
      _textTheme.bodySmall?.apply(color: _colors.onSurface.withOpacity(0.60));

  @override
  TextStyle? get dayStyle => _textTheme.bodySmall;

  @override
  WidgetStateProperty<Color?>? get dayForegroundColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return _colors.onPrimary;
        } else if (states.contains(WidgetState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        return _colors.onSurface;
      });

  @override
  WidgetStateProperty<Color?>? get dayBackgroundColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return _colors.primary;
        }
        return null;
      });

  @override
  WidgetStateProperty<Color?>? get dayOverlayColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          if (states.contains(WidgetState.pressed)) {
            return _colors.onPrimary.withOpacity(0.38);
          }
          if (states.contains(WidgetState.hovered)) {
            return _colors.onPrimary.withOpacity(0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return _colors.onPrimary.withOpacity(0.12);
          }
        } else {
          if (states.contains(WidgetState.pressed)) {
            return _colors.onSurfaceVariant.withOpacity(0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return _colors.onSurfaceVariant.withOpacity(0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return _colors.onSurfaceVariant.withOpacity(0.12);
          }
        }
        return null;
      });

  @override
  WidgetStateProperty<Color?>? get todayForegroundColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return _colors.onPrimary;
        } else if (states.contains(WidgetState.disabled)) {
          return _colors.onSurface.withOpacity(0.38);
        }
        return _colors.primary;
      });

  @override
  WidgetStateProperty<Color?>? get todayBackgroundColor => dayBackgroundColor;

  @override
  BorderSide? get todayBorder => BorderSide(color: _colors.primary);

  @override
  TextStyle? get yearStyle => _textTheme.bodyLarge;

  @override
  Color? get rangePickerBackgroundColor => _colors.surface;

  @override
  Color? get rangePickerShadowColor => Colors.transparent;

  @override
  Color? get rangePickerSurfaceTintColor => Colors.transparent;

  @override
  Color? get rangePickerHeaderBackgroundColor => _isDark ? _colors.surface : _colors.primary;

  @override
  Color? get rangePickerHeaderForegroundColor => _isDark ? _colors.onSurface : _colors.onPrimary;

  @override
  TextStyle? get rangePickerHeaderHeadlineStyle => _textTheme.headlineSmall;

  @override
  TextStyle? get rangePickerHeaderHelpStyle => _textTheme.labelSmall;

  @override
  Color? get rangeSelectionBackgroundColor => _colors.primary.withOpacity(0.12);

  @override
  WidgetStateProperty<Color?>? get rangeSelectionOverlayColor =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          if (states.contains(WidgetState.pressed)) {
            return _colors.onPrimary.withOpacity(0.38);
          }
          if (states.contains(WidgetState.hovered)) {
            return _colors.onPrimary.withOpacity(0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return _colors.onPrimary.withOpacity(0.12);
          }
        } else {
          if (states.contains(WidgetState.pressed)) {
            return _colors.onSurfaceVariant.withOpacity(0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return _colors.onSurfaceVariant.withOpacity(0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return _colors.onSurfaceVariant.withOpacity(0.12);
          }
        }
        return null;
      });
}
// BEGIN GENERATED TOKEN PROPERTIES - DatePicker

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _DatePickerDefaultsM3 extends DatePickerThemeData {
  _DatePickerDefaultsM3(this.context)
    : super(
        elevation: 6.0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
        // TODO(tahatesser): Update this to use token when gen_defaults
        // supports `CircleBorder` for fully rounded corners.
        dayShape: const WidgetStatePropertyAll<OutlinedBorder>(CircleBorder()),
        yearShape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        rangePickerElevation: 0.0,
        rangePickerShape: const RoundedRectangleBorder(),
      );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get backgroundColor => _colors.surfaceContainerHigh;

  @override
  Color? get subHeaderForegroundColor => _colors.onSurface.withOpacity(0.60);

  @override
  TextStyle? get toggleButtonTextStyle => _textTheme.titleSmall?.apply(
    color: subHeaderForegroundColor,
  );

  @override
  ButtonStyle get cancelButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  ButtonStyle get confirmButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  Color? get headerBackgroundColor => Colors.transparent;

  @override
  Color? get headerForegroundColor => _colors.onSurfaceVariant;

  @override
  TextStyle? get headerHeadlineStyle => _textTheme.headlineLarge;

  @override
  TextStyle? get headerHelpStyle => _textTheme.labelLarge;

  @override
  TextStyle? get weekdayStyle => _textTheme.bodyLarge?.apply(
    color: _colors.onSurface,
  );

  @override
  TextStyle? get dayStyle => _textTheme.bodyLarge;

  @override
  WidgetStateProperty<Color?>? get dayForegroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.onPrimary;
      } else if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      return _colors.onSurface;
    });

  @override
  WidgetStateProperty<Color?>? get dayBackgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      return null;
    });

  @override
  WidgetStateProperty<Color?>? get dayOverlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onPrimary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onPrimary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onPrimary.withOpacity(0.1);
        }
      } else {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurfaceVariant.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSurfaceVariant.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSurfaceVariant.withOpacity(0.1);
        }
      }
      return null;
    });

  @override
  WidgetStateProperty<Color?>? get todayForegroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.onPrimary;
      } else if (states.contains(WidgetState.disabled)) {
        return _colors.primary.withOpacity(0.38);
      }
      return _colors.primary;
    });

  @override
  WidgetStateProperty<Color?>? get todayBackgroundColor => dayBackgroundColor;

  @override
  BorderSide? get todayBorder => BorderSide(color: _colors.primary);

  @override
  TextStyle? get yearStyle => _textTheme.bodyLarge;

  @override
  WidgetStateProperty<Color?>? get yearForegroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.onPrimary;
      } else if (states.contains(WidgetState.disabled)) {
        return _colors.onSurfaceVariant.withOpacity(0.38);
      }
      return _colors.onSurfaceVariant;
    });

  @override
  WidgetStateProperty<Color?>? get yearBackgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      return null;
    });

  @override
  WidgetStateProperty<Color?>? get yearOverlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onPrimary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onPrimary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onPrimary.withOpacity(0.1);
        }
      } else {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurfaceVariant.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSurfaceVariant.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSurfaceVariant.withOpacity(0.1);
        }
      }
      return null;
    });

    @override
    Color? get rangePickerShadowColor => Colors.transparent;

    @override
    Color? get rangePickerSurfaceTintColor => Colors.transparent;

    @override
    Color? get rangeSelectionBackgroundColor => _colors.secondaryContainer;

  @override
  WidgetStateProperty<Color?>? get rangeSelectionOverlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return _colors.onPrimaryContainer.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onPrimaryContainer.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onPrimaryContainer.withOpacity(0.1);
      }
      return null;
    });

  @override
  Color? get rangePickerHeaderBackgroundColor => Colors.transparent;

  @override
  Color? get rangePickerHeaderForegroundColor => _colors.onSurfaceVariant;

  @override
  TextStyle? get rangePickerHeaderHeadlineStyle => _textTheme.titleLarge;

  @override
  TextStyle? get rangePickerHeaderHelpStyle => _textTheme.titleSmall;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - DatePicker
