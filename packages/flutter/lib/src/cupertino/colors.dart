// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

import '../../foundation.dart';
import '../widgets/basic.dart';
import '../widgets/framework.dart';
import '../widgets/media_query.dart';
import 'interface_level.dart';
import 'theme.dart';

// Examples can assume:
// Widget child;
// Color lightModeColor;
// Color darkModeColor;

/// A palette of [Color] constants that describe colors commonly used when
/// matching the iOS platform aesthetics.
class CupertinoColors {
  CupertinoColors._();

  /// iOS 10's default blue color. Used to indicate active elements such as
  /// buttons, selected tabs and your own chat bubbles.
  ///
  /// This is SystemBlue in the iOS palette.
  static const Color activeBlue = Color(0xFF007AFF);

  /// iOS 10's default green color. Used to indicate active accents such as
  /// the switch in its on state and some accent buttons such as the call button
  /// and Apple Map's 'Go' button.
  ///
  /// This is SystemGreen in the iOS palette.
  static const Color activeGreen = Color(0xFF4CD964);

  /// iOS 12's default dark mode color. Used in place of the [activeBlue] color
  /// as the default active elements' color when the theme's brightness is dark.
  ///
  /// This is SystemOrange in the iOS palette.
  static const Color activeOrange = Color(0xFFFF9500);

  /// Opaque white color. Used for backgrounds and fonts against dark backgrounds.
  ///
  /// This is SystemWhiteColor in the iOS palette.
  ///
  /// See also:
  ///
  ///  * [material.Colors.white], the same color, in the material design palette.
  ///  * [black], opaque black in the [CupertinoColors] palette.
  static const Color white = Color(0xFFFFFFFF);

  /// Opaque black color. Used for texts against light backgrounds.
  ///
  /// This is SystemBlackColor in the iOS palette.
  ///
  /// See also:
  ///
  ///  * [material.Colors.black], the same color, in the material design palette.
  ///  * [white], opaque white in the [CupertinoColors] palette.
  static const Color black = Color(0xFF000000);

  /// Used in iOS 10 for light background fills such as the chat bubble background.
  ///
  /// This is SystemLightGrayColor in the iOS palette.
  static const Color lightBackgroundGray = Color(0xFFE5E5EA);

  /// Used in iOS 12 for very light background fills in tables between cell groups.
  ///
  /// This is SystemExtraLightGrayColor in the iOS palette.
  static const Color extraLightBackgroundGray = Color(0xFFEFEFF4);

  /// Used in iOS 12 for very dark background fills in tables between cell groups
  /// in dark mode.
  // Value derived from screenshot from the dark themed Apple Watch app.
  static const Color darkBackgroundGray = Color(0xFF171717);

  /// Used in iOS 11 for unselected selectables such as tab bar items in their
  /// inactive state or de-emphasized subtitles and details text.
  ///
  /// Not the same gray as disabled buttons etc.
  ///
  /// This is SystemGrayColor in the iOS palette.
  static const Color inactiveGray = Color(0xFF8E8E93);

  /// Used for iOS 10 for destructive actions such as the delete actions in
  /// table view cells and dialogs.
  ///
  /// Not the same red as the camera shutter or springboard icon notifications
  /// or the foreground red theme in various native apps such as HealthKit.
  ///
  /// This is SystemRed in the iOS palette.
  static const Color destructiveRed = Color(0xFFFF3B30);
}

/// A [Color] subclass that represents a family of colors, and the currect effective
/// color in the color family.
///
/// When used as a regular color, `CupertinoDynamicColor` is equivalent to the
/// effective color (i.e. [CupertinoDynamicColor.value] will come from the effective
/// color), which is determined by the [BuildContext] it is last resolved against.
/// If it has never been resolved, the light, normal contrast, base elevation variant
/// [CupertinoDynamicColor.color] will be the effective color.
// TODO(LongCatIsLooong): publicize once all Cupertino components have adopted this.
// {@tool sample}
//
// The following snippet will create a [CupertinoButton] whose background color
// is _lightModeColor_ in light mode but _darkModeColor_ in dark mode.
//
//
// ```dart
// CupertinoButton(
//   child: child,
//   color: CupertinoDynamicColor.withVibrancy(
//     color: lightModeColor,
//     darkColor: darkModeColor,
//   ),
//   onTap: () => null,
// )
// ```
// {@end-tool}
//
// When a Cupertino component is provided with a `CupertinoDynamicColor`, either
// directly in its constructor, or from an [InheritedWidget] it depends on (for example,
// [DefaultTextStyle]), the component will automatically resolve the color by calling
// [CupertinoDynamicColor.resolve], using their own [BuildContext].
//
// When used outside of a Cupertino component, such color resolution will not happen
// automatically. It's essential to call [CupertinoDynamicColor.resolve] with the
// correct [BuildContext] before using the color to paint, in order to get the
// desired effect.
///
/// See also:
///
/// * [CupertinoUserInterfaceLevel], an [InheritedWidget] that may affect color
/// resolution of a `CupertinoDynamicColor`.
/// * [CupertinoSystemColors], an [InheritedWidget] that exposes system colors
/// of iOS 13+.
/// * https://developer.apple.com/documentation/uikit/uicolor/3238042-resolvedcolor.
@immutable
class CupertinoDynamicColor extends Color {
  /// Creates an adaptive [Color] that changes its effective color based on the
  /// [BuildContext] given. The default effective color is [color].
  ///
  /// All the colors must not be null.
  const CupertinoDynamicColor({
    @required Color color,
    @required Color darkColor,
    @required Color highContrastColor,
    @required Color darkHighContrastColor,
    @required Color elevatedColor,
    @required Color darkElevatedColor,
    @required Color highContrastElevatedColor,
    @required Color darkHighContrastElevatedColor,
  }) : this._(
         color,
         color,
         darkColor,
         highContrastColor,
         darkHighContrastColor,
         elevatedColor,
         darkElevatedColor,
         highContrastElevatedColor,
         darkHighContrastElevatedColor,
       );

