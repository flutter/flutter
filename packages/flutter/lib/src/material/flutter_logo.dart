// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'colors.dart';

/// The Flutter logo, in widget form. This widget respects the [IconTheme].
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
  const FlutterLogo({
    Key key,
    this.size,
    this.swatch: Colors.blue,
    this.textColor: const Color(0xFF616161),
    this.style: FlutterLogoStyle.markOnly,
    this.duration: const Duration(milliseconds: 750),
    this.curve: Curves.fastOutSlowIn,
  }) : super(key: key);

  /// The size of the logo in logical pixels.
  ///
  /// The logo will be fit into a square this size.
  ///
  /// Defaults to the current [IconTheme] size, if any. If there is no
  /// [IconTheme], or it does not specify an explicit size, then it defaults to
  /// 24.0.
  final double size;

  /// The colors to use to paint the logo. This map should contain at least two
  /// values, one for 400 and one for 900.
  ///
  /// If possible, the default should be used. It corresponds to the
  /// [Colors.blue] swatch.
  ///
  /// If for some reason that color scheme is impractical, the [Colors.amber],
  /// [Colors.red], or [Colors.indigo] swatches can be used. These are Flutter's
  /// secondary colors.
  ///
  /// In extreme cases where none of those four color schemes will work,
  /// [Colors.pink], [Colors.purple], or [Colors.cyan] swatches can be used.
  /// These are Flutter's tertiary colors.
  final Map<int, Color> swatch;

  /// The color used to paint the "Flutter" text on the logo, if [style] is
  /// [FlutterLogoStyle.horizontal] or [FlutterLogoStyle.stacked]. The
  /// appropriate color is `const Color(0xFF616161)` (a medium gray), against a
  /// white background.
  final Color textColor;

  /// Whether and where to draw the "Flutter" text. By default, only the logo
  /// itself is drawn.
  final FlutterLogoStyle style;

  /// The length of time for the animation if the [style], [swatch], or
  /// [textColor] properties are changed.
  final Duration duration;

  /// The curve for the logo animation if the [style], [swatch], or [textColor]
  /// change.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size;
    return new AnimatedContainer(
      width: iconSize,
      height: iconSize,
      duration: duration,
      curve: curve,
      decoration: new FlutterLogoDecoration(
        swatch: swatch,
        style: style,
        textColor: textColor,
      ),
    );
  }
}
