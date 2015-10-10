// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as sky;

import 'package:sky/gestures.dart';
import 'package:sky/painting.dart';
import 'package:sky/widgets.dart';

import 'colors.dart';
import 'icon.dart';
import 'ink_well.dart';
import 'theme.dart';

class DrawerItem extends StatefulComponent {
  const DrawerItem({ Key key, this.icon, this.child, this.onPressed, this.selected: false })
    : super(key: key);

  final String icon;
  final Widget child;
  final GestureTapCallback onPressed;
  final bool selected;

  _DrawerItemState createState() => new _DrawerItemState();
}

class _DrawerItemState extends State<DrawerItem> {
  bool _highlight = false;

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  TextStyle _getTextStyle(ThemeData themeData) {
    TextStyle result = themeData.text.body2;
    if (config.selected)
      result = result.copyWith(color: themeData.primaryColor);
    return result;
  }

  Color _getBackgroundColor(ThemeData themeData) {
    if (_highlight)
      return themeData.highlightColor;
    if (config.selected)
      return themeData.selectedColor;
    return Colors.transparent;
  }

  sky.ColorFilter _getColorFilter(ThemeData themeData) {
    if (config.selected)
      return new sky.ColorFilter.mode(themeData.primaryColor, sky.TransferMode.srcATop);
    return new sky.ColorFilter.mode(const Color(0x73000000), sky.TransferMode.dstIn);
  }

  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    List<Widget> flexChildren = new List<Widget>();
    if (config.icon != null) {
      flexChildren.add(
        new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new Icon(
            type: config.icon,
            size: 24,
            colorFilter: _getColorFilter(themeData))
        )
      );
    }
    flexChildren.add(
      new Flexible(
        child: new Padding(
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new DefaultTextStyle(
            style: _getTextStyle(themeData),
            child: config.child
          )
        )
      )
    );

    return new Container(
      height: 48.0,
      decoration: new BoxDecoration(backgroundColor: _getBackgroundColor(themeData)),
      child: new InkWell(
        onTap: config.onPressed,
        onHighlightChanged: _handleHighlightChanged,
        child: new Row(flexChildren)
      )
    );
  }
}
