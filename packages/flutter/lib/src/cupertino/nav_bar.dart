// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Standard iOS 10 nav bar height without the status bar.
const double _kNavBarHeight = 44.0;

const Color _kDefaultNavBarBackgroundColor = const Color(0xCCF8F8F8);
const Color _kDefaultNavBarBorderColor = const Color(0x4C000000);

/// An iOS-styled navigation bar.
///
/// The navigation bar is a toolbar that minimally consists of a widget, normally
/// a page title, in the [middle] of the toolbar.
///
/// It also supports a [leading] and [trailing] widget before and after the
/// [middle] widget while keeping the [middle] widget centered.
///
/// It should be placed at top of the screen and automatically accounts for
/// the OS's status bar.
///
/// If the given [backgroundColor]'s opacity is not 1.0 (which is the case by
/// default), it will produce a blurring effect to the content behind it.
//
// TODO(xster): document automatic addition of a CupertinoBackButton.
// TODO(xster): add sample code using icons.
// TODO(xster): document integration into a CupertinoScaffold.
class CupertinoNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a navigation bar in the iOS style.
  const CupertinoNavigationBar({
    Key key,
    this.leading,
    @required this.middle,
    this.trailing,
    this.backgroundColor: _kDefaultNavBarBackgroundColor,
    this.actionsForegroundColor: CupertinoColors.activeBlue,
  }) : assert(middle != null, 'There must be a middle widget, usually a title'),
      super(key: key);

  /// Widget to place at the start of the nav bar. Normally a back button
  /// for a normal page or a cancel button for full page dialogs.
  final Widget leading;

  /// Widget to place in the middle of the nav bar. Normally a title or
  /// a segmented control.
  final Widget middle;

  /// Widget to place at the end of the nav bar. Normally additional actions
  /// taken on the page such as a search or edit function.
  final Widget trailing;

  // TODO(xster): implement support for double row nav bars.

  /// The background color of the nav bar. If it contains transparency, the
  /// tab bar will automatically produce a blurring effect to the content
  /// behind it.
  final Color backgroundColor;

  /// Default color used for text and icons of the [leading] and [trailing]
  /// widgets in the nav bar.
  ///
  /// The [title] remains black if it's a text as per iOS standard design.
  final Color actionsForegroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(_kNavBarHeight);

  @override
  Widget build(BuildContext context) {
    final bool addBlur = backgroundColor.alpha != 0xFF;

    Widget styledMiddle = middle;
    if (styledMiddle.runtimeType == Text || styledMiddle.runtimeType == DefaultTextStyle) {
      // Let the middle be black rather than `actionsForegroundColor` in case
      // it's a plain text title.
      styledMiddle = DefaultTextStyle.merge(
        style: const TextStyle(color: CupertinoColors.black),
        child: middle,
      );
    }

    // TODO(xster): automatically build a CupertinoBackButton.

    Widget result = new DecoratedBox(
      decoration: new BoxDecoration(
        border: const Border(
          bottom: const BorderSide(
            color: _kDefaultNavBarBorderColor,
            width: 0.0, // One physical pixel.
            style: BorderStyle.solid,
          ),
        ),
        color: backgroundColor,
      ),
      child: new SizedBox(
        height: _kNavBarHeight + MediaQuery.of(context).padding.top,
        child: IconTheme.merge(
          data: new IconThemeData(
            color: actionsForegroundColor,
            size: 22.0,
          ),
          child: DefaultTextStyle.merge(
            style: new TextStyle(
              fontSize: 17.0,
              letterSpacing: -0.24,
              color: actionsForegroundColor,
            ),
            child: new Padding(
              padding: new EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                // TODO(xster): dynamically reduce padding when an automatic
                // CupertinoBackButton is present.
                left: 16.0,
                right: 16.0,
              ),
              child: new NavigationToolbar(
                leading: leading,
                middle: styledMiddle,
                trailing: trailing,
                centerMiddle: true,
              ),
            ),
          ),
        ),
      ),
    );

    if (addBlur) {
      // For non-opaque backgrounds, apply a blur effect.
      result = new ClipRect(
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: result,
        ),
      );
    }

    return result;
  }
}
