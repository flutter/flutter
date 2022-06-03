// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'data_table.dart';
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
/// null, the [DataTable] will use the values from [ThemeData] if they exist,
/// otherwise it will provide its own defaults based on the overall [Theme]'s
/// textTheme and colorScheme. See the individual [DataTable] properties for
/// details.
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
    @Deprecated(
      'Use dataRowHeightStyle instead. '
      'This feature was deprecated after v3.1.0-0.0.pre.',
    )
    double? dataRowHeight,
    DataRowHeightStyle? dataRowHeightStyle,
    this.dataTextStyle,
    this.headingRowColor,
    this.headingRowHeight,
    this.headingTextStyle,
    this.horizontalMargin,
    this.columnSpacing,
    this.dividerThickness,
    this.checkboxHorizontalMargin,
  }) :
    _dataRowHeight = dataRowHeight,
    _dataRowHeightStyle = dataRowHeightStyle;

  /// {@macro flutter.material.dataTable.decoration}
  final Decoration? decoration;

  /// {@macro flutter.material.dataTable.dataRowColor}
  /// {@macro flutter.material.DataTable.dataRowColor}
  final MaterialStateProperty<Color?>? dataRowColor;

  final double? _dataRowHeight;
  final DataRowHeightStyle? _dataRowHeightStyle;

  /// {@macro flutter.material.dataTable.dataRowHeightStyle}
  DataRowHeightStyle? get dataRowHeightStyle
    => _dataRowHeightStyle ?? (_dataRowHeight != null ? DataRowHeightStyle.fixed(height: _dataRowHeight!) : null);

  /// {@macro flutter.material.dataTable.dataTextStyle}
  final TextStyle? dataTextStyle;

  /// {@macro flutter.material.dataTable.headingRowColor}
  /// {@macro flutter.material.DataTable.headingRowColor}
  final MaterialStateProperty<Color?>? headingRowColor;

  /// {@macro flutter.material.dataTable.headingRowHeight}
  final double? headingRowHeight;

  /// {@macro flutter.material.dataTable.headingTextStyle}
  final TextStyle? headingTextStyle;

  /// {@macro flutter.material.dataTable.horizontalMargin}
  final double? horizontalMargin;

  /// {@macro flutter.material.dataTable.columnSpacing}
  final double? columnSpacing;

  /// {@macro flutter.material.dataTable.dividerThickness}
  final double? dividerThickness;

  /// {@macro flutter.material.dataTable.checkboxHorizontalMargin}
  final double? checkboxHorizontalMargin;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  DataTableThemeData copyWith({
    Decoration? decoration,
    MaterialStateProperty<Color?>? dataRowColor,
    @Deprecated(
      'Use dataRowHeightStyle instead. '
      'This feature was deprecated after v3.1.0-0.0.pre.',
    )
    double? dataRowHeight,
    DataRowHeightStyle? dataRowHeightStyle,
    TextStyle? dataTextStyle,
    MaterialStateProperty<Color?>? headingRowColor,
    double? headingRowHeight,
    TextStyle? headingTextStyle,
    double? horizontalMargin,
    double? columnSpacing,
    double? dividerThickness,
    double? checkboxHorizontalMargin,
  }) {
    return DataTableThemeData(
      decoration: decoration ?? this.decoration,
      dataRowColor: dataRowColor ?? this.dataRowColor,
      dataRowHeightStyle: dataRowHeightStyle ?? (dataRowHeight != null ? DataRowHeightStyle.fixed(height: dataRowHeight) : null) ?? this.dataRowHeightStyle,
      dataTextStyle: dataTextStyle ?? this.dataTextStyle,
      headingRowColor: headingRowColor ?? this.headingRowColor,
      headingRowHeight: headingRowHeight ?? this.headingRowHeight,
      headingTextStyle: headingTextStyle ?? this.headingTextStyle,
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      columnSpacing: columnSpacing ?? this.columnSpacing,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      checkboxHorizontalMargin: checkboxHorizontalMargin ?? this.checkboxHorizontalMargin,
    );
  }

  /// Linearly interpolate between two [DataTableThemeData]s.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DataTableThemeData lerp(DataTableThemeData a, DataTableThemeData b, double t) {
    assert(t != null);
    return DataTableThemeData(
      decoration: Decoration.lerp(a.decoration, b.decoration, t),
      dataRowColor: MaterialStateProperty.lerp<Color?>(a.dataRowColor, b.dataRowColor, t, Color.lerp),
      dataRowHeightStyle: _lerpDataRowHeightStyle(a.dataRowHeightStyle, b.dataRowHeightStyle, t),
      dataTextStyle: TextStyle.lerp(a.dataTextStyle, b.dataTextStyle, t),
      headingRowColor: MaterialStateProperty.lerp<Color?>(a.headingRowColor, b.headingRowColor, t, Color.lerp),
      headingRowHeight: lerpDouble(a.headingRowHeight, b.headingRowHeight, t),
      headingTextStyle: TextStyle.lerp(a.headingTextStyle, b.headingTextStyle, t),
      horizontalMargin: lerpDouble(a.horizontalMargin, b.horizontalMargin, t),
      columnSpacing: lerpDouble(a.columnSpacing, b.columnSpacing, t),
      dividerThickness: lerpDouble(a.dividerThickness, b.dividerThickness, t),
      checkboxHorizontalMargin: lerpDouble(a.checkboxHorizontalMargin, b.checkboxHorizontalMargin, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    decoration,
    dataRowColor,
    dataRowHeightStyle,
    dataTextStyle,
    headingRowColor,
    headingRowHeight,
    headingTextStyle,
    horizontalMargin,
    columnSpacing,
    dividerThickness,
    checkboxHorizontalMargin,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DataTableThemeData
      && other.decoration == decoration
      && other.dataRowColor == dataRowColor
      && other.dataRowHeightStyle == dataRowHeightStyle
      && other.dataTextStyle == dataTextStyle
      && other.headingRowColor == headingRowColor
      && other.headingRowHeight == headingRowHeight
      && other.headingTextStyle == headingTextStyle
      && other.horizontalMargin == horizontalMargin
      && other.columnSpacing == columnSpacing
      && other.dividerThickness == dividerThickness
      && other.checkboxHorizontalMargin == checkboxHorizontalMargin;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('dataRowColor', dataRowColor, defaultValue: null));
    properties.add(DiagnosticsProperty<DataRowHeightStyle>('dataRowHeightStyle', dataRowHeightStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('dataTextStyle', dataTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialStateProperty<Color?>>('headingRowColor', headingRowColor, defaultValue: null));
    properties.add(DoubleProperty('headingRowHeight', headingRowHeight, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('headingTextStyle', headingTextStyle, defaultValue: null));
    properties.add(DoubleProperty('horizontalMargin', horizontalMargin, defaultValue: null));
    properties.add(DoubleProperty('columnSpacing', columnSpacing, defaultValue: null));
    properties.add(DoubleProperty('dividerThickness', dividerThickness, defaultValue: null));
    properties.add(DoubleProperty('checkboxHorizontalMargin', checkboxHorizontalMargin, defaultValue: null));
  }

  /// Interpolate between two [DataRowHeightStyle] instances.
  static DataRowHeightStyle? _lerpDataRowHeightStyle(DataRowHeightStyle? a, DataRowHeightStyle? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    if (a?.fixedHeight != null || b?.fixedHeight != null) {
      return DataRowHeightStyle.fixed(height: lerpDouble(a?.fixedHeight, b?.fixedHeight, t) ?? 0.0);
    }
    return DataRowHeightStyle.auto(verticalPadding: lerpDouble(a?.verticalPadding, b?.verticalPadding, t) ?? 0.0);
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
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

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
    final DataTableTheme? dataTableTheme = context.dependOnInheritedWidgetOfExactType<DataTableTheme>();
    return dataTableTheme?.data ?? Theme.of(context).dataTableTheme;
  }

  @override
  bool updateShouldNotify(DataTableTheme oldWidget) => data != oldWidget.data;
}
