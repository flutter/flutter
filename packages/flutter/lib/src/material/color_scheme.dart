// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import 'colors.dart';
import 'theme_data.dart';

/// A set of 25 colors based on the
/// [Material spec](https://m3.material.io/styles/color/the-color-system/color-roles)
/// that can be used to configure the color properties of most components.
///
/// The main accent color groups in the scheme are [primary], [secondary],
/// and [tertiary].
///
/// * Primary colors are used for key components across the UI, such as the FAB,
///   prominent buttons, and active states.
///
/// * Secondary colors are used for less prominent components in the UI, such as
///   filter chips, while expanding the opportunity for color expression.
///
/// * Tertiary colors are used for contrasting accents that can be used to
///   balance primary and secondary colors or bring heightened attention to
///   an element, such as an input field. The tertiary colors are left
///   for makers to use at their discretion and are intended to support
///   broader color expression in products.
///
/// The remaining colors of the scheme are comprised of neutral colors used for
/// backgrounds and surfaces, as well as specific colors for errors, dividers
/// and shadows.
///
/// Many of the colors have matching 'on' colors, which are used for drawing
/// content on top of the matching color. For example, if something is using
/// [primary] for a background color, [onPrimary] would be used to paint text
/// and icons on top of it. For this reason, the 'on' colors should have a
/// contrast ratio with their matching colors of at least 4.5:1 in order to
/// be readable.
///
/// The [Theme] has a color scheme, [ThemeData.colorScheme], which can either be
/// passed in as a parameter to the constructor or by using 'brightness' and
/// 'colorSchemeSeed' parameters (which are used to generate a scheme with
/// [ColorScheme.fromSeed]).
@immutable
class ColorScheme with Diagnosticable {
  /// Create a ColorScheme instance from the given colors.
  ///
  /// [ColorScheme.fromSeed] can be used as a simpler way to create a full
  /// color scheme derived from a single seed color.
  ///
  /// For the color parameters that are nullable, it is still recommended
  /// that applications provide values for them. They are only nullable due
  /// to backwards compatibility concerns.
  ///
  /// If a color is not provided, the closest fallback color from the given
  /// colors will be used for it (e.g. [primaryContainer] will default
  /// to [primary]). Material Design 3 makes use of these colors for many
  /// component defaults, so for the best results the application should
  /// supply colors for all the parameters. An easy way to ensure this is to
  /// use [ColorScheme.fromSeed] to generate a full set of colors.
  ///
  /// During the migration to Material Design 3, if an app's
  /// [ThemeData.useMaterial3] is false, then components will only
  /// use the following colors for defaults:
  ///
  /// * [primary]
  /// * [onPrimary]
  /// * [secondary]
  /// * [onSecondary]
  /// * [error]
  /// * [onError]
  /// * [background]
  /// * [onBackground]
  /// * [surface]
  /// * [onSurface]
  const ColorScheme({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    required this.error,
    required this.onError,
    Color? errorContainer,
    Color? onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
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
  }) : assert(brightness != null),
       assert(primary != null),
       assert(onPrimary != null),
       assert(secondary != null),
       assert(onSecondary != null),
       assert(error != null),
       assert(onError != null),
       assert(background != null),
       assert(onBackground != null),
       assert(surface != null),
       assert(onSurface != null),
       _primaryContainer = primaryContainer,
       _onPrimaryContainer = onPrimaryContainer,
       _secondaryContainer = secondaryContainer,
       _onSecondaryContainer = onSecondaryContainer,
       _tertiary = tertiary,
       _onTertiary = onTertiary,
       _tertiaryContainer = tertiaryContainer,
       _onTertiaryContainer = onTertiaryContainer,
       _errorContainer = errorContainer,
       _onErrorContainer = onErrorContainer,
       _surfaceVariant = surfaceVariant,
       _onSurfaceVariant = onSurfaceVariant,
       _outline = outline,
       _shadow = shadow,
       _inverseSurface = inverseSurface,
       _onInverseSurface = onInverseSurface,
       _inversePrimary = inversePrimary,
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant,
       _surfaceTint = surfaceTint;

