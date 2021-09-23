// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
class ColorScheme with Diagnosticable {
  /// Create a ColorScheme instance.
  const ColorScheme({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.brightness,
    @Deprecated(
      'Use primary or primaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? primaryVariant,
    @Deprecated(
      'Use secondary or secondaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? secondaryVariant,
  }) : assert(primary != null),
       assert(secondary != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null),
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant;

  /// Create a ColorScheme based on a purple primary color that matches the
  /// [baseline Material color scheme](https://material.io/design/color/the-color-system.html#color-theme-creation).
  const ColorScheme.light({
    this.primary = const Color(0xff6200ee),
    this.secondary = const Color(0xff03dac6),
    this.surface = Colors.white,
    this.background = Colors.white,
    this.error = const Color(0xffb00020),
    this.onPrimary = Colors.white,
    this.onSecondary = Colors.black,
    this.onSurface = Colors.black,
    this.onBackground = Colors.black,
    this.onError = Colors.white,
    this.brightness = Brightness.light,
    @Deprecated(
      'Use primary or primaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? primaryVariant = const Color(0xff3700b3),
    @Deprecated(
      'Use secondary or secondaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? secondaryVariant = const Color(0xff018786),
  }) : assert(primary != null),
       assert(secondary != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null),
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant;

  /// Create the recommended dark color scheme that matches the
  /// [baseline Material color scheme](https://material.io/design/color/dark-theme.html#ui-application).
  const ColorScheme.dark({
    this.primary = const Color(0xffbb86fc),
    this.secondary = const Color(0xff03dac6),
    this.surface = const Color(0xff121212),
    this.background = const Color(0xff121212),
    this.error = const Color(0xffcf6679),
    this.onPrimary = Colors.black,
    this.onSecondary = Colors.black,
    this.onSurface = Colors.white,
    this.onBackground = Colors.white,
    this.onError = Colors.black,
    this.brightness = Brightness.dark,
    @Deprecated(
      'Use primary or primaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? primaryVariant = const Color(0xff3700B3),
    @Deprecated(
      'Use secondary or secondaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? secondaryVariant = const Color(0xff03dac6),
  }) : assert(primary != null),
       assert(secondary != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null),
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant;

  /// Create a high contrast ColorScheme based on a purple primary color that
  /// matches the [baseline Material color scheme](https://material.io/design/color/the-color-system.html#color-theme-creation).
  const ColorScheme.highContrastLight({
    this.primary = const Color(0xff0000ba),
    this.secondary = const Color(0xff66fff9),
    this.surface = Colors.white,
    this.background = Colors.white,
    this.error = const Color(0xff790000),
    this.onPrimary = Colors.white,
    this.onSecondary = Colors.black,
    this.onSurface = Colors.black,
    this.onBackground = Colors.black,
    this.onError = Colors.white,
    this.brightness = Brightness.light,
    @Deprecated(
      'Use primary or primaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? primaryVariant = const Color(0xff000088),
    @Deprecated(
      'Use secondary or secondaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? secondaryVariant = const Color(0xff018786),
  }) : assert(primary != null),
       assert(secondary != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null),
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant;

  /// Create a high contrast ColorScheme based on the dark
  /// [baseline Material color scheme](https://material.io/design/color/dark-theme.html#ui-application).
  const ColorScheme.highContrastDark({
    this.primary = const Color(0xffefb7ff),
    this.secondary = const Color(0xff66fff9),
    this.surface = const Color(0xff121212),
    this.background = const Color(0xff121212),
    this.error = const Color(0xff9b374d),
    this.onPrimary = Colors.black,
    this.onSecondary = Colors.black,
    this.onSurface = Colors.white,
    this.onBackground = Colors.white,
    this.onError = Colors.black,
    this.brightness = Brightness.dark,
    @Deprecated(
      'Use primary or primaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? primaryVariant = const Color(0xffbe9eff),
    @Deprecated(
      'Use secondary or secondaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? secondaryVariant = const Color(0xff66fff9),
  }) : assert(primary != null),
       assert(secondary != null),
       assert(surface != null),
       assert(background != null),
       assert(error != null),
       assert(onPrimary != null),
       assert(onSecondary != null),
       assert(onSurface != null),
       assert(onBackground != null),
       assert(onError != null),
       assert(brightness != null),
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant;

  /// Create a color scheme from a [MaterialColor] swatch.
  ///
  /// This constructor is used by [ThemeData] to create its default
  /// color scheme.
  factory ColorScheme.fromSwatch({
    MaterialColor primarySwatch = Colors.blue,
    Color? primaryColorDark,
    Color? accentColor,
    Color? cardColor,
    Color? backgroundColor,
    Color? errorColor,
    Brightness brightness = Brightness.light,
  }) {
    assert(primarySwatch != null);
    assert(brightness != null);

    final bool isDark = brightness == Brightness.dark;
    final bool primaryIsDark = _brightnessFor(primarySwatch) == Brightness.dark;
    final Color secondary = accentColor ?? (isDark ? Colors.tealAccent[200]! : primarySwatch);
    final bool secondaryIsDark = _brightnessFor(secondary) == Brightness.dark;

    return ColorScheme(
      primary: primarySwatch,
      primaryVariant: primaryColorDark ?? (isDark ? Colors.black : primarySwatch[700]!),
      secondary: secondary,
      secondaryVariant: isDark ? Colors.tealAccent[700]! : primarySwatch[700]!,
      surface: cardColor ?? (isDark ? Colors.grey[800]! : Colors.white),
      background: backgroundColor ?? (isDark ? Colors.grey[700]! : primarySwatch[200]!),
      error: errorColor ?? Colors.red[700]!,
      onPrimary: primaryIsDark ? Colors.white : Colors.black,
      onSecondary: secondaryIsDark ? Colors.white : Colors.black,
      onSurface: isDark ? Colors.white : Colors.black,
      onBackground: primaryIsDark ? Colors.white : Colors.black,
      onError: isDark ? Colors.black : Colors.white,
      brightness: brightness,
    );
  }

  static Brightness _brightnessFor(Color color) => ThemeData.estimateBrightnessForColor(color);

  /// The color displayed most frequently across your app’s screens and components.
  final Color primary;

  /// An accent color that, when used sparingly, calls attention to parts
  /// of your app.
  final Color secondary;

  /// The background color for widgets like [Card].
  final Color surface;

  /// A color that typically appears behind scrollable content.
  final Color background;

  /// The color to use for input validation errors, e.g. for
  /// [InputDecoration.errorText].
  final Color error;

  /// A color that's clearly legible when drawn on [primary].
  ///
  /// To ensure that an app is accessible, a contrast ratio of 4.5:1 for [primary]
  /// and [onPrimary] is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onPrimary;

  /// A color that's clearly legible when drawn on [secondary].
  ///
  /// To ensure that an app is accessible, a contrast ratio of 4.5:1 for [secondary]
  /// and [onSecondary] is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onSecondary;

  /// A color that's clearly legible when drawn on [surface].
  ///
  /// To ensure that an app is accessible, a contrast ratio of 4.5:1 for [surface]
  /// and [onSurface] is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onSurface;

  /// A color that's clearly legible when drawn on [background].
  ///
  /// To ensure that an app is accessible, a contrast ratio of 4.5:1 for [background]
  /// and [onBackground] is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onBackground;

  /// A color that's clearly legible when drawn on [error].
  ///
  /// To ensure that an app is accessible, a contrast ratio of 4.5:1 for [error]
  /// and [onError] is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onError;

  /// The overall brightness of this color scheme.
  final Brightness brightness;

  final Color? _primaryVariant;
  /// A darker version of the primary color.
  @Deprecated(
    'Use primary or primaryContainer instead. '
    'This feature was deprecated after v2.6.0-0.0.pre.'
  )
  Color get primaryVariant => _primaryVariant ?? primary;

  final Color? _secondaryVariant;
  /// A darker version of the secondary color.
  @Deprecated(
    'Use secondary or secondaryContainer instead. '
    'This feature was deprecated after v2.6.0-0.0.pre.'
  )
  Color get secondaryVariant => _secondaryVariant ?? secondary;

  /// Creates a copy of this color scheme with the given fields
  /// replaced by the non-null parameter values.
  ColorScheme copyWith({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? error,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onBackground,
    Color? onError,
    Brightness? brightness,
    @Deprecated(
      'Use primary or primaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? primaryVariant,
    @Deprecated(
      'Use secondary or secondaryContainer instead. '
      'This feature was deprecated after v2.6.0-0.0.pre.'
    )
    Color? secondaryVariant,
  }) {
    return ColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
      brightness: brightness ?? this.brightness,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
    );
  }

  /// Linearly interpolate between two [ColorScheme] objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static ColorScheme lerp(ColorScheme a, ColorScheme b, double t) {
    return ColorScheme(
      primary: Color.lerp(a.primary, b.primary, t)!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      error: Color.lerp(a.error, b.error, t)!,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t)!,
      onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
      onBackground: Color.lerp(a.onBackground, b.onBackground, t)!,
      onError: Color.lerp(a.onError, b.onError, t)!,
      brightness: t < 0.5 ? a.brightness : b.brightness,
      primaryVariant: Color.lerp(a.primaryVariant, b.primaryVariant, t),
      secondaryVariant: Color.lerp(a.secondaryVariant, b.secondaryVariant, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ColorScheme
        && other.primary == primary
        && other.secondary == secondary
        && other.surface == surface
        && other.background == background
        && other.error == error
        && other.onPrimary == onPrimary
        && other.onSecondary == onSecondary
        && other.onSurface == onSurface
        && other.onBackground == onBackground
        && other.onError == onError
        && other.brightness == brightness
        && other.primaryVariant == primaryVariant
        && other.secondaryVariant == secondaryVariant;
  }

  @override
  int get hashCode {
    return hashValues(
      primary,
      secondary,
      surface,
      background,
      error,
      onPrimary,
      onSecondary,
      onSurface,
      onBackground,
      onError,
      brightness,
      primaryVariant,
      secondaryVariant,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const ColorScheme defaultScheme = ColorScheme.light();
    properties.add(ColorProperty('primary', primary, defaultValue: defaultScheme.primary));
    properties.add(ColorProperty('secondary', secondary, defaultValue: defaultScheme.secondary));
    properties.add(ColorProperty('surface', surface, defaultValue: defaultScheme.surface));
    properties.add(ColorProperty('background', background, defaultValue: defaultScheme.background));
    properties.add(ColorProperty('error', error, defaultValue: defaultScheme.error));
    properties.add(ColorProperty('onPrimary', onPrimary, defaultValue: defaultScheme.onPrimary));
    properties.add(ColorProperty('onSecondary', onSecondary, defaultValue: defaultScheme.onSecondary));
    properties.add(ColorProperty('onSurface', onSurface, defaultValue: defaultScheme.onSurface));
    properties.add(ColorProperty('onBackground', onBackground, defaultValue: defaultScheme.onBackground));
    properties.add(ColorProperty('onError', onError, defaultValue: defaultScheme.onError));
    properties.add(DiagnosticsProperty<Brightness>('brightness', brightness, defaultValue: defaultScheme.brightness));
    properties.add(ColorProperty('primaryVariant', primaryVariant, defaultValue: defaultScheme.primaryVariant));
    properties.add(ColorProperty('secondaryVariant', secondaryVariant, defaultValue: defaultScheme.secondaryVariant));
  }
}
