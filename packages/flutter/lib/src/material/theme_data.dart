// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, hashList;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_bar_theme.dart';
import 'banner_theme.dart';
import 'bottom_app_bar_theme.dart';
import 'bottom_sheet_theme.dart';
import 'button_bar_theme.dart';
import 'button_theme.dart';
import 'card_theme.dart';
import 'chip_theme.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'dialog_theme.dart';
import 'divider_theme.dart';
import 'floating_action_button_theme.dart';
import 'ink_splash.dart';
import 'ink_well.dart' show InteractiveInkFeatureFactory;
import 'input_decorator.dart';
import 'page_transitions_theme.dart';
import 'popup_menu_theme.dart';
import 'slider_theme.dart';
import 'snack_bar_theme.dart';
import 'tab_bar_theme.dart';
import 'text_theme.dart';
import 'toggle_buttons_theme.dart';
import 'tooltip_theme.dart';
import 'typography.dart';

export 'package:flutter/services.dart' show Brightness;

// Deriving these values is black magic. The spec claims that pressed buttons
// have a highlight of 0x66999999, but that's clearly wrong. The videos in the
// spec show that buttons have a composited highlight of #E1E1E1 on a background
// of #FAFAFA. Assuming that the highlight really has an opacity of 0x66, we can
// solve for the actual color of the highlight:
const Color _kLightThemeHighlightColor = Color(0x66BCBCBC);

// The same video shows the splash compositing to #D7D7D7 on a background of
// #E1E1E1. Again, assuming the splash has an opacity of 0x66, we can solve for
// the actual color of the splash:
const Color _kLightThemeSplashColor = Color(0x66C8C8C8);

// Unfortunately, a similar video isn't available for the dark theme, which
// means we assume the values in the spec are actually correct.
const Color _kDarkThemeHighlightColor = Color(0x40CCCCCC);
const Color _kDarkThemeSplashColor = Color(0x40CCCCCC);

/// Configures the tap target and layout size of certain Material widgets.
///
/// Changing the value in [ThemeData.materialTapTargetSize] will affect the
/// accessibility experience.
///
/// Some of the impacted widgets include:
///
///   * [FloatingActionButton], only the mini tap target size is increased.
///   * [MaterialButton]
///   * [OutlineButton]
///   * [FlatButton]
///   * [RaisedButton]
///   * [TimePicker]
///   * [SnackBar]
///   * [Chip]
///   * [RawChip]
///   * [InputChip]
///   * [ChoiceChip]
///   * [FilterChip]
///   * [ActionChip]
///   * [Radio]
///   * [Switch]
///   * [Checkbox]
enum MaterialTapTargetSize {
  /// Expands the minimum tap target size to 48px by 48px.
  ///
  /// This is the default value of [ThemeData.materialHitTestSize] and the
  /// recommended size to conform to Android accessibility scanner
  /// recommendations.
  padded,

  /// Shrinks the tap target size to the minimum provided by the Material
  /// specification.
  shrinkWrap,
}

