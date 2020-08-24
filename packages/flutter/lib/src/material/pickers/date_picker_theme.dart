// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../input_decorator.dart';
import '../theme.dart';

@immutable
/// TODO(darrenaustin): doc
class DatePickerThemeData with Diagnosticable {
  /// TODO(darrenaustin): doc
  const DatePickerThemeData({
    this.backgroundColor,
    this.headerDecoration,
    this.headerLandscapeDecoration,
    this.headerForegroundColor,
    this.headerDisabledForegroundColor,
    this.headerHelpTextStyle,
    this.headerTitleTextStyle,
    this.headerCompactTitleTextStyle,
    this.headerIconTheme,
    this.gridForegroundColor,
    this.gridDisabledForegroundColor,
    this.gridSelectedColor,
    this.gridSelectedForegroundColor,
    this.inputDecorationTheme,
    this.dialogShape
  });

  /// TODO(darrenaustin): doc
  final Color backgroundColor;

  /// TODO(darrenaustin): doc
  final Decoration headerDecoration;

  /// TODO(darrenaustin): doc
  final Decoration headerLandscapeDecoration;

  /// TODO(darrenaustin): doc
  final Color headerForegroundColor;

  /// TODO(darrenaustin): doc
  final Color headerDisabledForegroundColor;

  /// TODO(darrenaustin): doc
  final TextStyle headerHelpTextStyle;

  /// TODO(darrenaustin): doc
  final TextStyle headerTitleTextStyle;

  /// TODO(darrenaustin): doc
  final TextStyle headerCompactTitleTextStyle;

  /// TODO(darrenaustin): doc
  final IconThemeData headerIconTheme;

  /// TODO(darrenaustin): doc
  final Color gridForegroundColor;

  /// TODO(darrenaustin): doc
  final Color gridDisabledForegroundColor;

  /// TODO(darrenaustin): doc
  final Color gridSelectedColor;

  /// TODO(darrenaustin): doc
  final Color gridSelectedForegroundColor;

  /// TODO(darrenaustin): doc
  final InputDecorationTheme inputDecorationTheme;

  /// TODO(darrenaustin): doc
  final ShapeBorder dialogShape;

