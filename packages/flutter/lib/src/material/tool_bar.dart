// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'material.dart';
import 'tabs.dart';
import 'theme.dart';
import 'typography.dart';

class ToolBar extends StatelessComponent {
  ToolBar({
    Key key,
    this.left,
    this.center,
    this.right,
    this.bottom,
    this.tabBar,
    this.elevation: 4,
    this.backgroundColor,
    this.textTheme,
    this.padding: EdgeDims.zero
  }) : super(key: key);

  final Widget left;
  final Widget center;
  final List<Widget> right;
  final Widget bottom;
  final TabBar tabBar;
  final int elevation;
  final Color backgroundColor;
  final TextTheme textTheme;
  final EdgeDims padding;

  ToolBar copyWith({
    Key key,
    Widget left,
    Widget center,
    List<Widget> right,
    Widget bottom,
    int elevation,
    Color backgroundColor,
    TextTheme textTheme,
    EdgeDims padding
  }) {
    return new ToolBar(
      key: key ?? this.key,
      left: left ?? this.left,
      center: center ?? this.center,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      tabBar: tabBar ?? this.tabBar,
      elevation: elevation ?? this.elevation,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textTheme: textTheme ?? this.textTheme,
      padding: padding ?? this.padding
    );
  }

  Widget build(BuildContext context) {
    Color color = backgroundColor;
    IconThemeData iconThemeData;
    TextStyle centerStyle = textTheme?.title;
    TextStyle sideStyle = textTheme?.body1;

    if (color == null || iconThemeData == null || textTheme == null) {
      ThemeData themeData = Theme.of(context);
      color ??= themeData.primaryColor;
      iconThemeData ??= themeData.primaryIconTheme;

      TextTheme primaryTextTheme = themeData.primaryTextTheme;
      centerStyle ??= primaryTextTheme.title;
      sideStyle ??= primaryTextTheme.body2;
    }

    final List<Widget> firstRow = <Widget>[];
    if (left != null)
      firstRow.add(left);
    firstRow.add(
      new Flexible(
        child: new Padding(
          padding: new EdgeDims.only(left: 24.0),
          child: center != null ? new DefaultTextStyle(style: centerStyle, child: center) : null
        )
      )
    );
    if (right != null)
      firstRow.addAll(right);

    final List<Widget> rows = <Widget>[
      new Container(
        height: kToolBarHeight,
        child: new DefaultTextStyle(
          style: sideStyle,
          child: new Row(firstRow)
        )
      )
    ];
    if (bottom != null) {
      rows.add(
        new DefaultTextStyle(
          style: centerStyle,
          child: new Container(
            height: kExtendedToolBarHeight - kToolBarHeight,
            child: bottom
          )
        )
      );
    }
    if (tabBar != null)
      rows.add(tabBar);

    EdgeDims combinedPadding = new EdgeDims.symmetric(horizontal: 8.0);
    if (padding != null)
      combinedPadding += padding;

    Widget contents = new Material(
      color: color,
      elevation: elevation,
      child: new Container(
        padding: combinedPadding,
        child: new Column(
          rows,
          justifyContent: FlexJustifyContent.collapse
        )
      )
    );

    if (iconThemeData != null)
      contents = new IconTheme(data: iconThemeData, child: contents);

    return contents;
  }

}
