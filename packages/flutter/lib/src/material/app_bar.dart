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

class AppBar extends StatelessWidget {
  AppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.foregroundOpacity: 1.0,
    this.tabBar,
    this.elevation: 4,
    this.backgroundColor,
    this.textTheme,
    this.padding: EdgeInsets.zero,
    double expandedHeight,
    double collapsedHeight,
    double minimumHeight,
    double actualHeight
  }) : _expandedHeight = expandedHeight,
       _collapsedHeight = collapsedHeight,
       _minimumHeight = minimumHeight,
       _actualHeight = actualHeight,
       super(key: key) {
    assert((flexibleSpace != null) ? tabBar == null : true);
    assert((tabBar != null) ? flexibleSpace == null : true);
  }

  final Widget leading;
  final Widget title;
  final List<Widget> actions;
  final WidgetBuilder flexibleSpace;
  final double foregroundOpacity;
  final TabBar<dynamic> tabBar;
  final int elevation;
  final Color backgroundColor;
  final TextTheme textTheme;
  final EdgeInsets padding;
  final double _expandedHeight;
  final double _collapsedHeight;
  final double _minimumHeight;
  final double _actualHeight;

  AppBar copyWith({
    Key key,
    Widget leading,
    Widget title,
    List<Widget> actions,
    WidgetBuilder flexibleSpace,
    double foregroundOpacity,
    int elevation,
    Color backgroundColor,
    TextTheme textTheme,
    EdgeInsets padding,
    double expandedHeight,
    double collapsedHeight,
    double actualHeight
  }) {
    return new AppBar(
      key: key ?? this.key,
      leading: leading ?? this.leading,
      title: title ?? this.title,
      actions: actions ?? this.actions,
      flexibleSpace: flexibleSpace ?? this.flexibleSpace,
      foregroundOpacity: foregroundOpacity ?? this.foregroundOpacity,
      tabBar: tabBar ?? this.tabBar,
      elevation: elevation ?? this.elevation,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textTheme: textTheme ?? this.textTheme,
      padding: padding ?? this.padding,
      expandedHeight: expandedHeight ?? this._expandedHeight,
      collapsedHeight: collapsedHeight ?? this._collapsedHeight,
      actualHeight: actualHeight ?? this._actualHeight
    );
  }

  double get _tabBarHeight => tabBar == null ? null : tabBar.minimumHeight;

  double get _toolBarHeight => kToolBarHeight;

  double get expandedHeight => _expandedHeight ?? (_toolBarHeight + (_tabBarHeight ?? 0.0));

  double get collapsedHeight => _collapsedHeight ?? (_toolBarHeight + (_tabBarHeight ?? 0.0));

  double get minimumHeight => _minimumHeight ?? _tabBarHeight ?? _toolBarHeight;

  double get actualHeight => _actualHeight ?? expandedHeight;

  // Defines the opacity of the toolbar's text and icons.
  double _toolBarOpacity(double statusBarHeight) {
    return ((actualHeight - (_tabBarHeight ?? 0.0) - statusBarHeight) / _toolBarHeight).clamp(0.0, 1.0);
  }

  double _tabBarOpacity(double statusBarHeight) {
    final double tabBarHeight = _tabBarHeight ?? 0.0;
    return ((actualHeight - statusBarHeight) / tabBarHeight).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = (MediaQuery.of(context)?.padding ?? EdgeInsets.zero).top;
    final ThemeData theme = Theme.of(context);

    IconThemeData iconTheme = theme.primaryIconTheme;
    TextStyle centerStyle = textTheme?.title ?? theme.primaryTextTheme.title;
    TextStyle sideStyle = textTheme?.body1 ?? theme.primaryTextTheme.body1;

    final double toolBarOpacity = _toolBarOpacity(statusBarHeight);
    if (toolBarOpacity != 1.0) {
      final double opacity = const Interval(0.25, 1.0, curve: Curves.ease).transform(toolBarOpacity);
      if (centerStyle?.color != null)
        centerStyle = centerStyle.copyWith(color: centerStyle.color.withOpacity(opacity));
      if (sideStyle?.color != null)
        sideStyle = sideStyle.copyWith(color: sideStyle.color.withOpacity(opacity));

      if (iconTheme != null) {
        iconTheme = new IconThemeData(
          opacity: opacity * iconTheme.clampedOpacity,
          color: iconTheme.color
        );
      }
    }

    final List<Widget> toolBarRow = <Widget>[];
    if (leading != null)
      toolBarRow.add(leading);
    toolBarRow.add(
      new Flexible(
        child: new Padding(
          padding: new EdgeInsets.only(left: 24.0),
          child: title != null ? new DefaultTextStyle(style: centerStyle, child: title) : null
        )
      )
    );
    if (actions != null)
      toolBarRow.addAll(actions);

    Widget appBar = new SizedBox(
      height: kToolBarHeight,
      child: new IconTheme(
        data: iconTheme,
        child: new DefaultTextStyle(
          style: sideStyle,
          child: new Row(children: toolBarRow)
        )
      )
    );

    final double tabBarOpacity = _tabBarOpacity(statusBarHeight);
    if (tabBar != null) {
      appBar = new Column(
        children: <Widget>[
          appBar,
          tabBarOpacity == 1.0 ? tabBar : new Opacity(
            child: tabBar,
            opacity: const Interval(0.25, 1.0, curve: Curves.ease).transform(tabBarOpacity)
          )
        ]
      );
    }

    EdgeInsets combinedPadding = new EdgeInsets.symmetric(horizontal: 8.0);
    if (padding != null)
      combinedPadding += padding;

    // If the appBar's height shrinks below collapsedHeight, it will be clipped and bottom
    // justified. This is so that the toolBar/tabBar appear to move upwards as the appBar's
    // height is reduced.
    final double paddedCollapsedHeight = collapsedHeight + combinedPadding.top + combinedPadding.bottom;
    appBar = new ConstrainedBox(
      constraints: new BoxConstraints(maxHeight: paddedCollapsedHeight),
      child: new Padding(
        padding: new EdgeInsets.only(left: combinedPadding.left, right: combinedPadding.right),
        child: new ClipRect(
          child: new OverflowBox(
            alignment: const FractionalOffset(0.0, 1.0), // bottom justify
            minHeight: paddedCollapsedHeight,
            maxHeight: paddedCollapsedHeight,
            child: new Padding(
              padding: new EdgeInsets.only(top: combinedPadding.top, bottom: combinedPadding.bottom),
              child: appBar
            )
          )
        )
      )
    );

    if (flexibleSpace != null) {
      appBar = new Stack(
        children: <Widget>[
          flexibleSpace(context),
          new Align(child: appBar, alignment: const FractionalOffset(0.0, 0.0))
        ]
      );
    }

    appBar = new Material(
      color: backgroundColor ?? theme.primaryColor,
      elevation: elevation,
      child: appBar
    );

    return appBar;
  }

}
