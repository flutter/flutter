// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as sky;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

enum IconThemeColor { white, black }

class IconThemeData {
  const IconThemeData({ this.color });
  final IconThemeColor color;

  bool operator==(other) => other.runtimeType == runtimeType && other.color == color;
  int get hashCode => color.hashCode;
}

class IconTheme extends InheritedWidget {

  IconTheme({
    Key key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(data != null);
    assert(child != null);
  }

  final IconThemeData data;

  static IconThemeData of(BuildContext context) {
    IconTheme result = context.inheritedWidgetOfType(IconTheme);
    return result?.data;
  }

  bool updateShouldNotify(IconTheme old) => data != old.data;

}

AssetBundle _initIconBundle() {
  if (rootBundle != null)
    return rootBundle;
  const String _kAssetBase = '/packages/material_design_icons/icons/';
  return new NetworkAssetBundle(Uri.base.resolve(_kAssetBase));
}

final AssetBundle _iconBundle = _initIconBundle();

class Icon extends StatelessComponent {
  Icon({
    Key key,
    this.size,
    this.type: '',
    this.color,
    this.colorFilter
  }) : super(key: key);

  final int size;
  final String type;
  final IconThemeColor color;
  final sky.ColorFilter colorFilter;

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
      bundle: _iconBundle,
      name: '${category}/${density}/ic_${subtype}_${colorSuffix}_${size}dp.png',
      width: size.toDouble(),
      height: size.toDouble(),
      colorFilter: colorFilter
    );
  }
}
