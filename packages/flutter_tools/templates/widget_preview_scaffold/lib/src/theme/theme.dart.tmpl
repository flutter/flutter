// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE: originally from package:devtools_app_shared

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widget_preview_scaffold/src/utils/color_utils.dart';

import 'ide_theme.dart';

// TODO(kenz): try to eliminate as many custom colors as possible, and pull
// colors only from the [lightColorScheme] and the [darkColorScheme].

/// Whether dark theme should be used as the default theme if none has been
/// explicitly set.
const useDarkThemeAsDefault = true;

/// Constructs the light or dark theme for the app taking into account
/// IDE-supplied theming.
ThemeData themeFor({
  required bool isDarkTheme,
  required IdeTheme ideTheme,
  required ThemeData theme,
}) {
  final colorTheme = isDarkTheme
      ? _darkTheme(ideTheme: ideTheme, theme: theme)
      : _lightTheme(ideTheme: ideTheme, theme: theme);

  return colorTheme.copyWith(
    primaryTextTheme: theme.primaryTextTheme.merge(colorTheme.primaryTextTheme),
    textTheme: theme.textTheme.merge(colorTheme.textTheme),
  );
}

ThemeData _darkTheme({required IdeTheme ideTheme, required ThemeData theme}) {
  final background = isValidDarkColor(ideTheme.backgroundColor)
      ? ideTheme.backgroundColor!
      : theme.colorScheme.surface;
  return _baseTheme(theme: theme, backgroundColor: background);
}

ThemeData _lightTheme({required IdeTheme ideTheme, required ThemeData theme}) {
  final background = isValidLightColor(ideTheme.backgroundColor)
      ? ideTheme.backgroundColor!
      : theme.colorScheme.surface;
  return _baseTheme(theme: theme, backgroundColor: background);
}

ThemeData _baseTheme({
  required ThemeData theme,
  required Color backgroundColor,
}) {
  // TODO(kenz): do we need to pass in the foreground color from the [IdeTheme]
  // as well as the background color?
  const kCardRadius = Radius.circular(12);
  return theme.copyWith(
    tabBarTheme: theme.tabBarTheme.copyWith(
      tabAlignment: TabAlignment.start,
      labelStyle: theme.regularTextStyle,
      labelPadding: const EdgeInsets.symmetric(
        horizontal: defaultTabBarPadding,
      ),
    ),
    canvasColor: backgroundColor,
    scaffoldBackgroundColor: backgroundColor,
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(densePadding),
        minimumSize: const Size(defaultButtonHeight, defaultButtonHeight),
        fixedSize: const Size(defaultButtonHeight, defaultButtonHeight),
        iconSize: defaultIconSize,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(buttonMinWidth, defaultButtonHeight),
        fixedSize: const Size.fromHeight(defaultButtonHeight),
        foregroundColor: theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: denseSpacing),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(densePadding),
        minimumSize: const Size(buttonMinWidth, defaultButtonHeight),
        fixedSize: const Size.fromHeight(defaultButtonHeight),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(buttonMinWidth, defaultButtonHeight),
        fixedSize: const Size.fromHeight(defaultButtonHeight),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: denseSpacing),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll<TextStyle>(theme.regularTextStyle),
        fixedSize: const WidgetStatePropertyAll<Size>(Size.fromHeight(24.0)),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: backgroundColor.brighten(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(kCardRadius),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(kCardRadius),
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      tileColor: backgroundColor.brighten(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(kCardRadius),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(textStyle: theme.regularTextStyle),
    primaryTextTheme: _devToolsTextTheme(theme, theme.primaryTextTheme),
    textTheme: _devToolsTextTheme(theme, theme.textTheme),
    colorScheme: theme.colorScheme.copyWith(surface: backgroundColor),
  );
}

TextTheme _devToolsTextTheme(ThemeData theme, TextTheme textTheme) {
  return textTheme.copyWith(
    displayLarge: theme.boldTextStyle.copyWith(fontSize: 24),
    displayMedium: theme.boldTextStyle.copyWith(fontSize: 22),
    displaySmall: theme.boldTextStyle.copyWith(fontSize: 20),
    headlineLarge: theme.regularTextStyle.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: theme.regularTextStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: theme.regularTextStyle.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: theme._largeText.copyWith(fontWeight: FontWeight.w500),
    titleMedium: theme.regularTextStyle.copyWith(fontWeight: FontWeight.w500),
    titleSmall: theme._smallText.copyWith(fontWeight: FontWeight.w500),
    bodyLarge: theme._largeText,
    bodyMedium: theme.regularTextStyle,
    bodySmall: theme._smallText,
    labelLarge: theme._largeText,
    labelMedium: theme.regularTextStyle,
    labelSmall: theme._smallText,
  );
}

/// Light theme color scheme generated from DevTools Figma file.
///
/// Do not manually change these values.
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF195BB9),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD8E2FF),
  onPrimaryContainer: Color(0xFF001A41),
  secondary: Color(0xFF575E71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFDBE2F9),
  onSecondaryContainer: Color(0xFF141B2C),
  tertiary: Color(0xFF815600),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFDDB1),
  onTertiaryContainer: Color(0xFF291800),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD5),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF1B1B1F),
  surfaceContainerHighest: Color(0xFFE1E2EC),
  onSurfaceVariant: Color(0xFF44474F),
  outline: Color(0xFF75777F),
  onInverseSurface: Color(0xFFF2F0F4),
  inverseSurface: Color(0xFF303033),
  inversePrimary: Color(0xFFADC6FF),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF195BB9),
  outlineVariant: Color(0xFFC4C6D0),
  scrim: Color(0xFF000000),
);

