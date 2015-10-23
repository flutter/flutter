// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size,
    this.type: '',
    this.color,
    this.colorFilter
  }) : super(key: key) {
    assert(size != null);
    assert(type != null);
  }

  final int size;
  final String type;
  final IconThemeColor color;
  final ColorFilter colorFilter;

  String _getColorSuffix(BuildContext context) {
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

  Widget build(BuildContext context) {
    String category = '';
    String subtype = '';
    List<String> parts = type.split('/');
    if (parts.length == 2) {
      category = parts[0];
      subtype = parts[1];
    }
    // TODO(eseidel): This clearly isn't correct.  Not sure what would be.
    // Should we use the ios images on ios?
    String density = 'drawable-xxhdpi';
    String colorSuffix = _getColorSuffix(context);
    return new AssetImage(
      name: '$category/$density/ic_${subtype}_${colorSuffix}_${size}dp.png',
      width: size.toDouble(),
      height: size.toDouble(),
      colorFilter: colorFilter
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$type');
    description.add('size: $size');
  }
}
