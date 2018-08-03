// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library nav_bar;

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'icons.dart';
import 'page_scaffold.dart';
import 'route.dart';

part 'nav_bar/nav_bar_private_static.dart';
part 'nav_bar/nav_bar_private_transition.dart';

/// An iOS-styled navigation bar.
///
/// The navigation bar is a toolbar that minimally consists of a widget, normally
/// a page title, in the [middle] of the toolbar.
///
/// It also supports a [leading] and [trailing] widget before and after the
/// [middle] widget while keeping the [middle] widget centered.
///
/// The [leading] widget will automatically be a back chevron icon button (or a
/// close button in case of a fullscreen dialog) to pop the current route if none
/// is provided and [automaticallyImplyLeading] is true (true by default).
///
/// The [middle] widget will automatically be a title text from the current
/// route if none is provided and [automaticallyImplyMiddle] is true (true by
/// default).
///
/// It should be placed at top of the screen and automatically accounts for
/// the OS's status bar.
///
/// If the given [backgroundColor]'s opacity is not 1.0 (which is the case by
/// default), it will produce a blurring effect to the content behind it.
///
/// See also:
///
///  * [CupertinoPageScaffold], a page layout helper typically hosting the
///    [CupertinoNavigationBar].
///  * [CupertinoSliverNavigationBar] for a navigation bar to be placed in a
///    scrolling list and that supports iOS-11-style large titles.
class CupertinoNavigationBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  /// Creates a navigation bar in the iOS style.
  const CupertinoNavigationBar({
    Key key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyMiddle = true,
    this.previousPageTitle,
    this.middle,
    this.trailing,
    this.border = _kDefaultNavBarBorder,
    this.backgroundColor = _kDefaultNavBarBackgroundColor,
    this.padding,
    this.actionsForegroundColor = CupertinoColors.activeBlue,
  }) : assert(automaticallyImplyLeading != null),
       assert(automaticallyImplyMiddle != null),
       super(key: key);

  /// {@template flutter.cupertino.navBar.leading}
  /// Widget to place at the start of the navigation bar. Normally a back button
  /// for a normal page or a cancel button for full page dialogs.
  ///
  /// If null and [automaticallyImplyLeading] is true, an appropriate button
  /// will be automatically created.
  /// {@endtemplate}
  final Widget leading;

  /// {@template flutter.cupertino.navBar.automaticallyImplyLeading}
  /// Controls whether we should try to imply the leading widget if null.
  ///
  /// If true and [leading] is null, automatically try to deduce what the [leading]
  /// widget should be. If [leading] widget is not null, this parameter has no effect.
  ///
  /// Specifically this navigation bar will:
  ///
  /// 1. Show a 'Close' button if the current route is a `fullscreenDialog`.
  /// 2. Show a back chevron with [previousPageTitle] if [previousPageTitle] is
  ///    not null.
  /// 3. Show a back chevron with the previous route's `title` if the current
  ///    route is a [CupertinoPageRoute] and the previous route is also a
  ///    [CupertinoPageRoute].
  ///
  /// This value cannot be null.
  /// {@endtemplate}
  final bool automaticallyImplyLeading;

  /// Controls whether we should try to imply the middle widget if null.
  ///
  /// If true and [middle] is null, automatically fill in a [Text] widget with
  /// the current route's `title` if the route is a [CupertinoPageRoute].
  /// If [middle] widget is not null, this parameter has no effect.
  ///
  /// This value cannot be null.
  final bool automaticallyImplyMiddle;

  /// {@template flutter.cupertino.navBar.previousPageTitle}
  /// Manually specify the previous route's title when automatically implying
  /// the leading back button.
  ///
  /// Overrides the text shown with the back chevron instead of automatically
  /// showing the previous [CupertinoPageRoute]'s `title` when
  /// [automaticallyImplyLeading] is true.
  ///
  /// Has no effect when [leading] is not null or if [automaticallyImplyLeading]
  /// is false.
  /// {@endtemplate}
  final String previousPageTitle;

  /// Widget to place in the middle of the navigation bar. Normally a title or
  /// a segmented control.
  ///
  /// If null and [automaticallyImplyMiddle] is true, an appropriate [Text]
  /// title will be created if the current route is a [CupertinoPageRoute] and
  /// has a `title`.
  final Widget middle;

  /// {@template flutter.cupertino.navBar.trailing}
  /// Widget to place at the end of the navigation bar. Normally additional actions
  /// taken on the page such as a search or edit function.
  /// {@endtemplate}
  final Widget trailing;

  // TODO(xster): implement support for double row navigation bars.

  /// {@template flutter.cupertino.navBar.backgroundColor}
  /// The background color of the navigation bar. If it contains transparency, the
  /// tab bar will automatically produce a blurring effect to the content
  /// behind it.
  /// {@endtemplate}
  final Color backgroundColor;

  /// {@template flutter.cupertino.navBar.padding}
  /// Padding for the contents of the navigation bar.
  ///
  /// If null, the navigation bar will adopt the following defaults:
  ///
  ///  * Vertically, contents will be sized to the same height as the navigation
  ///    bar itself minus the status bar.
  ///  * Horizontally, padding will be 16 pixels according to iOS specifications
  ///    unless the leading widget is an automatically inserted back button, in
  ///    which case the padding will be 0.
  ///
  /// Vertical padding won't change the height of the nav bar.
  /// {@endtemplate}
  final EdgeInsetsDirectional padding;

  /// {@template flutter.cupertino.navBar.border}
  /// The border of the navigation bar. By default renders a single pixel bottom border side.
  ///
  /// If a border is null, the navigation bar will not display a border.
  /// {@endtemplate}
  final Border border;

  /// Default color used for text and icons of the [leading] and [trailing]
  /// widgets in the navigation bar.
  ///
  /// The default color for text in the [middle] slot is always black, as per
  /// iOS standard design.
  final Color actionsForegroundColor;

  /// True if the navigation bar's background color has no transparency.
  @override
  bool get fullObstruction => backgroundColor.alpha == 0xFF;

  @override
  Size get preferredSize {
    return const Size.fromHeight(_kNavBarPersistentHeight);
  }

  _CupertinoNavigationBarComponents _components(ModalRoute<dynamic> route) {
    return new _CupertinoNavigationBarComponents(
      route: route,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      automaticallyImplyTitle: automaticallyImplyMiddle,
      previousPageTitle: previousPageTitle,
      middle: middle,
      trailing: trailing,
      padding: padding,
      actionsForegroundColor: actionsForegroundColor,
      large: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _wrapWithBackground(
      border: border,
      backgroundColor: backgroundColor,
      child: new _CupertinoPersistentNavigationBar(
        components: _components(ModalRoute.of(context)),
        padding: padding,
      ),
    );
  }
}

