// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

import 'framework.dart';

/// An interactive button within either material's [BottomNavigationBar]
/// or the iOS themed [CupertinoTabBar] with an icon and title.
///
/// This class is rarely used in isolation. It is typically embedded in one of
/// the bottom navigation widgets above.
///
/// See also:
///
///  * [BottomNavigationBar]
///  * <https://material.io/design/components/bottom-navigation.html>
///  * [CupertinoTabBar]
///  * <https://developer.apple.com/ios/human-interface-guidelines/bars/tab-bars>
class BottomNavigationBarItem {
  /// Creates an item that is used with [BottomNavigationBar.items].
  ///
  /// The argument [icon] should not be null and the argument [label] should not be null when used in a Material Design's [BottomNavigationBar].
  const BottomNavigationBarItem({
    this.key,
    required this.icon,
    this.label,
    Widget? activeIcon,
    this.backgroundColor,
    this.tooltip,
  }) : activeIcon = activeIcon ?? icon;

  /// A key to be passed through to the resultant widget.
  ///
  /// This allows the identification of different [BottomNavigationBarItem]s through their keys.
  ///
  /// When changing the number of bar items in response to a bar item being tapped, giving
  /// each item a key will allow the inkwell / splash animation to be correctly positioned.
  final Key? key;

  /// The icon of the item.
  ///
  /// Typically the icon is an [Icon] or an [ImageIcon] widget. If another type
  /// of widget is provided then it should configure itself to match the current
  /// [IconTheme] size and color.
  ///
  /// If [activeIcon] is provided, this will only be displayed when the item is
  /// not selected.
  ///
  /// To make the bottom navigation bar more accessible, consider choosing an
  /// icon with a stroked and filled version, such as [Icons.cloud] and
  /// [Icons.cloud_queue]. [icon] should be set to the stroked version and
  /// [activeIcon] to the filled version.
  ///
  /// If a particular icon doesn't have a stroked or filled version, then don't
  /// pair unrelated icons. Instead, make sure to use a
  /// [BottomNavigationBarType.shifting].
  final Widget icon;

  /// An alternative icon displayed when this bottom navigation item is
  /// selected.
  ///
  /// If this icon is not provided, the bottom navigation bar will display
  /// [icon] in either state.
  ///
  /// See also:
  ///
  ///  * [BottomNavigationBarItem.icon], for a description of how to pair icons.
  final Widget activeIcon;

  /// The text label for this [BottomNavigationBarItem].
  ///
  /// This will be used to create a [Text] widget to put in the bottom navigation bar.
  final String? label;

  /// The color of the background radial animation for material [BottomNavigationBar].
  ///
  /// If the navigation bar's type is [BottomNavigationBarType.shifting], then
  /// the entire bar is flooded with the [backgroundColor] when this item is
  /// tapped. This will override [BottomNavigationBar.backgroundColor].
  ///
  /// Not used for [CupertinoTabBar]. Control the invariant bar color directly
  /// via [CupertinoTabBar.backgroundColor].
  ///
  /// See also:
  ///
  ///  * [Icon.color] and [ImageIcon.color] to control the foreground color of
  ///    the icons themselves.
  final Color? backgroundColor;

  /// The text to display in the [Tooltip] for this [BottomNavigationBarItem].
  ///
  /// A [Tooltip] will only appear on this item if [tooltip] is set to a non-empty string.
  ///
  /// Defaults to null, in which case the tooltip is not shown.
  final String? tooltip;
}
