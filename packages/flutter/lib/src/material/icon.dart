// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'icon_theme.dart';
import 'theme.dart';

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size: 24.0,
    this.icon,
    this.color
  }) : super(key: key) {
    assert(size != null);
  }

  /// The size of the icon in logical pixels.
  ///
  /// Icons occupy a square with width and height equal to size.
  final double size;

  /// The icon to display.
  final IconData icon;

  /// The color to use when drawing the icon.
  final Color color;

  Color _getDefaultColorForThemeBrightness(ThemeBrightness brightness) {
    switch (brightness) {
      case ThemeBrightness.dark:
        return Colors.white;
      case ThemeBrightness.light:
        return Colors.black;
    }
  }

  Color _getDefaultColor(BuildContext context) {
    return IconTheme.of(context)?.color ?? _getDefaultColorForThemeBrightness(Theme.of(context).brightness);
  }

  Widget build(BuildContext context) {
    if (icon == null)
      return new SizedBox(width: size, height: size);

    Color iconColor = color ?? _getDefaultColor(context);
    final int iconAlpha = (255.0 * (IconTheme.of(context)?.clampedOpacity ?? 1.0)).round();
    if (iconAlpha != 255)
        iconColor = color.withAlpha((iconAlpha * color.opacity).round());

    return new SizedBox(
      width: size,
      height: size,
      child: new Center(
        child: new Text(new String.fromCharCode(icon.codePoint),
          style: new TextStyle(
            inherit: false,
            color: iconColor,
            fontSize: size,
            fontFamily: 'MaterialIcons'
          )
        )
      )
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
    description.add('size: $size');
    if (this.color != null)
      description.add('color: $color');
  }
}
