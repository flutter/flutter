// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;
import 'package:collection/collection.dart';
import 'package:flutter/src/widgets/basic.dart';

import '../../foundation.dart' show immutable;
import '../widgets/framework.dart' show BuildContext;
import '../widgets/media_query.dart';
import 'interface_level.dart';
import 'theme.dart';

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
/// A [CupertinoDynamicColor] itself can be used as a concrete [Color] for painting,
/// as it is a subclass of [Color], but it is rarely desirable.
@immutable
class CupertinoDynamicColor extends Color {
  /// Create a Color that can be resolved to different [Color]s in different [BuildContext].
  ///
  /// [defaultColor] will be used in other colors' absence, and it must not be null,
  /// unless none of the other colors is null.
  CupertinoDynamicColor({
    this.defaultColor,
    this.normalColor,
    this.darkColor,
    this.highContrastColor,
    this.darkHighContrastColor,
    this.elevatedColor,
    this.darkElevatedColor,
    this.elevatedHighContrastColor,
    this.darkElevatedHighContrastColor,
  }) : assert(defaultColor != null || normalColor != null
                                   && darkColor != null
                                   && elevatedColor != null
                                   && highContrastColor != null
                                   && darkElevatedColor != null
                                   && darkHighContrastColor != null
                                   && darkElevatedHighContrastColor != null
                                   && elevatedHighContrastColor != null),
       super(defaultColor?.value ?? normalColor?.value);

  /// The defaultColor color to use when the requested color is not specified.
  ///
  /// Must not be null unless all other colors are specified.
  final Color defaultColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// normal contrast, and base interface elevation.
  final Color normalColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// normal contrast, and base interface elevation.
  final Color darkColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// high contrast, and base interface elevation.
  final Color highContrastColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// high contrast, and base interface elevation.
  final Color darkHighContrastColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// normal contrast, and elevated interface elevation.
  final Color elevatedColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// normal contrast, and elevated interface elevation.
  final Color darkElevatedColor;

  /// The color to use when the [BuildContext] implies a combination of light mode,
  /// high contrast, and elevated interface elevation.
  final Color elevatedHighContrastColor;

  /// The color to use when the [BuildContext] implies a combination of dark mode,
  /// high contrast, and elevated interface elevation.
  final Color darkElevatedHighContrastColor;

  List<Color> get _colorMap => <Color> [
    normalColor,
    darkColor,
    highContrastColor,
    darkHighContrastColor,
    elevatedColor,
    darkElevatedColor,
    elevatedHighContrastColor,
    darkElevatedHighContrastColor,
  ];

  /// Resolve the givin [Color] to a concrete [Color], using the given [BuildContext].
  static Color resolve(Color resolvable, BuildContext context, { bool nullOk = false })
    => (resolvable is CupertinoDynamicColor)
      ? resolvable.resolveFrom(context, nullOk: nullOk)
      : resolvable;

  /// Resolve this [CupertinoDynamicColor] to a concrete [Color], using the given
  /// [BuildContext].
  ///
  /// Calling this function may create dependencies on the closest instance of some
  /// [InheritedWidget]s that enclose the given [BuildContext]. More specifically:
  ///
  /// * If any of the dark colors are specified ([darkColor], [darkHighContrastColor]
  /// or [darkElevatedHighContrastColor]), this function will call [CupertinoTheme.of],
  /// and then [MediaQuery.of] if brightness wasn't specified in the theme data retrived
  /// from the previous [CupertinoTheme.of] call.
  ///
  /// * If any of the high contrast colors are specified, [MediaQuery.of] will be
  /// called to retrieve the accessibility high contrast setting.
  ///
  /// * If any of the elevated colors are specified, [CupertinoUserInterfaceLevel.of]
  /// will be called to retrieve the user interface elevation.
  Color resolveFrom(BuildContext context, { bool nullOk = false }) {
    int dependencyBitMask, configBitMask = 0;
    final List<Color> colors = _colorMap;

    for (int i = 0; i < colors.length; i++) {
      // bitShift - color variant
      //    0     - color vibrancy
      //    1     - accessibility contrast
      //    2     - user interface level
      for(int bitShift = 0; bitShift < 3; bitShift ++) {
        final int mask = 1 << bitShift;
        final bool isSameColor = colors[i] ?? defaultColor == colors[i | mask] ?? defaultColor;
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
      // Something similar.
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

    return _colorMap[configBitMask] ?? defaultColor;
  }

  @override
  bool operator ==(dynamic other) {
    return other.runtimeType == runtimeType
        && ListEquality<Color>(_ColorMapElementEquality<Color>(defaultColor))
            .equals(_colorMap, other._colorMap);
  }

  @override
  int get hashCode => _colorMap.map((Color color) => color ?? defaultColor).hashCode;
}

class _ColorMapElementEquality<E> extends DefaultEquality<E> {
  const _ColorMapElementEquality(this.nullFallbackValue) : super();
  final E nullFallbackValue;

  @override
  bool equals(Object e1, Object e2) => super.equals(e1, e2)
                                    || super.equals(e1 ?? nullFallbackValue, e2 ?? nullFallbackValue);
}
