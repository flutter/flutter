// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'icons.dart';
import 'page_scaffold.dart';
import 'route.dart';

/// Standard iOS navigation bar height without the status bar.
///
/// This height is constant and independent of accessibility as it is in iOS.
const double _kNavBarPersistentHeight = 44.0;

/// Size increase from expanding the navigation bar into an iOS-11-style large title
/// form in a [CustomScrollView].
const double _kNavBarLargeTitleHeightExtension = 52.0;

/// Number of logical pixels scrolled down before the title text is transferred
/// from the normal navigation bar to a big title below the navigation bar.
const double _kNavBarShowLargeTitleThreshold = 10.0;

const double _kNavBarEdgePadding = 16.0;

const double _kNavBarBackButtonTapWidth = 50.0;

/// Title text transfer fade.
const Duration _kNavBarTitleFadeDuration = Duration(milliseconds: 150);

const Color _kDefaultNavBarBackgroundColor = Color(0xCCF8F8F8);
const Color _kDefaultNavBarBorderColor = Color(0x4C000000);

const Border _kDefaultNavBarBorder = Border(
  bottom: BorderSide(
    color: _kDefaultNavBarBorderColor,
    width: 0.0, // One physical pixel.
    style: BorderStyle.solid,
  ),
);

const TextStyle _kMiddleTitleTextStyle = TextStyle(
  fontFamily: '.SF UI Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.08,
  color: CupertinoColors.black,
);

const TextStyle _kLargeTitleTextStyle = TextStyle(
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.24,
  color: CupertinoColors.black,
);

// There's a single tag for all instances of navigation bars because they can
// all transition between each other (per Navigator) via Hero transitions.
const Object _heroTag = Object();

TextStyle _navBarItemStyle(Color color) {
  return new TextStyle(
    fontFamily: '.SF UI Text',
    fontSize: 17.0,
    letterSpacing: -0.24,
    color: color,
  );
}

/// Returns `child` wrapped with background and a bottom border if background color
/// is opaque. Otherwise, also blur with [BackdropFilter].
Widget _wrapWithBackground({
  Border border,
  Color backgroundColor,
  Widget child,
  bool annotate = true,
}) {
  Widget result = child;
  if (annotate) {
    final bool darkBackground = backgroundColor.computeLuminance() < 0.179;
    final SystemUiOverlayStyle overlayStyle = darkBackground
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    result = new AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      sized: true,
      child: result,
    );
  }
  final DecoratedBox childWithBackground = new DecoratedBox(
    decoration: new BoxDecoration(
      border: border,
      color: backgroundColor,
    ),
    child: result,
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

bool _isTransitionable(BuildContext context) {
  final ModalRoute<dynamic> route = ModalRoute.of(context);

  return route is PageRoute && !route.fullscreenDialog;
}

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
/// When [transitionBetweenRoutes] is true, this navigation bar will transition
/// on top of the routes instead of inside it if the route being transitioned
/// to also has a [CupertinoNavigationBar] or a [CupertinoSliverNavigationBar]
/// with [transitionBetweenRoutes] set to true. If [transitionBetweenRoutes] is
/// true, none of the [Widget] parameters can contain a key in its subtree since
/// that widget will exist in multiple places in the tree simultaneously.
///
/// See also:
///
///  * [CupertinoPageScaffold], a page layout helper typically hosting the
///    [CupertinoNavigationBar].
///  * [CupertinoSliverNavigationBar] for a navigation bar to be placed in a
///    scrolling list and that supports iOS-11-style large titles.
class CupertinoNavigationBar extends StatefulWidget implements ObstructingPreferredSizeWidget {
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
    this.transitionBetweenRoutes = true,
  }) : assert(automaticallyImplyLeading != null),
       assert(automaticallyImplyMiddle != null),
       assert(transitionBetweenRoutes != null),
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

  /// {@template flutter.cupertino.navBar.transitionBetweenRoutes}
  /// Whether to transition between navigation bars.
  ///
  /// When [transitionBetweenRoutes] is true, this navigation bar will transition
  /// on top of the routes instead of inside it if the route being transitioned
  /// to also has a [CupertinoNavigationBar] or a [CupertinoSliverNavigationBar]
  /// with [transitionBetweenRoutes] set to true.
  ///
  /// When set to true, only one navigation bar can be present per route.
  ///
  /// This value defaults to true and cannot be null.
  /// {@endtemplate}
  final bool transitionBetweenRoutes;

  /// True if the navigation bar's background color has no transparency.
  @override
  bool get fullObstruction => backgroundColor.alpha == 0xFF;

  @override
  Size get preferredSize {
    return const Size.fromHeight(_kNavBarPersistentHeight);
  }

  @override
  _CupertinoNavigationBarState createState() {
    return new _CupertinoNavigationBarState();
  }
}

class _CupertinoNavigationBarState extends State<CupertinoNavigationBar> {
  _NavigationBarStaticComponentsKeys keys;

  @override
  void initState() {
    super.initState();
    keys = new _NavigationBarStaticComponentsKeys();
  }

