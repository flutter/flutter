// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/button_base.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/widget.dart';

class MenuItem extends ButtonBase {
  MenuItem({ String key, this.icon, this.children, this.onPressed, this.selected: false })
    : super(key: key);

  String icon;
  List<Widget> children;
  Function onPressed;
  bool selected;

  void syncFields(MenuItem source) {
    icon = source.icon;
    children = source.children;
    onPressed = source.onPressed;
    selected = source.selected;
    super.syncFields(source);
  }

  TextStyle _getTextStyle(ThemeData themeData) {
    TextStyle result = themeData.text.body2;
    if (selected)
      result = result.copyWith(color: themeData.primaryColor);
    return result;
  }

  Color _getBackgroundColor(ThemeData themeData) {
    if (highlight)
      return themeData.highlightColor;
    if (selected)
      return themeData.selectedColor;
    return colors.transparent;
  }

  Widget buildContent() {
    ThemeData themeData = Theme.of(this);

    List<Widget> flexChildren = new List<Widget>();
    if (icon != null) {
      Widget child = new Icon(type: icon, size: 24);
      if (selected) {
        child = new ColorFilter(
          color: themeData.primaryColor,
          transferMode: sky.TransferMode.srcATop,
          child: child
        );
      }
      flexChildren.add(
        new Opacity(
          opacity: selected ? 1.0 : 0.45,
          child: new Padding(
            padding: const EdgeDims.symmetric(horizontal: 16.0),
            child: child
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
            child: new Flex(children, direction: FlexDirection.horizontal)
          )
        )
      )
    );

    return new Listener(
      onGestureTap: (_) {
        if (onPressed != null)
          onPressed();
      },
      child: new Container(
        height: 48.0,
        decoration: new BoxDecoration(backgroundColor: _getBackgroundColor(themeData)),
        child: new InkWell(
          child: new Flex(flexChildren)
        )
      )
    );
  }
}
