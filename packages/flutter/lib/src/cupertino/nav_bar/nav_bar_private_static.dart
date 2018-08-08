// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of nav_bar;

/// Standard iOS navigation bar height without the status bar.
///
/// This height is constant and independent of accessibility as is in iOS.
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
const Duration _kNavBarTitleFadeDuration = const Duration(milliseconds: 150);

const Color _kDefaultNavBarBackgroundColor = const Color(0xCCF8F8F8);
const Color _kDefaultNavBarBorderColor = const Color(0x4C000000);

const Border _kDefaultNavBarBorder = const Border(
  bottom: const BorderSide(
    color: _kDefaultNavBarBorderColor,
    width: 0.0, // One physical pixel.
    style: BorderStyle.solid,
  ),
);

const TextStyle _kMiddleTitleTextStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.08,
  color: CupertinoColors.black,
);

const TextStyle _kLargeTitleTextStyle = const TextStyle(
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.24,
  color: CupertinoColors.black,
);

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

class _LargeTitleNavigationBarSliverDelegate
    extends SliverPersistentHeaderDelegate with DiagnosticableTreeMixin {
  _LargeTitleNavigationBarSliverDelegate({
    @required this.leading,
    @required this.automaticallyImplyLeading,
    @required this.automaticallyImplyTitle,
    @required this.previousPageTitle,
    @required this.middle,
    @required this.trailing,
    @required this.largeTitle,
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

  final Widget leading;
  final bool automaticallyImplyLeading;
  final bool automaticallyImplyTitle;
  final String previousPageTitle;
  final Widget middle;
  final Widget trailing;
  final Widget largeTitle;
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

    final _NavigationBarComponents components = new _NavigationBarComponents(
      route: ModalRoute.of(context),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      automaticallyImplyTitle: automaticallyImplyTitle,
      previousPageTitle: previousPageTitle,
      middle: middle,
      trailing: trailing,
      largeTitle: largeTitle,
      padding: padding,
      backgroundColor: backgroundColor,
      border: border,
      actionsForegroundColor: actionsForegroundColor,
      large: true,
      largeExpanded: showLargeTitle,
    );

    final _PersistentNavigationBar persistentNavigationBar =
        new _PersistentNavigationBar(
      components: components,
      padding: padding,
      // If a user specified middle exists, always show it. Otherwise, show
      // title when collapsed.
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

    if (!transitionBetweenRoutes) {
      return navBar;
    }

    return new Hero(
      tag: _heroTag,
      createRectTween: _linearTranslateWithLargestRectSizeTween,
      flightShuttleBuilder: _navBarHeroFlightShuttleBuilder,
      // This is all the way down here instead of being at the top level of
      // CupertinoSliverNavigationBar like CupertinoNavigationBar because it
      // needs to wrap the top level RenderBox rather than a RenderSliver.
      child: new _TransitionableNavigationBar(
        components: components,
        child: navBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleNavigationBarSliverDelegate oldDelegate) {
    return leading != oldDelegate.leading
        || automaticallyImplyLeading != oldDelegate.automaticallyImplyLeading
        || automaticallyImplyTitle != oldDelegate.automaticallyImplyTitle
        || previousPageTitle != oldDelegate.previousPageTitle
        || middle != oldDelegate.middle
        || trailing != oldDelegate.trailing
        || largeTitle != oldDelegate.largeTitle
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

  final _NavigationBarComponents components;

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
        components.actionsStyle.color,
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

@immutable
class _NavigationBarComponents {
  _NavigationBarComponents({
    @required ModalRoute<dynamic> route,
    @required Widget leading,
    @required bool automaticallyImplyLeading,
    @required bool automaticallyImplyTitle,
    @required String previousPageTitle,
    @required Widget middle,
    @required Widget trailing,
    @required Widget largeTitle,
    @required this.backgroundColor,
    @required this.border,
    @required EdgeInsetsDirectional padding,
    @required Color actionsForegroundColor,
    @required this.large,
    this.largeExpanded,
  }) : leading = createLeading(
         userLeading: leading,
         route: route,
         automaticallyImplyLeading: automaticallyImplyLeading,
         padding: padding,
         actionsForegroundColor: actionsForegroundColor,
        ),
       backChevron = createBackChevron(
         userLeading: leading,
         route: route,
         automaticallyImplyLeading: automaticallyImplyLeading,
       ),
       backLabel = createBackLabel(
         userLeading: leading,
         route: route,
         previousPageTitle: previousPageTitle,
         automaticallyImplyLeading: automaticallyImplyLeading,
       ),
       hasUserMiddle = middle != null,
       middle = createMiddle(
         userMiddle: middle,
         userLargeTitle: largeTitle,
         route: route,
         automaticallyImplyTitle: automaticallyImplyTitle,
         large: large,
       ),
       trailing = createTrailing(
         userTrailing: trailing,
         padding: padding,
         actionsForegroundColor: actionsForegroundColor,
       ),
       largeTitle = createLargeTitle(
         userLargeTitle: largeTitle,
         route: route,
         automaticImplyTitle: automaticallyImplyTitle,
         large: large,
       ),
       actionsStyle = _navBarItemStyle(actionsForegroundColor);

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

  final Color backgroundColor;
  final Border border;
  final TextStyle actionsStyle;

  final _RenderObjectFindingWidget leading;
  static _RenderObjectFindingWidget createLeading({
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

    return new _RenderObjectFindingWidget(
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

  final _RenderObjectFindingWidget backChevron;
  static _RenderObjectFindingWidget createBackChevron({
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

    return new _RenderObjectFindingWidget(
      child: const _BackChevron(),
    );
  }

  final _RenderObjectFindingWidget backLabel;
  static _RenderObjectFindingWidget createBackLabel({
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

    return new _RenderObjectFindingWidget(
      child: new _BackLabel(
        specifiedPreviousTitle: previousPageTitle,
        route: route,
      ),
    );
  }

  final bool hasUserMiddle;
  final _RenderObjectFindingWidget middle;
  static _RenderObjectFindingWidget createMiddle({
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

    return new _RenderObjectFindingWidget(
      child: middleContent,
    );
  }

  final _RenderObjectFindingWidget trailing;
  static _RenderObjectFindingWidget createTrailing({
    @required Widget userTrailing,
    @required EdgeInsetsDirectional padding,
    @required Color actionsForegroundColor,
  }) {
    if (userTrailing == null) {
      return null;
    }

    return new _RenderObjectFindingWidget(
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

  final _RenderObjectFindingWidget largeTitle;
  static _RenderObjectFindingWidget createLargeTitle({
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

    if (largeTitleContent == null) {
      return null;
    }

    return new _RenderObjectFindingWidget(
      child: largeTitleContent,
    );
  }

  final bool large;
  final bool largeExpanded;
}

class _RenderObjectFindingWidget extends StatelessWidget {
  _RenderObjectFindingWidget({ @required this.child }) :
    assert(child != null),
    super(key: new GlobalKey());

  final Widget child;

  RenderBox get renderBox {
    final GlobalKey globalKey = key;
    final RenderBox renderBox = globalKey.currentContext?.findRenderObject();
    assert(
      renderBox != null && renderBox.attached,
      'The renderBox getter should only be called after the widget is added to the tree',
    );
    return renderBox;
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      context.visitAncestorElements((Element ancestor) {
        if (ancestor is StatelessElement) {
          assert(
            ancestor.widget.runtimeType != _NavigationBarTransition,
            '_RenderObjectFindingWidget should never appear inside '
            '_NavigationBarTransition. Keyed _RenderObjectFindingWidgets should '
            'only serve as anchor points in _TransitionableNavigationBars rather '
            'than appearing inside Hero flights themselves.',
          );
        }
        return true;
      });
      return true;
    }());
    return child;
  }
}

class _BackChevron extends StatelessWidget {
  const _BackChevron();

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
