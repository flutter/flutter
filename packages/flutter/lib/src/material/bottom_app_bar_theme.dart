// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'bottom_app_bar.dart';
/// @docImport 'material.dart';
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Defines default property values for descendant [BottomAppBar] widgets.
///
/// Descendant widgets obtain the current [BottomAppBarThemeData] object using
/// [BottomAppBarTheme.of]. Instances of [BottomAppBarThemeData] can be
/// customized with [BottomAppBarThemeData.copyWith].
///
/// Typically a [BottomAppBarThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.bottomAppBarTheme].
///
/// All [BottomAppBarTheme] properties are `null` by default. When null, the
/// [BottomAppBar] constructor provides defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class BottomAppBarTheme extends InheritedTheme with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.bottomAppBarTheme].
  const BottomAppBarTheme({
    super.key,
    Color? color,
    double? elevation,
    NotchedShape? shape,
    double? height,
    Color? surfaceTintColor,
    Color? shadowColor,
    EdgeInsetsGeometry? padding,
    BottomAppBarThemeData? data,
    Widget? child,
  }) : assert(
         data == null ||
             (color ??
                     elevation ??
                     shape ??
                     height ??
                     surfaceTintColor ??
                     shadowColor ??
                     padding) ==
                 null,
       ),
       _color = color,
       _elevation = elevation,
       _shape = shape,
       _height = height,
       _surfaceTintColor = surfaceTintColor,
       _shadowColor = shadowColor,
       _padding = padding,
       _data = data,
       super(child: child ?? const SizedBox.shrink());

  final BottomAppBarThemeData? _data;
  final Color? _color;
  final double? _elevation;
  final NotchedShape? _shape;
  final double? _height;
  final Color? _surfaceTintColor;
  final Color? _shadowColor;
  final EdgeInsetsGeometry? _padding;

  /// Overrides the default value for [BottomAppBar.color].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.color] property in [data] instead.
  Color? get color => _data != null ? _data.color : _color;

  /// Overrides the default value for [BottomAppBar.elevation].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.elevation] property in [data] instead.
  double? get elevation => _data != null ? _data.elevation : _elevation;

  /// Overrides the default value for [BottomAppBar.shape].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.shape] property in [data] instead.
  NotchedShape? get shape => _data != null ? _data.shape : _shape;

  /// Overrides the default value for [BottomAppBar.height].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.height] property in [data] instead.
  double? get height => _data != null ? _data.height : _height;

  /// Overrides the default value for [BottomAppBar.surfaceTintColor].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.surfaceTintColor] property in [data] instead.
  ///
  /// If null, [BottomAppBar] will not display an overlay color.
  ///
  /// See [Material.surfaceTintColor] for more details.
  Color? get surfaceTintColor => _data != null ? _data.surfaceTintColor : _surfaceTintColor;

  /// Overrides the default value for [BottomAppBar.shadowColor].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.shadowColor] property in [data] instead.
  Color? get shadowColor => _data != null ? _data.shadowColor : _shadowColor;

  /// Overrides the default value for [BottomAppBar.padding].
  ///
  /// This property is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.padding] property in [data] instead.
  EdgeInsetsGeometry? get padding => _data != null ? _data.padding : _padding;

  /// The properties used for all descendant [BottomAppBar] widgets.
  BottomAppBarThemeData get data =>
      _data ??
      BottomAppBarThemeData(
        color: _color,
        elevation: _elevation,
        shape: _shape,
        height: _height,
        surfaceTintColor: _surfaceTintColor,
        shadowColor: _shadowColor,
        padding: _padding,
      );

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  ///
  /// This method is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.copyWith] method instead.
  BottomAppBarTheme copyWith({
    Color? color,
    double? elevation,
    NotchedShape? shape,
    double? height,
    Color? surfaceTintColor,
    Color? shadowColor,
    EdgeInsetsGeometry? padding,
  }) {
    return BottomAppBarTheme(
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      height: height ?? this.height,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shadowColor: shadowColor ?? this.shadowColor,
      padding: padding ?? this.padding,
    );
  }

  /// Returns the closest [BottomAppBarThemeData] instance given the build context.
  static BottomAppBarThemeData of(BuildContext context) {
    final BottomAppBarTheme? bottomAppBarTheme = context
        .dependOnInheritedWidgetOfExactType<BottomAppBarTheme>();
    return bottomAppBarTheme?.data ?? Theme.of(context).bottomAppBarTheme;
  }

  /// Linearly interpolate between two bottom app bar themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  ///
  /// This method is obsolete and will be deprecated in a future release:
  /// please use the [BottomAppBarThemeData.lerp] instead.
  static BottomAppBarTheme lerp(BottomAppBarTheme? a, BottomAppBarTheme? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return BottomAppBarTheme(
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: t < 0.5 ? a?.shape : b?.shape,
      height: lerpDouble(a?.height, b?.height, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
    );
  }

  @override
  bool updateShouldNotify(BottomAppBarTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return BottomAppBarTheme(data: data, child: child);
  }
}

