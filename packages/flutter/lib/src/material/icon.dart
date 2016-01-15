// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';

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

class DensityQualifier extends BreakpointQualifier {
  DensityQualifier(BuildContext context) : super(
    candidates: [ 'mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi' ],
    values: [ 1.0, 1.5, 2.0, 3.0, 4.0 ]
  ) {
    MediaQueryData media = MediaQuery.of(context);
    value = media.devicePixelRatio;
  }
}

class ColorQualifier extends Qualifier {
  ColorQualifier({ this.context, this.color });
  final BuildContext context;
  final IconThemeColor color;
  String resolve() {
    IconThemeColor iconThemeColor = color;
    if (iconThemeColor == null) {
      IconThemeData iconThemeData = IconTheme.of(context);
      iconThemeColor = iconThemeData == null ? null : iconThemeData.color;
    }
    if (iconThemeColor == null) {
      ThemeBrightness themeBrightness = Theme.of(context).brightness;
      iconThemeColor = themeBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }
    switch(iconThemeColor) {
      case IconThemeColor.white:
        return "white";
      case IconThemeColor.black:
        return "black";
    }
  }
}

class MaterialIconResolver extends AssetResolver {
  MaterialIconResolver({ this.iconSize, this.context, this.color });

  int iconSize;
  BuildContext context;
  IconThemeColor color;

  Future<String> resolve(String icon) {
    String category = '';
    String subtype = '';
    List<String> parts = icon.split('/');
    if (parts.length == 2) {
      category = parts[0];
      subtype = parts[1];
    }
    String density = new DensityQualifier(context).resolve();
    String colorSuffix = new ColorQualifier(context: context, color: color).resolve();
    return new Future.sync(() => '$category/drawable-$density/ic_${subtype}_${colorSuffix}_${iconSize}dp.png');
  }
}

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size: IconSize.s24,
    this.icon: '',
    this.color,
    this.colorFilter
  }) : super(key: key) {
    assert(size != null);
    assert(icon != null);
  }

  final IconSize size;
  final String icon;
  final IconThemeColor color;
  final ColorFilter colorFilter;

  Widget build(BuildContext context) {
    MaterialIconResolver resolver = new MaterialIconResolver(
      context: context,
      iconSize: _kIconSize[size],
      color: color
    );
    int iconSize = _kIconSize[size];
    return new AssetImage(
      name: icon,
      resolver: resolver,
      width: iconSize.toDouble(),
      height: iconSize.toDouble(),
      colorFilter: colorFilter
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
    description.add('size: $size');
  }
}
