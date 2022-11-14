// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

// Examples can assume:
// late BuildContext context;

/// Overrides the default properties values for descendant [Material] widgets.
///
/// Descendant widgets obtain the current [MaterialThemeData] object
/// using `MaterialTheme.of(context)`. Instances of [MaterialThemeData] can
/// be customized with [MaterialThemeData.copyWith].
///
/// Typically a [MaterialThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.materialTheme].
///
/// All [MaterialThemeData] properties are `null` by default.
/// When null, the [Material] will use the values from [ThemeData]
/// if they exist, otherwise it will provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class MaterialThemeData with Diagnosticable {
  /// Creates the set of color, style, and size properties used to configure [Material].
  const MaterialThemeData({
    this.color,
    this.shadowColor,
  });

  /// Overrides the default value for [Material.color].
  final Color? color;

  /// Overrides the default value for [Material.shadowColor].
  final Color? shadowColor;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  MaterialThemeData copyWith({
    Color? color,
    Color? shadowColor,
  }) {
    return MaterialThemeData(
      color: color ?? this.color,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  /// Linearly interpolate between two [Material] themes.
  static MaterialThemeData lerp(MaterialThemeData? a, MaterialThemeData? b, double t) {
    return MaterialThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
    );
  }

  @override
  int get hashCode => Object.hash(
    color,
    shadowColor,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MaterialThemeData
      && other.color == color
      && other.shadowColor == shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
  }
}

/// An inherited widget that overrides default parameters for [Material]s in
/// this widget's subtree.
///
/// Values specified here override the defaults for [Material] properties which
/// are not given an explicit non-null value.
class MaterialTheme extends InheritedTheme {
  /// Creates a theme that overrides the default color parameters for [Material]s
  /// in this widget's subtree.
  const MaterialTheme({
    super.key,
    required this.data,
    required super.child,
  }) : assert(data != null);

  /// Specifies the default color and size overrides for descendant [Material] widgets.
  final MaterialThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [MaterialTheme] widget, then
  /// [ThemeData.materialTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MaterialThemeData theme = MaterialTheme.of(context);
  /// ```
  static MaterialThemeData of(BuildContext context) {
    final MaterialTheme? materialTheme = context.dependOnInheritedWidgetOfExactType<MaterialTheme>();
    return materialTheme?.data ?? Theme.of(context).materialTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MaterialTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MaterialTheme oldWidget) => data != oldWidget.data;
}
