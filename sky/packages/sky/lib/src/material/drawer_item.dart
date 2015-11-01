// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon.dart';
import 'ink_well.dart';
import 'theme.dart';

class DrawerItem extends StatelessComponent {
  const DrawerItem({ Key key, this.icon, this.child, this.onPressed, this.selected: false })
    : super(key: key);

  final String icon;
  final Widget child;
  final VoidCallback onPressed;
  final bool selected;

  TextStyle _getTextStyle(ThemeData themeData) {
    TextStyle result = themeData.text.body2;
    if (selected)
      result = result.copyWith(color: themeData.primaryColor);
    return result;
  }

  Color _getBackgroundColor(ThemeData themeData, { bool highlight }) {
    if (highlight)
      return themeData.highlightColor;
    if (selected)
      return themeData.selectedColor;
    return Colors.transparent;
  }

  ColorFilter _getColorFilter(ThemeData themeData) {
    if (selected)
      return new ColorFilter.mode(themeData.primaryColor, TransferMode.srcATop);
    return new ColorFilter.mode(const Color(0x73000000), TransferMode.dstIn);
  }

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    List<Widget> flexChildren = new List<Widget>();
    if (icon != null) {
      flexChildren.add(
        new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new Icon(
            icon: icon,
            colorFilter: _getColorFilter(themeData)
          )
        )
      );
    }
    flexChildren.add(
      new Flexible(
        child: new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new DefaultTextStyle(
            style: _getTextStyle(themeData),
            child: child
          )
        )
      )
    );

    return new Container(
      height: 48.0,
      child: new InkWell(
        onTap: onPressed,
        defaultColor: _getBackgroundColor(themeData, highlight: false),
        highlightColor: _getBackgroundColor(themeData, highlight: true),
        child: new Row(flexChildren)
      )
    );
  }

}