/// An iOS-styled navigation bar with iOS-11-style large titles using slivers.
///
/// The [CupertinoSliverNavigationBar] must be placed in a sliver group such
/// as the [CustomScrollView].
///
/// This navigation bar consists of two sections, a pinned static section on top
/// and a sliding section containing iOS-11-style large title below it.
///
/// It should be placed at top of the screen and automatically accounts for
/// the iOS status bar.
///
/// Minimally, a [largeTitle] widget will appear in the middle of the app bar
/// when the sliver is collapsed and transfer to the area below in larger font
/// when the sliver is expanded.
///
/// For advanced uses, an optional [middle] widget can be supplied to show a
/// different widget in the middle of the navigation bar when the sliver is collapsed.
///
/// Like [CupertinoNavigationBar], it also supports a [leading] and [trailing]
/// widget on the static section on top that remains while scrolling.
///
/// The [leading] widget will automatically be a back chevron icon button (or a
/// close button in case of a fullscreen dialog) to pop the current route if none
/// is provided and [automaticallyImplyLeading] is true (true by default).
///
/// The [largeTitle] widget will automatically be a title text from the current
/// route if none is provided and [automaticallyImplyTitle] is true (true by
/// default).
///
/// See also:
///
///  * [CupertinoNavigationBar], an iOS navigation bar for use on non-scrolling
///    pages.
class CupertinoSliverNavigationBar extends StatelessWidget {
  /// Creates a navigation bar for scrolling lists.
  ///
  /// The [largeTitle] argument is required and must not be null.
  const CupertinoSliverNavigationBar({
    Key key,
    this.largeTitle,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyTitle = true,
    this.previousPageTitle,
    this.middle,
    this.trailing,
    this.border = _kDefaultNavBarBorder,
    this.backgroundColor = _kDefaultNavBarBackgroundColor,
    this.padding,
    this.actionsForegroundColor = CupertinoColors.activeBlue,
  }) : assert(automaticallyImplyLeading != null),
       assert(automaticallyImplyTitle != null),
       super(key: key);

  /// The navigation bar's title.
  ///
  /// This text will appear in the top static navigation bar when collapsed and
  /// below the navigation bar, in a larger font, when expanded.
  ///
  /// A suitable [DefaultTextStyle] is provided around this widget as it is
  /// moved around, to change its font size.
  ///
  /// If [middle] is null, then the [largeTitle] widget will be inserted into
  /// the tree in two places when transitioning from the collapsed state to the
  /// expanded state. It is therefore imperative that this subtree not contain
  /// any [GlobalKey]s, and that it not rely on maintaining state (for example,
  /// animations will not survive the transition from one location to the other,
  /// and may in fact be visible in two places at once during the transition).
  ///
  /// If null and [automaticallyImplyTitle] is true, an appropriate [Text]
  /// title will be created if the current route is a [CupertinoPageRoute] and
  /// has a `title`.
  final Widget largeTitle;

  /// {@macro flutter.cupertino.navBar.leading}
  ///
  /// This widget is visible in both collapsed and expanded states.
  final Widget leading;

