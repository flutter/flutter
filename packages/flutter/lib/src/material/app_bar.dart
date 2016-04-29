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

// TODO(eseidel) Toolbar needs to change size based on orientation:
// http://www.google.com/design/spec/layout/structure.html#structure-app-bar
// Mobile Landscape: 48dp
// Mobile Portrait: 56dp
// Tablet/Desktop: 64dp

/// A material design app bar.
///
/// An app bar consists of a tool bar and potentially other widgets, such as a
/// [TabBar] and a [FlexibleSpaceBar]. App bars typically expose one or more
/// common actions with [IconButtons]s which are optionally followed by a
/// [PopupMenuButton] for less common operations.
///
/// App bars are most commonly used in the [Scaffold.appBar] property, which
/// places the app bar at the top of the app.
///
/// See also:
///
///  * [Scaffold]
///  * [TabBar]
///  * [IconButton]
///  * [PopupMenuButton]
///  * [FlexibleSpaceBar]
///  * <https://www.google.com/design/spec/layout/structure.html#structure-toolbars>
class AppBar extends StatelessWidget {
  /// Creates a material design app bar.
  ///
  /// Typically used in the [Scaffold.appBar] property.
  AppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
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

  /// A widget to display before the [title].
  ///
  /// If this field is null and this app bar is used in a [Scaffold], the
  /// [Scaffold] will fill this field with an appropriate widget. For example,
  /// if the [Scaffold] also has a [Drawer], the [Scaffold] will fill this
  /// widget with an [IconButton] that opens the drawer. If there's no [Drawer]
  /// and the parent [Navigator] can go back, the [Scaffold] will fill this
  /// field with an [IconButton] that calls [Navigator.pop].
  final Widget leading;

  /// The primary widget displayed in the app bar.
  ///
  /// Typically a [Text] widget containing a description of the current contents
  /// of the app.
  final Widget title;

  /// Widgets to display after the title.
  ///
  /// Typically these widgets are [IconButton]s representing common operations.
  /// For less common operations, consider using a [PopupMenuButton] as the
  /// last action.
  final List<Widget> actions;

  /// A widget to aid in building scroll-based collapsing app bar effects.
  ///
  /// Typically a [FlexibleSpaceBar]. See [FlexibleSpaceBar] for details.
  final Widget flexibleSpace;

  /// A horizontal bar of tabs to display at the bottom of the app bar.
  final TabBar<dynamic> tabBar;

  /// The z-coordinate at which to place this app bar.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  /// The color to use for the the app bar's material.
  ///
  /// Defaults to [ThemeData.primaryColor].
  final Color backgroundColor;

  /// The typographic style to use for text in the app bar.
  ///
  /// Defaults to [ThemeData.primaryTextTheme].
  final TextTheme textTheme;

  /// The amount of space by which to inset the contents of the app bar.
  final EdgeInsets padding;

  final double _expandedHeight;
  final double _collapsedHeight;
  final double _minimumHeight;
  final double _actualHeight;

  /// Creates a copy of this app bar but with the given fields replaced with the new values.
  AppBar copyWith({
    Key key,
    Widget leading,
    Widget title,
    List<Widget> actions,
    Widget flexibleSpace,
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

  /// The height of this app bar when fully expanded.
  double get expandedHeight => _expandedHeight ?? (_toolBarHeight + (_tabBarHeight ?? 0.0));

  /// The height of this app bar when fully collapsed.
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;
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
          opacity: opacity * iconTheme.opacity,
          color: iconTheme.color
        );
      }
    }

    final List<Widget> toolBarRow = <Widget>[];
    if (leading != null) {
      toolBarRow.add(new Padding(
        padding: new EdgeInsets.only(right: 16.0),
        child: leading
      ));
    }
    toolBarRow.add(new Flexible(
      child: new Padding(
        padding: new EdgeInsets.only(left: 8.0),
        child: title != null ? new DefaultTextStyle(style: centerStyle, child: title) : null
      )
    ));
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
            alignment: FractionalOffset.bottomLeft, // bottom justify
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
          flexibleSpace,
          new Align(child: appBar, alignment: FractionalOffset.topLeft)
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