  @override
  Widget build(BuildContext context) {
    final _NavigationBarStaticComponents components = new _NavigationBarStaticComponents(
      keys: keys,
      route: ModalRoute.of(context),
      userLeading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      automaticallyImplyTitle: widget.automaticallyImplyMiddle,
      previousPageTitle: widget.previousPageTitle,
      userMiddle: widget.middle,
      userTrailing: widget.trailing,
      padding: widget.padding,
      actionsForegroundColor: widget.actionsForegroundColor,
      userLargeTitle: null,
      large: false,
    );

    final Widget navBar = _wrapWithBackground(
      border: widget.border,
      backgroundColor: widget.backgroundColor,
      child: new _PersistentNavigationBar(
        components: components,
        padding: widget.padding,
      ),
    );

    if (!widget.transitionBetweenRoutes || !_isTransitionable(context)) {
      return navBar;
    }

    return new Hero(
      tag: _heroTag,
      createRectTween: _linearTranslateWithLargestRectSizeTween,
      launchPadBuilder: _navBarHeroLaunchPadBuilder,
      flightShuttleBuilder: _navBarHeroFlightShuttleBuilder,
      child: new _TransitionableNavigationBar(
        componentsKeys: keys,
        backgroundColor: widget.backgroundColor,
        actionsForegroundColor: widget.actionsForegroundColor,
        border: widget.border,
        hasUserMiddle: widget.middle != null,
        largeExpanded: false,
        child: navBar,
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
/// When [transitionBetweenRoutes] is true, this navigation bar will transition
/// on top of the routes instead of inside it if the route being transitioned
/// to also has a [CupertinoNavigationBar] or a [CupertinoSliverNavigationBar]
/// with [transitionBetweenRoutes] set to true. If [transitionBetweenRoutes] is
/// true, none of the [Widget] parameters can contain a key in its subtree since
/// that widget will exist in multiple places in the tree simultaneously.
///
/// See also:
///
///  * [CupertinoNavigationBar], an iOS navigation bar for use on non-scrolling
///    pages.
class CupertinoSliverNavigationBar extends StatefulWidget {
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
    this.transitionBetweenRoutes = true,
  }) : assert(automaticallyImplyLeading != null),
       assert(automaticallyImplyTitle != null),
       assert(
         automaticallyImplyTitle == true || largeTitle != null,
         'A largeTitle must be provided. Otherwise, automaticallyImplyTitle '
         'must be true.'
       ),
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
  ///
  /// This parameter must either be non-null or [automaticallyImplyTitle] must
  /// be true and the route has a title.
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

  /// {@macro flutter.cupertino.navBar.transitionBetweenRoutes}
  final bool transitionBetweenRoutes;

  /// True if the navigation bar's background color has no transparency.
  bool get opaque => backgroundColor.alpha == 0xFF;

  @override
  _CupertinoSliverNavigationBarState createState() {
    return new _CupertinoSliverNavigationBarState();
  }
}

class _CupertinoSliverNavigationBarState extends State<CupertinoSliverNavigationBar> {
  _NavigationBarStaticComponentsKeys keys;

  @override
  void initState() {
    super.initState();
    keys = new _NavigationBarStaticComponentsKeys();
  }

  @override
  Widget build(BuildContext context) {
    return new SliverPersistentHeader(
      pinned: true, // iOS navigation bars are always pinned.
      delegate: new _LargeTitleNavigationBarSliverDelegate(
        keys: keys,
        userLeading: widget.leading,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        automaticallyImplyTitle: widget.automaticallyImplyTitle,
        previousPageTitle: widget.previousPageTitle,
        userMiddle: widget.middle,
        userTrailing: widget.trailing,
        userLargeTitle: widget.largeTitle,
        backgroundColor: widget.backgroundColor,
        border: widget.border,
        padding: widget.padding,
        actionsForegroundColor: widget.actionsForegroundColor,
        transitionBetweenRoutes: widget.transitionBetweenRoutes,
        persistentHeight: _kNavBarPersistentHeight + MediaQuery.of(context).padding.top,
        alwaysShowMiddle: widget.middle != null,
      ),
    );
  }
}

class _LargeTitleNavigationBarSliverDelegate
    extends SliverPersistentHeaderDelegate with DiagnosticableTreeMixin {
  _LargeTitleNavigationBarSliverDelegate({
    @required this.keys,
    @required this.userLeading,
    @required this.automaticallyImplyLeading,
    @required this.automaticallyImplyTitle,
    @required this.previousPageTitle,
    @required this.userMiddle,
    @required this.userTrailing,
    @required this.userLargeTitle,
    @required this.backgroundColor,
    @required this.border,
    @required this.padding,
    @required this.actionsForegroundColor,
    @required this.transitionBetweenRoutes,
    @required this.persistentHeight,
    @required this.alwaysShowMiddle,
  }) : assert(persistentHeight != null),
       assert(alwaysShowMiddle != null),
       assert(transitionBetweenRoutes != null);

  final _NavigationBarStaticComponentsKeys keys;
  final Widget userLeading;
  final bool automaticallyImplyLeading;
  final bool automaticallyImplyTitle;
  final String previousPageTitle;
  final Widget userMiddle;
  final Widget userTrailing;
  final Widget userLargeTitle;
  final Color backgroundColor;
  final Border border;
  final EdgeInsetsDirectional padding;
  final Color actionsForegroundColor;
  final bool transitionBetweenRoutes;
  final double persistentHeight;
  final bool alwaysShowMiddle;

  @override
  double get minExtent => persistentHeight;

  @override
  double get maxExtent => persistentHeight + _kNavBarLargeTitleHeightExtension;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool showLargeTitle = shrinkOffset < maxExtent - minExtent - _kNavBarShowLargeTitleThreshold;

    final _NavigationBarStaticComponents components = new _NavigationBarStaticComponents(
      keys: keys,
      route: ModalRoute.of(context),
      userLeading: userLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      automaticallyImplyTitle: automaticallyImplyTitle,
      previousPageTitle: previousPageTitle,
      userMiddle: userMiddle,
      userTrailing: userTrailing,
      userLargeTitle: userLargeTitle,
      padding: padding,
      actionsForegroundColor: actionsForegroundColor,
      large: true,
    );

    final _PersistentNavigationBar persistentNavigationBar =
        new _PersistentNavigationBar(
      components: components,
      padding: padding,
      // If a user specified middle exists, always show it. Otherwise, show
      // title when sliver is collapsed.
      middleVisible: alwaysShowMiddle ? null : !showLargeTitle,
    );

    final Widget navBar = _wrapWithBackground(
      border: border,
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
                maxHeight: double.infinity,
                alignment: AlignmentDirectional.bottomStart,
                child: new Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: _kNavBarEdgePadding,
                    bottom: 8.0, // Bottom has a different padding.
                  ),
                  child: new SafeArea(
                    top: false,
                    bottom: false,
                    child: new AnimatedOpacity(
                      opacity: showLargeTitle ? 1.0 : 0.0,
                      duration: _kNavBarTitleFadeDuration,
                      child: new Semantics(
                        header: true,
                        child: new DefaultTextStyle(
                          style: _kLargeTitleTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: components.largeTitle,
                        ),
                      ),
                    ),
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

    if (!transitionBetweenRoutes || !_isTransitionable(context)) {
      return navBar;
    }

    return new Hero(
      tag: _heroTag,
      createRectTween: _linearTranslateWithLargestRectSizeTween,
      flightShuttleBuilder: _navBarHeroFlightShuttleBuilder,
      launchPadBuilder: _navBarHeroLaunchPadBuilder,
      // This is all the way down here instead of being at the top level of
      // CupertinoSliverNavigationBar like CupertinoNavigationBar because it
      // needs to wrap the top level RenderBox rather than a RenderSliver.
      child: new _TransitionableNavigationBar(
        componentsKeys: keys,
        backgroundColor: backgroundColor,
        actionsForegroundColor: actionsForegroundColor,
        border: border,
        hasUserMiddle: userMiddle != null,
        largeExpanded: showLargeTitle,
        child: navBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleNavigationBarSliverDelegate oldDelegate) {
    return userLeading != oldDelegate.userLeading
        || automaticallyImplyLeading != oldDelegate.automaticallyImplyLeading
        || automaticallyImplyTitle != oldDelegate.automaticallyImplyTitle
        || previousPageTitle != oldDelegate.previousPageTitle
        || userMiddle != oldDelegate.userMiddle
        || userTrailing != oldDelegate.userTrailing
        || userLargeTitle != oldDelegate.userLargeTitle
        || backgroundColor != oldDelegate.backgroundColor
        || border != oldDelegate.border
        || padding != oldDelegate.padding
        || actionsForegroundColor != oldDelegate.actionsForegroundColor
        || transitionBetweenRoutes != oldDelegate.transitionBetweenRoutes
        || persistentHeight != oldDelegate.persistentHeight
        || alwaysShowMiddle != oldDelegate.alwaysShowMiddle;
  }
}

/// The top part of the navigation bar that's never scrolled away.
///
/// Consists of the entire navigation bar without background and border when used
/// without large titles. With large titles, it's the top static half that
/// doesn't scroll.
class _PersistentNavigationBar extends StatelessWidget {
  const _PersistentNavigationBar({
    Key key,
    this.components,
    this.padding,
    this.middleVisible,
  }) : super(key: key);

  final _NavigationBarStaticComponents components;

  final EdgeInsetsDirectional padding;
  /// Whether the middle widget has a visible animated opacity. A null value
  /// means the middle opacity will not be animated.
  final bool middleVisible;

  @override
  Widget build(BuildContext context) {
    Widget middle = components.middle;

    if (middle != null) {
      middle = new DefaultTextStyle(
        style: _kMiddleTitleTextStyle,
        child: new Semantics(header: true, child: middle),
      );
      middle = middleVisible == null
        ? middle
        : new AnimatedOpacity(
          opacity: middleVisible ? 1.0 : 0.0,
          duration: _kNavBarTitleFadeDuration,
          child: middle,
        );
    }

    Widget leading = components.leading;
    final Widget backChevron = components.backChevron;
    final Widget backLabel = components.backLabel;

    if (leading == null && backChevron != null && backLabel != null) {
      leading = new CupertinoNavigationBarBackButton._assemble(
        backChevron,
        backLabel,
        components.actionsForegroundColor,
      );
    }

    Widget paddedToolbar = new NavigationToolbar(
      leading: leading,
      middle: middle,
      trailing: components.trailing,
      centerMiddle: true,
      middleSpacing: 6.0,
    );

    if (padding != null) {
      paddedToolbar = new Padding(
        padding: EdgeInsets.only(
          top: padding.top,
          bottom: padding.bottom,
        ),
        child: paddedToolbar,
      );
    }

    return new SizedBox(
      height: _kNavBarPersistentHeight + MediaQuery.of(context).padding.top,
      child: new SafeArea(
        bottom: false,
        child: paddedToolbar,
      ),
    );
  }
}

// A collection of keys always used when building static routes' nav bars's
// components with _NavigationBarStaticComponents and read in
// _NavigationBarTransition in Hero flights in order to reference the components'
// RenderBoxes.
@immutable
class _NavigationBarStaticComponentsKeys {
  _NavigationBarStaticComponentsKeys()
      : navBarBoxKey = new GlobalKey(),
        leadingKey = new GlobalKey(),
        backChevronKey = new GlobalKey(),
        backLabelKey = new GlobalKey(),
        middleKey = new GlobalKey(),
        trailingKey = new GlobalKey(),
        largeTitleKey = new GlobalKey();

  final GlobalKey navBarBoxKey;
  final GlobalKey leadingKey;
  final GlobalKey backChevronKey;
  final GlobalKey backLabelKey;
  final GlobalKey middleKey;
  final GlobalKey trailingKey;
  final GlobalKey largeTitleKey;
}

// Based on various user Widgets and other parameters, construct KeyedSubtree
// components that are used in common by the CupertinoNavigationBar and
// CupertinoSliverNavigationBar. The KeyedSubtrees are inserted into static
// routes and the KeyedSubtrees' child are reused in the Hero transitions.
@immutable
class _NavigationBarStaticComponents {
  _NavigationBarStaticComponents({
    @required _NavigationBarStaticComponentsKeys keys,
    @required ModalRoute<dynamic> route,
    @required Widget userLeading,
    @required bool automaticallyImplyLeading,
    @required bool automaticallyImplyTitle,
    @required String previousPageTitle,
    @required Widget userMiddle,
    @required Widget userTrailing,
    @required Widget userLargeTitle,
    @required EdgeInsetsDirectional padding,
    @required this.actionsForegroundColor,
    @required bool large,
  }) : leading = createLeading(
         leadingKey: keys.leadingKey,
         userLeading: userLeading,
         route: route,
         automaticallyImplyLeading: automaticallyImplyLeading,
         padding: padding,
         actionsForegroundColor: actionsForegroundColor,
       ),
       backChevron = createBackChevron(
         backChevronKey: keys.backChevronKey,
         userLeading: userLeading,
         route: route,
         automaticallyImplyLeading: automaticallyImplyLeading,
       ),
       backLabel = createBackLabel(
         backLabelKey: keys.backLabelKey,
         userLeading: userLeading,
         route: route,
         previousPageTitle: previousPageTitle,
         automaticallyImplyLeading: automaticallyImplyLeading,
       ),
       middle = createMiddle(
         middleKey: keys.middleKey,
         userMiddle: userMiddle,
         userLargeTitle: userLargeTitle,
         route: route,
         automaticallyImplyTitle: automaticallyImplyTitle,
         large: large,
       ),
       trailing = createTrailing(
         trailingKey: keys.trailingKey,
         userTrailing: userTrailing,
         padding: padding,
         actionsForegroundColor: actionsForegroundColor,
       ),
       largeTitle = createLargeTitle(
         largeTitleKey: keys.largeTitleKey,
         userLargeTitle: userLargeTitle,
         route: route,
         automaticImplyTitle: automaticallyImplyTitle,
         large: large,
       );

  static Widget _derivedTitle({
    bool automaticallyImplyTitle,
    ModalRoute<dynamic> currentRoute,
  }) {
    // Auto use the CupertinoPageRoute's title if middle not provided.
    if (automaticallyImplyTitle &&
        currentRoute is CupertinoPageRoute &&
        currentRoute.title != null) {
      return new Text(currentRoute.title);
    }

    return null;
  }

  final Color actionsForegroundColor;

  final KeyedSubtree leading;
  static KeyedSubtree createLeading({
    @required GlobalKey leadingKey,
    @required Widget userLeading,
    @required ModalRoute<dynamic> route,
    @required bool automaticallyImplyLeading,
    @required EdgeInsetsDirectional padding,
    @required Color actionsForegroundColor
  }) {
    Widget leadingContent;

    if (userLeading != null) {
      leadingContent = userLeading;
    } else if (
      automaticallyImplyLeading &&
      route.canPop &&
      route is PageRoute &&
      route.fullscreenDialog
    ) {
      leadingContent = new CupertinoButton(
        child: const Text('Close'),
        padding: EdgeInsets.zero,
        onPressed: () { route.navigator.maybePop(); },
      );
    }

    if (leadingContent == null) {
      return null;
    }

    return new KeyedSubtree(
      key: leadingKey,
      child: new Padding(
        padding: new EdgeInsetsDirectional.only(
          start: padding?.start ?? _kNavBarEdgePadding,
        ),
        child: new DefaultTextStyle(
          style: _navBarItemStyle(actionsForegroundColor),
          child: IconTheme.merge(
            data: new IconThemeData(
              color: actionsForegroundColor,
              size: 32.0,
            ),
            child: leadingContent,
          ),
        ),
      ),
    );
  }

  final KeyedSubtree backChevron;
  static KeyedSubtree createBackChevron({
    @required GlobalKey backChevronKey,
    @required Widget userLeading,
    @required ModalRoute<dynamic> route,
    @required bool automaticallyImplyLeading,
  }) {
    if (
      userLeading != null ||
      !automaticallyImplyLeading ||
      !route.canPop ||
      (route is PageRoute && route.fullscreenDialog)
    ) {
      return null;
    }

    return new KeyedSubtree(key: backChevronKey, child: const _BackChevron());
  }

  /// This widget is not decorated with a font since the font style could
  /// animate during transitions.
  final KeyedSubtree backLabel;
  static KeyedSubtree createBackLabel({
    @required GlobalKey backLabelKey,
    @required Widget userLeading,
    @required ModalRoute<dynamic> route,
    @required bool automaticallyImplyLeading,
    @required String previousPageTitle,
  }) {
    if (
      userLeading != null ||
      !automaticallyImplyLeading ||
      !route.canPop ||
      (route is PageRoute && route.fullscreenDialog)
    ) {
      return null;
    }

    return new KeyedSubtree(
      key: backLabelKey,
      child: new _BackLabel(
        specifiedPreviousTitle: previousPageTitle,
        route: route,
      ),
    );
  }

  /// This widget is not decorated with a font since the font style could
  /// animate during transitions.
  final KeyedSubtree middle;
  static KeyedSubtree createMiddle({
    @required GlobalKey middleKey,
    @required Widget userMiddle,
    @required Widget userLargeTitle,
    @required bool large,
    @required bool automaticallyImplyTitle,
    @required ModalRoute<dynamic> route,
  }) {
    Widget middleContent = userMiddle;

    if (large) {
      middleContent ??= userLargeTitle;
    }

    middleContent ??= _derivedTitle(
      automaticallyImplyTitle: automaticallyImplyTitle,
      currentRoute: route,
    );

    if (middleContent == null) {
      return null;
    }

    return new KeyedSubtree(
      key: middleKey,
      child: middleContent,
    );
  }

  final KeyedSubtree trailing;
  static KeyedSubtree createTrailing({
    @required GlobalKey trailingKey,
    @required Widget userTrailing,
    @required EdgeInsetsDirectional padding,
    @required Color actionsForegroundColor,
  }) {
    if (userTrailing == null) {
      return null;
    }

    return new KeyedSubtree(
      key: trailingKey,
      child: new Padding(
        padding: new EdgeInsetsDirectional.only(
          end: padding?.end ?? _kNavBarEdgePadding,
        ),
        child: new DefaultTextStyle(
          style: _navBarItemStyle(actionsForegroundColor),
          child: IconTheme.merge(
            data: new IconThemeData(
              color: actionsForegroundColor,
              size: 32.0,
            ),
            child: userTrailing,
          ),
        ),
      ),
    );
  }

  /// This widget is not decorated with a font since the font style could
  /// animate during transitions.
  final KeyedSubtree largeTitle;
  static KeyedSubtree createLargeTitle({
    @required GlobalKey largeTitleKey,
    @required Widget userLargeTitle,
    @required bool large,
    @required bool automaticImplyTitle,
    @required ModalRoute<dynamic> route,
  }) {
    if (!large) {
      return null;
    }

    final Widget largeTitleContent = userLargeTitle ?? _derivedTitle(
      automaticallyImplyTitle: automaticImplyTitle,
      currentRoute: route,
    );

    assert(
      largeTitleContent != null,
      'largeTitle was not provided and there was no title from the route',
    );

    return new KeyedSubtree(
      key: largeTitleKey,
      child: largeTitleContent,
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

  // Allow the back chevron and label to be separately created (and keyed)
  // because they animate separately during page transitions.
  const CupertinoNavigationBarBackButton._assemble(
    this._backChevron,
    this._backLabel,
    this.color,
  ) : previousPageTitle = null,
      assert(color != null);

  /// The [Color] of the back button.
  ///
  /// Must not be null.
  final Color color;

  /// An override for showing the previous route's title. If null, it will be
  /// automatically derived from [CupertinoPageRoute.title] if the current and
  /// previous routes are both [CupertinoPageRoute]s.
  final String previousPageTitle;

  final Widget _backChevron;

  final Widget _backLabel;

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
          child: new DefaultTextStyle(
            style: _navBarItemStyle(color),
            child: new Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Padding(padding: EdgeInsetsDirectional.only(start: 8.0)),
                _backChevron ?? const _BackChevron(),
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
      ),
      padding: EdgeInsets.zero,
      onPressed: () { Navigator.maybePop(context); },
    );
  }
}


class _BackChevron extends StatelessWidget {
  const _BackChevron({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    final TextStyle textStyle = DefaultTextStyle.of(context).style;

    // Replicate the Icon logic here to get a tightly sized icon and add
    // custom non-square padding.
    Widget iconWidget = new Text.rich(
      new TextSpan(
        text: new String.fromCharCode(CupertinoIcons.back.codePoint),
        style: new TextStyle(
          inherit: false,
          color: textStyle.color,
          fontSize: 34.0,
          fontFamily: CupertinoIcons.back.fontFamily,
          package: CupertinoIcons.back.fontPackage,
        ),
      ),
    );
    switch (textDirection) {
      case TextDirection.rtl:
        iconWidget = new Transform(
          transform: new Matrix4.identity()..scale(-1.0, 1.0, 1.0),
          alignment: Alignment.center,
          transformHitTests: false,
          child: iconWidget,
        );
        break;
      case TextDirection.ltr:
        break;
    }

    return iconWidget;
  }
}

/// A widget that shows next to the back chevron when `automaticallyImplyLeading`
/// is true.
class _BackLabel extends StatelessWidget {
  const _BackLabel({
    Key key,
    @required this.specifiedPreviousTitle,
    @required this.route,
  }) : assert(route != null),
       super(key: key);

  final String specifiedPreviousTitle;
  final ModalRoute<dynamic> route;

  // `child` is never passed in into ValueListenableBuilder so it's always
  // null here and unused.
  Widget _buildPreviousTitleWidget(BuildContext context, String previousTitle, Widget child) {
    if (previousTitle == null) {
      return const SizedBox(height: 0.0, width: 0.0);
    }

    Text textWidget = new Text(
      previousTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (previousTitle.length > 12) {
      textWidget = const Text('Back');
    }

    return new Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1.0,
      child: textWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (specifiedPreviousTitle != null) {
      return _buildPreviousTitleWidget(context, specifiedPreviousTitle, null);
    } else if (route is CupertinoPageRoute<dynamic>) {
      final CupertinoPageRoute<dynamic> cupertinoRoute = route;
      // There is no timing issue because the previousTitle Listenable changes
      // happen during route modifications before the ValueListenableBuilder
      // is built.
      return new ValueListenableBuilder<String>(
        valueListenable: cupertinoRoute.previousTitle,
        builder: _buildPreviousTitleWidget,
      );
    } else {
      return const SizedBox(height: 0.0, width: 0.0);
    }
  }
}

/// This class helps each Hero transition obtain the start or end navigation
/// bar's box size and the inner components of the navigation bar that will
/// move around.
///
/// It should be wrapped around the biggest [RenderBox] of the static
/// navigation bar in each route.
class _TransitionableNavigationBar extends StatelessWidget {
  _TransitionableNavigationBar({
    @required this.componentsKeys,
    @required this.backgroundColor,
    @required this.actionsForegroundColor,
    @required this.border,
    @required this.hasUserMiddle,
    @required this.largeExpanded,
    @required this.child,
  }) : assert(componentsKeys != null),
       assert(largeExpanded != null),
       super(key: componentsKeys.navBarBoxKey);

  final _NavigationBarStaticComponentsKeys componentsKeys;
  final Color backgroundColor;
  final Color actionsForegroundColor;
  final Border border;
  final bool hasUserMiddle;
  final bool largeExpanded;
  final Widget child;

  RenderBox get renderBox {
    final RenderBox box = componentsKeys.navBarBoxKey.currentContext.findRenderObject();
    assert(
      box.attached,
      '_TransitionableNavigationBar.renderBox should be called when building '
      'hero flight shuttles when the from and the to nav bar boxes are already '
      'laid out and painted.',
    );
    return box;
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      bool inHero;
      context.visitAncestorElements((Element ancestor) {
        if (ancestor is ComponentElement) {
          assert(
            ancestor.widget.runtimeType != _NavigationBarTransition,
            '_TransitionableNavigationBar should never re-appear inside '
            '_NavigationBarTransition. Keyed _TransitionableNavigationBar should '
            'only serve as anchor points in routes rather than appearing inside '
            'Hero flights themselves.',
          );
          if (ancestor.widget.runtimeType == Hero) {
            inHero = true;
          }
        }
        inHero ??= false;
        return true;
      });
      assert(
        inHero == true,
        '_TransitionableNavigationBar should only be added as the immediate '
        'child of Hero widgets.',
      );
      return true;
    }());
    return child;
  }
}

/// This class represents the widget that will be in the Hero flight instead of
/// the 2 static navigation bars by taking inner components from both.
///
/// The `topNavBar` parameter is the nav bar that was on top regardless of
/// push/pop direction.
///
/// Similarly, the `bottomNavBar` parameter is the nav bar that was at the
/// bottom regardless of the push/pop direction.
///
/// If [MediaQuery.padding] is still present in this widget's [BuildContext],
/// that padding will become part of the transitional navigation bar as well.
///
/// [MediaQuery.padding] should be consistent between the from/to routes and
/// the Hero overlay. Inconsistent [MediaQuery.padding] will produce undetermined
/// results.
class _NavigationBarTransition extends StatelessWidget {
  _NavigationBarTransition({
    @required this.animation,
    @required _TransitionableNavigationBar topNavBar,
    @required _TransitionableNavigationBar bottomNavBar,
  }) : heightTween = new Tween<double>(
         begin: bottomNavBar.renderBox.size.height,
         end: topNavBar.renderBox.size.height,
       ),
       backgroundTween = new ColorTween(
         begin: bottomNavBar.backgroundColor,
         end: topNavBar.backgroundColor,
       ),
       borderTween = new BorderTween(
         begin: bottomNavBar.border,
         end: topNavBar.border,
       ),
       componentsTransition = new _NavigationBarComponentsTransition(
         animation: animation,
         bottomNavBar: bottomNavBar,
         topNavBar: topNavBar,
       );

  final Animation<double> animation;
  final _NavigationBarComponentsTransition componentsTransition;

  final Tween<double> heightTween;
  final ColorTween backgroundTween;
  final BorderTween borderTween;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      // Draw an empty navigation bar box with changing shape behind all the
      // moving components without any components inside it itself.
      AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget child) {
          return _wrapWithBackground(
            annotate: false,
            backgroundColor: backgroundTween.evaluate(animation),
            border: borderTween.evaluate(animation),
            child: new SizedBox(
              height: heightTween.evaluate(animation),
              width: double.infinity,
            ),
          );
        },
      ),
      // Draw all the components on top of the empty bar box.
      componentsTransition.bottomBackChevron,
      componentsTransition.bottomBackLabel,
      componentsTransition.bottomLeading,
      componentsTransition.bottomMiddle,
      componentsTransition.bottomLargeTitle,
      componentsTransition.bottomTrailing,
      // Draw top components on top of the bottom components.
      componentsTransition.topLeading,
      componentsTransition.topBackChevron,
      componentsTransition.topBackLabel,
      componentsTransition.topMiddle,
      componentsTransition.topLargeTitle,
      componentsTransition.topTrailing,
    ];

    children.removeWhere((Widget child) => child == null);

    // The actual outer box is big enough to contain both the bottom and top
    // navigation bars. It's not a direct Rect lerp because some components
    // can actually be outside the linearly lerp'ed Rect in the middle of
    // the animation, such as the topLargeTitle.
    return new SizedBox(
      height: math.max(heightTween.begin, heightTween.end) + MediaQuery.of(context).padding.top,
      width: double.infinity,
      child: new Stack(
        children: children,
      ),
    );
  }
}