/// Holds the color and typography values for a material design theme.
///
/// Use this class to configure a [Theme] or [MaterialApp] widget.
///
/// To obtain the current theme, use [Theme.of].
///
/// {@tool sample}
///
/// This sample creates a [Theme] widget that stores the `ThemeData`. The
/// `ThemeData` can be accessed by descendant Widgets that use the correct
/// `context`. This example uses the [Builder] widget to gain access to a
/// descendant `context` that contains the `ThemeData`.
///
/// The [Container] widget uses [Theme.of] to retrieve the [primaryColor] from
/// the `ThemeData` to draw an amber square.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/theme_data.png)
///
/// ```dart
/// Theme(
///   data: ThemeData(primaryColor: Colors.amber),
///   child: Builder(
///     builder: (BuildContext context) {
///       return Container(
///         width: 100,
///         height: 100,
///         color: Theme.of(context).primaryColor,
///       );
///     },
///   ),
/// )
/// ```
/// {@end-tool}
///
/// In addition to using the [Theme] widget, you can provide `ThemeData` to a
/// [MaterialApp]. The `ThemeData` will be used throughout the app to style
/// material design widgets.
///
/// {@tool sample}
///
/// This sample creates a [MaterialApp] widget that stores `ThemeData` and
/// passes the `ThemeData` to descendant widgets. The [AppBar] widget uses the
/// [primaryColor] to create a blue background. The [Text] widget uses the
/// [TextTheme.body1] to create purple text. The [FloatingActionButton] widget
/// uses the [accentColor] to create a green background.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/material/material_app_theme_data.png)
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     primaryColor: Colors.blue,
///     accentColor: Colors.green,
///     textTheme: TextTheme(body1: TextStyle(color: Colors.purple)),
///   ),
///   home: Scaffold(
///     appBar: AppBar(
///       title: const Text('ThemeData Demo'),
///     ),
///     floatingActionButton: FloatingActionButton(
///       child: const Icon(Icons.add),
///       onPressed: () {},
///     ),
///     body: Center(
///       child: Text(
///         'Button pressed 0 times',
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
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
  /// See <https://material.io/design/color/> for
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
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    Color buttonColor,
    ButtonThemeData buttonTheme,
    ToggleButtonsThemeData toggleButtonsTheme,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color cursorColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    Color toggleableActiveColor,
    String fontFamily,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TabBarTheme tabBarTheme,
    TooltipThemeData tooltipTheme,
    CardTheme cardTheme,
    ChipThemeData chipTheme,
    TargetPlatform platform,
    MaterialTapTargetSize materialTapTargetSize,
    bool applyElevationOverlayColor,
    PageTransitionsTheme pageTransitionsTheme,
    AppBarTheme appBarTheme,
    BottomAppBarTheme bottomAppBarTheme,
    ColorScheme colorScheme,
    DialogTheme dialogTheme,
    FloatingActionButtonThemeData floatingActionButtonTheme,
    Typography typography,
    CupertinoThemeData cupertinoOverrideTheme,
    SnackBarThemeData snackBarTheme,
    BottomSheetThemeData bottomSheetTheme,
    PopupMenuThemeData popupMenuTheme,
    MaterialBannerThemeData bannerTheme,
    DividerThemeData dividerTheme,
    ButtonBarThemeData buttonBarTheme,
  }) {
    brightness ??= Brightness.light;
    final bool isDark = brightness == Brightness.dark;
    primarySwatch ??= Colors.blue;
    primaryColor ??= isDark ? Colors.grey[900] : primarySwatch;
    primaryColorBrightness ??= estimateBrightnessForColor(primaryColor);
    primaryColorLight ??= isDark ? Colors.grey[500] : primarySwatch[100];
    primaryColorDark ??= isDark ? Colors.black : primarySwatch[700];
    final bool primaryIsDark = primaryColorBrightness == Brightness.dark;
    toggleableActiveColor ??= isDark ? Colors.tealAccent[200] : (accentColor ?? primarySwatch[600]);
    accentColor ??= isDark ? Colors.tealAccent[200] : primarySwatch[500];
    accentColorBrightness ??= estimateBrightnessForColor(accentColor);
    final bool accentIsDark = accentColorBrightness == Brightness.dark;
    canvasColor ??= isDark ? Colors.grey[850] : Colors.grey[50];
    scaffoldBackgroundColor ??= canvasColor;
    bottomAppBarColor ??= isDark ? Colors.grey[800] : Colors.white;
    cardColor ??= isDark ? Colors.grey[800] : Colors.white;
    dividerColor ??= isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);

    // Create a ColorScheme that is backwards compatible as possible
    // with the existing default ThemeData color values.
    colorScheme ??= ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      primaryColorDark: primaryColorDark,
      accentColor: accentColor,
      cardColor: cardColor,
      backgroundColor: backgroundColor,
      errorColor: errorColor,
      brightness: brightness,
    );

    splashFactory ??= InkSplash.splashFactory;
    selectedRowColor ??= Colors.grey[100];
    unselectedWidgetColor ??= isDark ? Colors.white70 : Colors.black54;
    // Spec doesn't specify a dark theme secondaryHeaderColor, this is a guess.
    secondaryHeaderColor ??= isDark ? Colors.grey[700] : primarySwatch[50];
    textSelectionColor ??= isDark ? accentColor : primarySwatch[200];
    // TODO(sandrasandeep): change to color provided by Material Design team
    cursorColor = cursorColor ?? const Color.fromRGBO(66, 133, 244, 1.0);
    textSelectionHandleColor ??= isDark ? Colors.tealAccent[400] : primarySwatch[300];
    backgroundColor ??= isDark ? Colors.grey[700] : primarySwatch[200];
    dialogBackgroundColor ??= isDark ? Colors.grey[800] : Colors.white;
    indicatorColor ??= accentColor == primaryColor ? Colors.white : accentColor;
    hintColor ??= isDark ? const Color(0x80FFFFFF) : const Color(0x8A000000);
    errorColor ??= Colors.red[700];
    inputDecorationTheme ??= const InputDecorationTheme();
    pageTransitionsTheme ??= const PageTransitionsTheme();
    primaryIconTheme ??= primaryIsDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    accentIconTheme ??= accentIsDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black);
    iconTheme ??= isDark ? const IconThemeData(color: Colors.white) : const IconThemeData(color: Colors.black87);
    platform ??= defaultTargetPlatform;
    typography ??= Typography(platform: platform);
    final TextTheme defaultTextTheme = isDark ? typography.white : typography.black;
    textTheme = defaultTextTheme.merge(textTheme);
    final TextTheme defaultPrimaryTextTheme = primaryIsDark ? typography.white : typography.black;
    primaryTextTheme = defaultPrimaryTextTheme.merge(primaryTextTheme);
    final TextTheme defaultAccentTextTheme = accentIsDark ? typography.white : typography.black;
    accentTextTheme = defaultAccentTextTheme.merge(accentTextTheme);
    materialTapTargetSize ??= MaterialTapTargetSize.padded;
    applyElevationOverlayColor ??= false;
    if (fontFamily != null) {
      textTheme = textTheme.apply(fontFamily: fontFamily);
      primaryTextTheme = primaryTextTheme.apply(fontFamily: fontFamily);
      accentTextTheme = accentTextTheme.apply(fontFamily: fontFamily);
    }

    // Used as the default color (fill color) for RaisedButtons. Computing the
    // default for ButtonThemeData for the sake of backwards compatibility.
    buttonColor ??= isDark ? primarySwatch[600] : Colors.grey[300];
    focusColor ??= isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12);
    hoverColor ??= isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04);
    buttonTheme ??= ButtonThemeData(
      colorScheme: colorScheme,
      buttonColor: buttonColor,
      disabledColor: disabledColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      materialTapTargetSize: materialTapTargetSize,
    );
    toggleButtonsTheme ??= const ToggleButtonsThemeData();
    disabledColor ??= isDark ? Colors.white38 : Colors.black38;
    highlightColor ??= isDark ? _kDarkThemeHighlightColor : _kLightThemeHighlightColor;
    splashColor ??= isDark ? _kDarkThemeSplashColor : _kLightThemeSplashColor;

    sliderTheme ??= const SliderThemeData();
    tabBarTheme ??= const TabBarTheme();
    tooltipTheme ??= const TooltipThemeData();
    appBarTheme ??= const AppBarTheme();
    bottomAppBarTheme ??= const BottomAppBarTheme();
    cardTheme ??= const CardTheme();
    chipTheme ??= ChipThemeData.fromDefaults(
      secondaryColor: primaryColor,
      brightness: brightness,
      labelStyle: textTheme.body2,
    );
    dialogTheme ??= const DialogTheme();
    floatingActionButtonTheme ??= const FloatingActionButtonThemeData();
    cupertinoOverrideTheme = cupertinoOverrideTheme?.noDefault();
    snackBarTheme ??= const SnackBarThemeData();
    bottomSheetTheme ??= const BottomSheetThemeData();
    popupMenuTheme ??= const PopupMenuThemeData();
    bannerTheme ??= const MaterialBannerThemeData();
    dividerTheme ??= const DividerThemeData();
    buttonBarTheme ??= const ButtonBarThemeData();

    return ThemeData.raw(
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
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      splashFactory: splashFactory,
      selectedRowColor: selectedRowColor,
      unselectedWidgetColor: unselectedWidgetColor,
      disabledColor: disabledColor,
      buttonTheme: buttonTheme,
      buttonColor: buttonColor,
      toggleButtonsTheme: toggleButtonsTheme,
      toggleableActiveColor: toggleableActiveColor,
      secondaryHeaderColor: secondaryHeaderColor,
      textSelectionColor: textSelectionColor,
      cursorColor: cursorColor,
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
      tabBarTheme: tabBarTheme,
      tooltipTheme: tooltipTheme,
      cardTheme: cardTheme,
      chipTheme: chipTheme,
      platform: platform,
      materialTapTargetSize: materialTapTargetSize,
      applyElevationOverlayColor: applyElevationOverlayColor,
      pageTransitionsTheme: pageTransitionsTheme,
      appBarTheme: appBarTheme,
      bottomAppBarTheme: bottomAppBarTheme,
      colorScheme: colorScheme,
      dialogTheme: dialogTheme,
      floatingActionButtonTheme: floatingActionButtonTheme,
      typography: typography,
      cupertinoOverrideTheme: cupertinoOverrideTheme,
      snackBarTheme: snackBarTheme,
      bottomSheetTheme: bottomSheetTheme,
      popupMenuTheme: popupMenuTheme,
      bannerTheme: bannerTheme,
      dividerTheme: dividerTheme,
      buttonBarTheme: buttonBarTheme,
    );
  }

  /// Create a [ThemeData] given a set of exact values. All the values must be
  /// specified. They all must also be non-null except for
  /// [cupertinoOverrideTheme].
  ///
  /// This will rarely be used directly. It is used by [lerp] to
  /// create intermediate themes based on two themes created with the
  /// [new ThemeData] constructor.
  const ThemeData.raw({
    // Warning: make sure these properties are in the exact same order as in
    // operator == and in the hashValues method and in the order of fields
    // in this class, and in the lerp() method.
    @required this.brightness,
    @required this.primaryColor,
    @required this.primaryColorBrightness,
    @required this.primaryColorLight,
    @required this.primaryColorDark,
    @required this.canvasColor,
    @required this.accentColor,
    @required this.accentColorBrightness,
    @required this.scaffoldBackgroundColor,
    @required this.bottomAppBarColor,
    @required this.cardColor,
    @required this.dividerColor,
    @required this.focusColor,
    @required this.hoverColor,
    @required this.highlightColor,
    @required this.splashColor,
    @required this.splashFactory,
    @required this.selectedRowColor,
    @required this.unselectedWidgetColor,
    @required this.disabledColor,
    @required this.buttonTheme,
    @required this.buttonColor,
    @required this.toggleButtonsTheme,
    @required this.secondaryHeaderColor,
    @required this.textSelectionColor,
    @required this.cursorColor,
    @required this.textSelectionHandleColor,
    @required this.backgroundColor,
    @required this.dialogBackgroundColor,
    @required this.indicatorColor,
    @required this.hintColor,
    @required this.errorColor,
    @required this.toggleableActiveColor,
    @required this.textTheme,
    @required this.primaryTextTheme,
    @required this.accentTextTheme,
    @required this.inputDecorationTheme,
    @required this.iconTheme,
    @required this.primaryIconTheme,
    @required this.accentIconTheme,
    @required this.sliderTheme,
    @required this.tabBarTheme,
    @required this.tooltipTheme,
    @required this.cardTheme,
    @required this.chipTheme,
    @required this.platform,
    @required this.materialTapTargetSize,
    @required this.applyElevationOverlayColor,
    @required this.pageTransitionsTheme,
    @required this.appBarTheme,
    @required this.bottomAppBarTheme,
    @required this.colorScheme,
    @required this.dialogTheme,
    @required this.floatingActionButtonTheme,
    @required this.typography,
    @required this.cupertinoOverrideTheme,
    @required this.snackBarTheme,
    @required this.bottomSheetTheme,
    @required this.popupMenuTheme,
    @required this.bannerTheme,
    @required this.dividerTheme,
    @required this.buttonBarTheme,
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
       assert(focusColor != null),
       assert(hoverColor != null),
       assert(highlightColor != null),
       assert(splashColor != null),
       assert(splashFactory != null),
       assert(selectedRowColor != null),
       assert(unselectedWidgetColor != null),
       assert(disabledColor != null),
       assert(toggleableActiveColor != null),
       assert(buttonTheme != null),
       assert(toggleButtonsTheme != null),
       assert(secondaryHeaderColor != null),
       assert(textSelectionColor != null),
       assert(cursorColor != null),
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
       assert(tabBarTheme != null),
       assert(tooltipTheme != null),
       assert(cardTheme != null),
       assert(chipTheme != null),
       assert(platform != null),
       assert(materialTapTargetSize != null),
       assert(pageTransitionsTheme != null),
       assert(appBarTheme != null),
       assert(bottomAppBarTheme != null),
       assert(colorScheme != null),
       assert(dialogTheme != null),
       assert(floatingActionButtonTheme != null),
       assert(typography != null),
       assert(snackBarTheme != null),
       assert(bottomSheetTheme != null),
       assert(popupMenuTheme != null),
       assert(bannerTheme != null),
       assert(dividerTheme != null),
       assert(buttonBarTheme != null);

  /// Create a [ThemeData] based on the colors in the given [colorScheme] and
  /// text styles of the optional [textTheme].
  ///
  /// The [colorScheme] can not be null.
  ///
  /// If [colorScheme.brightness] is [Brightness.dark] then
  /// [ThemeData.applyElevationOverlayColor] will be set to true to support
  /// the Material dark theme method for indicating elevation by overlaying
  /// a semi-transparent white color on top of the surface color.
  ///
  /// This is the recommended method to theme your application. As we move
  /// forward we will be converting all the widget implementations to only use
  /// colors or colors derived from those in [ColorScheme].
  ///
  /// {@tool sample}
  /// This example will set up an application to use the baseline Material
  /// Design light and dark themes.
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: ThemeData.from(colorScheme: ColorScheme.light()),
  ///   darkTheme: ThemeData.from(colorScheme: ColorScheme.dark()),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See <https://material.io/design/color/> for
  /// more discussion on how to pick the right colors.
  factory ThemeData.from({
    @required ColorScheme colorScheme,
    TextTheme textTheme,
  }) {
    assert(colorScheme != null);

    final bool isDark = colorScheme.brightness == Brightness.dark;

    // For surfaces that use primary color in light themes and surface color in dark
    final Color primarySurfaceColor = isDark ? colorScheme.surface : colorScheme.primary;
    final Color onPrimarySurfaceColor = isDark ? colorScheme.onSurface : colorScheme.onPrimary;

    return ThemeData(
      brightness: colorScheme.brightness,
      primaryColor: primarySurfaceColor,
      primaryColorBrightness: ThemeData.estimateBrightnessForColor(primarySurfaceColor),
      canvasColor: colorScheme.background,
      accentColor: colorScheme.secondary,
      accentColorBrightness: ThemeData.estimateBrightnessForColor(colorScheme.secondary),
      scaffoldBackgroundColor: colorScheme.background,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.onSurface.withOpacity(0.12),
      backgroundColor: colorScheme.background,
      dialogBackgroundColor: colorScheme.background,
      errorColor: colorScheme.error,
      textTheme: textTheme,
      indicatorColor: onPrimarySurfaceColor,
      applyElevationOverlayColor: isDark,
      colorScheme: colorScheme,
    );
  }

  /// A default light blue theme.
  ///
  /// This theme does not contain text geometry. Instead, it is expected that
  /// this theme is localized using text geometry using [ThemeData.localize].
  factory ThemeData.light() => ThemeData(brightness: Brightness.light);

  /// A default dark theme with a teal accent color.
  ///
  /// This theme does not contain text geometry. Instead, it is expected that
  /// this theme is localized using text geometry using [ThemeData.localize].
  factory ThemeData.dark() => ThemeData(brightness: Brightness.dark);

  /// The default color theme. Same as [new ThemeData.light].
  ///
  /// This is used by [Theme.of] when no theme has been specified.
  ///
  /// This theme does not contain text geometry. Instead, it is expected that
  /// this theme is localized using text geometry using [ThemeData.localize].
  ///
  /// Most applications would use [Theme.of], which provides correct localized
  /// text geometry.
  factory ThemeData.fallback() => ThemeData.light();

  // Warning: make sure these properties are in the exact same order as in
  // hashValues() and in the raw constructor and in the order of fields in
  // the class and in the lerp() method.

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
  ///
  /// The theme's [colorScheme] property contains [ColorScheme.primary], as
  /// well as a color that contrasts well with the primary color called
  /// [ColorScheme.onPrimary]. It might be simpler to just configure an app's
  /// visuals in terms of the theme's [colorScheme].
  final Color primaryColor;

  /// The brightness of the [primaryColor]. Used to determine the color of text and
  /// icons placed on top of the primary color (e.g. toolbar text).
  final Brightness primaryColorBrightness;

  /// A lighter version of the [primaryColor].
  final Color primaryColorLight;

  /// A darker version of the [primaryColor].
  final Color primaryColorDark;

  /// The default color of [MaterialType.canvas] [Material].
  final Color canvasColor;

  /// The foreground color for widgets (knobs, text, overscroll edge effect, etc).
  ///
  /// Accent color is also known as the secondary color.
  ///
  /// The theme's [colorScheme] property contains [ColorScheme.secondary], as
  /// well as a color that contrasts well with the secondary color called
  /// [ColorScheme.onSecondary]. It might be simpler to just configure an app's
  /// visuals in terms of the theme's [colorScheme].
  final Color accentColor;

  /// The brightness of the [accentColor]. Used to determine the color of text
  /// and icons placed on top of the accent color (e.g. the icons on a floating
  /// action button).
  final Brightness accentColorBrightness;

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

  /// The focus color used indicate that a component has the input focus.
  final Color focusColor;

  /// The hover color used to indicate when a pointer is hovering over a
  /// component.
  final Color hoverColor;

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

  /// Defines the default configuration of button widgets, like [RaisedButton]
  /// and [FlatButton].
  final ButtonThemeData buttonTheme;

  /// Defines the default configuration of [ToggleButtons] widgets.
  final ToggleButtonsThemeData toggleButtonsTheme;

  /// The default fill color of the [Material] used in [RaisedButton]s.
  final Color buttonColor;

  /// The color of the header of a [PaginatedDataTable] when there are selected rows.
  // According to the spec for data tables:
  // https://material.io/archive/guidelines/components/data-tables.html#data-tables-tables-within-cards
  // ...this should be the "50-value of secondary app color".
  final Color secondaryHeaderColor;

  /// The color of text selections in text fields, such as [TextField].
  final Color textSelectionColor;

  /// The color of cursors in Material-style text fields, such as [TextField].
  final Color cursorColor;

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

  /// The color used to highlight the active states of toggleable widgets like
  /// [Switch], [Radio], and [Checkbox].
  final Color toggleableActiveColor;

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

  /// A theme for customizing the size, shape, and color of the tab bar indicator.
  final TabBarTheme tabBarTheme;

  /// A theme for customizing the visual properties of [Tooltip]s.
  ///
  /// This is the value returned from [TooltipTheme.of].
  final TooltipThemeData tooltipTheme;

  /// The colors and styles used to render [Card].
  ///
  /// This is the value returned from [CardTheme.of].
  final CardTheme cardTheme;

  /// The colors and styles used to render [Chip]s.
  ///
  /// This is the value returned from [ChipTheme.of].
  final ChipThemeData chipTheme;

  /// The platform the material widgets should adapt to target.
  ///
  /// Defaults to the current platform, as exposed by [defaultTargetPlatform].
  /// This should be used in order to style UI elements according to platform
  /// conventions.
  ///
  /// Widgets from the material library should use this getter (via [Theme.of])
  /// to determine the current platform for the purpose of emulating the
  /// platform behavior (e.g. scrolling or haptic effects). Widgets and render
  /// objects at lower layers that try to emulate the underlying platform
  /// platform can depend on [defaultTargetPlatform] directly, or may require
  /// that the target platform be provided as an argument. The
  /// [dart.io.Platform] object should only be used directly when it's critical
  /// to actually know the current platform, without any overrides possible (for
  /// example, when a system API is about to be called).
  ///
  /// In a test environment, the platform returned is [TargetPlatform.android]
  /// regardless of the host platform. (Android was chosen because the tests
  /// were originally written assuming Android-like behavior, and we added
  /// platform adaptations for iOS later). Tests can check iOS behavior by
  /// setting the [platform] of the [Theme] explicitly to [TargetPlatform.iOS],
  /// or by setting [debugDefaultTargetPlatformOverride].
  final TargetPlatform platform;

  /// Configures the hit test size of certain Material widgets.
  final MaterialTapTargetSize materialTapTargetSize;

  /// Apply a semi-transparent white overlay on Material surfaces to indicate
  /// elevation for dark themes.
  ///
  /// Material drop shadows can be difficult to see in a dark theme, so the
  /// elevation of a surface should be portrayed with an "overlay" in addition
  /// to the shadow. As the elevation of the component increases, the white
  /// overlay increases in opacity. [applyElevationOverlayColor] turns the
  /// application of this overlay on or off.
  ///
  /// If [true] a semi-transparent white overlay will be applied to the color
  /// of [Material] widgets when their [Material.color] is [colorScheme.surface].
  /// The level of transparency is based on [Material.elevation] as per the
  /// Material Dark theme specification.
  ///
  /// If [false] the surface color will be used unmodified.
  ///
  /// Defaults to [false].
  ///
  /// Note: this setting is here to maintain backwards compatibility with
  /// apps that were built before the Material Dark theme specification
  /// was published. New apps should set this to [true] for any themes
  /// where [brightness] is [Brightness.dark].
  ///
  /// See also:
  ///
  ///  * [Material.elevation], which effects how transparent the white overlay is.
  ///  * [Material.color], the white color overlay will only be applied of the
  ///    material's color is [colorScheme.surface].
  ///  * <https://material.io/design/color/dark-theme.html>, which specifies how
  ///    the overlay should be applied.
  final bool applyElevationOverlayColor;

  /// Default [MaterialPageRoute] transitions per [TargetPlatform].
  ///
  /// [MaterialPageRoute.buildTransitions] delegates to a [PageTransitionsBuilder]
  /// whose [PageTransitionsBuilder.platform] matches [platform]. If a matching
  /// builder is not found, a builder whose platform is null is used.
  final PageTransitionsTheme pageTransitionsTheme;

  /// A theme for customizing the color, elevation, brightness, iconTheme and
  /// textTheme of [AppBar]s.
  final AppBarTheme appBarTheme;

  /// A theme for customizing the shape, elevation, and color of a [BottomAppBar].
  final BottomAppBarTheme bottomAppBarTheme;

  /// A set of thirteen colors that can be used to configure the
  /// color properties of most components.
  ///
  /// This property was added much later than the theme's set of highly
  /// specific colors, like [cardColor], [buttonColor], [canvasColor] etc.
  /// New components can be defined exclusively in terms of [colorScheme].
  /// Existing components will gradually migrate to it, to the extent
  /// that is possible without significant backwards compatibility breaks.
  final ColorScheme colorScheme;

  /// A theme for customizing colors, shape, elevation, and behavior of a [SnackBar].
  final SnackBarThemeData snackBarTheme;

  /// A theme for customizing the shape of a dialog.
  final DialogTheme dialogTheme;

  /// A theme for customizing the shape, elevation, and color of a
  /// [FloatingActionButton].
  final FloatingActionButtonThemeData floatingActionButtonTheme;

  /// The color and geometry [TextTheme] values used to configure [textTheme],
  /// [primaryTextTheme], and [accentTextTheme].
  final Typography typography;

  /// Components of the [CupertinoThemeData] to override from the Material
  /// [ThemeData] adaptation.
  ///
  /// By default, [cupertinoOverrideTheme] is null and Cupertino widgets
  /// descendant to the Material [Theme] will adhere to a [CupertinoTheme]
  /// derived from the Material [ThemeData]. e.g. [ThemeData]'s [ColorTheme]
  /// will also inform the [CupertinoThemeData]'s `primaryColor` etc.
  ///
  /// This cascading effect for individual attributes of the [CupertinoThemeData]
  /// can be overridden using attributes of this [cupertinoOverrideTheme].
  final CupertinoThemeData cupertinoOverrideTheme;

  /// A theme for customizing the color, elevation, and shape of a bottom sheet.
  final BottomSheetThemeData bottomSheetTheme;

  /// A theme for customizing the color, shape, elevation, and text style of
  /// popup menus.
  final PopupMenuThemeData popupMenuTheme;

  /// A theme for customizing the color and text style of a [MaterialBanner].
  final MaterialBannerThemeData bannerTheme;

  /// A theme for customizing the color, thickness, and indents of [Divider]s,
  /// [VerticalDivider]s, etc.
  final DividerThemeData dividerTheme;

  /// A theme for customizing the appearance and layout of [ButtonBar] widgets.
  final ButtonBarThemeData buttonBarTheme;

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
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    ButtonThemeData buttonTheme,
    ToggleButtonsThemeData toggleButtonsTheme,
    Color buttonColor,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color cursorColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    Color toggleableActiveColor,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TabBarTheme tabBarTheme,
    TooltipThemeData tooltipTheme,
    CardTheme cardTheme,
    ChipThemeData chipTheme,
    TargetPlatform platform,
    MaterialTapTargetSize materialTapTargetSize,
    bool applyElevationOverlayColor,
    PageTransitionsTheme pageTransitionsTheme,
    AppBarTheme appBarTheme,
    BottomAppBarTheme bottomAppBarTheme,
    ColorScheme colorScheme,
    DialogTheme dialogTheme,
    FloatingActionButtonThemeData floatingActionButtonTheme,
    Typography typography,
    CupertinoThemeData cupertinoOverrideTheme,
    SnackBarThemeData snackBarTheme,
    BottomSheetThemeData bottomSheetTheme,
    PopupMenuThemeData popupMenuTheme,
    MaterialBannerThemeData bannerTheme,
    DividerThemeData dividerTheme,
    ButtonBarThemeData buttonBarTheme,
  }) {
    cupertinoOverrideTheme = cupertinoOverrideTheme?.noDefault();
    return ThemeData.raw(
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
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      highlightColor: highlightColor ?? this.highlightColor,
      splashColor: splashColor ?? this.splashColor,
      splashFactory: splashFactory ?? this.splashFactory,
      selectedRowColor: selectedRowColor ?? this.selectedRowColor,
      unselectedWidgetColor: unselectedWidgetColor ?? this.unselectedWidgetColor,
      disabledColor: disabledColor ?? this.disabledColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTheme: buttonTheme ?? this.buttonTheme,
      toggleButtonsTheme: toggleButtonsTheme ?? this.toggleButtonsTheme,
      secondaryHeaderColor: secondaryHeaderColor ?? this.secondaryHeaderColor,
      textSelectionColor: textSelectionColor ?? this.textSelectionColor,
      cursorColor: cursorColor ?? this.cursorColor,
      textSelectionHandleColor: textSelectionHandleColor ?? this.textSelectionHandleColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      dialogBackgroundColor: dialogBackgroundColor ?? this.dialogBackgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      hintColor: hintColor ?? this.hintColor,
      errorColor: errorColor ?? this.errorColor,
      toggleableActiveColor: toggleableActiveColor ?? this.toggleableActiveColor,
      textTheme: textTheme ?? this.textTheme,
      primaryTextTheme: primaryTextTheme ?? this.primaryTextTheme,
      accentTextTheme: accentTextTheme ?? this.accentTextTheme,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      iconTheme: iconTheme ?? this.iconTheme,
      primaryIconTheme: primaryIconTheme ?? this.primaryIconTheme,
      accentIconTheme: accentIconTheme ?? this.accentIconTheme,
      sliderTheme: sliderTheme ?? this.sliderTheme,
      tabBarTheme: tabBarTheme ?? this.tabBarTheme,
      tooltipTheme: tooltipTheme ?? this.tooltipTheme,
      cardTheme: cardTheme ?? this.cardTheme,
      chipTheme: chipTheme ?? this.chipTheme,
      platform: platform ?? this.platform,
      materialTapTargetSize: materialTapTargetSize ?? this.materialTapTargetSize,
      applyElevationOverlayColor: applyElevationOverlayColor ?? this.applyElevationOverlayColor,
      pageTransitionsTheme: pageTransitionsTheme ?? this.pageTransitionsTheme,
      appBarTheme: appBarTheme ?? this.appBarTheme,
      bottomAppBarTheme: bottomAppBarTheme ?? this.bottomAppBarTheme,
      colorScheme: colorScheme ?? this.colorScheme,
      dialogTheme: dialogTheme ?? this.dialogTheme,
      floatingActionButtonTheme: floatingActionButtonTheme ?? this.floatingActionButtonTheme,
      typography: typography ?? this.typography,
      cupertinoOverrideTheme: cupertinoOverrideTheme ?? this.cupertinoOverrideTheme,
      snackBarTheme: snackBarTheme ?? this.snackBarTheme,
      bottomSheetTheme: bottomSheetTheme ?? this.bottomSheetTheme,
      popupMenuTheme: popupMenuTheme ?? this.popupMenuTheme,
      bannerTheme: bannerTheme ?? this.bannerTheme,
      dividerTheme: dividerTheme ?? this.dividerTheme,
      buttonBarTheme: buttonBarTheme ?? this.buttonBarTheme,
    );
  }

  // The number 5 was chosen without any real science or research behind it. It
  // just seemed like a number that's not too big (we should be able to fit 5
  // copies of ThemeData in memory comfortably) and not too small (most apps
  // shouldn't have more than 5 theme/localization pairs).
  static const int _localizedThemeDataCacheSize = 5;

  /// Caches localized themes to speed up the [localize] method.
  static final _FifoCache<_IdentityThemeDataCacheKey, ThemeData> _localizedThemeDataCache =
      _FifoCache<_IdentityThemeDataCacheKey, ThemeData>(_localizedThemeDataCacheSize);

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
      _IdentityThemeDataCacheKey(baseTheme, localTextGeometry),
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
    // <https://material.io/go/design-theming#color-color-palette>.
    const double kThreshold = 0.15;
    if ((relativeLuminance + 0.05) * (relativeLuminance + 0.05) > kThreshold)
      return Brightness.light;
    return Brightness.dark;
  }

  /// Linearly interpolate between two themes.
  ///
  /// The arguments must not be null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static ThemeData lerp(ThemeData a, ThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    // Warning: make sure these properties are in the exact same order as in
    // hashValues() and in the raw constructor and in the order of fields in
    // the class and in the lerp() method.
    return ThemeData.raw(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      primaryColor: Color.lerp(a.primaryColor, b.primaryColor, t),
      primaryColorBrightness: t < 0.5 ? a.primaryColorBrightness : b.primaryColorBrightness,
      primaryColorLight: Color.lerp(a.primaryColorLight, b.primaryColorLight, t),
      primaryColorDark: Color.lerp(a.primaryColorDark, b.primaryColorDark, t),
      canvasColor: Color.lerp(a.canvasColor, b.canvasColor, t),
      accentColor: Color.lerp(a.accentColor, b.accentColor, t),
      accentColorBrightness: t < 0.5 ? a.accentColorBrightness : b.accentColorBrightness,
      scaffoldBackgroundColor: Color.lerp(a.scaffoldBackgroundColor, b.scaffoldBackgroundColor, t),
      bottomAppBarColor: Color.lerp(a.bottomAppBarColor, b.bottomAppBarColor, t),
      cardColor: Color.lerp(a.cardColor, b.cardColor, t),
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t),
      focusColor: Color.lerp(a.focusColor, b.focusColor, t),
      hoverColor: Color.lerp(a.hoverColor, b.hoverColor, t),
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t),
      splashColor: Color.lerp(a.splashColor, b.splashColor, t),
      splashFactory: t < 0.5 ? a.splashFactory : b.splashFactory,
      selectedRowColor: Color.lerp(a.selectedRowColor, b.selectedRowColor, t),
      unselectedWidgetColor: Color.lerp(a.unselectedWidgetColor, b.unselectedWidgetColor, t),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      buttonTheme: t < 0.5 ? a.buttonTheme : b.buttonTheme,
      toggleButtonsTheme: ToggleButtonsThemeData.lerp(a.toggleButtonsTheme, b.toggleButtonsTheme, t),
      buttonColor: Color.lerp(a.buttonColor, b.buttonColor, t),
      secondaryHeaderColor: Color.lerp(a.secondaryHeaderColor, b.secondaryHeaderColor, t),
      textSelectionColor: Color.lerp(a.textSelectionColor, b.textSelectionColor, t),
      cursorColor: Color.lerp(a.cursorColor, b.cursorColor, t),
      textSelectionHandleColor: Color.lerp(a.textSelectionHandleColor, b.textSelectionHandleColor, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      dialogBackgroundColor: Color.lerp(a.dialogBackgroundColor, b.dialogBackgroundColor, t),
      indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t),
      hintColor: Color.lerp(a.hintColor, b.hintColor, t),
      errorColor: Color.lerp(a.errorColor, b.errorColor, t),
      toggleableActiveColor: Color.lerp(a.toggleableActiveColor, b.toggleableActiveColor, t),
      textTheme: TextTheme.lerp(a.textTheme, b.textTheme, t),
      primaryTextTheme: TextTheme.lerp(a.primaryTextTheme, b.primaryTextTheme, t),
      accentTextTheme: TextTheme.lerp(a.accentTextTheme, b.accentTextTheme, t),
      inputDecorationTheme: t < 0.5 ? a.inputDecorationTheme : b.inputDecorationTheme,
      iconTheme: IconThemeData.lerp(a.iconTheme, b.iconTheme, t),
      primaryIconTheme: IconThemeData.lerp(a.primaryIconTheme, b.primaryIconTheme, t),
      accentIconTheme: IconThemeData.lerp(a.accentIconTheme, b.accentIconTheme, t),
      sliderTheme: SliderThemeData.lerp(a.sliderTheme, b.sliderTheme, t),
      tabBarTheme: TabBarTheme.lerp(a.tabBarTheme, b.tabBarTheme, t),
      tooltipTheme: TooltipThemeData.lerp(a.tooltipTheme, b.tooltipTheme, t),
      cardTheme: CardTheme.lerp(a.cardTheme, b.cardTheme, t),
      chipTheme: ChipThemeData.lerp(a.chipTheme, b.chipTheme, t),
      platform: t < 0.5 ? a.platform : b.platform,
      materialTapTargetSize: t < 0.5 ? a.materialTapTargetSize : b.materialTapTargetSize,
      applyElevationOverlayColor: t < 0.5 ? a.applyElevationOverlayColor : b.applyElevationOverlayColor,
      pageTransitionsTheme: t < 0.5 ? a.pageTransitionsTheme : b.pageTransitionsTheme,
      appBarTheme: AppBarTheme.lerp(a.appBarTheme, b.appBarTheme, t),
      bottomAppBarTheme: BottomAppBarTheme.lerp(a.bottomAppBarTheme, b.bottomAppBarTheme, t),
      colorScheme: ColorScheme.lerp(a.colorScheme, b.colorScheme, t),
      dialogTheme: DialogTheme.lerp(a.dialogTheme, b.dialogTheme, t),
      floatingActionButtonTheme: FloatingActionButtonThemeData.lerp(a.floatingActionButtonTheme, b.floatingActionButtonTheme, t),
      typography: Typography.lerp(a.typography, b.typography, t),
      cupertinoOverrideTheme: t < 0.5 ? a.cupertinoOverrideTheme : b.cupertinoOverrideTheme,
      snackBarTheme: SnackBarThemeData.lerp(a.snackBarTheme, b.snackBarTheme, t),
      bottomSheetTheme: BottomSheetThemeData.lerp(a.bottomSheetTheme, b.bottomSheetTheme, t),
      popupMenuTheme: PopupMenuThemeData.lerp(a.popupMenuTheme, b.popupMenuTheme, t),
      bannerTheme: MaterialBannerThemeData.lerp(a.bannerTheme, b.bannerTheme, t),
      dividerTheme: DividerThemeData.lerp(a.dividerTheme, b.dividerTheme, t),
      buttonBarTheme: ButtonBarThemeData.lerp(a.buttonBarTheme, b.buttonBarTheme, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ThemeData otherData = other;
    // Warning: make sure these properties are in the exact same order as in
    // hashValues() and in the raw constructor and in the order of fields in
    // the class and in the lerp() method.
    return (otherData.brightness == brightness) &&
           (otherData.primaryColor == primaryColor) &&
           (otherData.primaryColorBrightness == primaryColorBrightness) &&
           (otherData.primaryColorLight == primaryColorLight) &&
           (otherData.primaryColorDark == primaryColorDark) &&
           (otherData.accentColor == accentColor) &&
           (otherData.accentColorBrightness == accentColorBrightness) &&
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
           (otherData.buttonTheme == buttonTheme) &&
           (otherData.buttonColor == buttonColor) &&
           (otherData.toggleButtonsTheme == toggleButtonsTheme) &&
           (otherData.secondaryHeaderColor == secondaryHeaderColor) &&
           (otherData.textSelectionColor == textSelectionColor) &&
           (otherData.cursorColor == cursorColor) &&
           (otherData.textSelectionHandleColor == textSelectionHandleColor) &&
           (otherData.backgroundColor == backgroundColor) &&
           (otherData.dialogBackgroundColor == dialogBackgroundColor) &&
           (otherData.indicatorColor == indicatorColor) &&
           (otherData.hintColor == hintColor) &&
           (otherData.errorColor == errorColor) &&
           (otherData.toggleableActiveColor == toggleableActiveColor) &&
           (otherData.textTheme == textTheme) &&
           (otherData.primaryTextTheme == primaryTextTheme) &&
           (otherData.accentTextTheme == accentTextTheme) &&
           (otherData.inputDecorationTheme == inputDecorationTheme) &&
           (otherData.iconTheme == iconTheme) &&
           (otherData.primaryIconTheme == primaryIconTheme) &&
           (otherData.accentIconTheme == accentIconTheme) &&
           (otherData.sliderTheme == sliderTheme) &&
           (otherData.tabBarTheme == tabBarTheme) &&
           (otherData.tooltipTheme == tooltipTheme) &&
           (otherData.cardTheme == cardTheme) &&
           (otherData.chipTheme == chipTheme) &&
           (otherData.platform == platform) &&
           (otherData.materialTapTargetSize == materialTapTargetSize) &&
           (otherData.applyElevationOverlayColor == applyElevationOverlayColor) &&
           (otherData.pageTransitionsTheme == pageTransitionsTheme) &&
           (otherData.appBarTheme == appBarTheme) &&
           (otherData.bottomAppBarTheme == bottomAppBarTheme) &&
           (otherData.colorScheme == colorScheme) &&
           (otherData.dialogTheme == dialogTheme) &&
           (otherData.floatingActionButtonTheme == floatingActionButtonTheme) &&
           (otherData.typography == typography) &&
           (otherData.cupertinoOverrideTheme == cupertinoOverrideTheme) &&
           (otherData.snackBarTheme == snackBarTheme) &&
           (otherData.bottomSheetTheme == bottomSheetTheme) &&
           (otherData.popupMenuTheme == popupMenuTheme) &&
           (otherData.bannerTheme == bannerTheme) &&
           (otherData.dividerTheme == dividerTheme) &&
           (otherData.buttonBarTheme == buttonBarTheme);
  }

  @override
  int get hashCode {
    // Warning: For the sanity of the reader, please make sure these properties
    // are in the exact same order as in operator == and in the raw constructor
    // and in the order of fields in the class and in the lerp() method.
    final List<Object> values = <Object>[
      brightness,
      primaryColor,
      primaryColorBrightness,
      primaryColorLight,
      primaryColorDark,
      accentColor,
      accentColorBrightness,
      canvasColor,
      scaffoldBackgroundColor,
      bottomAppBarColor,
      cardColor,
      dividerColor,
      focusColor,
      hoverColor,
      highlightColor,
      splashColor,
      splashFactory,
      selectedRowColor,
      unselectedWidgetColor,
      disabledColor,
      buttonTheme,
      buttonColor,
      toggleButtonsTheme,
      toggleableActiveColor,
      secondaryHeaderColor,
      textSelectionColor,
      cursorColor,
      textSelectionHandleColor,
      backgroundColor,
      dialogBackgroundColor,
      indicatorColor,
      hintColor,
      errorColor,
      textTheme,
      primaryTextTheme,
      accentTextTheme,
      inputDecorationTheme,
      iconTheme,
      primaryIconTheme,
      accentIconTheme,
      sliderTheme,
      tabBarTheme,
      tooltipTheme,
      cardTheme,
      chipTheme,
      platform,
      materialTapTargetSize,
      applyElevationOverlayColor,
      pageTransitionsTheme,
      appBarTheme,
      bottomAppBarTheme,
      colorScheme,
      dialogTheme,
      floatingActionButtonTheme,
      typography,
      cupertinoOverrideTheme,
      snackBarTheme,
      bottomSheetTheme,
      popupMenuTheme,
      bannerTheme,
      dividerTheme,
      buttonBarTheme,
    ];
    return hashList(values);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultData = ThemeData.fallback();
    properties.add(EnumProperty<TargetPlatform>('platform', platform, defaultValue: defaultTargetPlatform));
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: defaultData.brightness));
    properties.add(ColorProperty('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(EnumProperty<Brightness>('primaryColorBrightness', primaryColorBrightness, defaultValue: defaultData.primaryColorBrightness));
    properties.add(ColorProperty('accentColor', accentColor, defaultValue: defaultData.accentColor));
    properties.add(EnumProperty<Brightness>('accentColorBrightness', accentColorBrightness, defaultValue: defaultData.accentColorBrightness));
    properties.add(ColorProperty('canvasColor', canvasColor, defaultValue: defaultData.canvasColor));
    properties.add(ColorProperty('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    properties.add(ColorProperty('bottomAppBarColor', bottomAppBarColor, defaultValue: defaultData.bottomAppBarColor));
    properties.add(ColorProperty('cardColor', cardColor, defaultValue: defaultData.cardColor));
    properties.add(ColorProperty('dividerColor', dividerColor, defaultValue: defaultData.dividerColor));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: defaultData.focusColor));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: defaultData.hoverColor));
    properties.add(ColorProperty('highlightColor', highlightColor, defaultValue: defaultData.highlightColor));
    properties.add(ColorProperty('splashColor', splashColor, defaultValue: defaultData.splashColor));
    properties.add(ColorProperty('selectedRowColor', selectedRowColor, defaultValue: defaultData.selectedRowColor));
    properties.add(ColorProperty('unselectedWidgetColor', unselectedWidgetColor, defaultValue: defaultData.unselectedWidgetColor));
    properties.add(ColorProperty('disabledColor', disabledColor, defaultValue: defaultData.disabledColor));
    properties.add(ColorProperty('buttonColor', buttonColor, defaultValue: defaultData.buttonColor));
    properties.add(ColorProperty('secondaryHeaderColor', secondaryHeaderColor, defaultValue: defaultData.secondaryHeaderColor));
    properties.add(ColorProperty('textSelectionColor', textSelectionColor, defaultValue: defaultData.textSelectionColor));
    properties.add(ColorProperty('cursorColor', cursorColor, defaultValue: defaultData.cursorColor));
    properties.add(ColorProperty('textSelectionHandleColor', textSelectionHandleColor, defaultValue: defaultData.textSelectionHandleColor));
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: defaultData.backgroundColor));
    properties.add(ColorProperty('dialogBackgroundColor', dialogBackgroundColor, defaultValue: defaultData.dialogBackgroundColor));
    properties.add(ColorProperty('indicatorColor', indicatorColor, defaultValue: defaultData.indicatorColor));
    properties.add(ColorProperty('hintColor', hintColor, defaultValue: defaultData.hintColor));
    properties.add(ColorProperty('errorColor', errorColor, defaultValue: defaultData.errorColor));
    properties.add(ColorProperty('toggleableActiveColor', toggleableActiveColor, defaultValue: defaultData.toggleableActiveColor));
    properties.add(DiagnosticsProperty<ButtonThemeData>('buttonTheme', buttonTheme));
    properties.add(DiagnosticsProperty<ToggleButtonsThemeData>('toggleButtonsTheme', toggleButtonsTheme));
    properties.add(DiagnosticsProperty<TextTheme>('textTheme', textTheme));
    properties.add(DiagnosticsProperty<TextTheme>('primaryTextTheme', primaryTextTheme));
    properties.add(DiagnosticsProperty<TextTheme>('accentTextTheme', accentTextTheme));
    properties.add(DiagnosticsProperty<InputDecorationTheme>('inputDecorationTheme', inputDecorationTheme));
    properties.add(DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme));
    properties.add(DiagnosticsProperty<IconThemeData>('primaryIconTheme', primaryIconTheme));
    properties.add(DiagnosticsProperty<IconThemeData>('accentIconTheme', accentIconTheme));
    properties.add(DiagnosticsProperty<SliderThemeData>('sliderTheme', sliderTheme));
    properties.add(DiagnosticsProperty<TabBarTheme>('tabBarTheme', tabBarTheme));
    properties.add(DiagnosticsProperty<TooltipThemeData>('tooltipTheme', tooltipTheme));
    properties.add(DiagnosticsProperty<CardTheme>('cardTheme', cardTheme));
    properties.add(DiagnosticsProperty<ChipThemeData>('chipTheme', chipTheme));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>('materialTapTargetSize', materialTapTargetSize));
    properties.add(DiagnosticsProperty<bool>('applyElevationOverlayColor', applyElevationOverlayColor));
    properties.add(DiagnosticsProperty<PageTransitionsTheme>('pageTransitionsTheme', pageTransitionsTheme));
    properties.add(DiagnosticsProperty<AppBarTheme>('appBarTheme', appBarTheme, defaultValue: defaultData.appBarTheme));
    properties.add(DiagnosticsProperty<BottomAppBarTheme>('bottomAppBarTheme', bottomAppBarTheme, defaultValue: defaultData.bottomAppBarTheme));
    properties.add(DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme, defaultValue: defaultData.colorScheme));
    properties.add(DiagnosticsProperty<DialogTheme>('dialogTheme', dialogTheme, defaultValue: defaultData.dialogTheme));
    properties.add(DiagnosticsProperty<FloatingActionButtonThemeData>('floatingActionButtonThemeData', floatingActionButtonTheme, defaultValue: defaultData.floatingActionButtonTheme));
    properties.add(DiagnosticsProperty<Typography>('typography', typography, defaultValue: defaultData.typography));
    properties.add(DiagnosticsProperty<CupertinoThemeData>('cupertinoOverrideTheme', cupertinoOverrideTheme, defaultValue: defaultData.cupertinoOverrideTheme));
    properties.add(DiagnosticsProperty<SnackBarThemeData>('snackBarTheme', snackBarTheme, defaultValue: defaultData.snackBarTheme));
    properties.add(DiagnosticsProperty<BottomSheetThemeData>('bottomSheetTheme', bottomSheetTheme, defaultValue: defaultData.bottomSheetTheme));
    properties.add(DiagnosticsProperty<PopupMenuThemeData>('popupMenuTheme', popupMenuTheme, defaultValue: defaultData.popupMenuTheme));
    properties.add(DiagnosticsProperty<MaterialBannerThemeData>('bannerTheme', bannerTheme, defaultValue: defaultData.bannerTheme));
    properties.add(DiagnosticsProperty<DividerThemeData>('dividerTheme', dividerTheme, defaultValue: defaultData.dividerTheme));
    properties.add(DiagnosticsProperty<ButtonBarThemeData>('buttonBarTheme', buttonBarTheme, defaultValue: defaultData.buttonBarTheme));
  }
}

