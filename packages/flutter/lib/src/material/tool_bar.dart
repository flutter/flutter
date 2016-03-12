// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'material.dart';
import 'theme.dart';
import 'typography.dart';

class ToolBar extends StatelessComponent {
  ToolBar({
    Key key,
    this.left,
    this.center,
    this.right,
    this.flexibleSpace,
    this.foregroundOpacity: 1.0,
    this.tabBar,
    this.elevation: 4,
    this.backgroundColor,
    this.textTheme,
    this.padding: EdgeInsets.zero
  }) : super(key: key) {
    assert((flexibleSpace != null) ? tabBar == null : true);
    assert((tabBar != null) ? flexibleSpace == null : true);
  }

  final Widget left;
  final Widget center;
  final List<Widget> right;
  final WidgetBuilder flexibleSpace;
  final double foregroundOpacity;
  final Widget tabBar;
  final int elevation;
  final Color backgroundColor;
  final TextTheme textTheme;
  final EdgeInsets padding;

  ToolBar copyWith({
    Key key,
    Widget left,
    Widget center,
    List<Widget> right,
    WidgetBuilder flexibleSpace,
    double foregroundOpacity,
    int elevation,
    Color backgroundColor,
    TextTheme textTheme,
    EdgeInsets padding
  }) {
    return new ToolBar(
      key: key ?? this.key,
      left: left ?? this.left,
      center: center ?? this.center,
      right: right ?? this.right,
      flexibleSpace: flexibleSpace ?? this.flexibleSpace,
      foregroundOpacity: foregroundOpacity ?? this.foregroundOpacity,
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

    if (foregroundOpacity != 1.0) {
      final int alpha = (foregroundOpacity.clamp(0.0, 1.0) * 255.0).round();
      if (centerStyle?.color != null)
        centerStyle = centerStyle.copyWith(color: centerStyle.color.withAlpha(alpha));
      if (sideStyle?.color != null)
        sideStyle = sideStyle.copyWith(color: sideStyle.color.withAlpha(alpha));
      if (iconThemeData != null) {
        iconThemeData = new IconThemeData(
          opacity: foregroundOpacity * iconThemeData.clampedOpacity,
          color: iconThemeData.color
        );
      }
    }

    final List<Widget> toolBarRow = <Widget>[];
    if (left != null)
      toolBarRow.add(left);
    toolBarRow.add(
      new Flexible(
        child: new Padding(
          padding: new EdgeInsets.only(left: 24.0),
          child: center != null ? new DefaultTextStyle(style: centerStyle, child: center) : null
        )
      )
    );
    if (right != null)
      toolBarRow.addAll(right);

    EdgeInsets combinedPadding = new EdgeInsets.symmetric(horizontal: 8.0);
    if (padding != null)
      combinedPadding += padding;

    // If the toolBar's height shrinks below toolBarHeight, it will be clipped and bottom
    // justified. This is so that the toolbar appears to move upwards as its height is reduced.
    final double toolBarHeight = kToolBarHeight + combinedPadding.top + combinedPadding.bottom;
    final Widget toolBar = new ConstrainedBox(
      constraints: new BoxConstraints(maxHeight: toolBarHeight),
      child: new Padding(
        padding: new EdgeInsets.only(left: combinedPadding.left, right: combinedPadding.right),
        child: new ClipRect(
          child: new OverflowBox(
            alignment: const FractionalOffset(0.0, 1.0), // bottom justify
            minHeight: toolBarHeight,
            maxHeight: toolBarHeight,
            child: new DefaultTextStyle(
              style: sideStyle,
              child: new Padding(
                padding: new EdgeInsets.only(top: combinedPadding.top, bottom: combinedPadding.bottom),
                child: new Row(children: toolBarRow)
              )
            )
          )
        )
      )
    );

    Widget appBar = toolBar;
    if (tabBar != null) {
      appBar = new Column(
        justifyContent: FlexJustifyContent.collapse,
        children: <Widget>[toolBar, tabBar]
      );
    } else if (flexibleSpace != null) {
      appBar = new Stack(
        children: <Widget>[
          flexibleSpace(context),
          new Align(child: toolBar, alignment: const FractionalOffset(0.0, 0.0))
        ]
      );
    }

    Widget contents = new Material(
      color: color,
      elevation: elevation,
      child: appBar
    );

    if (iconThemeData != null)
      contents = new IconTheme(data: iconThemeData, child: contents);

    return contents;
  }

}