/// This class helps create widgets that are in transition based on static
/// components from the bottom and top navigation bars.
///
/// It animates these transitional components both in terms of position and
/// their appearance.
///
/// Instead of running the components through their normal static navigation
/// bar layout logic, this creates transitional widgets that are based on
/// these widgets' existing render objects' layout and position.
///
/// This is possible because this widget is only used during Hero transitions
/// where both the from and to routes are already built and layed out.
///
/// The components' existing layout constraints and positions are then
/// replicated using [Positioned] or [PositionedTransition] wrappers.
///
/// This class should never return [KeyedSubtree]s created by
/// _NavigationBarStaticComponents directly. Since widgets from
/// _NavigationBarStaticComponents are still present in the widget tree during the
/// hero transitions, it would cause global key duplications. Instead, return
/// only the [KeyedSubtree]s' child.
@immutable
class _NavigationBarComponentsTransition {
  _NavigationBarComponentsTransition({
    @required this.animation,
    @required _TransitionableNavigationBar bottomNavBar,
    @required _TransitionableNavigationBar topNavBar,
  }) : bottomComponents = bottomNavBar.componentsKeys,
       topComponents = topNavBar.componentsKeys,
       bottomNavBarBox = bottomNavBar.renderBox,
       topNavBarBox = topNavBar.renderBox,
       bottomActionsStyle = _navBarItemStyle(bottomNavBar.actionsForegroundColor),
       topActionsStyle = _navBarItemStyle(topNavBar.actionsForegroundColor),
       bottomHasUserMiddle = bottomNavBar.hasUserMiddle,
       topHasUserMiddle = topNavBar.hasUserMiddle,
       bottomLargeExpanded = bottomNavBar.largeExpanded,
       topLargeExpanded = topNavBar.largeExpanded,
       transitionBox =
           // paintBounds are based on offset zero so it's ok to expand the Rects.
           bottomNavBar.renderBox.paintBounds.expandToInclude(topNavBar.renderBox.paintBounds);

