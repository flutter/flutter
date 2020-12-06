// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'text_theme.dart';
import 'theme.dart';

/// Defines default property values for descendant [AppBar] widgets.
///
/// Descendant widgets obtain the current [AppBarTheme] object using
/// `AppBarTheme.of(context)`. Instances of [AppBarTheme] can be customized
/// with [AppBarTheme.copyWith].
///
/// Typically an [AppBarTheme] is specified as part of the overall [Theme] with
/// [ThemeData.appBarTheme].
///
/// All [AppBarTheme] properties are `null` by default. When null, the [AppBar]
/// will use the values from [ThemeData] if they exist, otherwise it will
/// provide its own defaults.
///
/// See also:
///
///  * [ThemeData], which describes the overall theme information for the
///    application.
@immutable
class AppBarTheme with Diagnosticable {
  /// Creates a theme that can be used for [ThemeData.appBarTheme].
  const AppBarTheme({
    this.brightness,
    this.color,
    this.elevation,
    this.shadowColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.textTheme,
    this.centerTitle,
  });

  /// Default value for [AppBar.brightness].
  ///
  /// If null, [AppBar] uses [ThemeData.primaryColorBrightness].
  final Brightness brightness;

  /// Default value for [AppBar.backgroundColor].
  ///
  /// If null, [AppBar] uses [ThemeData.primaryColor].
  final Color color;

  /// Default value for [AppBar.elevation].
  ///
  /// If null, [AppBar] uses a default value of 4.0.
  final double elevation;

  /// Default value for [AppBar.shadowColor].
  ///
  /// If null, [AppBar] uses a default value of fully opaque black.
  final Color shadowColor;

  /// Default value for [AppBar.iconTheme].
  ///
  /// If null, [AppBar] uses [ThemeData.primaryIconTheme].
  final IconThemeData iconTheme;

  /// Default value for [AppBar.actionsIconTheme].
  ///
  /// If null, [AppBar] uses [ThemeData.primaryIconTheme].
  final IconThemeData actionsIconTheme;

  /// Default value for [AppBar.textTheme].
  ///
  /// If null, [AppBar] uses [ThemeData.primaryTextTheme].
  final TextTheme textTheme;

  /// Default value for [AppBar.centerTitle].
  ///
  /// If null, the value is adapted to current [TargetPlatform].
  final bool centerTitle;

  /// Creates a copy of this object with the given fields replaced with the
  /// new values.
  AppBarTheme copyWith({
    IconThemeData actionsIconTheme,
    Brightness brightness,
    Color color,
    double elevation,
    Color shadowColor,
    IconThemeData iconTheme,
    TextTheme textTheme,
    bool centerTitle,
  }) {
    return AppBarTheme(
      brightness: brightness ?? this.brightness,
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      iconTheme: iconTheme ?? this.iconTheme,
      actionsIconTheme: actionsIconTheme ?? this.actionsIconTheme,
      textTheme: textTheme ?? this.textTheme,
      centerTitle: centerTitle ?? this.centerTitle,
    );
  }

  /// The [ThemeData.appBarTheme] property of the ambient [Theme].
  static AppBarTheme of(BuildContext context) {
    return Theme.of(context).appBarTheme;
  }

  /// Linearly interpolate between two AppBar themes.
  ///
  /// The argument `t` must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static AppBarTheme lerp(AppBarTheme a, AppBarTheme b, double t) {
    assert(t != null);
    return AppBarTheme(
      brightness: t < 0.5 ? a?.brightness : b?.brightness,
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      iconTheme: IconThemeData.lerp(a?.iconTheme, b?.iconTheme, t),
      actionsIconTheme: IconThemeData.lerp(a?.actionsIconTheme, b?.actionsIconTheme, t),
      textTheme: TextTheme.lerp(a?.textTheme, b?.textTheme, t),
      centerTitle: t < 0.5 ? a?.centerTitle : b?.centerTitle,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      brightness,
      color,
      elevation,
      shadowColor,
      iconTheme,
      actionsIconTheme,
      textTheme,
      centerTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is AppBarTheme
        && other.brightness == brightness
        && other.color == color
        && other.elevation == elevation
        && other.shadowColor == shadowColor
        && other.iconTheme == iconTheme
        && other.actionsIconTheme == actionsIconTheme
        && other.textTheme == textTheme
        && other.centerTitle == centerTitle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Brightness>('brightness', brightness, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation, defaultValue: null));
    properties.add(ColorProperty('shadowColor', shadowColor, defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('actionsIconTheme', actionsIconTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<TextTheme>('textTheme', textTheme, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('centerTitle', centerTitle, defaultValue: null));
  }
}
