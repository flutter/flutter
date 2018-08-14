// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of nav_bar;

// This file contains all the code for building the Cupertino navigation
// bars as each pair transitions between routes.

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
      bool inHero = false;
      context.visitAncestorElements((Element ancestor) {
        if (ancestor is ComponentElement) {
          assert(
            ancestor.widget.runtimeType != _NavigationBarTransition,
            '_RenderObjectFindingWidget should never appear inside '
            '_NavigationBarTransition. Keyed _RenderObjectFindingWidgets should '
            'only serve as anchor points in _TransitionableNavigationBars rather '
            'than appearing inside Hero flights themselves.',
          );
          if (ancestor.widget.runtimeType == Hero) {
            inHero = true;
          }
        }
        return true;
      });
      assert(
        inHero,
        '_RenderObjectFindingWidget should only be used inside _TransitionableNavigationBars',
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
          opacity: fadeInFrom(0.4),
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
          opacity: fadeInFrom(0.3),
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
