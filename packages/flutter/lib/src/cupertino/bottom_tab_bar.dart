// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Standard iOS 10 tab bar height.
const double _kTabBarHeight = 50.0;

const Color _kDefaultTabBarBackgroundColor = const Color(0xCCF8F8F8);

class CupertinoTabBar extends StatelessWidget {
  CupertinoTabBar({
    Key key,
    @required this.items,
    this.onTap,
    this.currentIndex: 0,
    this.backgroundColor: _kDefaultTabBarBackgroundColor,
    this.activeColor: CupertinoColors.activeBlue,
    this.inactiveColor: CupertinoColors.inactiveGray,
    this.iconSize: 24.0,
  }) : super(key: key) {
    assert(items != null);
    assert(items.length >= 2);
    assert(0 <= currentIndex && currentIndex < items.length);
    assert(iconSize != null);
  }

  /// The interactive items laid out within the bottom navigation bar.
  final List<BottomNavigationBarItem> items;

  /// The callback that is called when a item is tapped.
  ///
  /// The widget creating the bottom navigation bar needs to keep track of the
  /// current index and call `setState` to rebuild it with the newly provided
  /// index.
  final ValueChanged<int> onTap;

  /// The index into [items] of the current active item.
  final int currentIndex;

  /// The background color of the tab bar. If it contains transparency, the
  /// tab bar will automatically produce a blurring effect to the content
  /// behind it.
  final Color backgroundColor;

  /// The foreground color of the icon and title for the [BottomNavigationBarItem]
  /// of the selected tab.
  final Color activeColor;

  /// The foreground color of the icon and title for the [BottomNavigationBarItem]s
  /// in the unselected state.
  final Color inactiveColor;

  /// The size of all of the [BottomNavigationBarItem] icons.
  ///
  /// This value is used to to configure the [IconTheme] for the navigation
  /// bar. When a [BottomNavigationBarItem.icon] widget is not an [Icon] the widget
  /// should configure itself to match the icon theme's size and color.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bool addBlur = backgroundColor.opacity < 1.0;

    Widget returnWidget;

    returnWidget = new DecoratedBox(
      decoration: new BoxDecoration(
        border: const Border(
          top: const BorderSide(
            color: const Color(0x4C000000),
            width: 0.5, // One physical pixel.
            style: BorderStyle.solid,
          ),
        ),
        color: backgroundColor,
      ),
      child: new SizedBox(
        height: _kTabBarHeight,
        child: IconTheme.merge( // Default with the inactive state.
          data: new IconThemeData(
            color: inactiveColor,
            size: iconSize,
          ),
          child: DefaultTextStyle.merge( // Default with the inactive state.
            style: new TextStyle(
              fontSize: 10.0,
              letterSpacing: 0.12,
              color: inactiveColor,
            ),
            child: new Row(
              // Align bottom since we want the labels to be aligned.
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildTabItems(),
            ),
          ),
        ),
      ),
    );

    if (addBlur) {
      // For non-opaque backgrounds, apply a blur effect.
      returnWidget = new ClipRect(
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: returnWidget,
        ),
      );
    }

    return returnWidget;
  }

  List<Widget> _buildTabItems() {
    final List<Widget> returnWidgets = <Widget>[];

    for (int i=0; i<items.length; i++) {
      returnWidgets.add(
        _wrapActiveItem(

          new Expanded(
            child: new GestureDetector(
              onTap: () {
                if (onTap != null)
                  onTap(i);
              },
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget> [
                  new Expanded(child: new Center(child: items[i].icon)),
                  items[i].title,
                  const Padding(padding: const EdgeInsets.only(bottom: 4.0)),
                ],
              ),
            ),
          ),
          active: i == currentIndex
        ),
      );
    }

    return returnWidgets;
  }

  /// Change the active tab item's icon and title colors to active.
  Widget _wrapActiveItem(Widget item, { bool active }) {
    if (!active)
      return item;

    return IconTheme.merge(
      data: new IconThemeData(color: activeColor),
      child: DefaultTextStyle.merge(
        style: new TextStyle(color: activeColor),
        child: item,
      ),
    );
  }
}