  /// Creates an adaptive [Color] that changes its effective color based on the
  /// given [BuildContext]'s brightness (from [MediaQueryData.platformBrightness]
  /// or [CupertinoThemeData.brightness]) and accessibility contrast setting
  /// ([MediaQueryData.highContrast]). The default effective color is [color].
  ///
  /// All the colors must not be null.
  const CupertinoDynamicColor.withBrightnessAndContrast({
    @required Color color,
    @required Color darkColor,
    @required Color highContrastColor,
    @required Color darkHighContrastColor,
  }) : this(
    color: color,
    darkColor: darkColor,
    highContrastColor: highContrastColor,
    darkHighContrastColor: darkHighContrastColor,
    elevatedColor: color,
    darkElevatedColor: darkColor,
    highContrastElevatedColor: highContrastColor,
    darkHighContrastElevatedColor: darkHighContrastColor,
  );

  /// Creates an adaptive [Color] that changes its effective color based on the given
  /// [BuildContext]'s brightness (from [MediaQueryData.platformBrightness] or
  /// [CupertinoThemeData.brightness]). The default effective color is [color].
  ///
  /// All the colors must not be null.
  const CupertinoDynamicColor.withBrightness({
    @required Color color,
    @required Color darkColor,
  }) : this(
    color: color,
    darkColor: darkColor,
    highContrastColor: color,
    darkHighContrastColor: darkColor,
    elevatedColor: color,
    darkElevatedColor: darkColor,
    highContrastElevatedColor: color,
    darkHighContrastElevatedColor: darkColor,
  );

  const CupertinoDynamicColor._(
    this._effectiveColor,
    this.color,
    this.darkColor,
    this.highContrastColor,
    this.darkHighContrastColor,
    this.elevatedColor,
    this.darkElevatedColor,
    this.highContrastElevatedColor,
    this.darkHighContrastElevatedColor,
  ) : assert(color != null),
      assert(darkColor != null),
      assert(highContrastColor != null),
      assert(darkHighContrastColor != null),
      assert(elevatedColor != null),
      assert(darkElevatedColor != null),
      assert(highContrastElevatedColor != null),
      assert(darkHighContrastElevatedColor != null),
      assert(_effectiveColor != null),
      // The super constructor has to be called with a dummy value in order to mark
      // this constructor const.
      // The field `value` is overriden in the class implementation.
      super(0);

  final Color _effectiveColor;

  @override
  int get value => _effectiveColor.value;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// normal contrast, and base interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.light],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.light].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `false`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.base].
  final Color color;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// normal contrast, and base interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.dark],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.dark].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `false`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.base].
  final Color darkColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// high contrast, and base interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.light],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.light].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `true`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.base].
  final Color highContrastColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// high contrast, and base interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.dark],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.dark].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `true`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.base].
  final Color darkHighContrastColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// normal contrast, and elevated interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.light],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.light].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `false`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.elevated].
  final Color elevatedColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// normal contrast, and elevated interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.dark],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.dark].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `false`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.elevated].
  final Color darkElevatedColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// high contrast, and elevated interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.light],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.light].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `true`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.elevated].
  final Color highContrastElevatedColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// high contrast, and elevated interface elevation.
  ///
  /// In other words, this color will be the effective color of the `CupertinoDynamicColor`
  /// after it is resolved against a [BuildContext] that:
  /// - has a [CupertinoTheme] whose [brightness] is [PlatformBrightness.dark],
  /// or a [MediaQuery] whose [MediaQueryData.platformBrightness] is [PlatformBrightness.dark].
  /// - has a [MediaQuery] whose [MediaQueryData.highContrast] is `true`.
  /// - has a [CupertinoUserInterfaceLevel] that indicates [CupertinoUserInterfaceLevelData.elevated].
  final Color darkHighContrastElevatedColor;

  /// Resolves the given [Color] by calling [resolveFrom].
  ///
  /// If the given color is already a concrete [Color], it will be returned as is.
  /// If the given color is null, returns null.
  /// If the given color is a [CupertinoDynamicColor], but the given [BuildContext]
  /// lacks the dependencies required to the color resolution, the default trait
  /// value will be used ([Brightness.light] platform brightness, normal contrast,
  /// [CupertinoUserInterfaceLevelData.base] elevation level), unless [nullOk] is
  /// set to false, in which case an exception will be thrown.
  static Color resolve(Color resolvable, BuildContext context, { bool nullOk = true }) {
    if (resolvable == null)
      return null;
    assert(context != null);
    return (resolvable is CupertinoDynamicColor)
      ? resolvable.resolveFrom(context, nullOk: nullOk)
      : resolvable;
  }

  bool get _isPlatformBrightnessDependent {
    return color != darkColor
        || elevatedColor != darkElevatedColor
        || highContrastColor != darkHighContrastColor
        || highContrastElevatedColor != darkHighContrastElevatedColor;
  }

  bool get _isHighContrastDependent {
    return color != highContrastColor
        || darkColor != darkHighContrastColor
        || elevatedColor != highContrastElevatedColor
        || darkElevatedColor != darkHighContrastElevatedColor;
  }

  bool get _isInterfaceElevationDependent {
    return color != elevatedColor
        || darkColor != darkElevatedColor
        || highContrastColor != highContrastElevatedColor
        || darkHighContrastColor != darkHighContrastElevatedColor;
  }

