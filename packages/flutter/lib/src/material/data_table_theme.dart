// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material_state.dart';
import 'theme.dart';

/// Defines default property values for descendant [DataTable]
/// widgets.
///
/// Descendant widgets obtain the current [DataTableThemeData] object
/// using `DataTableTheme.of(context)`. Instances of
/// [DataTableThemeData] can be customized with
/// [DataTableThemeData.copyWith].
///
/// Typically a [DataTableThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.dataTableTheme].
///
/// All [DataTableThemeData] properties are `null` by default. When
/// null, the [DataTable]'s build method provides defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
  class DataTableThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.dataTableTheme].
  const DataTableThemeData({
    this.decoration,
    this.dataRowColor,
    this.dataRowHeight,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
  });

  /// The background and border decoration for the table.
  final Decoration decoration;

  /// The color for the data rows.
  ///
  /// The effective color can depend on the [MaterialState] state, if the
  /// row is selected, pressed, hovered, focused, disabled or enabled. The
  /// color is painted as an overlay to the row. To make sure that the row's
  /// [InkWell] is visible (when pressed, hovered and focused), it is
  /// recommended to use a translucent color.
  ///
  /// ```dart
  /// DataTable(
  ///   dataRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.selected))
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  final MaterialStateProperty<Color> dataRowColor;

  /// The height of each row (excluding the row that contains column headings).
  final double dataRowHeight;

  /// The text style for data rows.
  final TextStyle dataTextStyle;

  /// The color for the heading row.
  ///
  /// The effective color can depend on the [MaterialState] state, if the
  /// row is pressed, hovered, focused. The color is painted as an overlay
  /// to the row. To make sure that the row's [InkWell] is visible (when
  /// pressed, hovered and focused), it is recommended to use a translucent
  /// color.
  ///
  /// ```dart
  /// DataTable(
  ///   headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
  ///     if (states.contains(MaterialState.hovered))
  ///       return Theme.of(context).colorScheme.primary.withOpacity(0.08);
  ///     return null;  // Use the default value.
  ///   }),
  /// )
  /// ```
  ///
  /// See also:
  ///
  ///  * The Material Design specification for overlay colors and how they
  ///    match a component's state:
  ///    <https://material.io/design/interaction/states.html#anatomy>.
  final MaterialStateProperty<Color> headingRowColor;

  /// The height of the heading row.
  final double headingRowHeight;

  /// The text style for the heading row.
  final TextStyle headingTextStyle;

  /// The horizontal margin between the edges of the table and the content
  /// in the first and last cells of each row.
  ///
  /// When a checkbox is displayed, it is also the margin between the checkbox
  /// the content in the first data column.
  final double horizontalMargin;

  /// The horizontal margin between the contents of each data column.
  final double columnSpacing;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  DataTableThemeData copyWith({
    Decoration decoration,
    MaterialStateProperty<Color> dataRowColor,
    double dataRowHeight,
    TextStyle dataTextStyle,
    MaterialStateProperty<Color> headingRowColor,
    double headingRowHeight,
    TextStyle headingTextStyle,
    double horizontalMargin,
    double columnSpacing,
  }) {
    return DataTableThemeData(
      decoration: decoration ?? this.decoration,
      dataRowColor: dataRowColor ?? this.dataRowColor,
      dataRowHeight: dataRowHeight ?? this.dataRowHeight,
      dataTextStyle: dataTextStyle ?? this.dataTextStyle,
      headingRowColor: headingRowColor ?? this.headingRowColor,
      headingRowHeight: headingRowHeight ?? this.headingRowHeight,
      headingTextStyle: headingTextStyle ?? this.headingTextStyle,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      columnSpacing: columnSpacing ?? this.columnSpacing,
    );
  }

  /// Linearly interpolate between two [DataTableThemeData].
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DataTableThemeData lerp(DataTableThemeData a, DataTableThemeData b, double t) {
    assert(t != null);
    return DataTableThemeData(
      decoration: Decoration.lerp(a.decoration, b.decoration, t),
      dataRowColor: _lerpProperties(a.dataRowColor, b.dataRowColor, t, Color.lerp),
      dataRowHeight: lerpDouble(a.dataRowHeight, b.dataRowHeight, t),
      dataTextStyle: TextStyle.lerp(a.dataTextStyle, b.dataTextStyle, t),
      headingRowColor: _lerpProperties(a.headingRowColor, b.headingRowColor, t, Color.lerp),
      headingRowHeight: lerpDouble(a.headingRowHeight, b.headingRowHeight, t),
      headingTextStyle: TextStyle.lerp(a.headingTextStyle, b.headingTextStyle, t),
      horizontalMargin: lerpDouble(a.horizontalMargin, b.horizontalMargin, t),
      columnSpacing: lerpDouble(a.columnSpacing, b.columnSpacing, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      decoration,
      dataRowColor,
      dataRowHeight,
      dataTextStyle,
      headingRowColor,
      headingRowHeight,
      headingTextStyle,
      horizontalMargin,
      columnSpacing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is DataTableThemeData
        && other.decoration == decoration
        && other.dataRowColor == dataRowColor
        && other.dataRowHeight == dataRowHeight
        && other.dataTextStyle == dataTextStyle
        && other.headingRowColor == headingRowColor
        && other.headingRowHeight == headingRowHeight
        && other.headingTextStyle == headingTextStyle
        && other.horizontalMargin == horizontalMargin
        && other.columnSpacing == columnSpacing;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color>>('dataRowColor', dataRowColor, defaultValue: null));
    properties.add(DoubleProperty('dataRowHeight', dataRowHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('dataTextStyle', dataTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color>>('headingRowColor', headingRowColor, defaultValue: null));
    properties.add(DoubleProperty('headingRowHeight', headingRowHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('headingTextStyle', headingTextStyle, defaultValue: null));
    properties.add(DoubleProperty('horizontalMargin', horizontalMargin, defaultValue: null));
    properties.add(DoubleProperty('columnSpacing', columnSpacing, defaultValue: null));
  }

  static MaterialStateProperty<T> _lerpProperties<T>(MaterialStateProperty<T> a, MaterialStateProperty<T> b, double t, T Function(T, T, double) lerpFunction ) {
    // Avoid creating a _LerpProperties object for a common case.
    if (a == null && b == null)
      return null;
    return _LerpProperties<T>(a, b, t, lerpFunction);
  }
}

class _LerpProperties<T> implements MaterialStateProperty<T> {
  const _LerpProperties(this.a, this.b, this.t, this.lerpFunction);

  final MaterialStateProperty<T> a;
  final MaterialStateProperty<T> b;
  final double t;
  final T Function(T, T, double) lerpFunction;

  @override
  T resolve(Set<MaterialState> states) {
    final T resolvedA = a?.resolve(states);
    final T resolvedB = b?.resolve(states);
    return lerpFunction(resolvedA, resolvedB, t);
  }
}

/// Applies a data table theme to descendant [DataTable] widgets.
///
/// Descendant widgets obtain the current theme's [DataTableTheme] object using
/// [DataTableTheme.of]. When a widget uses [DataTableTheme.of], it is
/// automatically rebuilt if the theme later changes.
///
/// A data table theme can be specified as part of the overall Material
/// theme using [ThemeData.dataTableTheme].
///
/// See also:
///
///  * [DataTableThemeData], which describes the actual configuration
///    of a data table theme.
class DataTableTheme extends InheritedWidget {
  /// Constructs a data table theme that configures all descendant
  /// [DataTable] widgets.
  ///
  /// The [data] must not be null.
  const DataTableTheme({
    Key key,
    @required this.data,
    Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// The properties used for all descendant [DataTable] widgets.
  final DataTableThemeData data;

  /// Returns the configuration [data] from the closest
  /// [DataTableTheme] ancestor. If there is no ancestor, it returns
  /// [ThemeData.dataTableTheme]. Applications can assume that the
  /// returned value will not be null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DataTableThemeData theme = DataTableTheme.of(context);
  /// ```
  static DataTableThemeData of(BuildContext context) {
    final DataTableTheme dataTableTheme = context.dependOnInheritedWidgetOfExactType<DataTableTheme>();
    return dataTableTheme?.data ?? Theme.of(context).dataTableTheme;
  }

  @override
  bool updateShouldNotify(DataTableTheme oldWidget) => data != oldWidget.data;
}
