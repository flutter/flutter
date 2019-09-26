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

  /// iOS 13's default blue color. Used to indicate active elements such as
  /// buttons, selected tabs and your own chat bubbles.
  ///
  /// This is SystemBlue in the iOS palette.
  static const CupertinoDynamicColor activeBlue = systemBlue;

  /// iOS 13's default green color. Used to indicate active accents such as
  /// the switch in its on state and some accent buttons such as the call button
  /// and Apple Map's 'Go' button.
  ///
  /// This is SystemGreen in the iOS palette.
  static const CupertinoDynamicColor activeGreen = systemGreen;

  /// iOS 13's orange color.
  ///
  /// This is SystemOrange in the iOS palette.
  static const CupertinoDynamicColor activeOrange = systemOrange;

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

  /// Used in iOS 13 for unselected selectables such as tab bar items in their
  /// inactive state or de-emphasized subtitles and details text.
  ///
  /// Not the same grey as disabled buttons etc.
  ///
  /// This is the disabled color in the iOS palette.
  static const Color inactiveGray = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF999999),
    darkColor: Color(0xFF757575),
  );

  /// Used for iOS 13 for destructive actions such as the delete actions in
  /// table view cells and dialogs.
  ///
  /// Not the same red as the camera shutter or springboard icon notifications
  /// or the foreground red theme in various native apps such as HealthKit.
  ///
  /// This is SystemRed in the iOS palette.
  static const Color destructiveRed = systemRed;

  /// A blue color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemBlue](https://developer.apple.com/documentation/uikit/uicolor/3173141-systemblue),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemBlue = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 0, 122, 255),
    darkColor: Color.fromARGB(255, 10, 132, 255),
    highContrastColor: Color.fromARGB(255, 0, 64, 221),
    darkHighContrastColor: Color.fromARGB(255, 64, 156, 255),
  );

  /// A green color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemGreen](https://developer.apple.com/documentation/uikit/uicolor/3173144-systemgreen),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGreen = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 52, 199, 89),
    darkColor: Color.fromARGB(255, 48, 209, 88),
    highContrastColor: Color.fromARGB(255, 36, 138, 61),
    darkHighContrastColor: Color.fromARGB(255, 48, 219, 91),
  );

  /// An indigo color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemIndigo](https://developer.apple.com/documentation/uikit/uicolor/3173146-systemindigo),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemIndigo = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 88, 86, 214),
    darkColor: Color.fromARGB(255, 94, 92, 230),
    highContrastColor: Color.fromARGB(255, 54, 52, 163),
    darkHighContrastColor: Color.fromARGB(255, 125, 122, 255),
  );

  /// An orange color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemOrange](https://developer.apple.com/documentation/uikit/uicolor/3173147-systemorange),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemOrange = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 149, 0),
    darkColor: Color.fromARGB(255, 255, 159, 10),
    highContrastColor: Color.fromARGB(255, 201, 52, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 179, 64),
  );

  /// A pink color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemPink](https://developer.apple.com/documentation/uikit/uicolor/3173148-systempink),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemPink = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 45, 85),
    darkColor: Color.fromARGB(255, 255, 55, 95),
    highContrastColor: Color.fromARGB(255, 211, 15, 69),
    darkHighContrastColor: Color.fromARGB(255, 255, 100, 130),
  );

  /// A purple color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemPurple](https://developer.apple.com/documentation/uikit/uicolor/3173149-systempurple),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemPurple = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 175, 82, 222),
    darkColor: Color.fromARGB(255, 191, 90, 242),
    highContrastColor: Color.fromARGB(255, 137, 68, 171),
    darkHighContrastColor: Color.fromARGB(255, 218, 143, 255),
  );

  /// A red color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemRed](https://developer.apple.com/documentation/uikit/uicolor/3173150-systemred),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemRed = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 59, 48),
    darkColor: Color.fromARGB(255, 255, 69, 58),
    highContrastColor: Color.fromARGB(255, 215, 0, 21),
    darkHighContrastColor: Color.fromARGB(255, 255, 105, 97),
  );

  /// A teal color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemTeal](https://developer.apple.com/documentation/uikit/uicolor/3173151-systemteal),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemTeal = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 90, 200, 250),
    darkColor: Color.fromARGB(255, 100, 210, 255),
    highContrastColor: Color.fromARGB(255, 0, 113, 164),
    darkHighContrastColor: Color.fromARGB(255, 112, 215, 255),
  );

  /// A yellow color that can adapt to the given [BuildContext].
  ///
  /// See also:
  ///
  /// * [UIColor.systemYellow](https://developer.apple.com/documentation/uikit/uicolor/3173152-systemyellow),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemYellow = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 255, 204, 0),
    darkColor: Color.fromARGB(255, 255, 214, 10),
    highContrastColor: Color.fromARGB(255, 160, 90, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 212, 38),
  );

  /// The base grey color.
  ///
  /// See also:
  ///
  /// * [UIColor.systemGray](https://developer.apple.com/documentation/uikit/uicolor/3173143-systemgray),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGrey = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 142, 142, 147),
    darkColor: Color.fromARGB(255, 142, 142, 147),
    highContrastColor: Color.fromARGB(255, 108, 108, 112),
    darkHighContrastColor: Color.fromARGB(255, 174, 174, 178),
  );

  /// A second-level shade of grey.
  ///
  /// See also:
  ///
  /// * [UIColor.systemGray2](https://developer.apple.com/documentation/uikit/uicolor/3255071-systemgray2),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGrey2 = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 174, 174, 178),
    darkColor: Color.fromARGB(255, 99, 99, 102),
    highContrastColor: Color.fromARGB(255, 142, 142, 147),
    darkHighContrastColor: Color.fromARGB(255, 124, 124, 128),
  );

  /// A third-level shade of grey.
  ///
  /// See also:
  ///
  /// * [UIColor.systemGray3](https://developer.apple.com/documentation/uikit/uicolor/3255072-systemgray3),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGrey3 = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 199, 199, 204),
    darkColor: Color.fromARGB(255, 72, 72, 74),
    highContrastColor: Color.fromARGB(255, 174, 174, 178),
    darkHighContrastColor: Color.fromARGB(255, 84, 84, 86),
  );

  /// A fourth-level shade of grey.
  ///
  /// See also:
  ///
  /// * [UIColor.systemGray4](https://developer.apple.com/documentation/uikit/uicolor/3255073-systemgray4),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGrey4 = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 209, 209, 214),
    darkColor: Color.fromARGB(255, 58, 58, 60),
    highContrastColor: Color.fromARGB(255, 188, 188, 192),
    darkHighContrastColor: Color.fromARGB(255, 68, 68, 70),
  );

  /// A fifth-level shade of grey.
  ///
  /// See also:
  ///
  /// * [UIColor.systemGray5](https://developer.apple.com/documentation/uikit/uicolor/3255074-systemgray5),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGrey5 = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 229, 229, 234),
    darkColor: Color.fromARGB(255, 44, 44, 46),
    highContrastColor: Color.fromARGB(255, 216, 216, 220),
    darkHighContrastColor: Color.fromARGB(255, 54, 54, 56),
  );

  /// A sixth-level shade of grey.
  ///
  /// See also:
  ///
  /// * [UIColor.systemGray6](https://developer.apple.com/documentation/uikit/uicolor/3255075-systemgray6),
  ///   the `UIKit` equivalent.
  static const CupertinoDynamicColor systemGrey6 = CupertinoDynamicColor.withBrightnessAndContrast(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 28, 28, 30),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 36, 36, 38),
  );

  /// The color for text labels containing primary content, equivalent to
  /// [UIColor.label](https://developer.apple.com/documentation/uikit/uicolor/3173131-label).
  static const CupertinoDynamicColor label = CupertinoDynamicColor(
    color: Color.fromARGB(255, 0, 0, 0),
    darkColor: Color.fromARGB(255, 255, 255, 255),
    highContrastColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 255, 255),
    elevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkElevatedColor: Color.fromARGB(255, 255, 255, 255),
    highContrastElevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
  );

  /// The color for text labels containing secondary content, equivalent to
  /// [UIColor.secondaryLabel](https://developer.apple.com/documentation/uikit/uicolor/3173136-secondarylabel).
  static const CupertinoDynamicColor secondaryLabel = CupertinoDynamicColor(
    color: Color.fromARGB(255, 0, 0, 0),
    darkColor: Color.fromARGB(255, 255, 255, 255),
    highContrastColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastColor: Color.fromARGB(255, 255, 255, 255),
    elevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkElevatedColor: Color.fromARGB(255, 255, 255, 255),
    highContrastElevatedColor: Color.fromARGB(255, 0, 0, 0),
    darkHighContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
  );

  /// The color for text labels containing tertiary content, equivalent to
  /// [UIColor.tertiaryLabel](https://developer.apple.com/documentation/uikit/uicolor/3173153-tertiarylabel).
  static const CupertinoDynamicColor tertiaryLabel = CupertinoDynamicColor(
    color: Color.fromARGB(76, 60, 60, 67),
    darkColor: Color.fromARGB(76, 235, 235, 245),
    highContrastColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(96, 235, 235, 245),
    elevatedColor: Color.fromARGB(76, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(76, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(96, 235, 235, 245),
  );

  /// The color for text labels containing quaternary content, equivalent to
  /// [UIColor.quaternaryLabel](https://developer.apple.com/documentation/uikit/uicolor/3173135-quaternarylabel).
  static const CupertinoDynamicColor quaternaryLabel = CupertinoDynamicColor(
    color: Color.fromARGB(45, 60, 60, 67),
    darkColor: Color.fromARGB(40, 235, 235, 245),
    highContrastColor: Color.fromARGB(66, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(61, 235, 235, 245),
    elevatedColor: Color.fromARGB(45, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(40, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(66, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(61, 235, 235, 245),
  );

  /// An overlay fill color for thin and small shapes, equivalent to
  /// [UIColor.systemFill](https://developer.apple.com/documentation/uikit/uicolor/3255070-systemfill).
  static const CupertinoDynamicColor systemFill = CupertinoDynamicColor(
    color: Color.fromARGB(51, 120, 120, 128),
    darkColor: Color.fromARGB(91, 120, 120, 128),
    highContrastColor: Color.fromARGB(71, 120, 120, 128),
    darkHighContrastColor: Color.fromARGB(112, 120, 120, 128),
    elevatedColor: Color.fromARGB(51, 120, 120, 128),
    darkElevatedColor: Color.fromARGB(91, 120, 120, 128),
    highContrastElevatedColor: Color.fromARGB(71, 120, 120, 128),
    darkHighContrastElevatedColor: Color.fromARGB(112, 120, 120, 128),
  );

  /// An overlay fill color for medium-size shapes, equivalent to
  /// [UIColor.secondarySystemFill](https://developer.apple.com/documentation/uikit/uicolor/3255069-secondarysystemfill).
  static const CupertinoDynamicColor secondarySystemFill = CupertinoDynamicColor(
    color: Color.fromARGB(40, 120, 120, 128),
    darkColor: Color.fromARGB(81, 120, 120, 128),
    highContrastColor: Color.fromARGB(61, 120, 120, 128),
    darkHighContrastColor: Color.fromARGB(102, 120, 120, 128),
    elevatedColor: Color.fromARGB(40, 120, 120, 128),
    darkElevatedColor: Color.fromARGB(81, 120, 120, 128),
    highContrastElevatedColor: Color.fromARGB(61, 120, 120, 128),
    darkHighContrastElevatedColor: Color.fromARGB(102, 120, 120, 128),
  );

  /// An overlay fill color for large shapes, equivalent to
  /// [UIColor.tertiarySystemFill](https://developer.apple.com/documentation/uikit/uicolor/3255076-tertiarysystemfill).
  static const CupertinoDynamicColor tertiarySystemFill = CupertinoDynamicColor(
    color: Color.fromARGB(30, 118, 118, 128),
    darkColor: Color.fromARGB(61, 118, 118, 128),
    highContrastColor: Color.fromARGB(51, 118, 118, 128),
    darkHighContrastColor: Color.fromARGB(81, 118, 118, 128),
    elevatedColor: Color.fromARGB(30, 118, 118, 128),
    darkElevatedColor: Color.fromARGB(61, 118, 118, 128),
    highContrastElevatedColor: Color.fromARGB(51, 118, 118, 128),
    darkHighContrastElevatedColor: Color.fromARGB(81, 118, 118, 128),
  );

  /// An overlay fill color for large areas containing complex content, equivalent
  /// to [UIColor.quaternarySystemFill](https://developer.apple.com/documentation/uikit/uicolor/3255068-quaternarysystemfill).
  static const CupertinoDynamicColor quaternarySystemFill = CupertinoDynamicColor(
    color: Color.fromARGB(20, 116, 116, 128),
    darkColor: Color.fromARGB(45, 118, 118, 128),
    highContrastColor: Color.fromARGB(40, 116, 116, 128),
    darkHighContrastColor: Color.fromARGB(66, 118, 118, 128),
    elevatedColor: Color.fromARGB(20, 116, 116, 128),
    darkElevatedColor: Color.fromARGB(45, 118, 118, 128),
    highContrastElevatedColor: Color.fromARGB(40, 116, 116, 128),
    darkHighContrastElevatedColor: Color.fromARGB(66, 118, 118, 128),
  );

  /// The color for placeholder text in controls or text views, equivalent to
  /// [UIColor.placeholderText](https://developer.apple.com/documentation/uikit/uicolor/3173134-placeholdertext).
  static const CupertinoDynamicColor placeholderText = CupertinoDynamicColor(
    color: Color.fromARGB(76, 60, 60, 67),
    darkColor: Color.fromARGB(76, 235, 235, 245),
    highContrastColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(96, 235, 235, 245),
    elevatedColor: Color.fromARGB(76, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(76, 235, 235, 245),
    highContrastElevatedColor: Color.fromARGB(96, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(96, 235, 235, 245),
  );

  /// The color for the main background of your interface, equivalent to
  /// [UIColor.systemBackground](https://developer.apple.com/documentation/uikit/uicolor/3173140-systembackground).
  ///
  /// Typically used for designs that have a white primary background in a light environment.
  static const CupertinoDynamicColor systemBackground = CupertinoDynamicColor(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 0, 0, 0),
    highContrastColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastColor: Color.fromARGB(255, 0, 0, 0),
    elevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkElevatedColor: Color.fromARGB(255, 28, 28, 30),
    highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 36, 36, 38),
  );

  /// The color for content layered on top of the main background, equivalent to
  /// [UIColor.secondarySystemBackground](https://developer.apple.com/documentation/uikit/uicolor/3173137-secondarysystembackground).
  ///
  /// Typically used for designs that have a white primary background in a light environment.
  static const CupertinoDynamicColor secondarySystemBackground = CupertinoDynamicColor(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 28, 28, 30),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 36, 36, 38),
    elevatedColor: Color.fromARGB(255, 242, 242, 247),
    darkElevatedColor: Color.fromARGB(255, 44, 44, 46),
    highContrastElevatedColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastElevatedColor: Color.fromARGB(255, 54, 54, 56),
  );

  /// The color for content layered on top of secondary backgrounds, equivalent
  /// to [UIColor.tertiarySystemBackground](https://developer.apple.com/documentation/uikit/uicolor/3173154-tertiarysystembackground).
  ///
  /// Typically used for designs that have a white primary background in a light environment.
  static const CupertinoDynamicColor tertiarySystemBackground = CupertinoDynamicColor(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 44, 44, 46),
    highContrastColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastColor: Color.fromARGB(255, 54, 54, 56),
    elevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkElevatedColor: Color.fromARGB(255, 58, 58, 60),
    highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 68, 68, 70),
  );

  /// The color for the main background of your grouped interface, equivalent to
  /// [UIColor.systemGroupedBackground](https://developer.apple.com/documentation/uikit/uicolor/3173145-systemgroupedbackground).
  ///
  /// Typically used for grouped content, including table views and platter-based designs.
  static const CupertinoDynamicColor systemGroupedBackground = CupertinoDynamicColor(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 0, 0, 0),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 0, 0, 0),
    elevatedColor: Color.fromARGB(255, 242, 242, 247),
    darkElevatedColor: Color.fromARGB(255, 28, 28, 30),
    highContrastElevatedColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastElevatedColor: Color.fromARGB(255, 36, 36, 38),
  );

  /// The color for content layered on top of the main background of your grouped interface,
  /// equivalent to [UIColor.secondarySystemGroupedBackground](https://developer.apple.com/documentation/uikit/uicolor/3173138-secondarysystemgroupedbackground).
  ///
  /// Typically used for grouped content, including table views and platter-based designs.
  static const CupertinoDynamicColor secondarySystemGroupedBackground = CupertinoDynamicColor(
    color: Color.fromARGB(255, 255, 255, 255),
    darkColor: Color.fromARGB(255, 28, 28, 30),
    highContrastColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastColor: Color.fromARGB(255, 36, 36, 38),
    elevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkElevatedColor: Color.fromARGB(255, 44, 44, 46),
    highContrastElevatedColor: Color.fromARGB(255, 255, 255, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 54, 54, 56),
  );

  /// The color for content layered on top of secondary backgrounds of your grouped interface,
  /// equivalent to [UIColor.tertiarySystemGroupedBackground](https://developer.apple.com/documentation/uikit/uicolor/3173155-tertiarysystemgroupedbackground).
  ///
  /// Typically used for grouped content, including table views and platter-based designs.
  static const CupertinoDynamicColor tertiarySystemGroupedBackground = CupertinoDynamicColor(
    color: Color.fromARGB(255, 242, 242, 247),
    darkColor: Color.fromARGB(255, 44, 44, 46),
    highContrastColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastColor: Color.fromARGB(255, 54, 54, 56),
    elevatedColor: Color.fromARGB(255, 242, 242, 247),
    darkElevatedColor: Color.fromARGB(255, 58, 58, 60),
    highContrastElevatedColor: Color.fromARGB(255, 235, 235, 240),
    darkHighContrastElevatedColor: Color.fromARGB(255, 68, 68, 70),
  );

  /// The color for thin borders or divider lines that allows some underlying content to be visible,
  /// equivalent to [UIColor.separator](https://developer.apple.com/documentation/uikit/uicolor/3173139-separator).
  static const CupertinoDynamicColor separator = CupertinoDynamicColor(
    color: Color.fromARGB(73, 60, 60, 67),
    darkColor: Color.fromARGB(153, 84, 84, 88),
    highContrastColor: Color.fromARGB(94, 60, 60, 67),
    darkHighContrastColor: Color.fromARGB(173, 84, 84, 88),
    elevatedColor: Color.fromARGB(73, 60, 60, 67),
    darkElevatedColor: Color.fromARGB(153, 84, 84, 88),
    highContrastElevatedColor: Color.fromARGB(94, 60, 60, 67),
    darkHighContrastElevatedColor: Color.fromARGB(173, 84, 84, 88),
  );

  /// The color for borders or divider lines that hide any underlying content,
  /// equivalent to [UIColor.opaqueSeparator](https://developer.apple.com/documentation/uikit/uicolor/3173133-opaqueseparator).
  static const CupertinoDynamicColor opaqueSeparator = CupertinoDynamicColor(
    color: Color.fromARGB(255, 198, 198, 200),
    darkColor: Color.fromARGB(255, 56, 56, 58),
    highContrastColor: Color.fromARGB(255, 198, 198, 200),
    darkHighContrastColor: Color.fromARGB(255, 56, 56, 58),
    elevatedColor: Color.fromARGB(255, 198, 198, 200),
    darkElevatedColor: Color.fromARGB(255, 56, 56, 58),
    highContrastElevatedColor: Color.fromARGB(255, 198, 198, 200),
    darkHighContrastElevatedColor: Color.fromARGB(255, 56, 56, 58),
  );

  /// The color for links, equivalent to
  /// [UIColor.link](https://developer.apple.com/documentation/uikit/uicolor/3173132-link).
  static const CupertinoDynamicColor link = CupertinoDynamicColor(
    color: Color.fromARGB(255, 0, 122, 255),
    darkColor: Color.fromARGB(255, 9, 132, 255),
    highContrastColor: Color.fromARGB(255, 0, 122, 255),
    darkHighContrastColor: Color.fromARGB(255, 9, 132, 255),
    elevatedColor: Color.fromARGB(255, 0, 122, 255),
    darkElevatedColor: Color.fromARGB(255, 9, 132, 255),
    highContrastElevatedColor: Color.fromARGB(255, 0, 122, 255),
    darkHighContrastElevatedColor: Color.fromARGB(255, 9, 132, 255),
  );
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
