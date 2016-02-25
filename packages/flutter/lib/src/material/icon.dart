// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'theme.dart';

enum IconSize {
  s18,
  s24,
  s36,
  s48,
}

const Map<IconSize, int> _kIconSize = const <IconSize, int>{
  IconSize.s18: 18,
  IconSize.s24: 24,
  IconSize.s36: 36,
  IconSize.s48: 48,
};

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size: IconSize.s24,
    this.icon,
    this.colorTheme,
    this.color
  }) : super(key: key) {
    assert(size != null);
  }

  final IconSize size;
  final String icon;
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
    final int iconSize = _kIconSize[size];
    if (icon == null) {
      return new SizedBox(
        width: iconSize.toDouble(),
        height: iconSize.toDouble()
      );
    }

    String category = '';
    String subtype = '';
    List<String> parts = icon.split('/');
    if (parts.length == 2) {
      category = parts[0];
      subtype = parts[1];
    }
    final IconThemeColor iconThemeColor = _getIconThemeColor(context);

    String colorSuffix;
    switch(iconThemeColor) {
      case IconThemeColor.black:
        colorSuffix = "black";
        break;
      case IconThemeColor.white:
        colorSuffix = "white";
        break;
    }

    Color iconColor = color;
    final int iconAlpha = (255.0 * (IconTheme.of(context)?.clampedOpacity ?? 1.0)).round();
    if (iconAlpha != 255) {
      if (color != null) {
        iconColor = color.withAlpha(iconAlpha);
      } else {
        switch(iconThemeColor) {
          case IconThemeColor.black:
            iconColor = Colors.black.withAlpha(iconAlpha);
            break;
          case IconThemeColor.white:
            iconColor = Colors.white.withAlpha(iconAlpha);
            break;
        }
      }
    }

    return new AssetImage(
      name: '$category/ic_${subtype}_${colorSuffix}_${iconSize}dp.png',
      width: iconSize.toDouble(),
      height: iconSize.toDouble(),
      color: iconColor
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
