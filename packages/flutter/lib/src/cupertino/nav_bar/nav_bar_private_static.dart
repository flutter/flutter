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

const TextStyle _kLargeTitleTextStyle = const TextStyle(
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.24,
  color: CupertinoColors.black,
);

class _CupertinoLargeTitleNavigationBarSliverDelegate
    extends SliverPersistentHeaderDelegate with DiagnosticableTreeMixin {
  _CupertinoLargeTitleNavigationBarSliverDelegate({
    @required this.components,
    @required this.persistentHeight,
    this.border,
    this.backgroundColor,
    this.alwaysShowMiddle,
  }) : assert(persistentHeight != null);

  final _CupertinoNavigationBarComponents components;

  final double persistentHeight;

  final Color backgroundColor;

  final Border border;

  final bool alwaysShowMiddle;

  @override
  double get minExtent => persistentHeight;

  @override
  double get maxExtent => persistentHeight + _kNavBarLargeTitleHeightExtension;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool showLargeTitle = shrinkOffset < maxExtent - minExtent - _kNavBarShowLargeTitleThreshold;

    final _CupertinoPersistentNavigationBar persistentNavigationBar =
        new _CupertinoPersistentNavigationBar(
      components: components,
      // If a user specified middle exists, always show it. Otherwise, show
      // title when collapsed.
      middleVisible: alwaysShowMiddle ? null : !showLargeTitle,
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
                child: new AnimatedOpacity(
                  opacity: showLargeTitle ? 1.0 : 0.0,
                  duration: _kNavBarTitleFadeDuration,
                  child: components.largeTitle,
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
    return components != oldDelegate.components
        || persistentHeight != oldDelegate.persistentHeight
        || border != oldDelegate.border
        || backgroundColor != oldDelegate.backgroundColor;
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

/// The top part of the navigation bar that's never scrolled away.
///
/// Consists of the entire navigation bar without background and border when used
/// without large titles. With large titles, it's the top static half that
/// doesn't scroll.
class _CupertinoPersistentNavigationBar extends StatelessWidget {
  const _CupertinoPersistentNavigationBar({
    Key key,
    this.components,
    this.middleVisible,
  }) : super(key: key);

  final _CupertinoNavigationBarComponents components;

  /// Whether the middle widget has a visible animated opacity. A null value
  /// means the middle opacity will not be animated.
  final bool middleVisible;

  @override
  Widget build(BuildContext context) {
    Widget middle = components.middle;

    middle = middleVisible == null
      ? middle
      : new AnimatedOpacity(
        opacity: middleVisible ? 1.0 : 0.0,
        duration: _kNavBarTitleFadeDuration,
        child: middle,
      );

    Widget leading = components.leading;
    final Widget backChevron = components.backChevron;
    final Widget backLabel = components.backLabel;

    if (leading == null && backChevron != null && backLabel != null) {
      leading = new CupertinoNavigationBarBackButton._assemble(backChevron, backLabel);
    }

    Widget paddedToolbar = new NavigationToolbar(
      leading: leading,
      middle: middle,
      trailing: components.trailing,
      centerMiddle: true,
      middleSpacing: 6.0,
    );

    if (components._padding != null) {
      paddedToolbar = new Padding(
        padding: EdgeInsets.only(
          top: components._padding.top,
          bottom: components._padding.bottom,
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
class _CupertinoNavigationBarComponents {
  _CupertinoNavigationBarComponents({
    ModalRoute<dynamic> route,
    Widget leading,
    bool automaticallyImplyLeading,
    bool automaticallyImplyTitle,
    String previousPageTitle,
    Widget middle,
    Widget trailing,
    Widget largeTitle,
    EdgeInsetsDirectional padding,
    Color actionsForegroundColor,
    bool middleVisible,
    bool large,
  }) : _route = route,
       _leading = leading,
       _automaticallyImplyLeading = automaticallyImplyLeading,
       _automaticallyImplyTitle = automaticallyImplyTitle,
       _previousPageTitle = previousPageTitle,
       _middle = middle,
       _trailing = trailing,
       _largeTitle = largeTitle,
       _padding = padding,
       _actionsForegroundColor = actionsForegroundColor,
       _middleVisible = middleVisible,
       _large = large,
       _actionsStyle = new TextStyle(
         fontFamily: '.SF UI Text',
         fontSize: 17.0,
         letterSpacing: -0.24,
         color: actionsForegroundColor,
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

  final TextStyle _actionsStyle;

  final ModalRoute<dynamic> _route;

  final Widget _leading;
  Widget get leading {
    Widget leadingContent;
    // Final allows implicit casting inside statements.
    final ModalRoute<dynamic> currentRoute = _route;

    if (_leading != null) {
      leadingContent = _leading;
    } else if (
      _automaticallyImplyLeading &&
      currentRoute.canPop &&
      currentRoute is PageRoute &&
      currentRoute.fullscreenDialog
    ) {
      leadingContent = new CupertinoButton(
        child: const Text('Close'),
        padding: EdgeInsets.zero,
        onPressed: () { currentRoute.navigator.maybePop(); },
      );
    }

    if (leadingContent == null) {
      return null;
    }

    return new Padding(
      padding: new EdgeInsetsDirectional.only(
        start: _padding?.start ?? _kNavBarEdgePadding,
      ),
      child: new DefaultTextStyle(
        style: _actionsStyle,
        child: leadingContent,
      ),
    );
  }

  Widget get backChevron {
    // Final allows implicit casting inside statements.
    final ModalRoute<dynamic> currentRoute = _route;

    if (
      _leading != null ||
      !_automaticallyImplyLeading ||
      !currentRoute.canPop ||
      (currentRoute is PageRoute && currentRoute.fullscreenDialog)
    ) {
      return null;
    }

    return new _BackChevron(color: _actionsForegroundColor);
  }

  Widget get backLabel {
    // Final allows implicit casting inside statements.
    final ModalRoute<dynamic> currentRoute = _route;

    if (
      _leading != null ||
      !_automaticallyImplyLeading ||
      !currentRoute.canPop ||
      (currentRoute is PageRoute && currentRoute.fullscreenDialog)
    ) {
      return null;
    }

    return new _BackLabel(
      specifiedPreviousTitle: _previousPageTitle,
      route: currentRoute,
    );
  }

  final bool _automaticallyImplyLeading;
  final bool _automaticallyImplyTitle;
  final String _previousPageTitle;

  final Widget _middle;
  Widget get middle {
    Widget middleContent = _middle;

    if (_large) {
      middleContent ??= _largeTitle;
    }

    middleContent ??= _derivedTitle(
      automaticallyImplyTitle: _automaticallyImplyTitle,
      currentRoute: _route,
    );

    if (middleContent == null) {
      return null;
    }

    return new DefaultTextStyle(
      style: _actionsStyle.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
        color: CupertinoColors.black,
      ),
      child: new Semantics(header: true, child: middleContent),
    );
  }

  final Widget _trailing;
  Widget get trailing {
    if (_trailing == null) {
      return null;
    }

    return new Padding(
      padding: new EdgeInsetsDirectional.only(
        end: _padding?.end ?? _kNavBarEdgePadding,
      ),
      child: new DefaultTextStyle(
        style: _actionsStyle,
        child: _trailing,
      ),
    );
  }

  final Widget _largeTitle;
  Widget get largeTitle {
    if (!_large) {
      return null;
    }

    final Widget effectiveLargeTitle = _largeTitle ?? _derivedTitle(
      automaticallyImplyTitle: _automaticallyImplyTitle,
      currentRoute: _route,
    );

    if (effectiveLargeTitle == null) {
      return null;
    }

    return new Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _kNavBarEdgePadding,
        bottom: 8.0, // Bottom has a different padding.
      ),
      child: new SafeArea(
        top: false,
        bottom: false,
        child: new Semantics(
          header: true,
          child: new DefaultTextStyle(
            style: _kLargeTitleTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: effectiveLargeTitle,
          ),
        ),
      ),
    );
  }

  final EdgeInsetsDirectional _padding;
  final Color _actionsForegroundColor;
  /// Whether the middle widget has a visible animated opacity. A null value
  /// means the middle opacity will not be animated.
  final bool _middleVisible;
  final bool _large;
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