  static final Tween<double> fadeOut = new Tween<double>(
    begin: 1.0,
    end: 0.0,
  );
  static final Tween<double> fadeIn = new Tween<double>(
    begin: 0.0,
    end: 1.0,
  );

  final Animation<double> animation;
  final _NavigationBarStaticComponentsKeys bottomComponents;
  final _NavigationBarStaticComponentsKeys topComponents;

  // These render boxes that are the ancestors of all the bottom and top
  // components are used to determine the components' relative positions inside
  // their respective navigation bars.
  final RenderBox bottomNavBarBox;
  final RenderBox topNavBarBox;

  final TextStyle bottomActionsStyle;
  final TextStyle topActionsStyle;
  final bool bottomHasUserMiddle;
  final bool topHasUserMiddle;
  final bool bottomLargeExpanded;
  final bool topLargeExpanded;

  // This is the outer box in which all the components will be fitted. The
  // sizing component of RelativeRects will be based on this rect's size.
  final Rect transitionBox;

  // Take a widget it its original ancestor navigation bar render box and
  // translate it into a RelativeBox in the transition navigation bar box.
  RelativeRect positionInTransitionBox(
    GlobalKey key, {
    @required RenderBox from,
  }) {
    final RenderBox componentBox = key.currentContext.findRenderObject();
    assert(componentBox.attached);

    return new RelativeRect.fromRect(
      componentBox.localToGlobal(Offset.zero, ancestor: from) & componentBox.size,
      transitionBox,
    );
  }

