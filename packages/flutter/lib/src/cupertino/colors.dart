// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;
import 'package:collection/collection.dart';
import 'package:flutter/src/widgets/basic.dart';

import '../../foundation.dart';
import '../widgets/framework.dart' show BuildContext;
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

/// A color that can be resolved to different [Color]s, based on the [BuildContext]
/// provided.
///
/// `CupertinoDynamicColor` is a subtype of [Color]. When used as a regular color,
/// it is equivalent to [defaultColor], or [normalColor] if [defaultColor] is not
/// specified.
///
// TODO(LongCatIsLooong): publicize once all Cupertino components have adopted this.
// This class is typically used in Cupertino components to represent colors that
// may change in different [BuildContext].
//
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
//     normalColor: lightModeColor,
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
  /// Creates a [Color] that can be resolved to different [Color]s in different
  /// [BuildContext], using [CupertinoDynamicColor.resolve].
  ///
  /// [defaultColor] will be used in other colors' absence, and it must not be null,
  /// unless all the other colors are not null.
  CupertinoDynamicColor({
    Color defaultColor,
    Color normalColor,
    Color darkColor,
    Color highContrastColor,
    Color darkHighContrastColor,
    Color elevatedColor,
    Color darkElevatedColor,
    Color highContrastElevatedColor,
    Color darkHighContrastElevatedColor,
  }) : this._(
         defaultColor,
         <Color>[
           normalColor,
           darkColor,
           highContrastColor,
           darkHighContrastColor,
           elevatedColor,
           darkElevatedColor,
           highContrastElevatedColor,
           darkHighContrastElevatedColor,
         ]
       );

  /// Creates a Color that can be resolved to different [Color]s, based on the given
  /// [BuildContext]'s color vibrancy and accessibility contrast.
  ///
  /// [defaultColor] will be used in other colors' absence, and it must not be null,
  /// unless all the other colors are not null.
  CupertinoDynamicColor.withVibrancyAndContrast({
    Color defaultColor,
    Color normalColor,
    Color darkColor,
    Color highContrastColor,
    Color darkHighContrastColor,
  }) : this(
    defaultColor: defaultColor,
    normalColor: normalColor,
    darkColor: darkColor,
    highContrastColor: highContrastColor,
    darkHighContrastColor: darkHighContrastColor,
    elevatedColor: normalColor,
    darkElevatedColor: darkColor,
    highContrastElevatedColor: highContrastColor,
    darkHighContrastElevatedColor: darkHighContrastColor,
  );

  /// Creates a Color that can be resolved to different [Color]s, based on the given
  /// [BuildContext]'s color vibrancy.
  ///
  /// [defaultColor] will be used in other colors' absence, and it must not be null,
  /// unless all the other colors are not null.
  CupertinoDynamicColor.withVibrancy({
    Color defaultColor,
    Color normalColor,
    Color darkColor,
  }) : this(
    defaultColor: defaultColor,
    normalColor: normalColor,
    darkColor: darkColor,
    highContrastColor: normalColor,
    darkHighContrastColor: darkColor,
    elevatedColor: normalColor,
    darkElevatedColor: darkColor,
    highContrastElevatedColor: normalColor,
    darkHighContrastElevatedColor: darkColor,
  );

  CupertinoDynamicColor._(
    this.defaultColor,
    this._colorMap,
  ) : assert(defaultColor != null || !_colorMap.contains(null)),
      assert(_colorMap.length == 8),
      super(defaultColor?.value ?? _colorMap[0].value);

  /// The defaultColor color to use when the requested color is not specified.
  ///
  /// Must not be null unless all other colors are specified.
  final Color defaultColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// normal contrast, and base interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get normalColor => _colorMap[0];

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// normal contrast, and base interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get darkColor => _colorMap[1];

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// high contrast, and base interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get highContrastColor => _colorMap[2];

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// high contrast, and base interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get darkHighContrastColor => _colorMap[3];

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// normal contrast, and elevated interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get elevatedColor => _colorMap[4];

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// normal contrast, and elevated interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get darkElevatedColor => _colorMap[5];

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// high contrast, and elevated interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get highContrastElevatedColor => _colorMap[6];

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// high contrast, and elevated interface elevation.
  ///
  /// Defaults to [defaultColor] when unspecified.
  Color get darkHighContrastElevatedColor => _colorMap[7];

  final List<Color> _colorMap;

  /// Resolves the given [Color] to a concrete [Color], using the given [BuildContext].
  /// If the given color is already a concrete [Color], it will be returned as is.
  static Color resolve(Color resolvable, BuildContext context, { bool nullOk = false })
    => (resolvable is CupertinoDynamicColor)
      ? resolvable.resolveFrom(context, nullOk: nullOk)
      : resolvable;

  /// Resolves this `CupertinoDynamicColor` using the provided [BuildContext].
  ///
  /// Calling this method will create a new `CupertinoDynamicColor` that is almost
  /// identical to the orignal `CupertinoDynamicColor` except with a different
  /// [defaultColor], such that when the new `CupertinoDynamicColor` is used as
  /// a regular [Color], it is equivalent to one of the specified colors that
  /// matches the given [BuildContext]'s traits.
  ///
  /// For example, if the given [BuildContext] indicates the widgets in the subtree
  /// should be displayed in dark mode, with high accessibility contrast and an
  /// elevated interface elevation, the resolved `CupertinoDynamicColor` will be
  /// the same as this [CupertinoDynamicColor], except that its [defaultColor]
  /// is `darkHighContrastElevatedColor` from the orignal `CupertinoDynamicColor`.
  ///
  /// Calling this function may create dependencies on the closest instance of some
  /// [InheritedWidget]s that enclose the given [BuildContext]. E.g., if [darkColor]
  /// is different from [normalColor], this function will call [CupertinoTheme.of],
  /// and then [MediaQuery.of] if brightness wasn't specified in the theme data
  /// retrived from the previous [CupertinoTheme.of] call, in an effort to determine
  /// the brightness value.
  ///
  /// If any of the required dependecies is missing from the given context, an exception
  /// will be thrown unless [nullOk] is set to `true`.
  CupertinoDynamicColor resolveFrom(BuildContext context, { bool nullOk = false }) {
    int dependencyBitMask = 0, configBitMask = 0;
    final List<Color> colors = _colorMap;

    for (int i = 0; i < colors.length; i++) {
      for(int bitShift = 0; bitShift < 3; bitShift ++) {
        // mask - represented trait
        // 001  - color vibrancy
        // 010  - accessibility contrast
        // 100  - user interface level
        final int mask = 1 << bitShift;
        if (i & mask != 0 || dependencyBitMask & mask != 0)
          continue;
        final bool isSameColor = (colors[i] ?? defaultColor) == (colors[i | mask] ?? defaultColor);
        dependencyBitMask |= isSameColor ? 0 : mask;
      }
    }

    // If this CupertinoDynamicColor cares about color vibrancy.
    if (dependencyBitMask & 1 != 0) {
      final CupertinoThemeData themeData = CupertinoTheme.of(context).noDefault();
      final Brightness brightness = themeData.brightness
        ?? MediaQuery.of(context, nullOk: nullOk)?.platformBrightness
        ?? Brightness.light;

      switch (brightness) {
        case Brightness.light:
          break;
        case Brightness.dark:
          configBitMask |= 1;
      }
    }

    // If this CupertinoDynamicColor cares about accessibility contrast.
    if (dependencyBitMask & 2 != 0) {
      final bool isHighContrastEnabled = MediaQuery.of(context, nullOk: nullOk)?.highContrastContent
        ?? false;

        configBitMask |= isHighContrastEnabled ? 2 : 0;
    }

    // If this CupertinoDynamicColor cares about user interface elevation.
    if (dependencyBitMask & 4 != 0) {
      final CupertinoUserInterfaceLevelData level =
        CupertinoUserInterfaceLevel.of(context, nullOk: nullOk)
        ?? CupertinoUserInterfaceLevelData.base;

      switch (level) {
        case CupertinoUserInterfaceLevelData.base:
          break;
        case CupertinoUserInterfaceLevelData.elevated:
          configBitMask |= 4;
      }
    }

    final Color resolved = _colorMap[configBitMask] ?? defaultColor;
    return resolved == defaultColor ? this : CupertinoDynamicColor._(resolved, _colorMap);
  }

  @override
  bool operator ==(dynamic other) {
    return other.runtimeType == runtimeType
        && value == other.value
        && ListEquality<Color>(_ColorMapElementEquality<Color>(defaultColor, other.defaultColor))
            .equals(_colorMap, other._colorMap);
  }

  @override
  int get hashCode => _colorMap.map((Color color) => color ?? defaultColor).hashCode;

  @override
  String toString() => '$runtimeType { $defaultColor & $_colorMap }';
}

