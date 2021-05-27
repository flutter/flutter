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
    required this.icon,
    @Deprecated(
      'Use "label" instead, as it allows for an improved text-scaling experience. '
      'This feature was deprecated after v1.19.0.',
    )
    this.title,
    this.label,
    Widget? activeIcon,
    this.backgroundColor,
    this.tooltip,
  }) : activeIcon = activeIcon ?? icon,
       assert(label == null || title == null),
       assert(icon != null);

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

  /// The title of the item. If the title is not provided only the icon will be shown when not used in a Material Design [BottomNavigationBar].
  ///
  /// This field is deprecated, use [label] instead.
  @Deprecated(
    'Use "label" instead, as it allows for an improved text-scaling experience. '
    'This feature was deprecated after v1.19.0.',
  )
  final Widget? title;

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

  /// The text to display in the tooltip for this [BottomNavigationBarItem], when
  /// the user long presses the item.
  ///
  /// The [Tooltip] will only appear on an item in a Material design [BottomNavigationBar], and
  /// when the string is not empty.
  ///
  /// Defaults to null, in which case the [label] text will be used.
  final String? tooltip;
}