  /// Generate a [ColorScheme] derived from the given `seedColor`.
  ///
  /// Using the seedColor as a starting point, a set of tonal palettes are
  /// constructed. These tonal palettes are based on the Material 3 Color
  /// system and provide all the needed colors for a [ColorScheme]. These
  /// colors are designed to work well together and meet contrast
  /// requirements for accessibility.
  ///
  /// If any of the optional color parameters are non-null they will be
  /// used in place of the generated colors for that field in the resulting
  /// color scheme. This allows apps to override specific colors for their
  /// needs.
  ///
  /// Given the nature of the algorithm, the seedColor may not wind up as
  /// one of the ColorScheme colors.
  ///
  /// See also:
  ///
  ///  * <https://m3.material.io/styles/color/the-color-system/color-roles>, the
  ///    Material 3 Color system specification.
  ///  * <https://pub.dev/packages/material_color_utilities>, the package
  ///    used to generate the tonal palettes needed for the scheme.
  factory ColorScheme.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? outline,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? shadow,
    Color? surfaceTint,
  }) {
    final Scheme scheme;
    switch (brightness) {
      case Brightness.light:
        scheme = Scheme.light(seedColor.value);
        break;
      case Brightness.dark:
        scheme = Scheme.dark(seedColor.value);
        break;
    }
    return ColorScheme(
      primary: primary ?? Color(scheme.primary),
      onPrimary: onPrimary ?? Color(scheme.onPrimary),
      primaryContainer: primaryContainer ?? Color(scheme.primaryContainer),
      onPrimaryContainer: onPrimaryContainer ?? Color(scheme.onPrimaryContainer),
      secondary: secondary ?? Color(scheme.secondary),
      onSecondary: onSecondary ?? Color(scheme.onSecondary),
      secondaryContainer: secondaryContainer ?? Color(scheme.secondaryContainer),
      onSecondaryContainer: onSecondaryContainer ?? Color(scheme.onSecondaryContainer),
      tertiary: tertiary ?? Color(scheme.tertiary),
      onTertiary: onTertiary ?? Color(scheme.onTertiary),
      tertiaryContainer: tertiaryContainer ?? Color(scheme.tertiaryContainer),
      onTertiaryContainer: onTertiaryContainer ?? Color(scheme.onTertiaryContainer),
      error: error ?? Color(scheme.error),
      onError: onError ?? Color(scheme.onError),
      errorContainer: errorContainer ?? Color(scheme.errorContainer),
      onErrorContainer: onErrorContainer ?? Color(scheme.onErrorContainer),
      outline: outline ?? Color(scheme.outline),
      background: background ?? Color(scheme.background),
      onBackground: onBackground ?? Color(scheme.onBackground),
      surface: surface ?? Color(scheme.surface),
      onSurface: onSurface ?? Color(scheme.onSurface),
      surfaceVariant: surfaceVariant ?? Color(scheme.surfaceVariant),
      onSurfaceVariant: onSurfaceVariant ?? Color(scheme.onSurfaceVariant),
      inverseSurface: inverseSurface ?? Color(scheme.inverseSurface),
      onInverseSurface: onInverseSurface ?? Color(scheme.inverseOnSurface),
      inversePrimary: inversePrimary ?? Color(scheme.inversePrimary),
      shadow: shadow ?? Color(scheme.shadow),
      surfaceTint: surfaceTint ?? Color(scheme.primary),
      brightness: brightness,
    );
  }

  /// Create a ColorScheme based on a purple primary color that matches the
  /// [baseline Material color scheme](https://material.io/design/color/the-color-system.html#color-theme-creation).
  const ColorScheme.light({
    this.brightness = Brightness.light,
    this.primary = const Color(0xff6200ee),
    this.onPrimary = Colors.white,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    this.secondary = const Color(0xff03dac6),
    this.onSecondary = Colors.black,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    this.error = const Color(0xffb00020),
    this.onError = Colors.white,
    Color? errorContainer,
    Color? onErrorContainer,
    this.background = Colors.white,
    this.onBackground = Colors.black,
    this.surface = Colors.white,
    this.onSurface = Colors.black,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
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
  }) : assert(brightness != null),
       assert(primary != null),
       assert(onPrimary != null),
       assert(secondary != null),
       assert(onSecondary != null),
       assert(error != null),
       assert(onError != null),
       assert(background != null),
       assert(onBackground != null),
       assert(surface != null),
       assert(onSurface != null),
       _primaryContainer = primaryContainer,
       _onPrimaryContainer = onPrimaryContainer,
       _secondaryContainer = secondaryContainer,
       _onSecondaryContainer = onSecondaryContainer,
       _tertiary = tertiary,
       _onTertiary = onTertiary,
       _tertiaryContainer = tertiaryContainer,
       _onTertiaryContainer = onTertiaryContainer,
       _errorContainer = errorContainer,
       _onErrorContainer = onErrorContainer,
       _surfaceVariant = surfaceVariant,
       _onSurfaceVariant = onSurfaceVariant,
       _outline = outline,
       _shadow = shadow,
       _inverseSurface = inverseSurface,
       _onInverseSurface = onInverseSurface,
       _inversePrimary = inversePrimary,
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant,
       _surfaceTint = surfaceTint;

  /// Create the recommended dark color scheme that matches the
  /// [baseline Material color scheme](https://material.io/design/color/dark-theme.html#ui-application).
  const ColorScheme.dark({
    this.brightness = Brightness.dark,
    this.primary = const Color(0xffbb86fc),
    this.onPrimary = Colors.black,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    this.secondary = const Color(0xff03dac6),
    this.onSecondary = Colors.black,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    this.error = const Color(0xffcf6679),
    this.onError = Colors.black,
    Color? errorContainer,
    Color? onErrorContainer,
    this.background = const Color(0xff121212),
    this.onBackground = Colors.white,
    this.surface = const Color(0xff121212),
    this.onSurface = Colors.white,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
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
  }) : assert(brightness != null),
       assert(primary != null),
       assert(onPrimary != null),
       assert(secondary != null),
       assert(onSecondary != null),
       assert(error != null),
       assert(onError != null),
       assert(background != null),
       assert(onBackground != null),
       assert(surface != null),
       assert(onSurface != null),
       _primaryContainer = primaryContainer,
       _onPrimaryContainer = onPrimaryContainer,
       _secondaryContainer = secondaryContainer,
       _onSecondaryContainer = onSecondaryContainer,
       _tertiary = tertiary,
       _onTertiary = onTertiary,
       _tertiaryContainer = tertiaryContainer,
       _onTertiaryContainer = onTertiaryContainer,
       _errorContainer = errorContainer,
       _onErrorContainer = onErrorContainer,
       _surfaceVariant = surfaceVariant,
       _onSurfaceVariant = onSurfaceVariant,
       _outline = outline,
       _shadow = shadow,
       _inverseSurface = inverseSurface,
       _onInverseSurface = onInverseSurface,
       _inversePrimary = inversePrimary,
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant,
       _surfaceTint = surfaceTint;

  /// Create a high contrast ColorScheme based on a purple primary color that
  /// matches the [baseline Material color scheme](https://material.io/design/color/the-color-system.html#color-theme-creation).
  const ColorScheme.highContrastLight({
    this.brightness = Brightness.light,
    this.primary = const Color(0xff0000ba),
    this.onPrimary = Colors.white,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    this.secondary = const Color(0xff66fff9),
    this.onSecondary = Colors.black,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    this.error = const Color(0xff790000),
    this.onError = Colors.white,
    Color? errorContainer,
    Color? onErrorContainer,
    this.background = Colors.white,
    this.onBackground = Colors.black,
    this.surface = Colors.white,
    this.onSurface = Colors.black,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
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
  }) : assert(brightness != null),
       assert(primary != null),
       assert(onPrimary != null),
       assert(secondary != null),
       assert(onSecondary != null),
       assert(error != null),
       assert(onError != null),
       assert(background != null),
       assert(onBackground != null),
       assert(surface != null),
       assert(onSurface != null),
       _primaryContainer = primaryContainer,
       _onPrimaryContainer = onPrimaryContainer,
       _secondaryContainer = secondaryContainer,
       _onSecondaryContainer = onSecondaryContainer,
       _tertiary = tertiary,
       _onTertiary = onTertiary,
       _tertiaryContainer = tertiaryContainer,
       _onTertiaryContainer = onTertiaryContainer,
       _errorContainer = errorContainer,
       _onErrorContainer = onErrorContainer,
       _surfaceVariant = surfaceVariant,
       _onSurfaceVariant = onSurfaceVariant,
       _outline = outline,
       _shadow = shadow,
       _inverseSurface = inverseSurface,
       _onInverseSurface = onInverseSurface,
       _inversePrimary = inversePrimary,
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant,
       _surfaceTint = surfaceTint;

  /// Create a high contrast ColorScheme based on the dark
  /// [baseline Material color scheme](https://material.io/design/color/dark-theme.html#ui-application).
  const ColorScheme.highContrastDark({
    this.brightness = Brightness.dark,
    this.primary = const Color(0xffefb7ff),
    this.onPrimary = Colors.black,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    this.secondary = const Color(0xff66fff9),
    this.onSecondary = Colors.black,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    this.error = const Color(0xff9b374d),
    this.onError = Colors.black,
    Color? errorContainer,
    Color? onErrorContainer,
    this.background = const Color(0xff121212),
    this.onBackground = Colors.white,
    this.surface = const Color(0xff121212),
    this.onSurface = Colors.white,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
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
  }) : assert(brightness != null),
       assert(primary != null),
       assert(onPrimary != null),
       assert(secondary != null),
       assert(onSecondary != null),
       assert(error != null),
       assert(onError != null),
       assert(background != null),
       assert(onBackground != null),
       assert(surface != null),
       assert(onSurface != null),
       _primaryContainer = primaryContainer,
       _onPrimaryContainer = onPrimaryContainer,
       _secondaryContainer = secondaryContainer,
       _onSecondaryContainer = onSecondaryContainer,
       _tertiary = tertiary,
       _onTertiary = onTertiary,
       _tertiaryContainer = tertiaryContainer,
       _onTertiaryContainer = onTertiaryContainer,
       _errorContainer = errorContainer,
       _onErrorContainer = onErrorContainer,
       _surfaceVariant = surfaceVariant,
       _onSurfaceVariant = onSurfaceVariant,
       _outline = outline,
       _shadow = shadow,
       _inverseSurface = inverseSurface,
       _onInverseSurface = onInverseSurface,
       _inversePrimary = inversePrimary,
       _primaryVariant = primaryVariant,
       _secondaryVariant = secondaryVariant,
       _surfaceTint = surfaceTint;

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

  /// The overall brightness of this color scheme.
  final Brightness brightness;

  /// The color displayed most frequently across your app’s screens and components.
  final Color primary;

  /// A color that's clearly legible when drawn on [primary].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [primary] and [onPrimary] of at least 4.5:1 is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onPrimary;

  final Color? _primaryContainer;
  /// A color used for elements needing less emphasis than [primary].
  Color get primaryContainer => _primaryContainer ?? primary;

  final Color? _onPrimaryContainer;
  /// A color that's clearly legible when drawn on [primaryContainer].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [primaryContainer] and [onPrimaryContainer] of at least 4.5:1
  /// is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onPrimaryContainer => _onPrimaryContainer ?? onPrimary;

  /// An accent color used for less prominent components in the UI, such as
  /// filter chips, while expanding the opportunity for color expression.
  final Color secondary;

  /// A color that's clearly legible when drawn on [secondary].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [secondary] and [onSecondary] of at least 4.5:1 is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onSecondary;

  final Color? _secondaryContainer;
  /// A color used for elements needing less emphasis than [secondary].
  Color get secondaryContainer => _secondaryContainer ?? secondary;

  final Color? _onSecondaryContainer;
  /// A color that's clearly legible when drawn on [secondaryContainer].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [secondaryContainer] and [onSecondaryContainer] of at least 4.5:1 is
  /// recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onSecondaryContainer => _onSecondaryContainer ?? onSecondary;

  final Color? _tertiary;
  /// A color used as a contrasting accent that can balance [primary]
  /// and [secondary] colors or bring heightened attention to an element,
  /// such as an input field.
  Color get tertiary => _tertiary ?? secondary;

  final Color? _onTertiary;
  /// A color that's clearly legible when drawn on [tertiary].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [tertiary] and [onTertiary] of at least 4.5:1 is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onTertiary => _onTertiary ?? onSecondary;

  final Color? _tertiaryContainer;
  /// A color used for elements needing less emphasis than [tertiary].
  Color get tertiaryContainer => _tertiaryContainer ?? tertiary;

  final Color? _onTertiaryContainer;
  /// A color that's clearly legible when drawn on [tertiaryContainer].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [tertiaryContainer] and [onTertiaryContainer] of at least 4.5:1 is
  /// recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onTertiaryContainer => _onTertiaryContainer ?? onTertiary;

  /// The color to use for input validation errors, e.g. for
  /// [InputDecoration.errorText].
  final Color error;

  /// A color that's clearly legible when drawn on [error].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [error] and [onError] of at least 4.5:1 is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onError;

  final Color? _errorContainer;
  /// A color used for error elements needing less emphasis than [error].
  Color get errorContainer => _errorContainer ?? error;

  final Color? _onErrorContainer;
  /// A color that's clearly legible when drawn on [errorContainer].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [errorContainer] and [onErrorContainer] of at least 4.5:1 is
  /// recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onErrorContainer => _onErrorContainer ?? onError;

  /// A color that typically appears behind scrollable content.
  final Color background;

  /// A color that's clearly legible when drawn on [background].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [background] and [onBackground] of at least 4.5:1 is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onBackground;

  /// The background color for widgets like [Card].
  final Color surface;

  /// A color that's clearly legible when drawn on [surface].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [surface] and [onSurface] of at least 4.5:1 is recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  final Color onSurface;

  final Color? _surfaceVariant;
  /// A color variant of [surface] that can be used for differentiation against
  /// a component using [surface].
  Color get surfaceVariant => _surfaceVariant ?? surface;

  final Color? _onSurfaceVariant;
  /// A color that's clearly legible when drawn on [surfaceVariant].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [surfaceVariant] and [onSurfaceVariant] of at least 4.5:1 is
  /// recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onSurfaceVariant => _onSurfaceVariant ?? onSurface;

  final Color? _outline;
  /// A utility color that creates boundaries and emphasis to improve usability.
  Color get outline => _outline ?? onBackground;

  final Color? _shadow;
  /// A color use to paint the drop shadows of elevated components.
  Color get shadow => _shadow ?? const Color(0xff000000);

  final Color? _inverseSurface;
  /// A surface color used for displaying the reverse of what’s seen in the
  /// surrounding UI, for example in a SnackBar to bring attention to
  /// an alert.
  Color get inverseSurface => _inverseSurface ?? onSurface;

  final Color? _onInverseSurface;
  /// A color that's clearly legible when drawn on [inverseSurface].
  ///
  /// To ensure that an app is accessible, a contrast ratio between
  /// [inverseSurface] and [onInverseSurface] of at least 4.5:1 is
  /// recommended. See
  /// <https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html>.
  Color get onInverseSurface => _onInverseSurface ?? surface;

  final Color? _inversePrimary;
  /// An accent color used for displaying a highlight color on [inverseSurface]
  /// backgrounds, like button text in a SnackBar.
  Color get inversePrimary => _inversePrimary ?? onPrimary;

  final Color? _surfaceTint;
  /// A color used as an overlay on a surface color to indicate a component's
  /// elevation.
  Color get surfaceTint => _surfaceTint ?? primary;

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
    Brightness? brightness,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? shadow,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
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
      brightness: brightness ?? this.brightness,
      primary : primary ?? this.primary,
      onPrimary : onPrimary ?? this.onPrimary,
      primaryContainer : primaryContainer ?? this.primaryContainer,
      onPrimaryContainer : onPrimaryContainer ?? this.onPrimaryContainer,
      secondary : secondary ?? this.secondary,
      onSecondary : onSecondary ?? this.onSecondary,
      secondaryContainer : secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer : onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary : tertiary ?? this.tertiary,
      onTertiary : onTertiary ?? this.onTertiary,
      tertiaryContainer : tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer : onTertiaryContainer ?? this.onTertiaryContainer,
      error : error ?? this.error,
      onError : onError ?? this.onError,
      errorContainer : errorContainer ?? this.errorContainer,
      onErrorContainer : onErrorContainer ?? this.onErrorContainer,
      background : background ?? this.background,
      onBackground : onBackground ?? this.onBackground,
      surface : surface ?? this.surface,
      onSurface : onSurface ?? this.onSurface,
      surfaceVariant : surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant : onSurfaceVariant ?? this.onSurfaceVariant,
      outline : outline ?? this.outline,
      shadow : shadow ?? this.shadow,
      inverseSurface : inverseSurface ?? this.inverseSurface,
      onInverseSurface : onInverseSurface ?? this.onInverseSurface,
      inversePrimary : inversePrimary ?? this.inversePrimary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      surfaceTint: _surfaceTint ?? this.surfaceTint,
    );
  }

  /// Linearly interpolate between two [ColorScheme] objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static ColorScheme lerp(ColorScheme a, ColorScheme b, double t) {
    return ColorScheme(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      primary: Color.lerp(a.primary, b.primary, t)!,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      primaryContainer: Color.lerp(a.primaryContainer, b.primaryContainer, t),
      onPrimaryContainer: Color.lerp(a.onPrimaryContainer, b.onPrimaryContainer, t),
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t)!,
      secondaryContainer: Color.lerp(a.secondaryContainer, b.secondaryContainer, t),
      onSecondaryContainer: Color.lerp(a.onSecondaryContainer, b.onSecondaryContainer, t),
      tertiary: Color.lerp(a.tertiary, b.tertiary, t),
      onTertiary: Color.lerp(a.onTertiary, b.onTertiary, t),
      tertiaryContainer: Color.lerp(a.tertiaryContainer, b.tertiaryContainer, t),
      onTertiaryContainer: Color.lerp(a.onTertiaryContainer, b.onTertiaryContainer, t),
      error: Color.lerp(a.error, b.error, t)!,
      onError: Color.lerp(a.onError, b.onError, t)!,
      errorContainer: Color.lerp(a.errorContainer, b.errorContainer, t),
      onErrorContainer: Color.lerp(a.onErrorContainer, b.onErrorContainer, t),
      background: Color.lerp(a.background, b.background, t)!,
      onBackground: Color.lerp(a.onBackground, b.onBackground, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
      surfaceVariant: Color.lerp(a.surfaceVariant, b.surfaceVariant, t),
      onSurfaceVariant: Color.lerp(a.onSurfaceVariant, b.onSurfaceVariant, t),
      outline: Color.lerp(a.outline, b.outline, t),
      shadow: Color.lerp(a.shadow, b.shadow, t),
      inverseSurface: Color.lerp(a.inverseSurface, b.inverseSurface, t),
      onInverseSurface: Color.lerp(a.onInverseSurface, b.onInverseSurface, t),
      inversePrimary: Color.lerp(a.inversePrimary, b.inversePrimary, t),
      primaryVariant: Color.lerp(a.primaryVariant, b.primaryVariant, t),
      secondaryVariant: Color.lerp(a.secondaryVariant, b.secondaryVariant, t),
      surfaceTint: Color.lerp(a.surfaceTint, b.surfaceTint, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is ColorScheme
      && other.brightness == brightness
      && other.primary == primary
      && other.onPrimary == onPrimary
      && other.primaryContainer == primaryContainer
      && other.onPrimaryContainer == onPrimaryContainer
      && other.secondary == secondary
      && other.onSecondary == onSecondary
      && other.secondaryContainer == secondaryContainer
      && other.onSecondaryContainer == onSecondaryContainer
      && other.tertiary == tertiary
      && other.onTertiary == onTertiary
      && other.tertiaryContainer == tertiaryContainer
      && other.onTertiaryContainer == onTertiaryContainer
      && other.error == error
      && other.onError == onError
      && other.errorContainer == errorContainer
      && other.onErrorContainer == onErrorContainer
      && other.background == background
      && other.onBackground == onBackground
      && other.surface == surface
      && other.onSurface == onSurface
      && other.surfaceVariant == surfaceVariant
      && other.onSurfaceVariant == onSurfaceVariant
      && other.outline == outline
      && other.shadow == shadow
      && other.inverseSurface == inverseSurface
      && other.onInverseSurface == onInverseSurface
      && other.inversePrimary == inversePrimary
      && other.primaryVariant == primaryVariant
      && other.secondaryVariant == secondaryVariant
      && other.surfaceTint == surfaceTint;
  }

  @override
  int get hashCode => Object.hash(
    brightness,
    primary,
    onPrimary,
    primaryContainer,
    onPrimaryContainer,
    secondary,
    onSecondary,
    secondaryContainer,
    onSecondaryContainer,
    tertiary,
    onTertiary,
    tertiaryContainer,
    onTertiaryContainer,
    error,
    onError,
    errorContainer,
    onErrorContainer,
    background,
    onBackground,
    Object.hash(
      surface,
      onSurface,
      surfaceVariant,
      onSurfaceVariant,
      outline,
      shadow,
      inverseSurface,
      onInverseSurface,
      inversePrimary,
      primaryVariant,
      secondaryVariant,
      surfaceTint,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const ColorScheme defaultScheme = ColorScheme.light();
    properties.add(DiagnosticsProperty<Brightness>('brightness', brightness, defaultValue: defaultScheme.brightness));
    properties.add(ColorProperty('primary', primary, defaultValue: defaultScheme.primary));
    properties.add(ColorProperty('onPrimary', onPrimary, defaultValue: defaultScheme.onPrimary));
    properties.add(ColorProperty('primaryContainer', primaryContainer, defaultValue: defaultScheme.primaryContainer));
    properties.add(ColorProperty('onPrimaryContainer', onPrimaryContainer, defaultValue: defaultScheme.onPrimaryContainer));
    properties.add(ColorProperty('secondary', secondary, defaultValue: defaultScheme.secondary));
    properties.add(ColorProperty('onSecondary', onSecondary, defaultValue: defaultScheme.onSecondary));
    properties.add(ColorProperty('secondaryContainer', secondaryContainer, defaultValue: defaultScheme.secondaryContainer));
    properties.add(ColorProperty('onSecondaryContainer', onSecondaryContainer, defaultValue: defaultScheme.onSecondaryContainer));
    properties.add(ColorProperty('tertiary', tertiary, defaultValue: defaultScheme.tertiary));
    properties.add(ColorProperty('onTertiary', onTertiary, defaultValue: defaultScheme.onTertiary));
    properties.add(ColorProperty('tertiaryContainer', tertiaryContainer, defaultValue: defaultScheme.tertiaryContainer));
    properties.add(ColorProperty('onTertiaryContainer', onTertiaryContainer, defaultValue: defaultScheme.onTertiaryContainer));
    properties.add(ColorProperty('error', error, defaultValue: defaultScheme.error));
    properties.add(ColorProperty('onError', onError, defaultValue: defaultScheme.onError));
    properties.add(ColorProperty('errorContainer', errorContainer, defaultValue: defaultScheme.errorContainer));
    properties.add(ColorProperty('onErrorContainer', onErrorContainer, defaultValue: defaultScheme.onErrorContainer));
    properties.add(ColorProperty('background', background, defaultValue: defaultScheme.background));
    properties.add(ColorProperty('onBackground', onBackground, defaultValue: defaultScheme.onBackground));
    properties.add(ColorProperty('surface', surface, defaultValue: defaultScheme.surface));
    properties.add(ColorProperty('onSurface', onSurface, defaultValue: defaultScheme.onSurface));
    properties.add(ColorProperty('surfaceVariant', surfaceVariant, defaultValue: defaultScheme.surfaceVariant));
    properties.add(ColorProperty('onSurfaceVariant', onSurfaceVariant, defaultValue: defaultScheme.onSurfaceVariant));
    properties.add(ColorProperty('outline', outline, defaultValue: defaultScheme.outline));
    properties.add(ColorProperty('shadow', shadow, defaultValue: defaultScheme.shadow));
    properties.add(ColorProperty('inverseSurface', inverseSurface, defaultValue: defaultScheme.inverseSurface));
    properties.add(ColorProperty('onInverseSurface', onInverseSurface, defaultValue: defaultScheme.onInverseSurface));
    properties.add(ColorProperty('inversePrimary', inversePrimary, defaultValue: defaultScheme.inversePrimary));
    properties.add(ColorProperty('primaryVariant', primaryVariant, defaultValue: defaultScheme.primaryVariant));
    properties.add(ColorProperty('secondaryVariant', secondaryVariant, defaultValue: defaultScheme.secondaryVariant));
    properties.add(ColorProperty('surfaceTint', surfaceTint, defaultValue: defaultScheme.surfaceTint));
  }
}
