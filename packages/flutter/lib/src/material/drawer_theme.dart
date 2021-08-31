// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines default property values for descendant [Drawer] widgets.
///
/// Descendant widgets obtain the current [DrawerThemeData] object
/// using `DrawerTheme.of(context)`. Instances of [DrawerThemeData] can be
/// customized with [DrawerThemeData.copyWith].
///
/// Typically a [DrawerThemeData] is specified as part of the
/// overall [Theme] with [ThemeData.drawerTheme].
///
/// All [DrawerThemeData] properties are `null` by default.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class DrawerThemeData with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.drawerTheme].
  const DrawerThemeData({
    this.backgroundColor,
    this.scrimColor,
    this.elevation,
    this.shape,
  });

  /// Color to be used for the [Drawer]'s background.
  final Color? backgroundColor;

  /// Color to be used for the [Drawer]'s scrim when the drawer is open.
  final Color? scrimColor;

  /// The z-coordinate to be used for the [Drawer]'s elevation.
  final double? elevation;

  /// Shape to be used for the [Drawer].
  final ShapeBorder? shape;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  DrawerThemeData copyWith({
    Color? backgroundColor,
    Color? scrimColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    return DrawerThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      scrimColor: scrimColor ?? this.scrimColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
    );
  }

  /// Linearly interpolate between two drawer themes.
  ///
  /// If both arguments are null then null is returned.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static DrawerThemeData? lerp(DrawerThemeData? a, DrawerThemeData? b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    return DrawerThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      scrimColor: Color.lerp(a?.scrimColor, b?.scrimColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      scrimColor,
      elevation,
      shape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is DrawerThemeData
        && other.backgroundColor == backgroundColor
        && other.scrimColor == scrimColor
        && other.elevation == elevation
        && other.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(ColorProperty('scrimColor', scrimColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

/// An inherited widget that defines visual properties for [Drawer]s in this
/// widget's subtree.
///
/// Values specified here are used for [Drawer] properties that are not
/// given an explicit non-null value.
class DrawerTheme extends InheritedTheme {
  /// Creates a drawe theme that controls the [DrawerThemeData] properties for a
  /// [Drawer].
  ///
  /// The data argument must not be null.
  const DrawerTheme({
    Key? key,
    required this.data,
    required Widget child,
  }) : assert(data != null), super(key: key, child: child);

  /// Specifies the background color, scrim color, elevation, and shape for
  /// descendant [Drawer] widgets.
  final DrawerThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [DrawerTheme] widget, then
  /// [ThemeData.drawerTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// DrawerTheme theme = DrawerTheme.of(context);
  /// ```
  static DrawerThemeData of(BuildContext context) {
    final DrawerTheme? drawerTheme = context.dependOnInheritedWidgetOfExactType<DrawerTheme>();
    return drawerTheme?.data ?? Theme.of(context).drawerTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return DrawerTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(DrawerTheme oldWidget) => data != oldWidget.data;
}