/// A [CupertinoThemeData] that defers unspecified theme attributes to an
/// upstream Material [ThemeData].
///
/// This type of [CupertinoThemeData] is used by the Material [Theme] to
/// harmonize the [CupertinoTheme] with the material theme's colors and text
/// styles.
///
/// In the most basic case, [ThemeData]'s `cupertinoOverrideTheme` is null and
/// and descendant Cupertino widgets' styling is derived from the Material theme.
///
/// To override individual parts of the Material-derived Cupertino styling,
/// `cupertinoOverrideTheme`'s construction parameters can be used.
///
/// To completely decouple the Cupertino styling from Material theme derivation,
/// another [CupertinoTheme] widget can be inserted as a descendant of the
/// Material [Theme]. On a [MaterialApp], this can be done using the `builder`
/// parameter on the constructor.
///
/// See also:
///
///  * [CupertinoThemeData], whose null constructor parameters default to
///    reasonable iOS styling defaults rather than harmonizing with a Material
///    theme.
///  * [Theme], widget which inserts a [CupertinoTheme] with this
///    [MaterialBasedCupertinoThemeData].
// This class subclasses CupertinoThemeData rather than composes one because it
// _is_ a CupertinoThemeData with partially altered behavior. e.g. its textTheme
// is from the superclass and based on the primaryColor but the primaryColor
// comes from the Material theme unless overridden.
class MaterialBasedCupertinoThemeData extends CupertinoThemeData {
  /// Create a [MaterialBasedCupertinoThemeData] based on a Material [ThemeData]
  /// and its `cupertinoOverrideTheme`.
  ///
  /// The [materialTheme] parameter must not be null.
  MaterialBasedCupertinoThemeData({
      @required ThemeData materialTheme,
  }) : this._(
    materialTheme,
    (materialTheme.cupertinoOverrideTheme ?? const CupertinoThemeData()).noDefault(),
  );

