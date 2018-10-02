// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme_data.dart';

/// A set of twelve colors based on the
/// [Material spec](https://material.io/design/color/the-color-system.html)
/// that can be used to configure the color properties of most components.
///
/// The [Theme] has a color scheme, [ThemeData.colorScheme], which is constructed
/// with [ColorScheme.fromSwatch].
@immutable
class ColorScheme extends Diagnosticable {
  const ColorScheme({
    @required this.primary,
    @required this.primaryVariant,
    @required this.secondary,
    @required this.secondaryVariant,
    @required this.surface,
    @required this.background,
    @required this.error,
    @required this.onPrimary,
    @required this.onSecondary,
    @required this.onSurface,
    @required this.onBackground,
    @required this.onError,
    @required this.brightness,
  }) : assert(primary != null),
       assert(primaryVariant != null),
       assert(secondary != null),
       assert(secondaryVariant != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null);

  const ColorScheme.light({
    this.primary = const Color(0xff6200ee),
    this.primaryVariant = const Color(0xff3700b3),
    this.secondary = const Color(0xff03dac6),
    this.secondaryVariant = const Color(0xff018786),
    this.surface = Colors.white,
    this.background = Colors.white,
    this.error = const Color(0xffb00020),
    this.onPrimary = Colors.white,
    this.onSecondary = Colors.black,
    this.onSurface = Colors.black,
    this.onBackground = Colors.black,
    this.onError = Colors.white,
    this.brightness = Brightness.light,
  }) : assert(primary != null),
       assert(primaryVariant != null),
       assert(secondary != null),
       assert(secondaryVariant != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null);

  const ColorScheme.dark({
    this.primary = const Color(0xffbb86fc),
    this.primaryVariant = const Color(0xff4b01d0),
    this.secondary = const Color(0xff03dac6),
    this.secondaryVariant = const Color(0xff03dac6),
    this.surface = Colors.black,
    this.background = Colors.black,
    this.error = const Color(0xffb00020),
    this.onPrimary = Colors.black,
    this.onSecondary = Colors.black,
    this.onSurface = Colors.white,
    this.onBackground = Colors.white,
    this.onError = Colors.black,
    this.brightness = Brightness.dark,
  }) : assert(primary != null),
       assert(primaryVariant != null),
       assert(secondary != null),
       assert(secondaryVariant != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null);

  factory ColorScheme.fromSwatch({
    MaterialColor primarySwatch = Colors.blue,
    Color primaryColorDark,
    Color accentColor,
    Color cardColor,
    Color backgroundColor,
    Color errorColor,
    Brightness brightness = Brightness.light,
  }) {
    assert(primarySwatch != null);
    assert(brightness != null);

    final bool isDark = brightness == Brightness.dark;
    final bool primaryIsDark = _brightnessFor(primarySwatch) == Brightness.dark;
    final Color secondary = accentColor ?? (isDark ? Colors.tealAccent[200] : primarySwatch);
    final bool secondaryIsDark = _brightnessFor(secondary) == Brightness.dark;

    return ColorScheme(
      primary: primarySwatch,
      primaryVariant: primaryColorDark ?? (isDark ? Colors.black : primarySwatch[700]),
      secondary: secondary,
      secondaryVariant: isDark ? Colors.tealAccent[700] : primarySwatch[700],
      surface: cardColor ?? (isDark ? Colors.grey[800] : Colors.white),
      background: backgroundColor ?? (isDark ? Colors.grey[700] : primarySwatch[200]),
      error: errorColor ?? Colors.red[700],
      onPrimary: primaryIsDark ? Colors.white : Colors.black,
      onSecondary: secondaryIsDark ? Colors.white : Colors.black,
      onSurface: isDark ? Colors.white : Colors.black,
      onBackground: primaryIsDark ? Colors.white : Colors.black,
      onError: isDark ? Colors.black : Colors.white,
      brightness: brightness,
    );
  }

