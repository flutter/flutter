// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'data_table.dart';
/// @docImport 'divider.dart';
/// @docImport 'list_tile.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// Defines the visual properties of [Divider], [VerticalDivider], dividers
/// between [ListTile]s, and dividers between rows in [DataTable]s.
///
/// Descendant widgets obtain the current [DividerThemeData] object using
/// `DividerTheme.of(context)`. Instances of [DividerThemeData]
/// can be customized with [DividerThemeData.copyWith].
///
/// Typically a [DividerThemeData] is specified as part of the overall
/// [Theme] with [ThemeData.dividerTheme].
///
/// All [DividerThemeData] properties are `null` by default. When null,
/// the widgets will provide their own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class DividerThemeData with Diagnosticable {
  /// Creates a theme that can be used for [DividerTheme] or
  /// [ThemeData.dividerTheme].
  const DividerThemeData({this.color, this.space, this.thickness, this.indent, this.endIndent});

  /// The color of [Divider]s and [VerticalDivider]s, also
  /// used between [ListTile]s, between rows in [DataTable]s, and so forth.
  final Color? color;

  /// The [Divider]'s height or the [VerticalDivider]'s width.
  ///
  /// This represents the amount of horizontal or vertical space the divider
  /// takes up.
  final double? space;

  /// The thickness of the line drawn within the divider.
  final double? thickness;

  /// The amount of empty space at the leading edge of [Divider] or top edge of
  /// [VerticalDivider].
  final double? indent;

  /// The amount of empty space at the trailing edge of [Divider] or bottom edge
  /// of [VerticalDivider].
  final double? endIndent;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  DividerThemeData copyWith({
    Color? color,
    double? space,
    double? thickness,
    double? indent,
    double? endIndent,
  }) {
    return DividerThemeData(
      color: color ?? this.color,
      space: space ?? this.space,
      thickness: thickness ?? this.thickness,
      indent: indent ?? this.indent,
      endIndent: endIndent ?? this.endIndent,
    );
  }

  /// Linearly interpolate between two Divider themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DividerThemeData lerp(DividerThemeData? a, DividerThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return DividerThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      space: lerpDouble(a?.space, b?.space, t),
      thickness: lerpDouble(a?.thickness, b?.thickness, t),
      indent: lerpDouble(a?.indent, b?.indent, t),
      endIndent: lerpDouble(a?.endIndent, b?.endIndent, t),
    );
  }

  @override
  int get hashCode => Object.hash(color, space, thickness, indent, endIndent);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DividerThemeData &&
        other.color == color &&
        other.space == space &&
        other.thickness == thickness &&
        other.indent == indent &&
        other.endIndent == endIndent;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DoubleProperty('space', space, defaultValue: null));
    properties.add(DoubleProperty('thickness', thickness, defaultValue: null));
    properties.add(DoubleProperty('indent', indent, defaultValue: null));
    properties.add(DoubleProperty('endIndent', endIndent, defaultValue: null));
  }
}

/// An inherited widget that defines the configuration for
/// [Divider]s, [VerticalDivider]s, dividers between [ListTile]s, and dividers
/// between rows in [DataTable]s in this widget's subtree.
class DividerTheme extends InheritedTheme<DividerThemeData, Object?> {
  /// Creates a divider theme that controls the configurations for
  /// [Divider]s, [VerticalDivider]s, dividers between [ListTile]s, and dividers
  /// between rows in [DataTable]s in its widget subtree.
  const DividerTheme({super.key, required this.data, required super.child});

  /// The properties for descendant [Divider]s, [VerticalDivider]s, dividers
  /// between [ListTile]s, and dividers between rows in [DataTable]s.
  final DividerThemeData data;

  /// The closest instance of this class's [data] value that encloses the given
  /// context.
  ///
  /// If there is no ancestor, it returns [ThemeData.dividerTheme]. Applications
  /// can assume that the returned value will not be null.
  ///
  /// For specific theme properties, consider using [selectOf],
  /// which will only rebuild widget when the selected property changes:
  /// ```dart
  /// final Color? color = DividerTheme.select(
  ///   context,
  ///   (DividerThemeData data) => data.color,
  /// );
  /// ```
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DividerThemeData theme = DividerTheme.of(context);
  /// ```
  static DividerThemeData of(BuildContext context) {
    final DividerTheme? dividerTheme = context.dependOnInheritedWidgetOfExactType<DividerTheme>();
    return dividerTheme?.data ?? Theme.of(context).dividerTheme;
  }

  /// Evaluates [ThemeSelector.selectFrom] using [data] provided by the
  /// nearest ancestor [DividerTheme] widget, and returns the result.
  ///
  /// When this value changes, a notification is sent to the [context]
  /// to trigger an update.
  static T selectOf<T>(BuildContext context, T Function(DividerThemeData) selector) {
    final ThemeSelector<DividerThemeData, T> themeSelector =
        ThemeSelector<DividerThemeData, T>.from(selector);
    final DividerThemeData theme =
        InheritedModel.inheritFrom<DividerTheme>(context, aspect: themeSelector)!.data;
    return themeSelector.selectFrom(theme);
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DividerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DividerTheme oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    DividerTheme oldWidget,
    Set<ThemeSelector<DividerThemeData, Object?>> dependencies,
  ) {
    for (final ThemeSelector<DividerThemeData, Object?> selector in dependencies) {
      final Object? oldValue = selector.selectFrom(oldWidget.data);
      final Object? newValue = selector.selectFrom(data);
      if (oldValue != newValue) {
        return true;
      }
    }
    return false;
  }
}