  /// {@macro flutter.cupertino.navBar.automaticallyImplyLeading}
  final bool automaticallyImplyLeading;

  /// Controls whether we should try to imply the [largeTitle] widget if null.
  ///
  /// If true and [largeTitle] is null, automatically fill in a [Text] widget
  /// with the current route's `title` if the route is a [CupertinoPageRoute].
  /// If [largeTitle] widget is not null, this parameter has no effect.
  ///
  /// This value cannot be null.
  final bool automaticallyImplyTitle;

  /// {@macro flutter.cupertino.navBar.previousPageTitle}
  final String previousPageTitle;

  /// A widget to place in the middle of the static navigation bar instead of
  /// the [largeTitle].
  ///
  /// This widget is visible in both collapsed and expanded states. The text
  /// supplied in [largeTitle] will no longer appear in collapsed state if a
  /// [middle] widget is provided.
  final Widget middle;

  /// {@macro flutter.cupertino.navBar.trailing}
  ///
  /// This widget is visible in both collapsed and expanded states.
  final Widget trailing;

  /// {@macro flutter.cupertino.navBar.backgroundColor}
  final Color backgroundColor;

  /// {@macro flutter.cupertino.navBar.padding}
  final EdgeInsetsDirectional padding;

  /// {@macro flutter.cupertino.navBar.border}
  final Border border;

  /// Default color used for text and icons of the [leading] and [trailing]
  /// widgets in the navigation bar.
  ///
  /// The default color for text in the [largeTitle] slot is always black, as per
  /// iOS standard design.
  final Color actionsForegroundColor;

  /// True if the navigation bar's background color has no transparency.
  bool get opaque => backgroundColor.alpha == 0xFF;

  _CupertinoNavigationBarComponents _components(ModalRoute<dynamic> route) {
    return new _CupertinoNavigationBarComponents(
      route: route,
      largeTitle: largeTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      automaticallyImplyTitle: automaticallyImplyTitle,
      previousPageTitle: previousPageTitle,
      middle: middle,
      trailing: trailing,
      padding: padding,
      actionsForegroundColor: actionsForegroundColor,
      large: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new SliverPersistentHeader(
      pinned: true, // iOS navigation bars are always pinned.
      delegate: new _CupertinoLargeTitleNavigationBarSliverDelegate(
        components: _components(ModalRoute.of(context)),
        persistentHeight: _kNavBarPersistentHeight + MediaQuery.of(context).padding.top,
        padding: padding,
        border: border,
        backgroundColor: backgroundColor,
        alwaysShowMiddle: middle != null,
      ),
    );
  }
}

/// A nav bar back button typically used in [CupertinoNavigationBar].
///
/// This is automatically inserted into [CupertinoNavigationBar] and
/// [CupertinoSliverNavigationBar]'s `leading` slot when
/// `automaticallyImplyLeading` is true.
///
/// Shows a back chevron and the previous route's title when available from
/// the previous [CupertinoPageRoute.title]. If [previousPageTitle] is specified,
/// it will be shown instead.
class CupertinoNavigationBarBackButton extends StatelessWidget {
  /// Construct a [CupertinoNavigationBarBackButton] that can be used to pop
  /// the current route.
  ///
  /// The [color] parameter must not be null.
  const CupertinoNavigationBarBackButton({
    @required this.color,
    this.previousPageTitle,
  }) : _backChevron = null,
       _backLabel = null,
       assert(color != null);

  const CupertinoNavigationBarBackButton._assemble(
    this._backChevron,
    this._backLabel,
  ) : color = null,
      previousPageTitle = null;

  /// The [Color] of the back chevron.
  ///
  /// Must not be null.
  final Color color;

  /// An override for showing the previous route's title. If null, it will be
  /// automatically derived from [CupertinoPageRoute.title] if the current and
  /// previous routes are both [CupertinoPageRoute]s.
  final String previousPageTitle;

  final _BackChevron _backChevron;

  final _BackLabel _backLabel;

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic> currentRoute = ModalRoute.of(context);
    assert(
      currentRoute.canPop,
      'CupertinoNavigationBarBackButton should only be used in routes that can be popped',
    );

    return new CupertinoButton(
      child: new Semantics(
        container: true,
        excludeSemantics: true,
        label: 'Back',
        button: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _kNavBarBackButtonTapWidth),
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Padding(padding: EdgeInsetsDirectional.only(start: 8.0)),
              _backChevron ?? new _BackChevron(color: color),
              const Padding(padding: EdgeInsetsDirectional.only(start: 6.0)),
              new Flexible(
                child: _backLabel ?? new _BackLabel(
                  specifiedPreviousTitle: previousPageTitle,
                  route: currentRoute,
                ),
              ),
            ],
          ),
        ),
      ),
      padding: EdgeInsets.zero,
      onPressed: () { Navigator.maybePop(context); },
    );
  }
}