  /// Resolves this `CupertinoDynamicColor` using the provided [BuildContext].
  ///
  /// Calling this method will create a new `CupertinoDynamicColor` that is almost
  /// identical to this `CupertinoDynamicColor`, except the effective color is
  /// changed to adapt to the given [BuildContext].
  ///
  /// For example, if the given [BuildContext] indicates the widgets in the subtree
  /// should be displayed in dark mode (the surrounding [CupertinoTheme]'s [CupertinoThemeData.brightness]
  /// or [MediaQuery]'s [MediaQueryData.platformBrightness] is [PlatformBrightness.dark]),
  /// with a high accessibility contrast (the surrounding [MediaQuery]'s [MediaQueryData.highContrast]
  /// is `true`), and an elevated interface elevation (the surrounding [CupertinoUserInterfaceLevel]'s
  /// `data` is [CupertinoUserInterfaceLevelData.elevated]), the resolved
  /// `CupertinoDynamicColor` will be the same as this [CupertinoDynamicColor],
  /// except its effective color will be the `darkHighContrastElevatedColor` variant
  /// from the orignal `CupertinoDynamicColor`.
  ///
  /// Calling this function may create dependencies on the closest instance of some
  /// [InheritedWidget]s that enclose the given [BuildContext]. E.g., if [darkColor]
  /// is different from [color], this method will call [CupertinoTheme.of], and
  /// then [MediaQuery.of] if brightness wasn't specified in the theme data retrived
  /// from the previous [CupertinoTheme.of] call, in an effort to determine the
  /// brightness value.
  ///
  /// If any of the required dependecies are missing from the given context, the
  /// default value of that trait will be used ([Brightness.light] platform
  /// brightness, normal contrast, [CupertinoUserInterfaceLevelData.base] elevation
  /// level), unless [nullOk] is set to false, in which case an exception will be
  /// thrown.
  CupertinoDynamicColor resolveFrom(BuildContext context, { bool nullOk = false }) {
    final Brightness brightness = _isPlatformBrightnessDependent
      ? CupertinoTheme.brightnessOf(context, nullOk: nullOk) ?? Brightness.light
      : Brightness.light;

    final bool isHighContrastEnabled = _isHighContrastDependent
      && (MediaQuery.of(context, nullOk: nullOk)?.highContrast ?? false);


    final CupertinoUserInterfaceLevelData level = _isInterfaceElevationDependent
      ? CupertinoUserInterfaceLevel.of(context, nullOk: nullOk) ?? CupertinoUserInterfaceLevelData.base
      : CupertinoUserInterfaceLevelData.base;

    Color resolved;
    switch (brightness) {
      case Brightness.light:
        switch (level) {
          case CupertinoUserInterfaceLevelData.base:
            resolved = isHighContrastEnabled ? highContrastColor : color;
            break;
          case CupertinoUserInterfaceLevelData.elevated:
            resolved = isHighContrastEnabled ? highContrastElevatedColor : elevatedColor;
            break;
        }
        break;
      case Brightness.dark:
        switch (level) {
          case CupertinoUserInterfaceLevelData.base:
            resolved = isHighContrastEnabled ? darkHighContrastColor : darkColor;
            break;
          case CupertinoUserInterfaceLevelData.elevated:
            resolved = isHighContrastEnabled ? darkHighContrastElevatedColor : darkElevatedColor;
            break;
        }
    }

    assert(resolved != null);
    return CupertinoDynamicColor._(
      resolved,
      color,
      darkColor,
      highContrastColor,
      darkHighContrastColor,
      elevatedColor,
      darkElevatedColor,
      highContrastElevatedColor,
      darkHighContrastElevatedColor,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;

    return other.runtimeType == runtimeType
        && value == other.value
        && color == other.color
        && darkColor == other.darkColor
        && highContrastColor == other.highContrastColor
        && darkHighContrastColor == other.darkHighContrastColor
        && elevatedColor == other.elevatedColor
        && darkElevatedColor == other.darkElevatedColor
        && highContrastElevatedColor == other.highContrastElevatedColor
        && darkHighContrastElevatedColor == other.darkHighContrastElevatedColor;
  }

  @override
  int get hashCode {
    return hashValues(
      value,
      color,
      darkColor,
      highContrastColor,
      elevatedColor,
      darkElevatedColor,
      darkHighContrastColor,
      darkHighContrastElevatedColor,
      highContrastElevatedColor,
    );
  }

  @override
  String toString() {
    String toString(String name, Color color) {
      final String marker = color.value == value ? '*' : '';
      return '$marker$name = $color$marker';
    }

    final List<String> xs = <String>[toString('color', color),
      if (_isPlatformBrightnessDependent) toString('darkColor', darkColor),
      if (_isHighContrastDependent) toString('highContrastColor', highContrastColor),
      if (_isPlatformBrightnessDependent && _isHighContrastDependent) toString('darkHighContrastColor', darkHighContrastColor),
      if (_isInterfaceElevationDependent) toString('elevatedColor', elevatedColor),
      if (_isPlatformBrightnessDependent && _isInterfaceElevationDependent) toString('darkElevatedColor', darkElevatedColor),
      if (_isHighContrastDependent && _isInterfaceElevationDependent) toString('highContrastElevatedColor', highContrastElevatedColor),
      if (_isPlatformBrightnessDependent && _isHighContrastDependent && _isInterfaceElevationDependent) toString('darkHighContrastElevatedColor', darkHighContrastElevatedColor),
    ];

    return '$runtimeType(${xs.join(', ')})';
  }
}

/// A color palette that typically matches iOS 13+ system colors.
///
/// Generally you should not create a [CupertinoSystemColorsData] yourself.
/// Use [CupertinoSystemColors.of] to get the [CupertinoSystemColorsData] from the
/// current [BuildContext] if possible, or [CupertinoSystemColors.fromSystem]
/// when the current [BuildContext] is not available (e.g., in [CupertinoApp]'s
/// constructor).
@immutable
class CupertinoSystemColorsData extends Diagnosticable {
  /// Creates a color palette.
  ///
  /// Generally you should not create your own `CupertinoSystemColorsData`.
  /// Use [CupertinoSystemColors.of] to get the [CupertinoSystemColorsData] from the
  /// current [BuildContext] if possible, or [CupertinoSystemColors.fromSystem]
  /// when the current [BuildContext] is not available (e.g., in [CupertinoApp]'s
  /// constructor).
  const CupertinoSystemColorsData({
    @required this.label,
    @required this.secondaryLabel,
    @required this.tertiaryLabel,
    @required this.quaternaryLabel,
    @required this.systemFill,
    @required this.secondarySystemFill,
    @required this.tertiarySystemFill,
    @required this.quaternarySystemFill,
    @required this.placeholderText,
    @required this.systemBackground,
    @required this.secondarySystemBackground,
    @required this.tertiarySystemBackground,
    @required this.systemGroupedBackground,
    @required this.secondarySystemGroupedBackground,
    @required this.tertiarySystemGroupedBackground,
    @required this.separator,
    @required this.opaqueSeparator,
    @required this.link,
    @required this.systemBlue,
    @required this.systemGreen,
    @required this.systemIndigo,
    @required this.systemOrange,
    @required this.systemPink,
    @required this.systemPurple,
    @required this.systemRed,
    @required this.systemTeal,
    @required this.systemYellow,
    @required this.systemGray,
    @required this.systemGray2,
    @required this.systemGray3,
    @required this.systemGray4,
    @required this.systemGray5,
    @required this.systemGray6,
  }) : assert(label != null),
       assert(secondaryLabel != null),
       assert(tertiaryLabel != null),
       assert(quaternaryLabel != null),
       assert(systemFill != null),
       assert(secondarySystemFill != null),
       assert(tertiarySystemFill != null),
       assert(quaternarySystemFill != null),
       assert(placeholderText != null),
       assert(systemBackground != null),
       assert(secondarySystemBackground != null),
       assert(tertiarySystemBackground != null),
       assert(systemGroupedBackground != null),
       assert(secondarySystemGroupedBackground != null),
       assert(tertiarySystemGroupedBackground != null),
       assert(separator != null),
       assert(opaqueSeparator != null),
       assert(link != null),
       assert(systemBlue != null),
       assert(systemGreen != null),
       assert(systemIndigo != null),
       assert(systemOrange != null),
       assert(systemPink != null),
       assert(systemPurple != null),
       assert(systemRed != null),
       assert(systemTeal != null),
       assert(systemYellow != null),
       assert(systemGray != null),
       assert(systemGray2 != null),
       assert(systemGray3 != null),
       assert(systemGray4 != null),
       assert(systemGray5 != null),
       assert(systemGray6 != null),
       super();