/// Defines default property values for descendant [BottomAppBar] widgets.
///
/// Descendant widgets obtain the current [BottomAppBarThemeData] object using
/// [BottomAppBarTheme.of]. Instances of [BottomAppBarThemeData] can be
/// customized with [BottomAppBarThemeData.copyWith].
///
/// Typically a [BottomAppBarThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.bottomAppBarTheme].
///
/// All [BottomAppBarThemeData] properties are `null` by default. When null, the [BottomAppBar]
/// will use the values from [ThemeData] if they exist, otherwise it will
/// provide its own defaults. See the individual [BottomAppBar] properties for details.
///
/// See also:
///
///  * [BottomAppBar], which is the widget that this theme configures.
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class BottomAppBarThemeData with Diagnosticable {
  /// Creates a bottom app bar theme that can be used with [ThemeData.bottomAppBarTheme].
  const BottomAppBarThemeData({
    this.color,
    this.elevation,
    this.shape,
    this.height,
    this.surfaceTintColor,
    this.shadowColor,
    this.padding,
  });

  /// Overrides the default value for [BottomAppBar.color].
  final Color? color;

  /// Overrides the default value for [BottomAppBar.elevation].
  final double? elevation;

  /// Overrides the default value for [BottomAppBar.shape].
  final NotchedShape? shape;

  /// Overrides the default value for [BottomAppBar.height].
  final double? height;

  /// Overrides the default value for [BottomAppBar.surfaceTintColor].
  ///
  /// If null, [BottomAppBar] will not display an overlay color.
  ///
  /// See [Material.surfaceTintColor] for more details.
  final Color? surfaceTintColor;

  /// Overrides the default value for [BottomAppBar.shadowColor].
  final Color? shadowColor;

  /// Overrides the default value for [BottomAppBar.padding].
  final EdgeInsetsGeometry? padding;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  BottomAppBarThemeData copyWith({
    Color? color,
    double? elevation,
    NotchedShape? shape,
    double? height,
    Color? surfaceTintColor,
    Color? shadowColor,
    EdgeInsetsGeometry? padding,
  }) {
    return BottomAppBarThemeData(
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      height: height ?? this.height,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shadowColor: shadowColor ?? this.shadowColor,
      padding: padding ?? this.padding,
    );
  }

  /// Linearly interpolate between two bottom app bar themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static BottomAppBarThemeData lerp(BottomAppBarThemeData? a, BottomAppBarThemeData? b, double t) {
    if (identical(a, b) && a != null) {
      return a;
    }
    return BottomAppBarThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: t < 0.5 ? a?.shape : b?.shape,
      height: lerpDouble(a?.height, b?.height, t),
      surfaceTintColor: Color.lerp(a?.surfaceTintColor, b?.surfaceTintColor, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
    );
  }

  @override
  int get hashCode =>
      Object.hash(color, elevation, shape, height, surfaceTintColor, shadowColor, padding);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is BottomAppBarThemeData &&
        other.color == color &&
        other.elevation == elevation &&
        other.shape == shape &&
        other.height == height &&
        other.surfaceTintColor == surfaceTintColor &&
        other.shadowColor == shadowColor &&
        other.padding == padding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<NotchedShape?>('shape', shape, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(ColorProperty('surfaceTintColor', surfaceTintColor, defaultValue: null));
    properties.add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>('padding', padding, defaultValue: null),
    );
  }
}
