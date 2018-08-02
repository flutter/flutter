// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'icons.dart';
import 'page_scaffold.dart';
import 'route.dart';

/// Standard iOS navigation bar height without the status bar.
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

const TextStyle _kLargeTitleTextStyle = TextStyle(
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.24,
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

  @override
  Widget build(BuildContext context) {
    final Widget effectiveMiddle = _effectiveTitle(
      title: middle,
      automaticallyImplyTitle: automaticallyImplyMiddle,
      currentRoute: ModalRoute.of(context),
    );

    return _wrapWithBackground(
      border: border,
      backgroundColor: backgroundColor,
      child: new _CupertinoPersistentNavigationBar(
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        previousPageTitle: previousPageTitle,
        middle: effectiveMiddle,
        trailing: trailing,
        padding: padding,
        actionsForegroundColor: actionsForegroundColor,
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

  @override
  Widget build(BuildContext context) {
    final Widget effectiveTitle = _effectiveTitle(
      title: largeTitle,
      automaticallyImplyTitle: automaticallyImplyTitle,
      currentRoute: ModalRoute.of(context),
    );

    return new SliverPersistentHeader(
      pinned: true, // iOS navigation bars are always pinned.
      delegate: new _CupertinoLargeTitleNavigationBarSliverDelegate(
        persistentHeight: _kNavBarPersistentHeight + MediaQuery.of(context).padding.top,
        largeTitle: effectiveTitle,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        previousPageTitle: previousPageTitle,
        middle: middle,
        trailing: trailing,
        padding: padding,
        border: border,
        backgroundColor: backgroundColor,
        actionsForegroundColor: actionsForegroundColor,
      ),
    );
  }
}

class _CupertinoLargeTitleNavigationBarSliverDelegate
    extends SliverPersistentHeaderDelegate with DiagnosticableTreeMixin {
  _CupertinoLargeTitleNavigationBarSliverDelegate({
    @required this.persistentHeight,
    @required this.largeTitle,
    this.leading,
    this.automaticallyImplyLeading,
    this.previousPageTitle,
    this.middle,
    this.trailing,
    this.padding,
    this.border,
    this.backgroundColor,
    this.actionsForegroundColor,
  }) : assert(persistentHeight != null);

  final double persistentHeight;

  final Widget largeTitle;

  final Widget leading;

  final bool automaticallyImplyLeading;

  final String previousPageTitle;

  final Widget middle;

  final Widget trailing;

  final EdgeInsetsDirectional padding;

  final Color backgroundColor;

  final Border border;

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
      automaticallyImplyLeading: automaticallyImplyLeading,
      previousPageTitle: previousPageTitle,
      middle: middle ?? largeTitle,
      trailing: trailing,
      // If middle widget exists, always show it. Otherwise, show title
      // when collapsed.
      middleVisible: middle != null ? null : !showLargeTitle,
      padding: padding,
      actionsForegroundColor: actionsForegroundColor,
    );

    return _wrapWithBackground(
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
                  child: new DefaultTextStyle(
                    style: _kLargeTitleTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: new AnimatedOpacity(
                      opacity: showLargeTitle ? 1.0 : 0.0,
                      duration: _kNavBarTitleFadeDuration,
                      child: new SafeArea(
                        top: false,
                        bottom: false,
                        child: new Semantics(
                          header: true,
                          child: largeTitle,
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
  }

  @override
  bool shouldRebuild(_CupertinoLargeTitleNavigationBarSliverDelegate oldDelegate) {
    return persistentHeight != oldDelegate.persistentHeight
        || largeTitle != oldDelegate.largeTitle
        || leading != oldDelegate.leading
        || middle != oldDelegate.middle
        || trailing != oldDelegate.trailing
        || border != oldDelegate.border
        || backgroundColor != oldDelegate.backgroundColor
        || actionsForegroundColor != oldDelegate.actionsForegroundColor;
  }
}

/// Returns `child` wrapped with background and a bottom border if background color
/// is opaque. Otherwise, also blur with [BackdropFilter].
Widget _wrapWithBackground({
  Border border,
  Color backgroundColor,
  Widget child,
}) {

  final bool darkBackground = backgroundColor.computeLuminance() < 0.179;
  final SystemUiOverlayStyle overlayStyle = darkBackground
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;
  final DecoratedBox childWithBackground = new DecoratedBox(
    decoration: new BoxDecoration(
      border: border,
      color: backgroundColor,
    ),
    child: new AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      sized: true,
      child: child,
    ),
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

Widget _effectiveTitle({
  Widget title,
  bool automaticallyImplyTitle,
  ModalRoute<dynamic> currentRoute,
}) {
  // Auto use the CupertinoPageRoute's title if middle not provided.
  if (title == null &&
      automaticallyImplyTitle &&
      currentRoute is CupertinoPageRoute &&
      currentRoute.title != null) {
    return new Text(currentRoute.title);
  }

  return title;
}

/// The top part of the navigation bar that's never scrolled away.
///
/// Consists of the entire navigation bar without background and border when used
/// without large titles. With large titles, it's the top static half that
/// doesn't scroll.
class _CupertinoPersistentNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const _CupertinoPersistentNavigationBar({
    Key key,
    this.leading,
    this.automaticallyImplyLeading,
    this.previousPageTitle,
    this.middle,
    this.trailing,
    this.padding,
    this.actionsForegroundColor,
    this.middleVisible,
  }) : super(key: key);

  final Widget leading;

  final bool automaticallyImplyLeading;

  final String previousPageTitle;

  final Widget middle;

  final Widget trailing;

  final EdgeInsetsDirectional padding;

  final Color actionsForegroundColor;

  /// Whether the middle widget has a visible animated opacity. A null value
  /// means the middle opacity will not be animated.
  final bool middleVisible;

  @override
  Size get preferredSize => const Size.fromHeight(_kNavBarPersistentHeight);

  @override
  Widget build(BuildContext context) {
    final TextStyle actionsStyle = new TextStyle(
      fontFamily: '.SF UI Text',
      fontSize: 17.0,
      letterSpacing: -0.24,
      color: actionsForegroundColor,
    );

    final Widget styledLeading = leading == null
        ? null
        : new Padding(
          padding: new EdgeInsetsDirectional.only(
            start: padding?.start ?? _kNavBarEdgePadding,
          ),
          child: new DefaultTextStyle(
            style: actionsStyle,
            child: leading,
          ),
        );

    final Widget styledTrailing = trailing == null
        ? null
        : Padding(
          padding: new EdgeInsetsDirectional.only(
            end: padding?.end ?? _kNavBarEdgePadding,
          ),
          child: new DefaultTextStyle(
            style: actionsStyle,
            child: trailing,
          ),
        );

    // Let the middle be black rather than `actionsForegroundColor` in case
    // it's a plain text title.
    final Widget styledMiddle = middle == null
        ? null
        : new DefaultTextStyle(
          style: actionsStyle.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
            color: CupertinoColors.black,
          ),
          child: new Semantics(child: middle, header: true),
        );

    final Widget animatedStyledMiddle = middleVisible == null
      ? styledMiddle
      : new AnimatedOpacity(
        opacity: middleVisible ? 1.0 : 0.0,
        duration: _kNavBarTitleFadeDuration,
        child: styledMiddle,
      );

    // Auto add back button if leading not provided.
    Widget backOrCloseButton;
    if (styledLeading == null && automaticallyImplyLeading) {
      final ModalRoute<dynamic> currentRoute = ModalRoute.of(context);
      if (currentRoute?.canPop == true) {
        if (currentRoute is PageRoute && currentRoute?.fullscreenDialog == true) {
          backOrCloseButton = new CupertinoButton(
            child: const Padding(
              padding: EdgeInsetsDirectional.only(
                start: _kNavBarEdgePadding,
              ),
              child: Text('Close'),
            ),
            padding: EdgeInsets.zero,
            onPressed: () { Navigator.maybePop(context); },
          );
        } else {
          backOrCloseButton = new CupertinoNavigationBarBackButton(
            color: actionsForegroundColor,
            previousPageTitle: previousPageTitle,
          );
        }
      }
    }

    Widget paddedToolbar = new NavigationToolbar(
      leading: styledLeading ?? backOrCloseButton,
      middle: animatedStyledMiddle,
      trailing: styledTrailing,
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
  }) : assert(color != null);

  /// The [Color] of the back chevron.
  ///
  /// Must not be null.
  final Color color;

  /// An override for showing the previous route's title. If null, it will be
  /// automatically derived from [CupertinoPageRoute.title] if the current and
  /// previous routes are both [CupertinoPageRoute]s.
  final String previousPageTitle;

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
              new _BackChevron(color: color),
              const Padding(padding: EdgeInsetsDirectional.only(start: 6.0)),
              new Flexible(
                child: new _BackLabel(
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

class _BackChevron extends StatelessWidget {
  const _BackChevron({
    @required this.color,
  }) : assert(color != null);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);

    // Replicate the Icon logic here to get a tightly sized icon and add
    // custom non-square padding.
    Widget iconWidget = new Text.rich(
      new TextSpan(
        text: new String.fromCharCode(CupertinoIcons.back.codePoint),
        style: new TextStyle(
          inherit: false,
          color: color,
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
    @required this.specifiedPreviousTitle,
    @required this.route,
  }) : assert(route != null);

  final String specifiedPreviousTitle;
  final ModalRoute<dynamic> route;

  // `child` is never passed in into ValueListenableBuilder so it's always
  // null here and unused.
  Widget _buildPreviousTitleWidget(BuildContext context, String previousTitle, Widget child) {
    if (previousTitle == null) {
      return const SizedBox(height: 0.0, width: 0.0);
    }

    if (previousTitle.length > 10) {
      return const Text('Back');
    }

    return new Text(previousTitle, maxLines: 1);
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
