// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, hashValues;

import 'package:flutter/foundation.dart';

import 'colors.dart';
import 'icon_theme_data.dart';
import 'typography.dart';

/// Describes the contrast needs of a color.
enum Brightness {
  /// The color is dark and will require a light text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be dark grey, requiring white text.
  dark,

  /// The color is light and will require a dark text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be bright white, requiring black text.
  light,
}

// Deriving these values is black magic. The spec claims that pressed buttons
// have a highlight of 0x66999999, but that's clearly wrong. The videos in the
// spec show that buttons have a composited highlight of #E1E1E1 on a background
// of #FAFAFA. Assuming that the highlight really has an opacity of 0x66, we can
// solve for the actual color of the highlight:
const Color _kLightThemeHighlightColor = const Color(0x66BCBCBC);

// The same video shows the splash compositing to #D7D7D7 on a background of
// #E1E1E1. Again, assuming the splash has an opacity of 0x66, we can solve for
// the actual color of the splash:
const Color _kLightThemeSplashColor = const Color(0x66C8C8C8);

// Unfortunately, a similar video isn't available for the dark theme, which
// means we assume the values in the spec are actually correct.
const Color _kDarkThemeHighlightColor = const Color(0x40CCCCCC);
const Color _kDarkThemeSplashColor = const Color(0x40CCCCCC);