  /// The color for text labels containing primary content.
  final CupertinoDynamicColor label;

  /// The color for text labels containing secondary content.
  final CupertinoDynamicColor secondaryLabel;

  /// The color for text labels containing tertiary content.
  final CupertinoDynamicColor tertiaryLabel;

  /// The color for text labels containing quaternary content.
  final CupertinoDynamicColor quaternaryLabel;

  /// An overlay fill color for thin and small shapes.
  final CupertinoDynamicColor systemFill;

  /// An overlay fill color for medium-size shapes.
  final CupertinoDynamicColor secondarySystemFill;

  /// An overlay fill color for large shapes.
  final CupertinoDynamicColor tertiarySystemFill;

  /// An overlay fill color for large areas containing complex content.
  final CupertinoDynamicColor quaternarySystemFill;

  /// The color for placeholder text in controls or text views.
  final CupertinoDynamicColor placeholderText;

  /// The color for the main background of your interface.
  ///
  /// Typically used for designs that have a white primary background in a light environment.
  final CupertinoDynamicColor systemBackground;

  /// The color for content layered on top of the main background.
  ///
  /// Typically used for designs that have a white primary background in a light environment.
  final CupertinoDynamicColor secondarySystemBackground;

  /// The color for content layered on top of secondary backgrounds.
  ///
  /// Typically used for designs that have a white primary background in a light environment.
  final CupertinoDynamicColor tertiarySystemBackground;

  /// The color for the main background of your grouped interface.
  ///
  /// Typically used for grouped content, including table views and platter-based designs.
  final CupertinoDynamicColor systemGroupedBackground;

  /// The color for content layered on top of the main background of your grouped interface.
  ///
  /// Typically used for grouped content, including table views and platter-based designs.
  final CupertinoDynamicColor secondarySystemGroupedBackground;

  /// The color for content layered on top of secondary backgrounds of your grouped interface.
  ///
  /// Typically used for grouped content, including table views and platter-based designs.
  final CupertinoDynamicColor tertiarySystemGroupedBackground;

  /// The color for thin borders or divider lines that allows some underlying content to be visible.
  final CupertinoDynamicColor separator;

  /// The color for borders or divider lines that hide any underlying content.
  final CupertinoDynamicColor opaqueSeparator;

  /// The color for links.
  final CupertinoDynamicColor link;

  /// A blue color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemBlue;

  /// A green color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemGreen;

  /// An indigo color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemIndigo;

  /// An orange color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemOrange;

  /// A pink color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemPink;

  /// A purple color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemPurple;

  /// A red color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemRed;

  /// A teal color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemTeal;

  /// A yellow color that can adapt to the given [BuildContext].
  final CupertinoDynamicColor systemYellow;

  /// The base gray color.
  final CupertinoDynamicColor systemGray;

  /// A second-level shade of grey.
  final CupertinoDynamicColor systemGray2;

  /// A third-level shade of grey.
  final CupertinoDynamicColor systemGray3;

  /// A fourth-level shade of grey.
  final CupertinoDynamicColor systemGray4;

  /// A fifth-level shade of grey.
  final CupertinoDynamicColor systemGray5;

  /// A sixth-level shade of grey.
  final CupertinoDynamicColor systemGray6;