  MaterialBasedCupertinoThemeData._(
    this._materialTheme,
    this._cupertinoOverrideTheme,
  ) : assert(_materialTheme != null),
      assert(_cupertinoOverrideTheme != null),
      // Pass all values to the superclass so Material-agnostic properties
      // like barBackgroundColor can still behave like a normal
      // CupertinoThemeData.
      super.raw(
        _cupertinoOverrideTheme.brightness,
        _cupertinoOverrideTheme.primaryColor,
        _cupertinoOverrideTheme.primaryContrastingColor,
        _cupertinoOverrideTheme.textTheme,
        _cupertinoOverrideTheme.barBackgroundColor,
        _cupertinoOverrideTheme.scaffoldBackgroundColor,
      );

  final ThemeData _materialTheme;
  final CupertinoThemeData _cupertinoOverrideTheme;

  @override
  Brightness get brightness => _cupertinoOverrideTheme.brightness ?? _materialTheme.brightness;

  @override
  Color get primaryColor => _cupertinoOverrideTheme.primaryColor ?? _materialTheme.colorScheme.primary;

  @override
  Color get primaryContrastingColor => _cupertinoOverrideTheme.primaryContrastingColor ?? _materialTheme.colorScheme.onPrimary;

  @override
  Color get scaffoldBackgroundColor => _cupertinoOverrideTheme.scaffoldBackgroundColor ?? _materialTheme.scaffoldBackgroundColor;