  // Create a Tween that moves a widget between its original position in its
  // ancestor navigation bar to another widget's position in that widget's
  // navigation bar.
  //
  // Anchor their positions based on the center of their respective render
  // boxes' leading edge.
  //
  // Also produce RelativeRects with sizes that would preserve the constant
  // BoxConstraints of the 'from' widget so that animating font sizes etc don't
  // produce rounding error artifacts with a linearly resizing rect.
  RelativeRectTween slideFromLeadingEdge({
    @required GlobalKey fromKey,
    @required RenderBox fromNavBarBox,
    @required GlobalKey toKey,
    @required RenderBox toNavBarBox,
  }) {
    final RelativeRect fromRect = positionInTransitionBox(fromKey, from: fromNavBarBox);

    final RenderBox fromBox = fromKey.currentContext.findRenderObject();
    final RenderBox toBox = toKey.currentContext.findRenderObject();
    final Rect toRect =
        toBox.localToGlobal(
          Offset.zero,
          ancestor: toNavBarBox,
        ).translate(
          0.0,
          - fromBox.size.height / 2 + toBox.size.height / 2
        ) & fromBox.size; // Keep the from render object's size.

    return new RelativeRectTween(
        begin: fromRect,
        end: new RelativeRect.fromRect(toRect, transitionBox),
      );
  }