  static Brightness _brightnessFor(Color color) => ThemeData.estimateBrightnessForColor(color);

  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color background;
  final Color error;
  final Color surface;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onError;
  final Color onBackground;
  final Brightness brightness;

  ColorScheme copyWith({
    Color primary,
    Color primaryVariant,
    Color secondary,
    Color secondaryVariant,
    Color surface,
    Color background,
    Color error,
    Color onPrimary,
    Color onSecondary,
    Color onSurface,
    Color onBackground,
    Color onError,
    Brightness brightness,
  }) {
    return ColorScheme(
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondary: secondary ?? this.secondary,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
      brightness: brightness ?? this.brightness,
    );
  }

  static ColorScheme lerp(ColorScheme a, ColorScheme b, double t) {
    return ColorScheme(
      primary: Color.lerp(a.primary, b.primary, t),
      primaryVariant: Color.lerp(a.primaryVariant, b.primaryVariant, t),
      secondary: Color.lerp(a.secondary, b.secondary, t),
      secondaryVariant: Color.lerp(a.secondaryVariant, b.secondaryVariant, t),
      surface: Color.lerp(a.surface, b.surface, t),
      background: Color.lerp(a.background, b.background, t),
      error: Color.lerp(a.error, b.error, t),
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t),
      onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t),
      onSurface: Color.lerp(a.onSurface, b.onSurface, t),
      onBackground: Color.lerp(a.onBackground, b.onBackground, t),
      onError: Color.lerp(a.onError, b.onError, t),
      brightness: t < 0.5 ? a.brightness : b.brightness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final ColorScheme otherScheme = other;
    return otherScheme.primary == primary
        && otherScheme.primaryVariant == primaryVariant
        && otherScheme.secondary == secondary
        && otherScheme.secondaryVariant == secondaryVariant
        && otherScheme.surface == surface
        && otherScheme.background == background
        && otherScheme.error == error
        && otherScheme.onPrimary == onPrimary
        && otherScheme.onSecondary == onSecondary
        && otherScheme.onSurface == onSurface
        && otherScheme.onBackground == onBackground
        && otherScheme.onError == onError
        && otherScheme.brightness == brightness;
  }

  @override
  int get hashCode {
    return hashValues(
      primary,
      primaryVariant,
      secondary,
      secondaryVariant,
      surface,
      background,
      error,
      onPrimary,
      onSecondary,
      onSurface,
      onBackground,
      onError,
      brightness,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const ColorScheme defaultScheme = ColorScheme.light();
    properties.add(DiagnosticsProperty<Color>('primary', primary, defaultValue: defaultScheme.primary));
    properties.add(DiagnosticsProperty<Color>('primaryVariant', primaryVariant, defaultValue: defaultScheme.primaryVariant));
    properties.add(DiagnosticsProperty<Color>('secondary', secondary, defaultValue: defaultScheme.secondary));
    properties.add(DiagnosticsProperty<Color>('secondaryVariant', secondaryVariant, defaultValue: defaultScheme.secondaryVariant));
    properties.add(DiagnosticsProperty<Color>('surface', surface, defaultValue: defaultScheme.surface));
    properties.add(DiagnosticsProperty<Color>('background', background, defaultValue: defaultScheme.background));
    properties.add(DiagnosticsProperty<Color>('error', error, defaultValue: defaultScheme.error));
    properties.add(DiagnosticsProperty<Color>('onPrimary', onPrimary, defaultValue: defaultScheme.onPrimary));
    properties.add(DiagnosticsProperty<Color>('onSecondary', onSecondary, defaultValue: defaultScheme.onSecondary));
    properties.add(DiagnosticsProperty<Color>('onSurface', onSurface, defaultValue: defaultScheme.onSurface));
    properties.add(DiagnosticsProperty<Color>('onBackground', onBackground, defaultValue: defaultScheme.onBackground));
    properties.add(DiagnosticsProperty<Color>('onError', onError, defaultValue: defaultScheme.onError));
    properties.add(DiagnosticsProperty<Brightness>('brightness', brightness, defaultValue: defaultScheme.brightness));
  }
}