  /// Copies the [ThemeData]'s `cupertinoOverrideTheme`.
  ///
  /// Only the specified override attributes of the [ThemeData]'s
  /// `cupertinoOverrideTheme` and the newly specified parameters are in the
  /// returned [CupertinoThemeData]. No derived attributes from iOS defaults or
  /// from cascaded Material theme attributes are copied.
  ///
  /// [MaterialBasedCupertinoThemeData.copyWith] cannot change the base
  /// Material [ThemeData]. To change the base Material [ThemeData], create a
  /// new Material [Theme] and use `copyWith` on the Material [ThemeData]
  /// instead.
  @override
  MaterialBasedCupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) {
    return MaterialBasedCupertinoThemeData._(
      _materialTheme,
      _cupertinoOverrideTheme.copyWith(
        brightness: brightness,
        primaryColor: primaryColor,
        primaryContrastingColor: primaryContrastingColor,
        textTheme: textTheme,
        barBackgroundColor: barBackgroundColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      ),
    );
  }

  @override
  CupertinoThemeData resolveFrom(BuildContext context, { bool nullOk = false }) {
    // Only the cupertino override theme part will be resolved.
    // If the color comes from the material theme it's not resolved.
    return MaterialBasedCupertinoThemeData._(
      _materialTheme,
      _cupertinoOverrideTheme.resolveFrom(context, nullOk: nullOk),
    );
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
