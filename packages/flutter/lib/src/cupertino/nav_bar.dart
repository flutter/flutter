// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Standard iOS nav bar height without the status bar.
const double _kNavBarPersistentHeight = 44.0;

/// Size increase from expanding the nav bar into an iOS 11 style large title
/// form in a [CustomScrollView].
const double _kNavBarLargeTitleHeightExtension = 56.0;

/// Number of logical pixels scrolled down before the title text is transferred
/// from the normal nav bar to a big title below the nav bar.
const double _kNavBarShowLargeTitleThreshold = 10.0;

const double _kNavBarEdgePadding = 16.0;

/// Title text transfer fade.
const Duration _kNavBarTitleFadeDuration = const Duration(milliseconds: 150);

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
///
/// Enabling [largeTitle] will create a scrollable second row showing the title
/// in a larger font introduced in iOS 11. The [middle] widget must be a text
/// and the [CupertinoNavigationBar] must be placed in a sliver group in this case.
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
  /// text in a larger font when scrolled down.
  ///
  /// Navigation bars with large titles must be used in a sliver group such
  /// as [CustomScrollView].
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
      return _wrapWithBackground(
        backgroundColor: backgroundColor,
        child: new _CupertinoPersistentNavigationBar(
          leading: leading,
          middle: middle,
          trailing: trailing,
          actionsForegroundColor: actionsForegroundColor,
        ),
      );
    } else {
      return new SliverPersistentHeader(
        pinned: true, // iOS navigation bars are always pinned.
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

/// Returns `child` wrapped with background and a bottom border if background color
/// is opaque. Otherwise, also blur with [BackdropFilter].
Widget _wrapWithBackground({Color backgroundColor, Widget child}) {
  final DecoratedBox childWithBackground = new DecoratedBox(
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
    child: child,
  );

  if (backgroundColor.alpha == 0xFF)
    return childWithBackground;

  return new ClipRect(
    child: new BackdropFilter(
      filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: childWithBackground,
    ),
  );
}

/// The top part of the nav bar that's never scrolled away.
///
/// Consists of the entire nav bar without background and border when used
/// without large titles. With large titles, it's the top static half that
/// doesn't scroll.
class _CupertinoPersistentNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const _CupertinoPersistentNavigationBar({
    Key key,
    this.leading,
    @required this.middle,
    this.trailing,
    this.actionsForegroundColor,
    this.middleVisible,
  }) : super(key: key);

  final Widget leading;

  final Widget middle;

  final Widget trailing;

  final Color actionsForegroundColor;

  /// Whether the middle widget has a visible animated opacity. A null value
  /// means the middle opacity will not be animated.
  final bool middleVisible;

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

    final Widget animatedStyledMiddle = middleVisible == null
      ? styledMiddle
      : new AnimatedOpacity(
        opacity: middleVisible ? 1.0 : 0.0,
        duration: _kNavBarTitleFadeDuration,
        child: styledMiddle,
      );

    // TODO(xster): automatically build a CupertinoBackButton.

    return new SizedBox(
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
            middle: animatedStyledMiddle,
            trailing: styledTrailing,
            centerMiddle: true,
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
    final bool showLargeTitle = shrinkOffset < maxExtent - minExtent - _kNavBarShowLargeTitleThreshold;

    final _CupertinoPersistentNavigationBar persistentNavigationBar =
        new _CupertinoPersistentNavigationBar(
      leading: leading,
      middle: middle,
      trailing: trailing,
      middleVisible: !showLargeTitle,
      actionsForegroundColor: actionsForegroundColor,
    );

    return _wrapWithBackground(
      backgroundColor: backgroundColor,
      child: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new Positioned(
            top: persistentHeight,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: new ClipRect(
              // The large title starts at the persistent bar.
              // It's aligned with the bottom of the sliver and expands clipped
              // and behind the persistent bar.
              child: new OverflowBox(
                minHeight: 0.0,
                maxHeight: double.INFINITY,
                alignment: FractionalOffsetDirectional.bottomStart,
                child: new Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: _kNavBarEdgePadding,
                    bottom: 8.0, // Bottom has a different padding.
                  ),
                  child: new DefaultTextStyle(
                    style: _kLargeTitleTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: new AnimatedOpacity(
                      opacity: showLargeTitle ? 1.0 : 0.0,
                      duration: _kNavBarTitleFadeDuration,
                      child: middle,
                    )
                  ),
                ),
              ),
            ),
          ),
          new Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            child: persistentNavigationBar,
          ),
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