/// Dark theme color scheme generated from DevTools Figma file.
///
/// Do not manually change these values.
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFADC6FF),
  onPrimary: Color(0xFF002E69),
  primaryContainer: Color(0xFF004494),
  onPrimaryContainer: Color(0xFFD8E2FF),
  secondary: Color(0xFFBFC6DC),
  onSecondary: Color(0xFF293041),
  secondaryContainer: Color(0xFF3F4759),
  onSecondaryContainer: Color(0xFFDBE2F9),
  tertiary: Color(0xFFFEBA4B),
  onTertiary: Color(0xFF442B00),
  tertiaryContainer: Color(0xFF624000),
  onTertiaryContainer: Color(0xFFFFDDB1),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF930009),
  onError: Color(0xFF690004),
  onErrorContainer: Color(0xFFFFDAD5),
  surface: Color(0xFF1B1B1F),
  onSurface: Color(0xFFC7C6CA),
  surfaceContainerHighest: Color(0xFF44474F),
  onSurfaceVariant: Color(0xFFC4C6D0),
  outline: Color(0xFF8E9099),
  onInverseSurface: Color(0xFF1B1B1F),
  inverseSurface: Color(0xFFE3E2E6),
  inversePrimary: Color(0xFF195BB9),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFADC6FF),
  outlineVariant: Color(0xFF44474F),
  scrim: Color(0xFF000000),
);

/// Threshold used to determine whether a colour is light/dark enough for us to
/// override the default DevTools themes with.
///
/// A value of 0.5 would result in all colours being considered light/dark, and
/// a value of 0.12 allowing around only the 12% darkest/lightest colours by
/// Flutter's luminance calculation.
/// 12% was chosen because VS Code's default light background color is #f3f3f3
/// which is a little under 11%.
const _lightDarkLuminanceThreshold = 0.12;

bool isValidDarkColor(Color? color) {
  if (color == null) {
    return false;
  }
  return color.computeLuminance() <= _lightDarkLuminanceThreshold;
}

bool isValidLightColor(Color? color) {
  if (color == null) {
    return false;
  }
  return color.computeLuminance() >= 1 - _lightDarkLuminanceThreshold;
}

// Size constants:
const defaultButtonHeight = 26.0;
const buttonMinWidth = 26.0;

const defaultIconSize = 14.0;

// Padding / spacing constants:
const extraLargeSpacing = 32.0;
const largeSpacing = 16.0;
const defaultSpacing = 12.0;
const intermediateSpacing = 10.0;
const denseSpacing = 8.0;

const defaultTabBarPadding = 14.0;
const tabBarSpacing = 8.0;
const denseRowSpacing = 6.0;

const densePadding = 4.0;

// Other UI related constants:
final defaultBorderRadius = BorderRadius.circular(_defaultBorderRadiusValue);
const defaultRadius = Radius.circular(_defaultBorderRadiusValue);
const _defaultBorderRadiusValue = 16.0;

const defaultElevation = 4.0;

// Font size constants:
const largeFontSize = 14.0;
const defaultFontSize = 12.0;
const smallFontSize = 10.0;

extension DevToolsSharedColorScheme on ColorScheme {
  bool get isLight => brightness == Brightness.light;

  bool get isDark => brightness == Brightness.dark;

  Color get subtleTextColor => const Color(0xFF919094);

  Color get _devtoolsLink =>
      isLight ? const Color(0xFF1976D2) : Colors.lightBlueAccent;

  Color get tooltipTextColor => isLight ? Colors.white : Colors.black;
}

/// Utility extension methods to the [ThemeData] class.
extension ThemeDataExtension on ThemeData {
  /// Returns whether we are currently using a dark theme.
  bool get isDarkTheme => brightness == Brightness.dark;

  TextStyle get regularTextStyle => fixBlurryText(
    TextStyle(color: colorScheme.onSurface, fontSize: defaultFontSize),
  );

  TextStyle regularTextStyleWithColor(Color? color, {Color? backgroundColor}) =>
      regularTextStyle.copyWith(color: color, backgroundColor: backgroundColor);

  TextStyle get _smallText =>
      regularTextStyle.copyWith(fontSize: smallFontSize);

  TextStyle get _largeText =>
      regularTextStyle.copyWith(fontSize: largeFontSize);

  TextStyle get errorTextStyle => regularTextStyleWithColor(colorScheme.error);

  TextStyle get boldTextStyle =>
      regularTextStyle.copyWith(fontWeight: FontWeight.bold);

  TextStyle get subtleTextStyle =>
      regularTextStyle.copyWith(color: colorScheme.subtleTextColor);

  TextStyle get fixedFontStyle => fixBlurryText(
    regularTextStyle.copyWith(
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      // Slightly smaller for fixes font text since it will appear larger
      // to begin with.
      fontSize: defaultFontSize - 1,
    ),
  );

  TextStyle get subtleFixedFontStyle =>
      fixedFontStyle.copyWith(color: colorScheme.subtleTextColor);

  TextStyle get selectedSubtleTextStyle =>
      subtleTextStyle.copyWith(color: colorScheme.onSurface);

  TextStyle get tooltipFixedFontStyle =>
      fixedFontStyle.copyWith(color: colorScheme.tooltipTextColor);

  TextStyle get fixedFontLinkStyle => fixedFontStyle.copyWith(
    color: colorScheme._devtoolsLink,
    decoration: TextDecoration.underline,
  );

  TextStyle get linkTextStyle => fixBlurryText(
    TextStyle(
      color: colorScheme._devtoolsLink,
      decoration: TextDecoration.underline,
      fontSize: defaultFontSize,
    ),
  );
}

/// Returns a [TextStyle] with [FontFeature.proportionalFigures] applied to
/// fix blurry text.
TextStyle fixBlurryText(TextStyle style) {
  return style.copyWith(
    fontFeatures: [const FontFeature.proportionalFigures()],
  );
}
