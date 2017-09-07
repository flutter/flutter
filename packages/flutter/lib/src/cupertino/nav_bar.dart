// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Standard iOS 10 nav bar height without the status bar.
const double _kNavBarPersistentHeight = 44.0;

/// Size increase from expanding the nav bar in a [CustomScrollView].
const double _kNavBarLargeTitleHeightExtension = 30.0;

const double _kNavBarEdgePadding = 16.0;

const Color _kDefaultNavBarBackgroundColor = const Color(0xCCF8F8F8);
const Color _kDefaultNavBarBorderColor = const Color(0x4C000000);

const TextStyle _kLargeTitleTextStyle = const TextStyle(
  fontSize: 34.0,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.41,
  color: CupertinoColors.black,
);

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
    this.largeTitle: false,
  }) : assert(middle != null, 'There must be a middle widget, usually a title.'),
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
  /// The default color for text in the [middle] slot is always black, as per
  /// iOS standard design.
  final Color actionsForegroundColor;

  /// True if the nav bar's background color has no transparency.
  bool get opaque => backgroundColor.alpha == 0xFF;

  /// Use iOS 11 style large title navigation bars.
  ///
  /// When true, the navigation bar will split into 2 sections. The static
  /// top 44px section will be wrapped in a SliverPersistentHeader and a
  /// second scrollable section behind it will show and replace the `middle`
  /// section in a larger font when scrolled down.
  final bool largeTitle;

  @override
  Size get preferredSize => const Size.fromHeight(_kNavBarPersistentHeight);

  @override
  Widget build(BuildContext context) {
    assert(
      !largeTitle || middle is Text,
      "largeTitle mode is only possible when 'middle' is a Text widget",
    );

    if (!largeTitle) {
      return new _CupertinoPersistentNavigationBar(
        leading: leading,
        middle: middle,
        trailing: trailing,
        backgroundColor: backgroundColor,
        actionsForegroundColor: actionsForegroundColor,
      );
    } else {
      return new SliverPersistentHeader(
        pinned: true, // iOS navigation bars are always pinned.
        floating: true,
        delegate: new _CupertinoLargeTitleNavigationBarSliverDelegate(
          persistentHeight: _kNavBarPersistentHeight + MediaQuery.of(context).padding.top,
          leading: leading,
          middle: middle,
          trailing: trailing,
          backgroundColor: backgroundColor,
          actionsForegroundColor: actionsForegroundColor,
        ),
      );
    }
  }
}

/// Returns `child` as is if backgroundColor is opaque. Otherwise, wraps child
/// with blurring [BackdropFilter].
Widget _wrapWithBlurEffectIfNecessary({Color backgroundColor, Widget child}) {
  if (backgroundColor.alpha == 0xFF)
    return child;

  return new ClipRect(
    child: new BackdropFilter(
      filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: child,
    ),
  );
}

/// The top part of the nav bar that's never scrolled away.
class _CupertinoPersistentNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const _CupertinoPersistentNavigationBar({
    Key key,
    this.leading,
    @required this.middle,
    this.trailing,
    this.backgroundColor,
    this.actionsForegroundColor,
  }) : super(key: key);

  final Widget leading;

  final Widget middle;

  final Widget trailing;

  final Color backgroundColor;

  final Color actionsForegroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(_kNavBarPersistentHeight);

  @override
  Widget build(BuildContext context) {
    final TextStyle actionsStyle = new TextStyle(
      fontSize: 17.0,
      letterSpacing: -0.24,
      color: actionsForegroundColor,
    );

    final Widget styledLeading = leading == null ? null : DefaultTextStyle.merge(
      style: actionsStyle,
      child: leading,
    );

    final Widget styledTrailing = trailing == null ? null : DefaultTextStyle.merge(
      style: actionsStyle,
      child: trailing,
    );

    // Let the middle be black rather than `actionsForegroundColor` in case
    // it's a plain text title.
    final Widget styledMiddle = middle == null ? null : DefaultTextStyle.merge(
      style: actionsStyle.copyWith(color: CupertinoColors.black),
      child: middle,
    );

    // TODO(xster): automatically build a CupertinoBackButton.

    return _wrapWithBlurEffectIfNecessary(
      backgroundColor: backgroundColor,
      child:  new DecoratedBox(
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
          height: _kNavBarPersistentHeight + MediaQuery.of(context).padding.top,
          child: IconTheme.merge(
            data: new IconThemeData(
              color: actionsForegroundColor,
              size: 22.0,
            ),
            child: new Padding(
              padding: new EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                // TODO(xster): dynamically reduce padding when an automatic
                // CupertinoBackButton is present.
                left: _kNavBarEdgePadding,
                right: _kNavBarEdgePadding,
              ),
              child: new NavigationToolbar(
                leading: styledLeading,
                middle: styledMiddle,
                trailing: styledTrailing,
                centerMiddle: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CupertinoLargeTitleNavigationBarSliverDelegate extends SliverPersistentHeaderDelegate {
  const _CupertinoLargeTitleNavigationBarSliverDelegate({
    @required this.persistentHeight,
    this.leading,
    @required this.middle,
    this.trailing,
    this.backgroundColor,
    this.actionsForegroundColor,
  }) : assert(persistentHeight != null);

  final double persistentHeight;

  final Widget leading;

  final Text middle;

  final Widget trailing;

  final Color backgroundColor;

  final Color actionsForegroundColor;

  @override
  double get minExtent => persistentHeight;

  @override
  double get maxExtent => persistentHeight + _kNavBarLargeTitleHeightExtension;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool showLargeTitle = shrinkOffset < maxExtent - minExtent;

    final _CupertinoPersistentNavigationBar persistentNavigationBar =
        new _CupertinoPersistentNavigationBar(
      leading: leading,
      middle: showLargeTitle ? null : middle,
      trailing: trailing,
      backgroundColor: backgroundColor,
      actionsForegroundColor: actionsForegroundColor,
    );

    return _wrapWithBlurEffectIfNecessary(
      backgroundColor: backgroundColor,
      child: new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          new PositionedDirectional(
            start: _kNavBarEdgePadding,
            bottom: _kNavBarEdgePadding,
            child: new DefaultTextStyle(
              style: _kLargeTitleTextStyle,
              child: middle,
            ),
          ),
          persistentNavigationBar,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CupertinoLargeTitleNavigationBarSliverDelegate oldDelegate) {
    return persistentHeight != oldDelegate.persistentHeight ||
        leading != oldDelegate.leading ||
        middle != oldDelegate.middle ||
        trailing != oldDelegate.trailing ||
        backgroundColor != oldDelegate.backgroundColor ||
        actionsForegroundColor != oldDelegate.actionsForegroundColor;
  }
}
