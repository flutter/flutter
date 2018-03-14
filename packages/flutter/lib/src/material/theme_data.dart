// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'ink_splash.dart';
import 'ink_well.dart' show InteractiveInkFeatureFactory;
import 'input_decorator.dart';
import 'slider_theme.dart';
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
///
/// To obtain the current theme, use [Theme.of].
@immutable
class ThemeData extends Diagnosticable {
  /// Create a [ThemeData] given a set of preferred values.
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
  /// See <https://material.google.com/style/color.html> for
  /// more discussion on how to pick the right colors.
  factory ThemeData({
    Brightness brightness,
    MaterialColor primarySwatch,
    Color primaryColor,
    Brightness primaryColorBrightness,
    Color primaryColorLight,
    Color primaryColorDark,
    Color accentColor,
    Brightness accentColorBrightness,
    Color canvasColor,
    Color scaffoldBackgroundColor,
    Color bottomAppBarColor,
    Color cardColor,
    Color dividerColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    Color buttonColor,
    ButtonThemeData buttonTheme,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    String fontFamily,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TargetPlatform platform,
  }) {
    brightness ??= Brightness.light;
    final bool isDark = brightness == Brightness.dark;
    primarySwatch ??= Colors.blue;
    primaryColor ??= isDark ? Colors.grey[900] : primarySwatch;
    primaryColorBrightness ??= estimateBrightnessForColor(primaryColor);
    primaryColorLight ??= isDark ? Colors.grey[500] : primarySwatch[100];
    primaryColorDark ??= isDark ? Colors.black : primarySwatch[700];
    final bool primaryIsDark = primaryColorBrightness == Brightness.dark;
    accentColor ??= isDark ? Colors.tealAccent[200] : primarySwatch[500];
    accentColorBrightness ??= estimateBrightnessForColor(accentColor);
    final bool accentIsDark = accentColorBrightness == Brightness.dark;
    canvasColor ??= isDark ? Colors.grey[850] : Colors.grey[50];
    scaffoldBackgroundColor ??= canvasColor;
    bottomAppBarColor ??= isDark ? Colors.grey[800] : Colors.white;
    cardColor ??= isDark ? Colors.grey[800] : Colors.white;
    dividerColor ??= isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);
    highlightColor ??= isDark ? _kDarkThemeHighlightColor : _kLightThemeHighlightColor;
    splashColor ??= isDark ? _kDarkThemeSplashColor : _kLightThemeSplashColor;
    splashFactory ??= InkSplash.splashFactory;
    selectedRowColor ??= Colors.grey[100];
    unselectedWidgetColor ??= isDark ? Colors.white70 : Colors.black54;
    disabledColor ??= isDark ? Colors.white30 : Colors.black26;
    buttonColor ??= isDark ? primarySwatch[600] : Colors.grey[300];
    buttonTheme ??= const ButtonThemeData();
    // Spec doesn't specify a dark theme secondaryHeaderColor, this is a guess.
    secondaryHeaderColor ??= isDark ? Colors.grey[700] : primarySwatch[50];
    textSelectionColor ??= isDark ? accentColor : primarySwatch[200];
    textSelectionHandleColor ??= isDark ? Colors.tealAccent[400] : primarySwatch[300];
    backgroundColor ??= isDark ? Colors.grey[700] : primarySwatch[200];
    dialogBackgroundColor ??= isDark ? Colors.grey[800] : Colors.white;
    indicatorColor ??= accentColor == primaryColor ? Colors.white : accentColor;
    hintColor ??= isDark ?  const Color(0x80FFFFFF) : const Color(0x8A000000);
    errorColor ??= Colors.red[700];
    inputDecorationTheme ??= const InputDecorationTheme();
    iconTheme ??= isDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    primaryIconTheme ??= primaryIsDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    accentIconTheme ??= accentIsDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    platform ??= defaultTargetPlatform;
    final Typography typography = new Typography(platform: platform);
    textTheme ??= isDark ? typography.white : typography.black;
    primaryTextTheme ??= primaryIsDark ? typography.white : typography.black;
    accentTextTheme ??= accentIsDark ? typography.white : typography.black;
    if (fontFamily != null) {
      textTheme = textTheme.apply(fontFamily: fontFamily);
      primaryTextTheme = primaryTextTheme.apply(fontFamily: fontFamily);
      accentTextTheme = accentTextTheme.apply(fontFamily: fontFamily);
    }
    sliderTheme ??= new SliderThemeData.fromPrimaryColors(
      primaryColor: primaryColor,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
    );
    return new ThemeData.raw(
      brightness: brightness,
      primaryColor: primaryColor,
      primaryColorBrightness: primaryColorBrightness,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      accentColor: accentColor,
      accentColorBrightness: accentColorBrightness,
      canvasColor: canvasColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      bottomAppBarColor: bottomAppBarColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      splashFactory: splashFactory,
      selectedRowColor: selectedRowColor,
      unselectedWidgetColor: unselectedWidgetColor,
      disabledColor: disabledColor,
      buttonColor: buttonColor,
      buttonTheme: buttonTheme,
      secondaryHeaderColor: secondaryHeaderColor,
      textSelectionColor: textSelectionColor,
      textSelectionHandleColor: textSelectionHandleColor,
      backgroundColor: backgroundColor,
      dialogBackgroundColor: dialogBackgroundColor,
      indicatorColor: indicatorColor,
      hintColor: hintColor,
      errorColor: errorColor,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      accentTextTheme: accentTextTheme,
      inputDecorationTheme: inputDecorationTheme,
      iconTheme: iconTheme,
      primaryIconTheme: primaryIconTheme,
      accentIconTheme: accentIconTheme,
      sliderTheme: sliderTheme,
      platform: platform,
    );
  }

  /// Create a [ThemeData] given a set of exact values. All the values
  /// must be specified.
  ///
  /// This will rarely be used directly. It is used by [lerp] to
  /// create intermediate themes based on two themes created with the
  /// [new ThemeData] constructor.
  const ThemeData.raw({
    @required this.brightness,
    @required this.primaryColor,
    @required this.primaryColorBrightness,
    @required this.primaryColorLight,
    @required this.primaryColorDark,
    @required this.accentColor,
    @required this.accentColorBrightness,
    @required this.canvasColor,
    @required this.scaffoldBackgroundColor,
    @required this.bottomAppBarColor,
    @required this.cardColor,
    @required this.dividerColor,
    @required this.highlightColor,
    @required this.splashColor,
    @required this.splashFactory,
    @required this.selectedRowColor,
    @required this.unselectedWidgetColor,
    @required this.disabledColor,
    @required this.buttonColor,
    @required this.buttonTheme,
    @required this.secondaryHeaderColor,
    @required this.textSelectionColor,
    @required this.textSelectionHandleColor,
    @required this.backgroundColor,
    @required this.dialogBackgroundColor,
    @required this.indicatorColor,
    @required this.hintColor,
    @required this.errorColor,
    @required this.textTheme,
    @required this.primaryTextTheme,
    @required this.accentTextTheme,
    @required this.inputDecorationTheme,
    @required this.iconTheme,
    @required this.primaryIconTheme,
    @required this.accentIconTheme,
    @required this.sliderTheme,
    @required this.platform,
  }) : assert(brightness != null),
       assert(primaryColor != null),
       assert(primaryColorBrightness != null),
       assert(primaryColorLight != null),
       assert(primaryColorDark != null),
       assert(accentColor != null),
       assert(accentColorBrightness != null),
       assert(canvasColor != null),
       assert(scaffoldBackgroundColor != null),
       assert(bottomAppBarColor != null),
       assert(cardColor != null),
       assert(dividerColor != null),
       assert(highlightColor != null),
       assert(splashColor != null),
       assert(splashFactory != null),
       assert(selectedRowColor != null),
       assert(unselectedWidgetColor != null),
       assert(disabledColor != null),
       assert(buttonTheme != null),
       assert(secondaryHeaderColor != null),
       assert(textSelectionColor != null),
       assert(textSelectionHandleColor != null),
       assert(backgroundColor != null),
       assert(dialogBackgroundColor != null),
       assert(indicatorColor != null),
       assert(hintColor != null),
       assert(errorColor != null),
       assert(textTheme != null),
       assert(primaryTextTheme != null),
       assert(accentTextTheme != null),
       assert(inputDecorationTheme != null),
       assert(iconTheme != null),
       assert(primaryIconTheme != null),
       assert(accentIconTheme != null),
       assert(sliderTheme != null),
       assert(platform != null);

  /// A default light blue theme.
  ///
  /// This theme does not contain text geometry. Instead, it is expected that
  /// this theme is localized using text geometry using [ThemeData.localize].
  factory ThemeData.light() => new ThemeData(brightness: Brightness.light);

  /// A default dark theme with a teal accent color.
  ///
  /// This theme does not contain text geometry. Instead, it is expected that
  /// this theme is localized using text geometry using [ThemeData.localize].
  factory ThemeData.dark() => new ThemeData(brightness: Brightness.dark);

  /// The default color theme. Same as [new ThemeData.light].
  ///
  /// This is used by [Theme.of] when no theme has been specified.
  ///
  /// This theme does not contain text geometry. Instead, it is expected that
  /// this theme is localized using text geometry using [ThemeData.localize].
  ///
  /// Most applications would use [Theme.of], which provides correct localized
  /// text geometry.
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

  /// The brightness of the [primaryColor]. Used to determine the color of text and
  /// icons placed on top of the primary color (e.g. toolbar text).
  final Brightness primaryColorBrightness;

  /// A lighter version of the [primaryColor].
  final Color primaryColorLight;

  /// A darker version of the [primaryColor].
  final Color primaryColorDark;

  /// The foreground color for widgets (knobs, text, overscroll edge effect, etc).
  final Color accentColor;

  /// The brightness of the [accentColor]. Used to determine the color of text
  /// and icons placed on top of the accent color (e.g. the icons on a floating
  /// action button).
  final Brightness accentColorBrightness;

  /// The default color of [MaterialType.canvas] [Material].
  final Color canvasColor;

  /// The default color of the [Material] that underlies the [Scaffold]. The
  /// background color for a typical material app or a page within the app.
  final Color scaffoldBackgroundColor;

  /// The default color of the [BottomAppBar].
  ///
  /// This can be overridden by specifying [BottomAppBar.color].
  final Color bottomAppBarColor;

  /// The color of [Material] when it is used as a [Card].
  final Color cardColor;

  /// The color of [Divider]s and [PopupMenuDivider]s, also used
  /// between [ListTile]s, between rows in [DataTable]s, and so forth.
  ///
  /// To create an appropriate [BorderSide] that uses this color, consider
  /// [Divider.createBorderSide].
  final Color dividerColor;

  /// The highlight color used during ink splash animations or to
  /// indicate an item in a menu is selected.
  final Color highlightColor;

  /// The color of ink splashes. See [InkWell].
  final Color splashColor;

  /// Defines the appearance of ink splashes produces by [InkWell]
  /// and [InkResponse].
  ///
  /// See also:
  ///
  ///  * [InkSplash.splashFactory], which defines the default splash.
  ///  * [InkRipple.splashFactory], which defines a splash that spreads out
  ///    more aggressively than the default.
  final InteractiveInkFeatureFactory splashFactory;

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

  /// The default fill color of the [Material] used in [RaisedButton]s.
  final Color buttonColor;

  /// Defines the default configuration of button widgets, like [RaisedButton]
  /// and [FlatButton].
  final ButtonThemeData buttonTheme;

  /// The color of the header of a [PaginatedDataTable] when there are selected rows.
  // According to the spec for data tables:
  // https://material.google.com/components/data-tables.html#data-tables-tables-within-cards
  // ...this should be the "50-value of secondary app color".
  final Color secondaryHeaderColor;

  /// The color of text selections in text fields, such as [TextField].
  final Color textSelectionColor;

  /// The color of the handles used to adjust what part of the text is currently selected.
  final Color textSelectionHandleColor;

  /// A color that contrasts with the [primaryColor], e.g. used as the
  /// remaining part of a progress bar.
  final Color backgroundColor;

  /// The background color of [Dialog] elements.
  final Color dialogBackgroundColor;

  /// The color of the selected tab indicator in a tab bar.
  final Color indicatorColor;

  /// The color to use for hint text or placeholder text, e.g. in
  /// [TextField] fields.
  final Color hintColor;

  /// The color to use for input validation errors, e.g. in [TextField] fields.
  final Color errorColor;

  /// Text with a color that contrasts with the card and canvas colors.
  final TextTheme textTheme;

  /// A text theme that contrasts with the primary color.
  final TextTheme primaryTextTheme;

  /// A text theme that contrasts with the accent color.
  final TextTheme accentTextTheme;

  /// The default [InputDecoration] values for [InputDecorator], [TextField],
  /// and [TextFormField] are based on this theme.
  ///
  /// See [InputDecoration.applyDefaults].
  final InputDecorationTheme inputDecorationTheme;

  /// An icon theme that contrasts with the card and canvas colors.
  final IconThemeData iconTheme;

  /// An icon theme that contrasts with the primary color.
  final IconThemeData primaryIconTheme;

  /// An icon theme that contrasts with the accent color.
  final IconThemeData accentIconTheme;

  /// The colors and shapes used to render [Slider].
  ///
  /// This is the value returned from [SliderTheme.of].
  final SliderThemeData sliderTheme;

  /// The platform the material widgets should adapt to target.
  ///
  /// Defaults to the current platform.
  final TargetPlatform platform;

  /// Creates a copy of this theme but with the given fields replaced with the new values.
  ThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Brightness primaryColorBrightness,
    Color primaryColorLight,
    Color primaryColorDark,
    Color accentColor,
    Brightness accentColorBrightness,
    Color canvasColor,
    Color scaffoldBackgroundColor,
    Color bottomAppBarColor,
    Color cardColor,
    Color dividerColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    Color buttonColor,
    ButtonThemeData buttonTheme,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TargetPlatform platform,
  }) {
    return new ThemeData.raw(
      brightness: brightness ?? this.brightness,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryColorBrightness: primaryColorBrightness ?? this.primaryColorBrightness,
      primaryColorLight: primaryColorLight ?? this.primaryColorLight,
      primaryColorDark: primaryColorDark ?? this.primaryColorDark,
      accentColor: accentColor ?? this.accentColor,
      accentColorBrightness: accentColorBrightness ?? this.accentColorBrightness,
      canvasColor: canvasColor ?? this.canvasColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      bottomAppBarColor: bottomAppBarColor ?? this.bottomAppBarColor,
      cardColor: cardColor ?? this.cardColor,
      dividerColor: dividerColor ?? this.dividerColor,
      highlightColor: highlightColor ?? this.highlightColor,
      splashColor: splashColor ?? this.splashColor,
      splashFactory: splashFactory ?? this.splashFactory,
      selectedRowColor: selectedRowColor ?? this.selectedRowColor,
      unselectedWidgetColor: unselectedWidgetColor ?? this.unselectedWidgetColor,
      disabledColor: disabledColor ?? this.disabledColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTheme: buttonTheme ?? this.buttonTheme,
      secondaryHeaderColor: secondaryHeaderColor ?? this.secondaryHeaderColor,
      textSelectionColor: textSelectionColor ?? this.textSelectionColor,
      textSelectionHandleColor: textSelectionHandleColor ?? this.textSelectionHandleColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      dialogBackgroundColor: dialogBackgroundColor ?? this.dialogBackgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      hintColor: hintColor ?? this.hintColor,
      errorColor: errorColor ?? this.errorColor,
      textTheme: textTheme ?? this.textTheme,
      primaryTextTheme: primaryTextTheme ?? this.primaryTextTheme,
      accentTextTheme: accentTextTheme ?? this.accentTextTheme,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      iconTheme: iconTheme ?? this.iconTheme,
      primaryIconTheme: primaryIconTheme ?? this.primaryIconTheme,
      accentIconTheme: accentIconTheme ?? this.accentIconTheme,
      sliderTheme: sliderTheme ?? this.sliderTheme,
      platform: platform ?? this.platform,
    );
  }

  // The number 5 was chosen without any real science or research behind it. It
  // just seemed like a number that's not too big (we should be able to fit 5
  // copies of ThemeData in memory comfortably) and not too small (most apps
  // shouldn't have more than 5 theme/localization pairs).
  static const int _localizedThemeDataCacheSize = 5;

  /// Caches localized themes to speed up the [localize] method.
  static final _FifoCache<_IdentityThemeDataCacheKey, ThemeData> _localizedThemeDataCache =
      new _FifoCache<_IdentityThemeDataCacheKey, ThemeData>(_localizedThemeDataCacheSize);

  /// Returns a new theme built by merging the text geometry provided by the
  /// [localTextGeometry] theme with the [baseTheme].
  ///
  /// For those text styles in the [baseTheme] whose [TextStyle.inherit] is set
  /// to true, the returned theme's text styles inherit the geometric properties
  /// of [localTextGeometry]. The resulting text styles' [TextStyle.inherit] is
  /// set to those provided by [localTextGeometry].
  static ThemeData localize(ThemeData baseTheme, TextTheme localTextGeometry) {
    // WARNING: this method memoizes the result in a cache based on the
    // previously seen baseTheme and localTextGeometry. Memoization is safe
    // because all inputs and outputs of this function are deeply immutable, and
    // the computations are referentially transparent. It only short-circuits
    // the computation if the new inputs are identical() to the previous ones.
    // It does not use the == operator, which performs a costly deep comparison.
    //
    // When changing this method, make sure the memoization logic is correct.
    // Remember:
    //
    // There are only two hard things in Computer Science: cache invalidation
    // and naming things. -- Phil Karlton
    assert(baseTheme != null);
    assert(localTextGeometry != null);

    return _localizedThemeDataCache.putIfAbsent(
      new _IdentityThemeDataCacheKey(baseTheme, localTextGeometry),
      () {
        return baseTheme.copyWith(
          primaryTextTheme: localTextGeometry.merge(baseTheme.primaryTextTheme),
          accentTextTheme: localTextGeometry.merge(baseTheme.accentTextTheme),
          textTheme: localTextGeometry.merge(baseTheme.textTheme),
        );
      },
    );
  }

  /// Determines whether the given [Color] is [Brightness.light] or
  /// [Brightness.dark].
  ///
  /// This compares the luminosity of the given color to a threshold value that
  /// matches the material design specification.
  static Brightness estimateBrightnessForColor(Color color) {
    final double relativeLuminance = color.computeLuminance();

    // See <https://www.w3.org/TR/WCAG20/#contrast-ratiodef>
    // The spec says to use kThreshold=0.0525, but Material Design appears to bias
    // more towards using light text than WCAG20 recommends. Material Design spec
    // doesn't say what value to use, but 0.15 seemed close to what the Material
    // Design spec shows for its color palette on
    // <https://material.io/guidelines/style/color.html#color-color-palette>.
    const double kThreshold = 0.15;
    if ((relativeLuminance + 0.05) * (relativeLuminance + 0.05) > kThreshold)
      return Brightness.light;
    return Brightness.dark;
  }

  /// Linearly interpolate between two themes.
  ///
  /// The arguments must not be null.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static ThemeData lerp(ThemeData a, ThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return new ThemeData.raw(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      primaryColor: Color.lerp(a.primaryColor, b.primaryColor, t),
      primaryColorBrightness: t < 0.5 ? a.primaryColorBrightness : b.primaryColorBrightness,
      primaryColorLight: Color.lerp(a.primaryColorLight, b.primaryColorLight, t),
      primaryColorDark: Color.lerp(a.primaryColorDark, b.primaryColorDark, t),
      canvasColor: Color.lerp(a.canvasColor, b.canvasColor, t),
      scaffoldBackgroundColor: Color.lerp(a.scaffoldBackgroundColor, b.scaffoldBackgroundColor, t),
      bottomAppBarColor: Color.lerp(a.bottomAppBarColor, b.bottomAppBarColor, t),
      cardColor: Color.lerp(a.cardColor, b.cardColor, t),
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t),
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t),
      splashColor: Color.lerp(a.splashColor, b.splashColor, t),
      splashFactory: t < 0.5 ? a.splashFactory : b.splashFactory,
      selectedRowColor: Color.lerp(a.selectedRowColor, b.selectedRowColor, t),
      unselectedWidgetColor: Color.lerp(a.unselectedWidgetColor, b.unselectedWidgetColor, t),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      buttonColor: Color.lerp(a.buttonColor, b.buttonColor, t),
      buttonTheme: t < 0.5 ? a.buttonTheme : b.buttonTheme,
      secondaryHeaderColor: Color.lerp(a.secondaryHeaderColor, b.secondaryHeaderColor, t),
      textSelectionColor: Color.lerp(a.textSelectionColor, b.textSelectionColor, t),
      textSelectionHandleColor: Color.lerp(a.textSelectionHandleColor, b.textSelectionHandleColor, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      dialogBackgroundColor: Color.lerp(a.dialogBackgroundColor, b.dialogBackgroundColor, t),
      accentColor: Color.lerp(a.accentColor, b.accentColor, t),
      accentColorBrightness: t < 0.5 ? a.accentColorBrightness : b.accentColorBrightness,
      indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t),
      hintColor: Color.lerp(a.hintColor, b.hintColor, t),
      errorColor: Color.lerp(a.errorColor, b.errorColor, t),
      textTheme: TextTheme.lerp(a.textTheme, b.textTheme, t),
      primaryTextTheme: TextTheme.lerp(a.primaryTextTheme, b.primaryTextTheme, t),
      accentTextTheme: TextTheme.lerp(a.accentTextTheme, b.accentTextTheme, t),
      inputDecorationTheme: t < 0.5 ? a.inputDecorationTheme : b.inputDecorationTheme,
      iconTheme: IconThemeData.lerp(a.iconTheme, b.iconTheme, t),
      primaryIconTheme: IconThemeData.lerp(a.primaryIconTheme, b.primaryIconTheme, t),
      accentIconTheme: IconThemeData.lerp(a.accentIconTheme, b.accentIconTheme, t),
      sliderTheme: SliderThemeData.lerp(a.sliderTheme, b.sliderTheme, t),
      platform: t < 0.5 ? a.platform : b.platform,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ThemeData otherData = other;
    return (otherData.brightness == brightness) &&
           (otherData.primaryColor == primaryColor) &&
           (otherData.primaryColorBrightness == primaryColorBrightness) &&
           (otherData.canvasColor == canvasColor) &&
           (otherData.scaffoldBackgroundColor == scaffoldBackgroundColor) &&
           (otherData.bottomAppBarColor == bottomAppBarColor) &&
           (otherData.cardColor == cardColor) &&
           (otherData.dividerColor == dividerColor) &&
           (otherData.highlightColor == highlightColor) &&
           (otherData.splashColor == splashColor) &&
           (otherData.splashFactory == splashFactory) &&
           (otherData.selectedRowColor == selectedRowColor) &&
           (otherData.unselectedWidgetColor == unselectedWidgetColor) &&
           (otherData.disabledColor == disabledColor) &&
           (otherData.buttonColor == buttonColor) &&
           (otherData.buttonTheme == buttonTheme) &&
           (otherData.secondaryHeaderColor == secondaryHeaderColor) &&
           (otherData.textSelectionColor == textSelectionColor) &&
           (otherData.textSelectionHandleColor == textSelectionHandleColor) &&
           (otherData.backgroundColor == backgroundColor) &&
           (otherData.dialogBackgroundColor == dialogBackgroundColor) &&
           (otherData.accentColor == accentColor) &&
           (otherData.accentColorBrightness == accentColorBrightness) &&
           (otherData.indicatorColor == indicatorColor) &&
           (otherData.hintColor == hintColor) &&
           (otherData.errorColor == errorColor) &&
           (otherData.textTheme == textTheme) &&
           (otherData.primaryTextTheme == primaryTextTheme) &&
           (otherData.accentTextTheme == accentTextTheme) &&
           (otherData.inputDecorationTheme == inputDecorationTheme) &&
           (otherData.iconTheme == iconTheme) &&
           (otherData.primaryIconTheme == primaryIconTheme) &&
           (otherData.accentIconTheme == accentIconTheme) &&
           (otherData.sliderTheme == sliderTheme) &&
           (otherData.platform == platform);
  }

  @override
  int get hashCode {
    return hashValues(
      brightness,
      primaryColor,
      primaryColorBrightness,
      canvasColor,
      scaffoldBackgroundColor,
      bottomAppBarColor,
      cardColor,
      dividerColor,
      highlightColor,
      splashColor,
      splashFactory,
      selectedRowColor,
      unselectedWidgetColor,
      disabledColor,
      buttonColor,
      buttonTheme,
      secondaryHeaderColor,
      textSelectionColor,
      textSelectionHandleColor,
      hashValues(  // Too many values.
        backgroundColor,
        accentColor,
        accentColorBrightness,
        indicatorColor,
        dialogBackgroundColor,
        hintColor,
        errorColor,
        textTheme,
        primaryTextTheme,
        accentTextTheme,
        iconTheme,
        inputDecorationTheme,
        primaryIconTheme,
        accentIconTheme,
        sliderTheme,
        platform,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    final ThemeData defaultData = new ThemeData.fallback();
    description.add(new EnumProperty<TargetPlatform>('platform', platform, defaultValue: defaultTargetPlatform));
    description.add(new EnumProperty<Brightness>('brightness', brightness, defaultValue: defaultData.brightness));
    description.add(new DiagnosticsProperty<Color>('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    description.add(new EnumProperty<Brightness>('primaryColorBrightness', primaryColorBrightness, defaultValue: defaultData.primaryColorBrightness));
    description.add(new DiagnosticsProperty<Color>('accentColor', accentColor, defaultValue: defaultData.accentColor));
    description.add(new EnumProperty<Brightness>('accentColorBrightness', accentColorBrightness, defaultValue: defaultData.accentColorBrightness));
    description.add(new DiagnosticsProperty<Color>('canvasColor', canvasColor, defaultValue: defaultData.canvasColor));
    description.add(new DiagnosticsProperty<Color>('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    description.add(new DiagnosticsProperty<Color>('bottomAppBarColor', bottomAppBarColor, defaultValue: defaultData.bottomAppBarColor));
    description.add(new DiagnosticsProperty<Color>('cardColor', cardColor, defaultValue: defaultData.cardColor));
    description.add(new DiagnosticsProperty<Color>('dividerColor', dividerColor, defaultValue: defaultData.dividerColor));
    description.add(new DiagnosticsProperty<Color>('highlightColor', highlightColor, defaultValue: defaultData.highlightColor));
    description.add(new DiagnosticsProperty<Color>('splashColor', splashColor, defaultValue: defaultData.splashColor));
    description.add(new DiagnosticsProperty<Color>('selectedRowColor', selectedRowColor, defaultValue: defaultData.selectedRowColor));
    description.add(new DiagnosticsProperty<Color>('unselectedWidgetColor', unselectedWidgetColor, defaultValue: defaultData.unselectedWidgetColor));
    description.add(new DiagnosticsProperty<Color>('disabledColor', disabledColor, defaultValue: defaultData.disabledColor));
    description.add(new DiagnosticsProperty<Color>('buttonColor', buttonColor, defaultValue: defaultData.buttonColor));
    description.add(new DiagnosticsProperty<Color>('secondaryHeaderColor', secondaryHeaderColor, defaultValue: defaultData.secondaryHeaderColor));
    description.add(new DiagnosticsProperty<Color>('textSelectionColor', textSelectionColor, defaultValue: defaultData.textSelectionColor));
    description.add(new DiagnosticsProperty<Color>('textSelectionHandleColor', textSelectionHandleColor, defaultValue: defaultData.textSelectionHandleColor));
    description.add(new DiagnosticsProperty<Color>('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    description.add(new DiagnosticsProperty<Color>('dialogBackgroundColor', dialogBackgroundColor, defaultValue: defaultData.dialogBackgroundColor));
    description.add(new DiagnosticsProperty<Color>('indicatorColor', indicatorColor, defaultValue: defaultData.indicatorColor));
    description.add(new DiagnosticsProperty<Color>('hintColor', hintColor, defaultValue: defaultData.hintColor));
    description.add(new DiagnosticsProperty<Color>('errorColor', errorColor, defaultValue: defaultData.errorColor));
    description.add(new DiagnosticsProperty<ButtonThemeData>('buttonTheme', buttonTheme));
    description.add(new DiagnosticsProperty<TextTheme>('textTheme', textTheme));
    description.add(new DiagnosticsProperty<TextTheme>('primaryTextTheme', primaryTextTheme));
    description.add(new DiagnosticsProperty<TextTheme>('accentTextTheme', accentTextTheme));
    description.add(new DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme));
    description.add(new DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme));
    description.add(new DiagnosticsProperty<IconThemeData>('primaryIconTheme', primaryIconTheme));
    description.add(new DiagnosticsProperty<IconThemeData>('accentIconTheme', accentIconTheme));
    description.add(new DiagnosticsProperty<SliderThemeData>('sliderTheme', sliderTheme));
  }
}

class _IdentityThemeDataCacheKey {
  _IdentityThemeDataCacheKey(this.baseTheme, this.localTextGeometry);

  final ThemeData baseTheme;
  final TextTheme localTextGeometry;

  // Using XOR to make the hash function as fast as possible (e.g. Jenkins is
  // noticeably slower).
  @override
  int get hashCode => identityHashCode(baseTheme) ^ identityHashCode(localTextGeometry);

  @override
  bool operator ==(Object other) {
    // We are explicitly ignoring the possibility that the types might not
    // match in the interests of speed.
    final _IdentityThemeDataCacheKey otherKey = other;
    return identical(baseTheme, otherKey.baseTheme) && identical(localTextGeometry, otherKey.localTextGeometry);
  }
}

/// Cache of objects of limited size that uses the first in first out eviction
/// strategy (a.k.a least recently inserted).
///
/// The key that was inserted before all other keys is evicted first, i.e. the
/// one inserted least recently.
class _FifoCache<K, V> {
  _FifoCache(this._maximumSize) : assert(_maximumSize != null && _maximumSize > 0);

  /// In Dart the map literal uses a linked hash-map implementation, whose keys
  /// are stored such that [Map.keys] returns them in the order they were
  /// inserted.
  final Map<K, V> _cache = <K, V>{};

  /// Maximum number of entries to store in the cache.
  ///
  /// Once this many entries have been cached, the entry inserted least recently
  /// is evicted when adding a new entry.
  final int _maximumSize;

  /// Returns the previously cached value for the given key, if available;
  /// if not, calls the given callback to obtain it first.
  ///
  /// The arguments must not be null.
  V putIfAbsent(K key, V loader()) {
    assert(key != null);
    assert(loader != null);
    final V result = _cache[key];
    if (result != null)
      return result;
    if (_cache.length == _maximumSize)
      _cache.remove(_cache.keys.first);
    return _cache[key] = loader();
  }
}