  Animation<double> fadeInFrom(double t, { Curve curve = Curves.easeIn }) {
    return fadeIn.animate(
      new CurvedAnimation(curve: new Interval(t, 1.0, curve: curve), parent: animation),
    );
  }

  Animation<double> fadeOutBy(double t, { Curve curve = Curves.easeOut }) {
    return fadeOut.animate(
      new CurvedAnimation(curve: new Interval(0.0, t, curve: curve), parent: animation),
    );
  }

  Widget get bottomLeading {
    final KeyedSubtree bottomLeading = bottomComponents.leadingKey.currentWidget;

    if (bottomLeading == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(bottomComponents.leadingKey, from: bottomNavBarBox),
      child: new FadeTransition(
        opacity: fadeOutBy(0.4),
        child: bottomLeading.child,
      ),
    );
  }

  Widget get bottomBackChevron {
    final KeyedSubtree bottomBackChevron = bottomComponents.backChevronKey.currentWidget;

    if (bottomBackChevron == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(bottomComponents.backChevronKey, from: bottomNavBarBox),
      child: new FadeTransition(
        opacity: fadeOutBy(0.6),
        child: new DefaultTextStyle(
          style: bottomActionsStyle,
          child: bottomBackChevron.child,
        ),
      ),
    );
  }

