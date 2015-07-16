// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';

enum IconThemeColor { white, black }

class IconThemeData {
  const IconThemeData({ this.color });
  final IconThemeColor color;
}

class IconTheme extends Inherited {

  IconTheme({
    String key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(data != null);
    assert(child != null);
  }

  final IconThemeData data;

  static IconThemeData of(Component component) {
    IconTheme result = component.inheritedOfType(IconTheme);
    return result == null ? null : result.data;
  }

  bool syncShouldNotify(IconTheme old) => data != old.data;

}

AssetBundle _initIconBundle() {
  if (rootBundle != null)
    return rootBundle;
  const String _kAssetBase = '/packages/sky/assets/material-design-icons/';
  return new NetworkAssetBundle(Uri.base.resolve(_kAssetBase));
}

final AssetBundle _iconBundle = _initIconBundle();

class Icon extends Component {
  Icon({
    String key,
    this.size,
    this.type: '',
    this.color,
    this.colorFilter
  }) : super(key: key);

  final int size;
  final String type;
  final IconThemeColor color;
  final sky.ColorFilter colorFilter;

  String get colorSuffix {
    IconThemeColor iconThemeColor = color;
    if (iconThemeColor == null) {
      IconThemeData iconThemeData = IconTheme.of(this);
      iconThemeColor = iconThemeData == null ? null : iconThemeData.color;
    }
    if (iconThemeColor == null) {
      ThemeBrightness themeBrightness = Theme.of(this).brightness;
      iconThemeColor = themeBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }
    switch(iconThemeColor) {
      case IconThemeColor.white:
        return "white";
      case IconThemeColor.black:
        return "black";
    }
  }

  Widget build() {
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
    return new AssetImage(
      bundle: _iconBundle,
      name: '${category}/${density}/ic_${subtype}_${colorSuffix}_${size}dp.png',
      size: new Size(size.toDouble(), size.toDouble()),
      colorFilter: colorFilter
    );
  }
}