/// Holds the color and typography values for a material design theme.
///
/// Use this class to configure a [Theme] widget.
class ThemeData {
  /// Create a ThemeData given a set of preferred values.
  ///
  /// Default values will be derived for arguments that are omitted.
  ///
  /// The most useful values to give are, in order of importance:
  ///
  ///  * The desired theme [brightness].
  ///
  ///  * The primary color palette (the [primarySwatch]), chosen from
  ///    one of the swatches defined by the material design spec. This
  ///    should be one of the maps from the [Colors] class that do not
  ///    have "accent" in their name.
  ///
  ///  * The [accentColor], sometimes called the secondary color, and,
  ///    if the accent color is specified, its brightness
  ///    ([accentColorBrightness]), so that the right contrasting text
  ///    color will be used over the accent color.
  ///
  /// See <https://www.google.com/design/spec/style/color.html> for
  /// more discussion on how to pick the right colors.
  factory ThemeData({
    Brightness brightness,
    Map<int, Color> primarySwatch,
    Color primaryColor,
    Brightness primaryColorBrightness,
    Color accentColor,
    Brightness accentColorBrightness,
    Color canvasColor,
    Color cardColor,
    Color dividerColor,
    Color highlightColor,
    Color splashColor,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    Color buttonColor,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    TargetPlatform platform
  }) {
    brightness ??= Brightness.light;
    final bool isDark = brightness == Brightness.dark;
    primarySwatch ??= Colors.blue;
    primaryColor ??= isDark ? Colors.grey[900] : primarySwatch[500];
    primaryColorBrightness ??= Brightness.dark;
    final bool primaryIsDark = primaryColorBrightness == Brightness.dark;
    accentColor ??= isDark ? Colors.tealAccent[200] : primarySwatch[500];
    accentColorBrightness ??= Brightness.dark;
    canvasColor ??= isDark ? Colors.grey[850] : Colors.grey[50];
    cardColor ??= isDark ? Colors.grey[800] : Colors.white;
    dividerColor ??= isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);
    highlightColor ??= isDark ? _kDarkThemeHighlightColor : _kLightThemeHighlightColor;
    splashColor ??= isDark ? _kDarkThemeSplashColor : _kLightThemeSplashColor;
    selectedRowColor ??= Colors.grey[100];
    unselectedWidgetColor ??= isDark ? Colors.white70 : Colors.black54;
    disabledColor ??= isDark ? Colors.white30 : Colors.black26;
    buttonColor ??= isDark ? primarySwatch[600] : Colors.grey[300];
    // Spec doesn't specify a dark theme secondaryHeaderColor, this is a guess.
    secondaryHeaderColor ??= isDark ? Colors.grey[700] : primarySwatch[50];
    textSelectionColor ??= isDark ? accentColor : primarySwatch[200];
    textSelectionHandleColor ??= isDark ? Colors.tealAccent[400] : primarySwatch[300];
    backgroundColor ??= isDark ? Colors.grey[700] : primarySwatch[200];
    indicatorColor ??= accentColor == primaryColor ? Colors.white : accentColor;
    hintColor ??= isDark ? const Color(0x42FFFFFF) : const Color(0x4C000000);
    errorColor ??= Colors.red[700];
    textTheme ??= isDark ? Typography.white : Typography.black;
    primaryTextTheme ??= primaryIsDark ? Typography.white : Typography.black;
    iconTheme ??= isDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    primaryIconTheme ??= primaryIsDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    platform ??= defaultTargetPlatform;
    return new ThemeData.raw(
      brightness: brightness,
      primaryColor: primaryColor,
      primaryColorBrightness: primaryColorBrightness,
      accentColor: accentColor,
      accentColorBrightness: accentColorBrightness,
      canvasColor: canvasColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      selectedRowColor: selectedRowColor,
      unselectedWidgetColor: unselectedWidgetColor,
      disabledColor: disabledColor,
      buttonColor: buttonColor,
      secondaryHeaderColor: secondaryHeaderColor,
      textSelectionColor: textSelectionColor,
      textSelectionHandleColor: textSelectionHandleColor,
      backgroundColor: backgroundColor,
      indicatorColor: indicatorColor,
      hintColor: hintColor,
      errorColor: errorColor,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      iconTheme: iconTheme,
      primaryIconTheme: primaryIconTheme,
      platform: platform
    );
  }

  /// Create a ThemeData given a set of exact values. All the values
  /// must be specified.
  ///
  /// This will rarely be used directly. It is used by [lerp] to
  /// create intermediate themes based on two themes created with the
  /// [new ThemeData] constructor.
  ThemeData.raw({
    this.brightness,
    this.primaryColor,
    this.primaryColorBrightness,
    this.accentColor,
    this.accentColorBrightness,
    this.canvasColor,
    this.cardColor,
    this.dividerColor,
    this.highlightColor,
    this.splashColor,
    this.selectedRowColor,
    this.unselectedWidgetColor,
    this.disabledColor,
    this.buttonColor,
    this.secondaryHeaderColor,
    this.textSelectionColor,
    this.textSelectionHandleColor,
    this.backgroundColor,
    this.indicatorColor,
    this.hintColor,
    this.errorColor,
    this.textTheme,
    this.primaryTextTheme,
    this.iconTheme,
    this.primaryIconTheme,
    this.platform
  }) {
    assert(brightness != null);
    assert(primaryColor != null);
    assert(primaryColorBrightness != null);
    assert(accentColor != null);
    assert(accentColorBrightness != null);
    assert(canvasColor != null);
    assert(cardColor != null);
    assert(dividerColor != null);
    assert(highlightColor != null);
    assert(splashColor != null);
    assert(selectedRowColor != null);
    assert(unselectedWidgetColor != null);
    assert(disabledColor != null);
    assert(buttonColor != null);
    assert(secondaryHeaderColor != null);
    assert(textSelectionColor != null);
    assert(textSelectionHandleColor != null);
    assert(disabledColor != null);
    assert(indicatorColor != null);
    assert(hintColor != null);
    assert(errorColor != null);
    assert(textTheme != null);
    assert(primaryTextTheme != null);
    assert(iconTheme != null);
    assert(primaryIconTheme != null);
    assert(platform != null);
  }

  /// A default light blue theme.
  factory ThemeData.light() => new ThemeData(brightness: Brightness.light);

  /// A default dark theme with a teal accent color.
  factory ThemeData.dark() => new ThemeData(brightness: Brightness.dark);

  /// The default theme. Same as [new ThemeData.light].
  ///
  /// This is used by [Theme.of] when no theme has been specified.
  factory ThemeData.fallback() => new ThemeData.light();

  /// The brightness of the overall theme of the application. Used by widgets
  /// like buttons to determine what color to pick when not using the primary or
  /// accent color.
  ///
  /// When the [Brightness] is dark, the canvas, card, and primary colors are
  /// all dark. When the [Brightness] is light, the canvas and card colors
  /// are bright, and the primary color's darkness varies as described by
  /// primaryColorBrightness. The primaryColor does not contrast well with the
  /// card and canvas colors when the brightness is dark; when the brightness is
  /// dark, use Colors.white or the accentColor for a contrasting color.
  final Brightness brightness;

  /// The background color for major parts of the app (toolbars, tab bars, etc)
  final Color primaryColor;

  /// The brightness of the primaryColor. Used to determine the color of text and
  /// icons placed on top of the primary color (e.g. toolbar text).
  final Brightness primaryColorBrightness;

  /// The foreground color for widgets (knobs, text, etc)
  final Color accentColor;

  /// The brightness of the accentColor. Used to determine the color of text
  /// and icons placed on top of the accent color (e.g. the icons on a floating
  /// action button).
  final Brightness accentColorBrightness;

  /// The color of [Material] when it is of infinite extent, e.g. the
  /// body of a [Scaffold].
  final Color canvasColor;

  /// The color of [Material] when it is used as a [Card].
  final Color cardColor;

  /// The color of [Divider]s and [PopupMenuDivider]s, also used
  /// between [ListItem]s, between rows in [DataTable]s, and so forth.
  final Color dividerColor;

  /// The highlight color used during ink splash animations or to
  /// indicate an item in a menu is selected.
  final Color highlightColor;

  /// The color of ink splashes. See [InkWell].
  final Color splashColor;

  /// The color used to highlight selected rows.
  final Color selectedRowColor;

  /// The color used for widgets in their inactive (but enabled)
  /// state. For example, an unchecked checkbox. Usually contrasted
  /// with the [accentColor]. See also [disabledColor].
  final Color unselectedWidgetColor;

  /// The color used for widgets that are inoperative, regardless of
  /// their state. For example, a disabled checkbox (which may be
  /// checked or unchecked).
  final Color disabledColor;

  /// The default color of the [Material] used in [RaisedButton]s.
  final Color buttonColor;

  /// The color of the header of a [PaginatedDataTable] when there are selected rows.
  // According to the spec for data tables:
  // https://material.google.com/components/data-tables.html#data-tables-tables-within-cards
  // ...this should be the "50-value of secondary app color".
  final Color secondaryHeaderColor;

  /// The color of text selections in text fields, such as [Input].
  final Color textSelectionColor;

  /// The color of the handles used to adjust what part of the text is currently selected.
  final Color textSelectionHandleColor;

  /// A color that contrasts with the [primaryColor], e.g. used as the
  /// remaining part of a progress bar.
  final Color backgroundColor;

  /// The color of the selected tab indicator in a tab bar.
  final Color indicatorColor;

  /// The color to use for hint text or placeholder text, e.g. in
  /// [Input] fields.
  final Color hintColor;

  /// The color to use for input validation errors, e.g. in [Input] fields.
  final Color errorColor;

  /// Text with a color that contrasts with the card and canvas colors.
  final TextTheme textTheme;

  /// A text theme that contrasts with the primary color.
  final TextTheme primaryTextTheme;

  /// An icon theme that contrasts with the card and canvas colors.
  final IconThemeData iconTheme;

  /// An icon theme that contrasts with the primary color.
  final IconThemeData primaryIconTheme;

  /// The platform the material widgets should adapt to target.
  ///
  /// Defaults to the current platform.
  final TargetPlatform platform;

  /// Linearly interpolate between two themes.
  static ThemeData lerp(ThemeData begin, ThemeData end, double t) {
    return new ThemeData.raw(
      brightness: t < 0.5 ? begin.brightness : end.brightness,
      primaryColor: Color.lerp(begin.primaryColor, end.primaryColor, t),
      primaryColorBrightness: t < 0.5 ? begin.primaryColorBrightness : end.primaryColorBrightness,
      canvasColor: Color.lerp(begin.canvasColor, end.canvasColor, t),
      cardColor: Color.lerp(begin.cardColor, end.cardColor, t),
      dividerColor: Color.lerp(begin.dividerColor, end.dividerColor, t),
      highlightColor: Color.lerp(begin.highlightColor, end.highlightColor, t),
      splashColor: Color.lerp(begin.splashColor, end.splashColor, t),
      selectedRowColor: Color.lerp(begin.selectedRowColor, end.selectedRowColor, t),
      unselectedWidgetColor: Color.lerp(begin.unselectedWidgetColor, end.unselectedWidgetColor, t),
      disabledColor: Color.lerp(begin.disabledColor, end.disabledColor, t),
      buttonColor: Color.lerp(begin.buttonColor, end.buttonColor, t),
      secondaryHeaderColor: Color.lerp(begin.secondaryHeaderColor, end.secondaryHeaderColor, t),
      textSelectionColor: Color.lerp(begin.textSelectionColor, end.textSelectionColor, t),
      textSelectionHandleColor: Color.lerp(begin.textSelectionHandleColor, end.textSelectionHandleColor, t),
      backgroundColor: Color.lerp(begin.backgroundColor, end.backgroundColor, t),
      accentColor: Color.lerp(begin.accentColor, end.accentColor, t),
      accentColorBrightness: t < 0.5 ? begin.accentColorBrightness : end.accentColorBrightness,
      indicatorColor: Color.lerp(begin.indicatorColor, end.indicatorColor, t),
      hintColor: Color.lerp(begin.hintColor, end.hintColor, t),
      errorColor: Color.lerp(begin.errorColor, end.errorColor, t),
      textTheme: TextTheme.lerp(begin.textTheme, end.textTheme, t),
      primaryTextTheme: TextTheme.lerp(begin.primaryTextTheme, end.primaryTextTheme, t),
      iconTheme: IconThemeData.lerp(begin.iconTheme, end.iconTheme, t),
      primaryIconTheme: IconThemeData.lerp(begin.primaryIconTheme, end.primaryIconTheme, t),
      platform: t < 0.5 ? begin.platform : end.platform
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    ThemeData otherData = other;
    return (otherData.brightness == brightness) &&
           (otherData.primaryColor == primaryColor) &&
           (otherData.primaryColorBrightness == primaryColorBrightness) &&
           (otherData.canvasColor == canvasColor) &&
           (otherData.cardColor == cardColor) &&
           (otherData.dividerColor == dividerColor) &&
           (otherData.highlightColor == highlightColor) &&
           (otherData.splashColor == splashColor) &&
           (otherData.selectedRowColor == selectedRowColor) &&
           (otherData.unselectedWidgetColor == unselectedWidgetColor) &&
           (otherData.disabledColor == disabledColor) &&
           (otherData.buttonColor == buttonColor) &&
           (otherData.secondaryHeaderColor == secondaryHeaderColor) &&
           (otherData.textSelectionColor == textSelectionColor) &&
           (otherData.textSelectionHandleColor == textSelectionHandleColor) &&
           (otherData.backgroundColor == backgroundColor) &&
           (otherData.accentColor == accentColor) &&
           (otherData.accentColorBrightness == accentColorBrightness) &&
           (otherData.indicatorColor == indicatorColor) &&
           (otherData.hintColor == hintColor) &&
           (otherData.errorColor == errorColor) &&
           (otherData.textTheme == textTheme) &&
           (otherData.primaryTextTheme == primaryTextTheme) &&
           (otherData.iconTheme == iconTheme) &&
           (otherData.primaryIconTheme == primaryIconTheme);
  }

  @override
  int get hashCode {
    return hashValues(
      brightness,
      primaryColor,
      primaryColorBrightness,
      canvasColor,
      cardColor,
      dividerColor,
      highlightColor,
      splashColor,
      selectedRowColor,
      unselectedWidgetColor,
      disabledColor,
      buttonColor,
      secondaryHeaderColor,
      textSelectionColor,
      textSelectionHandleColor,
      backgroundColor,
      accentColor,
      accentColorBrightness,
      hashValues( // Too many values.
        indicatorColor,
        hintColor,
        errorColor,
        textTheme,
        primaryTextTheme,
        iconTheme,
        primaryIconTheme
      )
    );
  }

  @override
  String toString() => '$runtimeType($brightness $primaryColor etc...)';
}