  Widget get bottomBackLabel {
    final KeyedSubtree bottomBackLabel = bottomComponents.backLabelKey.currentWidget;

    if (bottomBackLabel == null) {
      return null;
    }

    final RelativeRect from = positionInTransitionBox(bottomComponents.backLabelKey, from: bottomNavBarBox);

    // Transition away by sliding horizontally to the left off of the screen.
    final RelativeRectTween positionTween = new RelativeRectTween(
      begin: from,
      end: from.shift(new Offset(-bottomNavBarBox.size.width / 2.0, 0.0)),
    );

    return new PositionedTransition(
      rect: positionTween.animate(animation),
      child: new FadeTransition(
        opacity: fadeOutBy(0.2),
        child: new DefaultTextStyle(
          style: bottomActionsStyle,
          child: bottomBackLabel.child,
        ),
      ),
    );
  }

  Widget get bottomMiddle {
    final KeyedSubtree bottomMiddle = bottomComponents.middleKey.currentWidget;
    final KeyedSubtree topBackLabel = topComponents.backLabelKey.currentWidget;
    final KeyedSubtree topLeading = topComponents.leadingKey.currentWidget;

    // The middle component is non-null when the nav bar is a large title
    // nav bar but would be invisible when expanded, therefore don't show it here.
    if (!bottomHasUserMiddle && bottomLargeExpanded) {
      return null;
    }

    if (bottomMiddle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          fromKey: bottomComponents.middleKey,
          fromNavBarBox: bottomNavBarBox,
          toKey: topComponents.backLabelKey,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          // A custom middle widget like a segmented control fades away faster.
          opacity: fadeOutBy(bottomHasUserMiddle ? 0.4 : 0.7),
          child: new Align(
            // As the text shrinks, make sure it's still anchored to the leading
            // edge of a constantly sized outer box.
            alignment: AlignmentDirectional.centerStart,
            child: new DefaultTextStyleTransition(
              style: TextStyleTween(
                begin: _kMiddleTitleTextStyle,
                end: topActionsStyle,
              ).animate(animation),
              child: bottomMiddle.child,
            ),
          ),
        ),
      );
    }

    // When the top page has a leading widget override, don't move the bottom
    // middle widget.
    if (bottomMiddle != null && topLeading != null) {
      return new Positioned.fromRelativeRect(
        rect: positionInTransitionBox(bottomComponents.middleKey, from: bottomNavBarBox),
        child: new FadeTransition(
          opacity: fadeOutBy(bottomHasUserMiddle ? 0.4 : 0.7),
          // Keep the font when transitioning into a non-back label leading.
          child: new DefaultTextStyle(
            style: _kMiddleTitleTextStyle,
            child: bottomMiddle.child,
          ),
        ),
      );
    }

    return null;
  }

  Widget get bottomLargeTitle {
    final KeyedSubtree bottomLargeTitle = bottomComponents.largeTitleKey.currentWidget;
    final KeyedSubtree topBackLabel = topComponents.backLabelKey.currentWidget;
    final KeyedSubtree topLeading = topComponents.leadingKey.currentWidget;

    if (bottomLargeTitle == null || !bottomLargeExpanded) {
      return null;
    }

    if (bottomLargeTitle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          fromKey: bottomComponents.largeTitleKey,
          fromNavBarBox: bottomNavBarBox,
          toKey: topComponents.backLabelKey,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: fadeOutBy(0.6),
          child: new Align(
            // As the text shrinks, make sure it's still anchored to the leading
            // edge of a constantly sized outer box.
            alignment: AlignmentDirectional.centerStart,
            child: new DefaultTextStyleTransition(
              style: TextStyleTween(
                begin: _kLargeTitleTextStyle,
                end: topActionsStyle,
              ).animate(animation),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: bottomLargeTitle.child,
            ),
          ),
        ),
      );
    }

    if (bottomLargeTitle != null && topLeading != null) {
      final RelativeRect from = positionInTransitionBox(bottomComponents.largeTitleKey, from: bottomNavBarBox);

      final RelativeRectTween positionTween = new RelativeRectTween(
        begin: from,
        end: from.shift(new Offset(bottomNavBarBox.size.width / 4.0, 0.0)),
      );

      // Just shift slightly towards the right instead of moving to the back
      // label position.
      return new PositionedTransition(
        rect: positionTween.animate(animation),
        child: new FadeTransition(
          opacity: fadeOutBy(0.4),
          // Keep the font when transitioning into a non-back-label leading.
          child: new DefaultTextStyle(
            style: _kLargeTitleTextStyle,
            child: bottomLargeTitle.child,
          ),
        ),
      );
    }

    return null;
  }

  Widget get bottomTrailing {
    final KeyedSubtree bottomTrailing = bottomComponents.trailingKey.currentWidget;

    if (bottomTrailing == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(bottomComponents.trailingKey, from: bottomNavBarBox),
      child: new FadeTransition(
        opacity: fadeOutBy(0.6),
        child: bottomTrailing.child,
      ),
    );
  }

  Widget get topLeading {
    final KeyedSubtree topLeading = topComponents.leadingKey.currentWidget;

    if (topLeading == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(topComponents.leadingKey, from: topNavBarBox),
      child: new FadeTransition(
        opacity: fadeInFrom(0.6),
        child: topLeading.child,
      ),
    );
  }

  Widget get topBackChevron {
    final KeyedSubtree topBackChevron = topComponents.backChevronKey.currentWidget;
    final KeyedSubtree bottomBackChevron = bottomComponents.backChevronKey.currentWidget;

    if (topBackChevron == null) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topComponents.backChevronKey, from: topNavBarBox);
    RelativeRect from = to;

    // If it's the first page with a back chevron, shift in slightly from the
    // right.
    if (bottomBackChevron == null) {
      final RenderBox topBackChevronBox = topComponents.backChevronKey.currentContext.findRenderObject();
      from = to.shift(new Offset(topBackChevronBox.size.width * 2.0, 0.0));
    }

    final RelativeRectTween positionTween = new RelativeRectTween(
      begin: from,
      end: to,
    );

    return new PositionedTransition(
      rect: positionTween.animate(animation),
      child: new FadeTransition(
        opacity: fadeInFrom(bottomBackChevron == null ? 0.7 : 0.4),
        child: new DefaultTextStyle(
          style: topActionsStyle,
          child: topBackChevron.child,
        ),
      ),
    );
  }

  Widget get topBackLabel {
    final KeyedSubtree bottomMiddle = bottomComponents.middleKey.currentWidget;
    final KeyedSubtree bottomLargeTitle = bottomComponents.largeTitleKey.currentWidget;
    final KeyedSubtree topBackLabel = topComponents.backLabelKey.currentWidget;
    final RenderAnimatedOpacity opacity =
        topComponents.backLabelKey.currentContext?.ancestorRenderObjectOfType(
          const TypeMatcher<RenderAnimatedOpacity>()
        );

    Animation<double> midClickOpacity;
    if (opacity != null && opacity.opacity.value < 1.0) {
      midClickOpacity = new Tween<double>(
        begin: 0.0,
        end: opacity.opacity.value,
      ).animate(animation);
    }

    if (topBackLabel == null) {
      return null;
    }

    // Pick up from an incoming transition from the large title. This is
    // duplicated here from the bottomLargeTitle transition widget because the
    // content text might be different. For instance, if the bottomLargeTitle
    // text is too long, the topBackLabel will say 'Back' instead of the original
    // text.
    if (bottomLargeTitle != null &&
        topBackLabel != null &&
        bottomLargeExpanded
    ) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          fromKey: bottomComponents.largeTitleKey,
          fromNavBarBox: bottomNavBarBox,
          toKey: topComponents.backLabelKey,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: midClickOpacity ?? fadeInFrom(0.4),
          child: new DefaultTextStyleTransition(
            style: TextStyleTween(
              begin: _kLargeTitleTextStyle,
              end: topActionsStyle,
            ).animate(animation),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: topBackLabel.child,
          ),
        ),
      );
    }

    // The topBackLabel always comes from the large title first if available
    // and expanded instead of middle.
    if (bottomMiddle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          fromKey: bottomComponents.middleKey,
          fromNavBarBox: bottomNavBarBox,
          toKey: topComponents.backLabelKey,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: midClickOpacity ?? fadeInFrom(0.3),
          child: new DefaultTextStyleTransition(
            style: TextStyleTween(
              begin: _kMiddleTitleTextStyle,
              end: topActionsStyle,
            ).animate(animation),
            child: topBackLabel.child,
          ),
        ),
      );
    }

    return null;
  }

  Widget get topMiddle {
    final KeyedSubtree topMiddle = topComponents.middleKey.currentWidget;

    if (topMiddle == null) {
      return null;
    }

    // The middle component is non-null when the nav bar is a large title
    // nav bar but would be invisible when expanded, therefore don't show it here.
    if (!topHasUserMiddle && topLargeExpanded) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topComponents.middleKey, from: topNavBarBox);

    // Shift in from the trailing edge of the screen.
    final RelativeRectTween positionTween = new RelativeRectTween(
      begin: to.shift(new Offset(topNavBarBox.size.width / 2.0, 0.0)),
      end: to,
    );

    return new PositionedTransition(
      rect: positionTween.animate(animation),
      child: new FadeTransition(
        opacity: fadeInFrom(0.25),
        child: new DefaultTextStyle(
          style: _kMiddleTitleTextStyle,
          child: topMiddle.child,
        ),
      ),
    );
  }

  Widget get topTrailing {
    final KeyedSubtree topTrailing = topComponents.trailingKey.currentWidget;

    if (topTrailing == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(topComponents.trailingKey, from: topNavBarBox),
      child: new FadeTransition(
        opacity: fadeInFrom(0.4),
        child: topTrailing.child,
      ),
    );
  }

  Widget get topLargeTitle {
    final KeyedSubtree topLargeTitle = topComponents.largeTitleKey.currentWidget;

    if (topLargeTitle == null || !topLargeExpanded) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topComponents.largeTitleKey, from: topNavBarBox);

    // Shift in from the trailing edge of the screen.
    final RelativeRectTween positionTween = new RelativeRectTween(
      begin: to.shift(new Offset(topNavBarBox.size.width, 0.0)),
      end: to,
    );

    return new PositionedTransition(
      rect: positionTween.animate(animation),
      child: new FadeTransition(
        opacity: fadeInFrom(0.3),
        child: new DefaultTextStyle(
          style: _kLargeTitleTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: topLargeTitle.child,
        ),
      ),
    );
  }
}