class _ColorMapElementEquality<E> extends DefaultEquality<E> {
  const _ColorMapElementEquality(this.nullFallbackValue1, this.nullFallbackValue2) : super();
  final E nullFallbackValue1, nullFallbackValue2;

  @override
  bool equals(Object e1, Object e2) => (e1 ?? nullFallbackValue1) == (e2 ?? nullFallbackValue2);
}

/// A color palette that typically matches iOS 13+ system colors.
///
/// Generally you shouldn't not create a [CupertinoSystemColorData] yourself.
/// Use [CupertinoSystemColors.of] to get the [CupertinoSystemColorData] from the
/// current [BuildContext] if possible, or [CupertinoSystemColors.fromSystem]
/// when the current [BuildContext] is not available (e.g., in [CupertinoApp]'s
/// constructor).
@immutable
class CupertinoSystemColorData extends Diagnosticable {
  /// Creates a color palette.
  ///
  /// Generally you should not create your own `CupertinoSystemColorData`.
  /// Use [CupertinoSystemColors.of] to get the [CupertinoSystemColorData] from the
  /// current [BuildContext] if possible, or [CupertinoSystemColors.fromSystem]
  /// when the current [BuildContext] is not available (e.g., in [CupertinoApp]'s
  /// constructor).
  const CupertinoSystemColorData({
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
  /// [CupertinoDynamicColor.resolve], and return a new [CupertinoSystemColorData]
  /// with all the resolved colors.
  CupertinoSystemColorData resolveColors(BuildContext context) {
    return CupertinoSystemColorData(
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
    return other.runtimeType == runtimeType
        && label == label
        && secondaryLabel == secondaryLabel
        && tertiaryLabel == tertiaryLabel
        && quaternaryLabel == quaternaryLabel
        && systemFill == systemFill
        && secondarySystemFill == secondarySystemFill
        && tertiarySystemFill == tertiarySystemFill
        && quaternarySystemFill == quaternarySystemFill
        && placeholderText == placeholderText
        && systemBackground == systemBackground
        && secondarySystemBackground == secondarySystemBackground
        && tertiarySystemBackground == tertiarySystemBackground
        && systemGroupedBackground == systemGroupedBackground
        && secondarySystemGroupedBackground == secondarySystemGroupedBackground
        && tertiarySystemGroupedBackground == tertiarySystemGroupedBackground
        && separator == separator
        && opaqueSeparator== opaqueSeparator
        && link == link
        && systemBlue == systemBlue
        && systemGreen == systemGreen
        && systemIndigo == systemIndigo
        && systemOrange == systemOrange
        && systemPink == systemPink
        && systemPurple == systemPurple
        && systemRed == systemRed
        && systemTeal == systemTeal
        && systemYellow == systemYellow
        && systemGray == systemGray
        && systemGray2 == systemGray2
        && systemGray3 == systemGray3
        && systemGray4 == systemGray4
        && systemGray5 == systemGray5
        && systemGray6 == systemGray6;
  }

  @override
  int get hashCode => hashList(<Color>[label,
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
