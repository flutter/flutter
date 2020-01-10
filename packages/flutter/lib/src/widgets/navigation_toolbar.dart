// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';

/// [NavigationToolbar] is a layout helper to position 3 widgets or groups of
/// widgets along a horizontal axis that's sensible for an application's
/// navigation bar such as in Material Design and in iOS.
///
/// The [leading] and [trailing] widgets occupy the edges of the widget with
/// reasonable size constraints while the [middle] widget occupies the remaining
/// space in either a center aligned or start aligned fashion.
///
/// Either directly use the themed app bars such as the Material [AppBar] or
/// the iOS [CupertinoNavigationBar] or wrap this widget with more theming
/// specifications for your own custom app bar.
class NavigationToolbar extends StatelessWidget {
  /// Creates a widget that lays out its children in a manner suitable for a
  /// toolbar.
  const NavigationToolbar({
    Key key,
    this.leading,
    this.middle,
    this.trailing,
    this.centerMiddle = true,
    this.middleSpacing = kMiddleSpacing,
    this.centerIcons = true,
  })  : assert(centerMiddle != null),
        assert(middleSpacing != null),
        assert(centerIcons != null),
        super(key: key);

  /// The default spacing around the [middle] widget in dp.
  static const double kMiddleSpacing = 16.0;

  /// Widget to place at the start of the horizontal toolbar.
  final Widget leading;

  /// Widget to place in the middle of the horizontal toolbar, occupying
  /// as much remaining space as possible.
  final Widget middle;

  /// Widget to place at the end of the horizontal toolbar.
  final Widget trailing;

  /// Whether to align the [middle] widget to the center of this widget or
  /// next to the [leading] widget when false.
  final bool centerMiddle;

  /// The spacing around the [middle] widget on horizontal axis.
  ///
  /// Defaults to [kMiddleSpacing].
  final double middleSpacing;

  /// Specifies whether the [AppBar.leading] and [AppBar.actions] should always be placed vertically center of the AppBar.
  /// If you don't use [AppBar.titleHeight] exclusively, this option has NO effect.
  ///
  /// If you plan to set AppBar height manually (by specifying [AppBar.titleHeight]), the icons ([AppBar.leading] and [AppBar.actions]) are always placed vertically center of the AppBar.
  ///
  /// If this is set to false, the icons will be placed on top (as you had not specified titleHeight).
  ///
  /// Defaults to true.
  final bool centerIcons;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection textDirection = Directionality.of(context);
    return CustomMultiChildLayout(
      delegate: _ToolbarLayout(
        centerMiddle: centerMiddle,
        middleSpacing: middleSpacing,
        textDirection: textDirection,
        centerIcons: centerIcons,
      ),
      children: <Widget>[
        if (leading != null) LayoutId(id: _ToolbarSlot.leading, child: leading),
        if (middle != null) LayoutId(id: _ToolbarSlot.middle, child: middle),
        if (trailing != null)
          LayoutId(id: _ToolbarSlot.trailing, child: trailing),
      ],
    );
  }
}

enum _ToolbarSlot {
  leading,
  middle,
  trailing,
}

class _ToolbarLayout extends MultiChildLayoutDelegate {
  _ToolbarLayout({
    this.centerMiddle,
    @required this.middleSpacing,
    @required this.textDirection,
    @required this.centerIcons,
  })  : assert(middleSpacing != null),
        assert(textDirection != null),
        assert(centerIcons != null);

  // If false the middle widget should be start-justified within the space
  // between the leading and trailing widgets.
  // If true the middle widget is centered within the toolbar (not within the horizontal
  // space between the leading and trailing widgets).
  final bool centerMiddle;

  /// The spacing around middle widget on horizontal axis.
  final double middleSpacing;

  final TextDirection textDirection;

  final bool centerIcons;

  @override
  void performLayout(Size size) {
    double leadingWidth = 0.0;
    double trailingWidth = 0.0;

    if (hasChild(_ToolbarSlot.leading)) {
      final BoxConstraints constraints = BoxConstraints(
        minWidth: 0.0,
        maxWidth: size.width / 3.0,
        // The leading widget shouldn't take up more than 1/3 of the space.
        minHeight: centerIcons ? size.height : min(size.height, kToolbarHeight),
        // The height should be exactly the height of the bar.
        // If icons need to be centered, use received height, otherwise use minimum of received height and standard height.
        maxHeight: centerIcons ? size.height : min(size.height, kToolbarHeight),
      );
      leadingWidth = layoutChild(_ToolbarSlot.leading, constraints).width;
      double leadingX;
      switch (textDirection) {
        case TextDirection.rtl:
          leadingX = size.width - leadingWidth;
          break;
        case TextDirection.ltr:
          leadingX = 0.0;
          break;
      }
      positionChild(_ToolbarSlot.leading, Offset(leadingX, 0.0));
    }

    if (hasChild(_ToolbarSlot.trailing)) {
      final BoxConstraints constraints = BoxConstraints(
          minWidth: 0.0,
          maxWidth: size.width,
          minHeight: 0.0,
          maxHeight:
              centerIcons ? size.height : min(size.height, kToolbarHeight));
      final Size trailingSize = layoutChild(_ToolbarSlot.trailing, constraints);
      double trailingX;
      switch (textDirection) {
        case TextDirection.rtl:
          trailingX = 0.0;
          break;
        case TextDirection.ltr:
          trailingX = size.width - trailingSize.width;
          break;
      }
      final double trailingY =
          ((centerIcons ? size.height : min(size.height, kToolbarHeight)) -
                  trailingSize.height) /
              2.0;
      trailingWidth = trailingSize.width;
      positionChild(_ToolbarSlot.trailing, Offset(trailingX, trailingY));
    }

    if (hasChild(_ToolbarSlot.middle)) {
      final double maxWidth = math.max(
          size.width - leadingWidth - trailingWidth - middleSpacing * 2.0, 0.0);
      final BoxConstraints constraints =
          BoxConstraints.loose(size).copyWith(maxWidth: maxWidth);
      final Size middleSize = layoutChild(_ToolbarSlot.middle, constraints);

      final double middleStartMargin = leadingWidth + middleSpacing;
      double middleStart = middleStartMargin;
      final double middleY = (size.height - middleSize.height) / 2.0;
      // If the centered middle will not fit between the leading and trailing
      // widgets, then align its left or right edge with the adjacent boundary.
      if (centerMiddle) {
        middleStart = (size.width - middleSize.width) / 2.0;
        if (middleStart + middleSize.width > size.width - trailingWidth)
          middleStart = size.width - trailingWidth - middleSize.width;
        else if (middleStart < middleStartMargin)
          middleStart = middleStartMargin;
      }

      double middleX;
      switch (textDirection) {
        case TextDirection.rtl:
          middleX = size.width - middleSize.width - middleStart;
          break;
        case TextDirection.ltr:
          middleX = middleStart;
          break;
      }

      positionChild(_ToolbarSlot.middle, Offset(middleX, middleY));
    }
  }

  @override
  bool shouldRelayout(_ToolbarLayout oldDelegate) {
    return oldDelegate.centerMiddle != centerMiddle ||
        oldDelegate.middleSpacing != middleSpacing ||
        oldDelegate.textDirection != textDirection;
  }
}