  /// Resolve every color in the palette using the given [BuildContext], by calling
  /// [CupertinoDynamicColor.resolve], and return a new [CupertinoSystemColorsData]
  /// with all the resolved colors.
  CupertinoSystemColorsData resolveColors(BuildContext context) {
    return CupertinoSystemColorsData(
      label: CupertinoDynamicColor.resolve(label, context),
      secondaryLabel: CupertinoDynamicColor.resolve(secondaryLabel, context),
      tertiaryLabel: CupertinoDynamicColor.resolve(tertiaryLabel, context),
      quaternaryLabel: CupertinoDynamicColor.resolve(quaternaryLabel, context),
      systemFill: CupertinoDynamicColor.resolve(systemFill, context),
      secondarySystemFill: CupertinoDynamicColor.resolve(secondarySystemFill, context),
      tertiarySystemFill: CupertinoDynamicColor.resolve(tertiarySystemFill, context),
      quaternarySystemFill: CupertinoDynamicColor.resolve(quaternarySystemFill, context),
      placeholderText: CupertinoDynamicColor.resolve(placeholderText, context),
      systemBackground: CupertinoDynamicColor.resolve(systemBackground, context),
      secondarySystemBackground: CupertinoDynamicColor.resolve(secondarySystemBackground, context),
      tertiarySystemBackground: CupertinoDynamicColor.resolve(tertiarySystemBackground, context),
      systemGroupedBackground: CupertinoDynamicColor.resolve(systemGroupedBackground, context),
      secondarySystemGroupedBackground: CupertinoDynamicColor.resolve(secondarySystemGroupedBackground, context),
      tertiarySystemGroupedBackground: CupertinoDynamicColor.resolve(tertiarySystemGroupedBackground, context),
      separator: CupertinoDynamicColor.resolve(separator, context),
      opaqueSeparator: CupertinoDynamicColor.resolve(opaqueSeparator, context),
      link: CupertinoDynamicColor.resolve(link, context),
      systemBlue: CupertinoDynamicColor.resolve(systemBlue, context),
      systemGreen: CupertinoDynamicColor.resolve(systemGreen, context),
      systemIndigo: CupertinoDynamicColor.resolve(systemIndigo, context),
      systemOrange: CupertinoDynamicColor.resolve(systemOrange, context),
      systemPink: CupertinoDynamicColor.resolve(systemPink, context),
      systemPurple: CupertinoDynamicColor.resolve(systemPurple, context),
      systemRed: CupertinoDynamicColor.resolve(systemRed, context),
      systemTeal: CupertinoDynamicColor.resolve(systemTeal, context),
      systemYellow: CupertinoDynamicColor.resolve(systemYellow, context),
      systemGray: CupertinoDynamicColor.resolve(systemGray, context),
      systemGray2: CupertinoDynamicColor.resolve(systemGray2, context),
      systemGray3: CupertinoDynamicColor.resolve(systemGray3, context),
      systemGray4: CupertinoDynamicColor.resolve(systemGray4, context),
      systemGray5: CupertinoDynamicColor.resolve(systemGray5, context),
      systemGray6: CupertinoDynamicColor.resolve(systemGray6, context),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    return other.runtimeType == runtimeType
        && other.label == label
        && other.secondaryLabel == secondaryLabel
        && other.tertiaryLabel == tertiaryLabel
        && other.quaternaryLabel == quaternaryLabel
        && other.systemFill == systemFill
        && other.secondarySystemFill == secondarySystemFill
        && other.tertiarySystemFill == tertiarySystemFill
        && other.quaternarySystemFill == quaternarySystemFill
        && other.placeholderText == placeholderText
        && other.systemBackground == systemBackground
        && other.secondarySystemBackground == secondarySystemBackground
        && other.tertiarySystemBackground == tertiarySystemBackground
        && other.systemGroupedBackground == systemGroupedBackground
        && other.secondarySystemGroupedBackground == secondarySystemGroupedBackground
        && other.tertiarySystemGroupedBackground == tertiarySystemGroupedBackground
        && other.separator == separator
        && other.opaqueSeparator== opaqueSeparator
        && other.link == link
        && other.systemBlue == systemBlue
        && other.systemGreen == systemGreen
        && other.systemIndigo == systemIndigo
        && other.systemOrange == systemOrange
        && other.systemPink == systemPink
        && other.systemPurple == systemPurple
        && other.systemRed == systemRed
        && other.systemTeal == systemTeal
        && other.systemYellow == systemYellow
        && other.systemGray == systemGray
        && other.systemGray2 == systemGray2
        && other.systemGray3 == systemGray3
        && other.systemGray4 == systemGray4
        && other.systemGray5 == systemGray5
        && other.systemGray6 == systemGray6;
  }

  @override
  int get hashCode {
    return hashList(
      <Color>[
        label,
        secondaryLabel,
        tertiaryLabel,
        quaternaryLabel,
        systemFill,
        secondarySystemFill,
        tertiarySystemFill,
        quaternarySystemFill,
        placeholderText,
        systemBackground,
        secondarySystemBackground,
        tertiarySystemBackground,
        systemGroupedBackground,
        secondarySystemGroupedBackground,
        tertiarySystemGroupedBackground,
        separator,
        opaqueSeparator,
        link,
        systemBlue,
        systemGreen,
        systemIndigo,
        systemOrange,
        systemPink,
        systemPurple,
        systemRed,
        systemTeal,
        systemYellow,
        systemGray,
        systemGray2,
        systemGray3,
        systemGray4,
        systemGray5,
        systemGray6,
    ]);
  }

  /// Creates a copy of this CupertinoSystemColorsData but with the given fields
  /// replace with the new values.
  CupertinoSystemColorsData copyWith({
    CupertinoDynamicColor label,
    CupertinoDynamicColor secondaryLabel,
    CupertinoDynamicColor tertiaryLabel,
    CupertinoDynamicColor quaternaryLabel,
    CupertinoDynamicColor systemFill,
    CupertinoDynamicColor secondarySystemFill,
    CupertinoDynamicColor tertiarySystemFill,
    CupertinoDynamicColor quaternarySystemFill,
    CupertinoDynamicColor placeholderText,
    CupertinoDynamicColor systemBackground,
    CupertinoDynamicColor secondarySystemBackground,
    CupertinoDynamicColor tertiarySystemBackground,
    CupertinoDynamicColor systemGroupedBackground,
    CupertinoDynamicColor secondarySystemGroupedBackground,
    CupertinoDynamicColor tertiarySystemGroupedBackground,
    CupertinoDynamicColor separator,
    CupertinoDynamicColor opaqueSeparator,
    CupertinoDynamicColor link,
    CupertinoDynamicColor systemBlue,
    CupertinoDynamicColor systemGreen,
    CupertinoDynamicColor systemIndigo,
    CupertinoDynamicColor systemOrange,
    CupertinoDynamicColor systemPink,
    CupertinoDynamicColor systemPurple,
    CupertinoDynamicColor systemRed,
    CupertinoDynamicColor systemTeal,
    CupertinoDynamicColor systemYellow,
    CupertinoDynamicColor systemGray,
    CupertinoDynamicColor systemGray2,
    CupertinoDynamicColor systemGray3,
    CupertinoDynamicColor systemGray4,
    CupertinoDynamicColor systemGray5,
    CupertinoDynamicColor systemGray6,
  }) {
    return CupertinoSystemColorsData(
      label: label ?? this.label,
      secondaryLabel: secondaryLabel ?? this.secondaryLabel,
      tertiaryLabel: tertiaryLabel ?? this.tertiaryLabel,
      quaternaryLabel: quaternaryLabel ?? this.quaternaryLabel,
      systemFill: systemFill ?? this.systemFill,
      secondarySystemFill: secondarySystemFill ?? this.secondarySystemFill,
      tertiarySystemFill: tertiarySystemFill ?? this.tertiarySystemFill,
      quaternarySystemFill: quaternarySystemFill ?? this.quaternarySystemFill,
      placeholderText: placeholderText ?? this.placeholderText,
      systemBackground: systemBackground ?? this.systemBackground,
      secondarySystemBackground: secondarySystemBackground ?? this.secondarySystemBackground,
      tertiarySystemBackground: tertiarySystemBackground ?? this.tertiarySystemBackground,
      systemGroupedBackground: systemGroupedBackground ?? this.systemGroupedBackground,
      secondarySystemGroupedBackground: secondarySystemGroupedBackground ?? this.secondarySystemGroupedBackground,
      tertiarySystemGroupedBackground: tertiarySystemGroupedBackground ?? this.tertiarySystemGroupedBackground,
      separator: separator ?? this.separator,
      opaqueSeparator: opaqueSeparator ?? this.opaqueSeparator,
      link: link ?? this.link,
      systemBlue: systemBlue ?? this.systemBlue,
      systemGreen: systemGreen ?? this.systemGreen,
      systemIndigo: systemIndigo ?? this.systemIndigo,
      systemOrange: systemOrange ?? this.systemOrange,
      systemPink: systemPink ?? this.systemPink,
      systemPurple: systemPurple ?? this.systemPurple,
      systemRed: systemRed ?? this.systemRed,
      systemTeal: systemTeal ?? this.systemTeal,
      systemYellow: systemYellow ?? this.systemYellow,
      systemGray: systemGray ?? this.systemGray,
      systemGray2: systemGray2 ?? this.systemGray2,
      systemGray3: systemGray3 ?? this.systemGray3,
      systemGray4: systemGray4 ?? this.systemGray4,
      systemGray5: systemGray5 ?? this.systemGray5,
      systemGray6: systemGray6 ?? this.systemGray6,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('label', label));
    properties.add(ColorProperty('secondaryLabel', secondaryLabel));
    properties.add(ColorProperty('tertiaryLabel', tertiaryLabel));
    properties.add(ColorProperty('quaternaryLabel', quaternaryLabel));
    properties.add(ColorProperty('systemFill', systemFill));
    properties.add(ColorProperty('secondarySystemFill', secondarySystemFill));
    properties.add(ColorProperty('tertiarySystemFill', tertiarySystemFill));
    properties.add(ColorProperty('quaternarySystemFill', quaternarySystemFill));
    properties.add(ColorProperty('placeholderText', placeholderText));
    properties.add(ColorProperty('systemBackground', systemBackground));
    properties.add(ColorProperty('secondarySystemBackground', secondarySystemBackground));
    properties.add(ColorProperty('tertiarySystemBackground', tertiarySystemBackground));
    properties.add(ColorProperty('systemGroupedBackground', systemGroupedBackground));
    properties.add(ColorProperty('secondarySystemGroupedBackground', secondarySystemGroupedBackground));
    properties.add(ColorProperty('tertiarySystemGroupedBackground', tertiarySystemGroupedBackground));
    properties.add(ColorProperty('separator', separator));
    properties.add(ColorProperty('opaqueSeparator', opaqueSeparator));
    properties.add(ColorProperty('link', link));
    properties.add(ColorProperty('systemBlue', systemBlue));
    properties.add(ColorProperty('systemGreen', systemGreen));
    properties.add(ColorProperty('systemIndigo', systemIndigo));
    properties.add(ColorProperty('systemOrange', systemOrange));
    properties.add(ColorProperty('systemPink', systemPink));
    properties.add(ColorProperty('systemPurple', systemPurple));
    properties.add(ColorProperty('systemRed', systemRed));
    properties.add(ColorProperty('systemTeal', systemTeal));
    properties.add(ColorProperty('systemYellow', systemYellow));
    properties.add(ColorProperty('systemGray', systemGray));
    properties.add(ColorProperty('systemGray2', systemGray2));
    properties.add(ColorProperty('systemGray3', systemGray3));
    properties.add(ColorProperty('systemGray4', systemGray4));
    properties.add(ColorProperty('systemGray5', systemGray5));
    properties.add(ColorProperty('systemGray6', systemGray6));
  }
}

/// Establishes a subtree where iOS system colors resolve to the given data.
///
/// Typically the given [CupertinoSystemColorsData] is resolved against its own
/// [BuildContext] using [CupertinoSystemColorsData.resolveColors].
class CupertinoSystemColors extends InheritedWidget {
  /// Creates a widget that provides a given [CupertinoSystemColorsData] to its
  /// descendants.
  const CupertinoSystemColors({
    Key key,
    @required CupertinoSystemColorsData data,
    Widget child,
  }) : _data = data,
       assert(data != null),
       super(key: key, child: child);

