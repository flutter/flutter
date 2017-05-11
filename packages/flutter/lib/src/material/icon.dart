// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon_button.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'icons.dart';
import 'theme.dart';

/// A material design icon.
///
/// Icons are not interactive. For an interactive icon, consider [IconButton].
///
/// Icons are identified by their name (as given on that page), with spaces
/// converted to underscores, from the [Icons] class. For example, the "alarm
/// add" icon is [Icons.alarm_add].
///
/// Available icons are shown on this page: <https://design.google.com/icons/>
///
/// To use this class, make sure you set `uses-material-design: true` in your
/// project's `pubspec.yaml` file in the `flutter` section. This ensures that
/// the MaterialIcons font is included in your application. This font is used to
/// display the icons. For example:
///
/// ```yaml
/// name: my_awesome_application
/// flutter:
///   uses-material-design: true
/// ```
///
/// See also:
///
///  * [IconButton], for interactive icons.
///  * [Icons], for the list of available icons for use with this class.
///  * [IconTheme], which provides ambient configuration for icons.
///  * [ImageIcon], for showing icons from [AssetImage]s or other [ImageProvider]s.
class Icon extends StatelessWidget {
  /// Creates an icon.
  ///
  /// The [size] and [color] default to the value given by the current [IconTheme].
  const Icon(this.icon, {
    Key key,
    this.size,
    this.color
  }) : super(key: key);

  /// The icon to display. The available icons are described in [Icons].
  ///
  /// The icon can be null, in which case the widget will render as an empty
  /// space of the specified [size].
  final IconData icon;

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  ///
  /// Defaults to the current [IconTheme] size, if any. If there is no
  /// [IconTheme], or it does not specify an explicit size, then it defaults to
  /// 24.0.
  ///
  /// If this [Icon] is being placed inside an [IconButton], then use
  /// [IconButton.iconSize] instead, so that the [IconButton] can make the splash
  /// area the appropriate size as well. The [IconButton] uses an [IconTheme] to
  /// pass down the size to the [Icon].
  final double size;

  /// The color to use when drawing the icon.
  ///
  /// Defaults to the current [IconTheme] color, if any. If there is
  /// no [IconTheme], then it defaults to white if the theme is dark
  /// and black if the theme is light. See [Theme] to set the current
  /// theme and [ThemeData.brightness] for setting the current theme's
  /// brightness.
  ///
  /// The given color will be adjusted by the opacity of the current
  /// [IconTheme], if any.
  ///
  /// Typically, a material design color will be used, as follows:
  ///
  /// ```dart
  ///  new Icon(
  ///    icon: Icons.widgets,
  ///    color: Colors.blue.shade400,
  ///  ),
  /// ```
  final Color color;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);

    final double iconSize = size ?? iconTheme.size;

    if (icon == null)
      return new SizedBox(width: iconSize, height: iconSize);

    final double iconOpacity = iconTheme.opacity;
    Color iconColor = color ?? iconTheme.color;
    if (iconOpacity != 1.0)
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);

    return new ExcludeSemantics(
      child: new SizedBox(
        width: iconSize,
        height: iconSize,
        child: new Center(
          child: new RichText(
            text: new TextSpan(
              text: new String.fromCharCode(icon.codePoint),
              style: new TextStyle(
                inherit: false,
                color: iconColor,
                fontSize: iconSize,
                fontFamily: icon.fontFamily
              )
            )
          )
        )
      )
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (icon != null) {
      description.add('$icon');
    } else {
      description.add('<empty>');
    }
    if (size != null)
      description.add('size: $size');
    if (color != null)
      description.add('color: $color');
  }
}
