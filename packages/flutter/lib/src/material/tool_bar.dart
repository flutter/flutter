// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'shadows.dart';
import 'theme.dart';
import 'typography.dart';

class ToolBar extends StatelessComponent {
  ToolBar({
    Key key,
    this.left,
    this.center,
    this.right,
    this.bottom,
    this.elevation: 4,
    this.backgroundColor,
    this.textTheme,
    this.padding: EdgeDims.zero
  }) : super(key: key);

  final Widget left;
  final Widget center;
  final List<Widget> right;
  final Widget bottom;
  final int elevation;
  final Color backgroundColor;
  final TextTheme textTheme;
  final EdgeDims padding;

  ToolBar withPadding(EdgeDims newPadding) {
    return new ToolBar(
      key: key,
      left: left,
      center: center,
      right: right,
      bottom: bottom,
      elevation: elevation,
      backgroundColor: backgroundColor,
      textTheme: textTheme,
      padding: newPadding
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

    List<Widget> children = new List<Widget>();

    if (left != null)
      children.add(left);

    children.add(
      new Flexible(
        child: new Padding(
          child: center != null ? new DefaultTextStyle(child: center, style: centerStyle) : null,
          padding: new EdgeDims.only(left: 24.0)
        )
      )
    );

    if (right != null)
      children.addAll(right);

    final List<Widget> columnChildren = <Widget>[
      new Container(height: kToolBarHeight, child: new Row(children))
    ];

    if (bottom != null)
      columnChildren.add(new DefaultTextStyle(
        style: centerStyle,
        child: new Container(height: kExtendedToolBarHeight - kToolBarHeight, child: bottom)
      ));

    Widget content = new AnimatedContainer(
      duration: kThemeChangeDuration,
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(
        backgroundColor: color,
        boxShadow: elevationToShadow[elevation]
      ),
      child: new DefaultTextStyle(
        style: sideStyle,
        child: new Container(padding: padding, child: new Column(columnChildren, justifyContent: FlexJustifyContent.collapse))
      )
    );

    if (iconThemeData != null)
      content = new IconTheme(data: iconThemeData, child: content);
    return content;
  }

}