  final CupertinoSystemColorsData _data;

  @override
  bool updateShouldNotify(CupertinoSystemColors oldWidget) => oldWidget._data != _data;

  /// Retrieves the iOS system colors from the given [BuildContext].
  ///
  /// Falls back to [fromSystem] if a [CupertinoSystemColors] widget couldn't be
  /// found in the ancestry tree. When [fromSystem] returns null, setting [useFallbackValues]
  /// to true will make the method return a set of default system colors extracted
  /// from iOS 13 beta.
  static CupertinoSystemColorsData of(BuildContext context, { bool useFallbackValues = true }) {
    assert(context != null);
    assert(useFallbackValues != null);
    final CupertinoSystemColors widget = context.inheritFromWidgetOfExactType(CupertinoSystemColors);
    return widget?._data ?? (useFallbackValues ? _kSystemColorsFallback : null);
  }
}

// Fallback System Colors, extracted from:
// https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/#dynamic-system-colors
// and iOS 13 beta.
const CupertinoSystemColorsData _kSystemColorsFallback = CupertinoSystemColorsData(
  label: CupertinoDynamicColor(
    color: Color.fromARGB(255, 0, 0, 0),
    darkColor: Color.fromARGB(255, 255, 255, 255),
    highContrastColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 255, 255),
    elevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkElevatedColor: Color.fromARGB(255, 255, 255, 255),
    highContrastElevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
  ),
  secondaryLabel: CupertinoDynamicColor(
    color: Color.fromARGB(255, 0, 0, 0),
    darkColor: Color.fromARGB(255, 255, 255, 255),
    highContrastColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 255, 255),
    elevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkElevatedColor: Color.fromARGB(255, 255, 255, 255),
    highContrastElevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
  ),
  tertiaryLabel: CupertinoDynamicColor(
    color: Color.fromARGB(76, 60, 60, 67),
    darkColor: Color.fromARGB(76, 235, 235, 245),
    highContrastColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(96, 235, 235, 245),
    elevatedColor: Color.fromARGB(76, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(76, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(96, 235, 235, 245),
  ),
  quaternaryLabel: CupertinoDynamicColor(
    color: Color.fromARGB(45, 60, 60, 67),
    darkColor: Color.fromARGB(40, 235, 235, 245),
    highContrastColor: Color.fromARGB(66, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(61, 235, 235, 245),
    elevatedColor: Color.fromARGB(45, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(40, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(66, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(61, 235, 235, 245),
  ),
  systemFill: CupertinoDynamicColor(
    color: Color.fromARGB(51, 120, 120, 128),
    darkColor: Color.fromARGB(91, 120, 120, 128),
    highContrastColor: Color.fromARGB(71, 120, 120, 128),
    darkHighContrastColor: Color.fromARGB(112, 120, 120, 128),
    elevatedColor: Color.fromARGB(51, 120, 120, 128),
    darkElevatedColor: Color.fromARGB(91, 120, 120, 128),
    highContrastElevatedColor: Color.fromARGB(71, 120, 120, 128),
    darkHighContrastElevatedColor: Color.fromARGB(112, 120, 120, 128),
  ),
  secondarySystemFill: CupertinoDynamicColor(
    color: Color.fromARGB(153, 60, 60, 67),
    darkColor: Color.fromARGB(153, 235, 235, 245),
    highContrastColor: Color.fromARGB(173, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(173, 235, 235, 245),
    elevatedColor: Color.fromARGB(153, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(153, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(173, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(173, 235, 235, 245),
  ),
  tertiarySystemFill: CupertinoDynamicColor(
    color: Color.fromARGB(30, 118, 118, 128),
    darkColor: Color.fromARGB(61, 118, 118, 128),
    highContrastColor: Color.fromARGB(51, 118, 118, 128),
    darkHighContrastColor: Color.fromARGB(81, 118, 118, 128),
    elevatedColor: Color.fromARGB(30, 118, 118, 128),
    darkElevatedColor: Color.fromARGB(61, 118, 118, 128),
    highContrastElevatedColor: Color.fromARGB(51, 118, 118, 128),
    darkHighContrastElevatedColor: Color.fromARGB(81, 118, 118, 128),
  ),
  quaternarySystemFill: CupertinoDynamicColor(
    color: Color.fromARGB(20, 116, 116, 128),
    darkColor: Color.fromARGB(45, 118, 118, 128),
    highContrastColor: Color.fromARGB(40, 116, 116, 128),
    darkHighContrastColor: Color.fromARGB(66, 118, 118, 128),
    elevatedColor: Color.fromARGB(20, 116, 116, 128),
    darkElevatedColor: Color.fromARGB(45, 118, 118, 128),
    highContrastElevatedColor: Color.fromARGB(40, 116, 116, 128),
    darkHighContrastElevatedColor: Color.fromARGB(66, 118, 118, 128),
  ),
  placeholderText: CupertinoDynamicColor(
    color: Color.fromARGB(76, 60, 60, 67),
    darkColor: Color.fromARGB(76, 235, 235, 245),
    highContrastColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(96, 235, 235, 245),
    elevatedColor: Color.fromARGB(76, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(76, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(96, 235, 235, 245),
  ),
  systemBackground: CupertinoDynamicColor(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 0, 0, 0),
    highContrastColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastColor: Color.fromARGB(255, 0, 0, 0),
    elevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkElevatedColor: Color.fromARGB(255, 28, 28, 30),
    highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 36, 36, 38),
  ),
  secondarySystemBackground: CupertinoDynamicColor(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 28, 28, 30),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 36, 36, 38),
    elevatedColor: Color.fromARGB(255, 242, 242, 247),
    darkElevatedColor: Color.fromARGB(255, 44, 44, 46),
    highContrastElevatedColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastElevatedColor: Color.fromARGB(255, 54, 54, 56),
  ),
  tertiarySystemBackground: CupertinoDynamicColor(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 44, 44, 46),
    highContrastColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastColor: Color.fromARGB(255, 54, 54, 56),
    elevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkElevatedColor: Color.fromARGB(255, 58, 58, 60),
    highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 68, 68, 70),
  ),
  systemGroupedBackground: CupertinoDynamicColor(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 0, 0, 0),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 0, 0, 0),
    elevatedColor: Color.fromARGB(255, 242, 242, 247),
    darkElevatedColor: Color.fromARGB(255, 28, 28, 30),
    highContrastElevatedColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastElevatedColor: Color.fromARGB(255, 36, 36, 38),
  ),
  secondarySystemGroupedBackground: CupertinoDynamicColor(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 28, 28, 30),
    highContrastColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastColor: Color.fromARGB(255, 36, 36, 38),
    elevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkElevatedColor: Color.fromARGB(255, 44, 44, 46),
    highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 54, 54, 56),
  ),
  tertiarySystemGroupedBackground: CupertinoDynamicColor(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 44, 44, 46),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 54, 54, 56),
    elevatedColor: Color.fromARGB(255, 242, 242, 247),
    darkElevatedColor: Color.fromARGB(255, 58, 58, 60),
    highContrastElevatedColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastElevatedColor: Color.fromARGB(255, 68, 68, 70),
  ),
  separator: CupertinoDynamicColor(
    color: Color.fromARGB(73, 60, 60, 67),
    darkColor: Color.fromARGB(153, 84, 84, 88),
    highContrastColor: Color.fromARGB(94, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(173, 84, 84, 88),
    elevatedColor: Color.fromARGB(73, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(153, 84, 84, 88),
    highContrastElevatedColor: Color.fromARGB(94, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(173, 84, 84, 88),
  ),
  opaqueSeparator: CupertinoDynamicColor(
    color: Color.fromARGB(255, 198, 198, 200),
    darkColor: Color.fromARGB(255, 56, 56, 58),
    highContrastColor: Color.fromARGB(255, 198, 198, 200),
    darkHighContrastColor: Color.fromARGB(255, 56, 56, 58),
    elevatedColor: Color.fromARGB(255, 198, 198, 200),
    darkElevatedColor: Color.fromARGB(255, 56, 56, 58),
    highContrastElevatedColor: Color.fromARGB(255, 198, 198, 200),
    darkHighContrastElevatedColor: Color.fromARGB(255, 56, 56, 58),
  ),
  link: CupertinoDynamicColor(
    color: Color.fromARGB(255, 0, 122, 255),
    darkColor: Color.fromARGB(255, 9, 132, 255),
    highContrastColor: Color.fromARGB(255, 0, 122, 255),
    darkHighContrastColor: Color.fromARGB(255, 9, 132, 255),
    elevatedColor: Color.fromARGB(255, 0, 122, 255),
    darkElevatedColor: Color.fromARGB(255, 9, 132, 255),
    highContrastElevatedColor: Color.fromARGB(255, 0, 122, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 9, 132, 255),
  ),
  systemBlue: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 0, 122, 255),
    darkColor: Color.fromARGB(255, 10, 132, 255),
    highContrastColor: Color.fromARGB(255, 0, 64, 221),
    darkHighContrastColor: Color.fromARGB(255, 64, 156, 255),
  ),
  systemGreen: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 52, 199, 89),
    darkColor: Color.fromARGB(255, 48, 209, 88),
    highContrastColor: Color.fromARGB(255, 36, 138, 61),
    darkHighContrastColor: Color.fromARGB(255, 48, 219, 91),
  ),
  systemIndigo: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 88, 86, 214),
    darkColor: Color.fromARGB(255, 94, 92, 230),
    highContrastColor: Color.fromARGB(255, 54, 52, 163),
    darkHighContrastColor: Color.fromARGB(255, 125, 122, 255),
  ),
  systemOrange: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 149, 0),
    darkColor: Color.fromARGB(255, 255, 159, 10),
    highContrastColor: Color.fromARGB(255, 201, 52, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 179, 64),
  ),
  systemPink: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 45, 85),
    darkColor: Color.fromARGB(255, 255, 55, 95),
    highContrastColor: Color.fromARGB(255, 211, 15, 69),
    darkHighContrastColor: Color.fromARGB(255, 255, 100, 130),
  ),
  systemPurple: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 175, 82, 222),
    darkColor: Color.fromARGB(255, 191, 90, 242),
    highContrastColor: Color.fromARGB(255, 137, 68, 171),
    darkHighContrastColor: Color.fromARGB(255, 218, 143, 255),
  ),
  systemRed: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 59, 48),
    darkColor: Color.fromARGB(255, 255, 69, 58),
    highContrastColor: Color.fromARGB(255, 215, 0, 21),
    darkHighContrastColor: Color.fromARGB(255, 255, 105, 97),
  ),
  systemTeal: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 90, 200, 250),
    darkColor: Color.fromARGB(255, 100, 210, 255),
    highContrastColor: Color.fromARGB(255, 0, 113, 164),
    darkHighContrastColor: Color.fromARGB(255, 112, 215, 255),
  ),
  systemYellow: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 204, 0),
    darkColor: Color.fromARGB(255, 255, 214, 10),
    highContrastColor: Color.fromARGB(255, 160, 90, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 212, 38),
  ),
  systemGray: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 142, 142, 147),
    darkColor: Color.fromARGB(255, 142, 142, 147),
    highContrastColor: Color.fromARGB(255, 108, 108, 112),
    darkHighContrastColor: Color.fromARGB(255, 174, 174, 178),
  ),
  systemGray2: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 174, 174, 178),
    darkColor: Color.fromARGB(255, 99, 99, 102),
    highContrastColor: Color.fromARGB(255, 142, 142, 147),
    darkHighContrastColor: Color.fromARGB(255, 124, 124, 128),
  ),
  systemGray3: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 199, 199, 204),
    darkColor: Color.fromARGB(255, 72, 72, 74),
    highContrastColor: Color.fromARGB(255, 174, 174, 178),
    darkHighContrastColor: Color.fromARGB(255, 84, 84, 86),
  ),
  systemGray4: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 209, 209, 214),
    darkColor: Color.fromARGB(255, 58, 58, 60),
    highContrastColor: Color.fromARGB(255, 188, 188, 192),
    darkHighContrastColor: Color.fromARGB(255, 68, 68, 70),
  ),
  systemGray5: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 229, 229, 234),
    darkColor: Color.fromARGB(255, 44, 44, 46),
    highContrastColor: Color.fromARGB(255, 216, 216, 220),
    darkHighContrastColor: Color.fromARGB(255, 54, 54, 56),
  ),
  systemGray6: CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 28, 28, 30),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 36, 36, 38),
  ),
);
