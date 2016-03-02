// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'theme.dart';

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size: 24.0,
    this.icon,
    this.colorTheme,
    this.color
  }) : super(key: key) {
    assert(size != null);
  }

  final double size;
  final IconData icon;
  final IconThemeColor colorTheme;
  final Color color;

  IconThemeColor _getIconThemeColor(BuildContext context) {
    IconThemeColor iconThemeColor = colorTheme;
    if (iconThemeColor == null) {
      IconThemeData iconThemeData = IconTheme.of(context);
      iconThemeColor = iconThemeData == null ? null : iconThemeData.color;
    }
    if (iconThemeColor == null) {
      ThemeBrightness themeBrightness = Theme.of(context).brightness;
      iconThemeColor = themeBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }
    return iconThemeColor;
  }

  Widget build(BuildContext context) {
    if (icon == null) {
      return new SizedBox(
        width: size,
        height: size
      );
    }

    Color iconColor = color;
    final int iconAlpha = (255.0 * (IconTheme.of(context)?.clampedOpacity ?? 1.0)).round();
    if (color != null) {
        if (iconAlpha != 255)
          iconColor = color.withAlpha((iconAlpha * color.opacity).round());
    } else {
      switch(_getIconThemeColor(context)) {
        case IconThemeColor.black:
          iconColor = Colors.black.withAlpha(iconAlpha);
          break;
        case IconThemeColor.white:
          iconColor = Colors.white.withAlpha(iconAlpha);
          break;
      }
    }

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
    if (this.colorTheme != null)
      description.add('colorTheme: $colorTheme');
    if (this.color != null)
      description.add('color: $color');
  }
}
