// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/widgets.dart';

import 'colors.dart';

/// The Flutter logo, in widget form. This widget respects the [IconTheme].
/// For guidelines on using the Flutter logo, visit https://flutter.dev/brand.
///
/// See also:
///
///  * [IconTheme], which provides ambient configuration for icons.
///  * [Icon], for showing icons the Material design icon library.
///  * [ImageIcon], for showing icons from [AssetImage]s or other [ImageProvider]s.
class FlutterLogo extends StatelessWidget {
  /// Creates a widget that paints the Flutter logo.
  ///
  /// The [size] defaults to the value given by the current [IconTheme].
  ///
  /// The [lightColor], [mediumColor], [darkColor], [textColor], [style],
  /// [duration], and [curve] arguments must not be null.
  const FlutterLogo({
    Key key,
    this.size,
    this.lightColor = FlutterLogoDecoration.defaultLightColor,
    this.mediumColor = FlutterLogoDecoration.defaultMediumColor,
    this.darkColor = FlutterLogoDecoration.defaultDarkColor,
    this.textColor = FlutterLogoDecoration.defaultTextColor,
    this.style = FlutterLogoStyle.markOnly,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
  }) : assert(lightColor != null),
       assert(mediumColor != null),
       assert(darkColor != null),
       assert(textColor != null),
       assert(style != null),
       assert(duration != null),
       assert(curve != null),
       super(key: key);

  /// The size of the logo in logical pixels.
  ///
  /// The logo will be fit into a square this size.
  ///
  /// Defaults to the current [IconTheme] size, if any. If there is no
  /// [IconTheme], or it does not specify an explicit size, then it defaults to
  /// 24.0.
  final double size;

  /// The lightest of the three colors used to paint the logo.
  ///
  /// This color is used to paint the top and middle beam of the Flutter "F"
  /// logo.
  ///
  /// If possible, the default ([FlutterLogoDecoration.defaultLightColor])
  /// should be used.
  final Color lightColor;

  /// A color in between the [lightColor] and the [darColor] used to paint
  /// the logo.
  ///
  /// This color is used to paint the intersection of the middle and bottom beam
  /// of the Flutter "F" logo.
  ///
  /// If possible, the default ([FlutterLogoDecoration.defaultMediumColor])
  /// should be used.
  final Color mediumColor;

  /// The darkest of the three colors used to paint the logo.
  ///
  /// This color is used to paint the bottom beam of the Flutter "F"
  /// logo.
  ///
  /// If possible, the default ([FlutterLogoDecoration.defaultDarkColor]) should
  /// be used.
  final Color darkColor;

  /// The color used to paint the "Flutter" text on the logo, if [style] is
  /// [FlutterLogoStyle.horizontal] or [FlutterLogoStyle.stacked].
  ///
  /// If possible, the default ([FlutterLogoDecoration.defaultTextColor], a
  /// medium grey) should be used against a white background.
  final Color textColor;

  /// Whether and where to draw the "Flutter" text. By default, only the logo
  /// itself is drawn.
  final FlutterLogoStyle style;

  /// The length of time for the animation if the [style], [colors], or
  /// [textColor] properties are changed.
  final Duration duration;

  /// The curve for the logo animation if the [style], [colors], or [textColor]
  /// change.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size;
    return AnimatedContainer(
      width: iconSize,
      height: iconSize,
      duration: duration,
      curve: curve,
      decoration: FlutterLogoDecoration(
        lightColor: lightColor,
        mediumColor: mediumColor,
        darkColor: darkColor,
        textColor: textColor,
        style: style,
      ),
    );
  }
}