  /// TODO(darrenaustin): doc
  DatePickerThemeData copyWith({
    Color backgroundColor,
    Decoration headerDecoration,
    Decoration headerLandscapeDecoration,
    Color headerForegroundColor,
    Color headerDisabledForegroundColor,
    TextStyle headerHelpTextStyle,
    TextStyle headerTitleTextStyle,
    TextStyle headerCompactTitleTextStyle,
    IconThemeData headerIconTheme,
    Color gridForegroundColor,
    Color gridDisabledForegroundColor,
    Color gridSelectedColor,
    Color gridSelectedForegroundColor,
    InputDecorationTheme inputDecorationTheme,
    ShapeBorder dialogShape,
  }) {
    return DatePickerThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      headerDecoration: headerDecoration ?? this.headerDecoration,
      headerLandscapeDecoration: headerLandscapeDecoration ?? this.headerLandscapeDecoration,
      headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
      headerDisabledForegroundColor: headerDisabledForegroundColor ?? this.headerDisabledForegroundColor,
      headerHelpTextStyle: headerHelpTextStyle ?? this.headerHelpTextStyle,
      headerTitleTextStyle: headerTitleTextStyle ?? this.headerTitleTextStyle,
      headerCompactTitleTextStyle: headerCompactTitleTextStyle ?? this.headerCompactTitleTextStyle,
      headerIconTheme: headerIconTheme ?? this.headerIconTheme,
      gridForegroundColor: gridForegroundColor ?? this.gridForegroundColor,
      gridDisabledForegroundColor: gridDisabledForegroundColor ?? this.gridDisabledForegroundColor,
      gridSelectedColor: gridSelectedColor ?? this.gridSelectedColor,
      gridSelectedForegroundColor: gridSelectedForegroundColor ?? this.gridSelectedForegroundColor,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      dialogShape: dialogShape ?? this.dialogShape,
    );
  }

  /// TODO(darrenaustin): doc
  static DatePickerThemeData lerp(DatePickerThemeData a, DatePickerThemeData b, double t) {
    if (a == null && b == null)
      return null;
    assert(t != null);
    return DatePickerThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      headerDecoration: Decoration.lerp(a?.headerDecoration, b?.headerDecoration, t),
      headerLandscapeDecoration: Decoration.lerp(a?.headerLandscapeDecoration, b?.headerLandscapeDecoration, t),
      headerForegroundColor: Color.lerp(a?.headerForegroundColor, b?.headerForegroundColor, t),
      headerDisabledForegroundColor: Color.lerp(a?.headerDisabledForegroundColor, b?.headerDisabledForegroundColor, t),
      headerHelpTextStyle: TextStyle.lerp(a?.headerHelpTextStyle, b?.headerHelpTextStyle, t),
      headerTitleTextStyle: TextStyle.lerp(a?.headerTitleTextStyle, b?.headerTitleTextStyle, t),
      headerCompactTitleTextStyle: TextStyle.lerp(a?.headerCompactTitleTextStyle, b?.headerCompactTitleTextStyle, t),
      headerIconTheme: IconThemeData.lerp(a?.headerIconTheme, b?.headerIconTheme, t),
      gridForegroundColor: Color.lerp(a?.gridForegroundColor, b?.gridForegroundColor, t),
      gridDisabledForegroundColor: Color.lerp(a?.gridDisabledForegroundColor, b?.gridDisabledForegroundColor, t),
      gridSelectedColor: Color.lerp(a?.gridSelectedColor, b?.gridSelectedColor, t),
      gridSelectedForegroundColor: Color.lerp(a?.gridSelectedForegroundColor, b?.gridSelectedForegroundColor, t),
      inputDecorationTheme: t < 0.5 ? a.inputDecorationTheme : b.inputDecorationTheme,
      dialogShape: ShapeBorder.lerp(a?.dialogShape, b?.dialogShape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      headerDecoration,
      headerLandscapeDecoration,
      headerForegroundColor,
      headerDisabledForegroundColor,
      headerHelpTextStyle,
      headerTitleTextStyle,
      headerCompactTitleTextStyle,
      headerIconTheme,
      gridForegroundColor,
      gridDisabledForegroundColor,
      gridSelectedColor,
      gridSelectedForegroundColor,
      inputDecorationTheme,
      dialogShape,
    );
  }

  @override
  bool operator==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is DatePickerThemeData
        && other.backgroundColor == backgroundColor
        && other.headerDecoration == headerDecoration
        && other.headerLandscapeDecoration == headerLandscapeDecoration
        && other.headerForegroundColor == headerForegroundColor
        && other.headerDisabledForegroundColor == headerDisabledForegroundColor
        && other.headerHelpTextStyle == headerHelpTextStyle
        && other.headerCompactTitleTextStyle == headerCompactTitleTextStyle
        && other.headerTitleTextStyle == headerTitleTextStyle
        && other.gridForegroundColor == gridForegroundColor
        && other.gridDisabledForegroundColor == gridDisabledForegroundColor
        && other.gridSelectedColor == gridSelectedColor
        && other.gridSelectedForegroundColor == gridSelectedForegroundColor
        && other.inputDecorationTheme == inputDecorationTheme
        && other.dialogShape == dialogShape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('headerDecoration', headerDecoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('headerLandscapeDecoration', headerLandscapeDecoration, defaultValue: null));
    properties.add(ColorProperty('headerForegroundColor', headerForegroundColor, defaultValue: null));
    properties.add(ColorProperty('headerDisabledForegroundColor', headerDisabledForegroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('headerHelpTextStyle', headerHelpTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('headerTitleTextStyle', headerTitleTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('headerCompactTitleTextStyle', headerCompactTitleTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('headerIconTheme', headerIconTheme, defaultValue: null));
    properties.add(ColorProperty('gridForegroundColor', gridForegroundColor, defaultValue: null));
    properties.add(ColorProperty('gridDisabledForegroundColor', gridDisabledForegroundColor, defaultValue: null));
    properties.add(ColorProperty('gridSelectedColor', gridSelectedColor, defaultValue: null));
    properties.add(ColorProperty('gridSelectedForegroundColor', gridSelectedForegroundColor, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('dialogShape', dialogShape, defaultValue: null));
  }
}

/// TODO(darrenaustin): doc
class DatePickerTheme extends InheritedTheme {
  /// TODO(darrenaustin): doc
  const DatePickerTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// TODO(darrenaustin): doc
  final DatePickerThemeData data;

  static DatePickerThemeData of(BuildContext context) {
    final DatePickerTheme datePickerTheme = context.dependOnInheritedWidgetOfExactType<DatePickerTheme>();
    return datePickerTheme?.data ?? Theme.of(context).datePickerTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final DatePickerTheme ancestorTheme = context.findAncestorWidgetOfExactType<DatePickerTheme>();
    return identical(this, ancestorTheme) ? child : DatePickerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DatePickerTheme oldWidget) => data != oldWidget.data;
}