/// Navigation bars' hero rect tween that will move between the static bars
/// but keep a constant size that can contain both navigation bars.
CreateRectTween _linearTranslateWithLargestRectSizeTween = (Rect begin, Rect end) {
  final Size largestSize = new Size(
    math.max(begin.size.width, end.size.width),
    math.max(begin.size.height, end.size.height),
  );
  return new RectTween(
    begin: begin.topLeft & largestSize,
    end: end.topLeft & largestSize,
  );
};

TransitionBuilder _navBarHeroLaunchPadBuilder = (
  BuildContext context,
  Widget child,
) {
  assert(child is _TransitionableNavigationBar);
  // Tree reshaping is fine here because the Heroes' child is always a
  // _TransitionableNavigationBar which has a GlobalKey.

  // Keeping the Hero subtree here is needed (instead of just swapping out the
  // anchor nav bars for fixed size boxes during flights) because the nav bar
  // and their specific component children may serve as anchor points again if
  // another mid-transition flight diversion is triggered.

  // This is ok performance-wise because static nav bars are generally cheap to
  // build and layout but expensive to GPU render (due to clips and blurs) which
  // we're skipping here.
  return new Visibility(
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    visible: false,
    child: child,
  );
};

/// Navigation bars' hero flight shuttle builder.
HeroFlightShuttleBuilder _navBarHeroFlightShuttleBuilder = (
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  assert(animation != null);
  assert(flightDirection != null);
  assert(fromHeroContext != null);
  assert(toHeroContext != null);
  assert(fromHeroContext.widget is Hero);
  assert(toHeroContext.widget is Hero);

  final Hero fromHeroWidget = fromHeroContext.widget;
  final Hero toHeroWidget = toHeroContext.widget;

  assert(fromHeroWidget.child is _TransitionableNavigationBar);
  assert(toHeroWidget.child is _TransitionableNavigationBar);

  final _TransitionableNavigationBar fromNavBar = fromHeroWidget.child;
  final _TransitionableNavigationBar toNavBar = toHeroWidget.child;

  assert(fromNavBar.componentsKeys != null);
  assert(toNavBar.componentsKeys != null);

  assert(
    fromNavBar.componentsKeys.navBarBoxKey.currentContext.owner != null,
    'The from nav bar to Hero must have been mounted in the previous frame',
  );
  assert(
    toNavBar.componentsKeys.navBarBoxKey.currentContext.owner != null,
    'The to nav bar to Hero must have been mounted in the previous frame',
  );

  switch (flightDirection) {
    case HeroFlightDirection.push:
      return new _NavigationBarTransition(
        animation: animation,
        bottomNavBar: fromNavBar,
        topNavBar: toNavBar,
      );
      break;
    case HeroFlightDirection.pop:
      return new _NavigationBarTransition(
        animation: animation,
        bottomNavBar: toNavBar,
        topNavBar: fromNavBar,
      );
  }
};
