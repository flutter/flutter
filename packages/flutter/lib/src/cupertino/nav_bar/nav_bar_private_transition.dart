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
class _TransitionableNavigationBar extends _RenderObjectFindingWidget {
  _TransitionableNavigationBar({
    @required this.components,
    @required Widget child,
  }) : assert(components != null),
       super(child: child);

  final _NavigationBarStaticComponents components;
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
         begin: bottomNavBar.components.backgroundColor,
         end: topNavBar.components.backgroundColor,
       ),
       borderTween = new BorderTween(
         begin: bottomNavBar.components.border,
         end: topNavBar.components.border,
       ),
       componentsTransition = new _NavigationBarComponentsTransition(
         animation: animation,
         bottomComponents: bottomNavBar.components,
         bottomNavBarBox: bottomNavBar.renderBox,
         topComponents: topNavBar.components,
         topNavBarBox: topNavBar.renderBox,
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
    @required this.bottomComponents,
    @required this.topComponents,
    @required this.bottomNavBarBox,
    @required this.topNavBarBox,
  }) : transitionBox =
      // paintBounds are based on offset zero so it's ok to expand the Rects.
      bottomNavBarBox.paintBounds.expandToInclude(topNavBarBox.paintBounds);

  static final Tween<double> fadeOut = new Tween<double>(
    begin: 1.0,
    end: 0.0,
  );
  static final Tween<double> fadeIn = new Tween<double>(
    begin: 0.0,
    end: 1.0,
  );

  final Animation<double> animation;
  final _NavigationBarStaticComponents bottomComponents;
  final _NavigationBarStaticComponents topComponents;

  // These render boxes that are the ancestors of all the bottom and top
  // components are used to determine the components' relative positions inside
  // their respective navigation bars.
  final RenderBox bottomNavBarBox;
  final RenderBox topNavBarBox;

  // This is the outer box in which all the components will be fitted. The
  // sizing component of RelativeRects will be based on this rect's size.
  final Rect transitionBox;

  // Take a widget it its original ancestor navigation bar render box and
  // translate it into a RelativeBox in the transition navigation bar box.
  RelativeRect positionInTransitionBox(
    _RenderObjectFindingWidget widget, {
    @required RenderBox from,
  }) {
    return new RelativeRect.fromRect(
      widget.renderBox.localToGlobal(Offset.zero, ancestor: from) & widget.renderBox.size,
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
    @required _RenderObjectFindingWidget from,
    @required RenderBox fromNavBarBox,
    @required _RenderObjectFindingWidget to,
    @required RenderBox toNavBarBox,
  }) {
    final RelativeRect fromRect = positionInTransitionBox(from, from: fromNavBarBox);
    final Rect toRect =
        to.renderBox.localToGlobal(
          Offset.zero,
          ancestor: toNavBarBox,
        ).translate(
          0.0,
          - from.renderBox.size.height / 2 + to.renderBox.size.height / 2
        ) & from.renderBox.size; // Keep the from render object's size.

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
    final _RenderObjectFindingWidget bottomLeading = bottomComponents.leading;

    if (bottomLeading == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(bottomLeading, from: bottomNavBarBox),
      child: new FadeTransition(
        opacity: fadeOutBy(0.4),
        child: bottomLeading.child,
      ),
    );
  }

  Widget get bottomBackChevron {
    final _RenderObjectFindingWidget bottomBackChevron = bottomComponents.backChevron;

    if (bottomBackChevron == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(bottomBackChevron, from: bottomNavBarBox),
      child: new FadeTransition(
        opacity: fadeOutBy(0.6),
        child: new DefaultTextStyle(
          style: bottomComponents.actionsStyle,
          child: bottomBackChevron.child,
        ),
      ),
    );
  }

  Widget get bottomBackLabel {
    final _RenderObjectFindingWidget bottomBackLabel = bottomComponents.backLabel;

    if (bottomBackLabel == null) {
      return null;
    }

    final RelativeRect from = positionInTransitionBox(bottomBackLabel, from: bottomNavBarBox);

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
          style: topComponents.actionsStyle,
          child: bottomBackLabel.child,
        ),
      ),
    );
  }

  Widget get bottomMiddle {
    final _RenderObjectFindingWidget bottomMiddle = bottomComponents.middle;
    final _RenderObjectFindingWidget topBackLabel = topComponents.backLabel;
    final _RenderObjectFindingWidget topLeading = topComponents.leading;

    // The middle component is non-null when the nav bar is a large title
    // nav bar but would be invisible when expanded, therefore don't show it here.
    if (bottomComponents.large &&
        !bottomComponents.hasUserMiddle &&
        bottomComponents.largeExpanded
    ) {
      return null;
    }

    if (bottomMiddle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          from: bottomMiddle,
          fromNavBarBox: bottomNavBarBox,
          to: topBackLabel,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          // A custom middle widget like a segmented control fades away faster.
          opacity: fadeOutBy(bottomComponents.hasUserMiddle ? 0.4 : 0.7),
          child: new Align(
            // As the text shrinks, make sure it's still anchored to the leading
            // edge of a constantly sized outer box.
            alignment: AlignmentDirectional.centerStart,
            child: new DefaultTextStyleTransition(
              style: TextStyleTween(
                begin: _kMiddleTitleTextStyle,
                end: topComponents.actionsStyle,
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
        rect: positionInTransitionBox(bottomMiddle, from: bottomNavBarBox),
        child: new FadeTransition(
          opacity: fadeOutBy(bottomComponents.hasUserMiddle ? 0.4 : 0.7),
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
    final _RenderObjectFindingWidget bottomLargeTitle = bottomComponents.largeTitle;
    final _RenderObjectFindingWidget topBackLabel = topComponents.backLabel;
    final _RenderObjectFindingWidget topLeading = topComponents.leading;

    if (bottomLargeTitle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          from: bottomLargeTitle,
          fromNavBarBox: bottomNavBarBox,
          to: topBackLabel,
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
                end: topComponents.actionsStyle,
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
      final RelativeRect from = positionInTransitionBox(bottomLargeTitle, from: bottomNavBarBox);

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
    final _RenderObjectFindingWidget bottomTrailing = bottomComponents.trailing;

    if (bottomTrailing == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(bottomTrailing, from: bottomNavBarBox),
      child: new FadeTransition(
        opacity: fadeOutBy(0.6),
        child: bottomTrailing.child,
      ),
    );
  }

  Widget get topLeading {
    final _RenderObjectFindingWidget topLeading = topComponents.leading;

    if (topLeading == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(topLeading, from: topNavBarBox),
      child: new FadeTransition(
        opacity: fadeInFrom(0.6),
        child: topLeading.child,
      ),
    );
  }

  Widget get topBackChevron {
    final _RenderObjectFindingWidget topBackChevron = topComponents.backChevron;
    final _RenderObjectFindingWidget bottomBackChevron = bottomComponents.backChevron;

    if (topBackChevron == null) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topBackChevron, from: topNavBarBox);
    RelativeRect from = to;

    // If it's the first page with a back chevron, shift in slightly from the
    // right.
    if (bottomComponents.backChevron == null) {
      from = to.shift(new Offset(topBackChevron.renderBox.size.width, 0.0));
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
          style: topComponents.actionsStyle,
          child: topBackChevron.child,
        ),
      ),
    );
  }

  Widget get topBackLabel {
    final _RenderObjectFindingWidget bottomMiddle = bottomComponents.middle;
    final _RenderObjectFindingWidget bottomLargeTitle = bottomComponents.largeTitle;
    final _RenderObjectFindingWidget topBackLabel = topComponents.backLabel;

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
        bottomComponents.largeExpanded
    ) {
      return new PositionedTransition(
        rect: slideFromLeadingEdge(
          from: bottomLargeTitle,
          fromNavBarBox: bottomNavBarBox,
          to: topBackLabel,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: fadeInFrom(0.4),
          child: new DefaultTextStyleTransition(
            style: TextStyleTween(
              begin: _kLargeTitleTextStyle,
              end: topComponents.actionsStyle,
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
          from: bottomMiddle,
          fromNavBarBox: bottomNavBarBox,
          to: topBackLabel,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: fadeInFrom(0.3),
          child: new DefaultTextStyleTransition(
            style: TextStyleTween(
              begin: _kMiddleTitleTextStyle,
              end: topComponents.actionsStyle,
            ).animate(animation),
            child: topBackLabel.child,
          ),
        ),
      );
    }

    return null;
  }

  Widget get topMiddle {
    final _RenderObjectFindingWidget topMiddle = topComponents.middle;

    if (topMiddle == null) {
      return null;
    }

    // The middle component is non-null when the nav bar is a large title
    // nav bar but would be invisible when expanded, therefore don't show it here.
    if (topComponents.large &&
        !topComponents.hasUserMiddle &&
        topComponents.largeExpanded
    ) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topMiddle, from: topNavBarBox);

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
    final _RenderObjectFindingWidget topTrailing = topComponents.trailing;

    if (topTrailing == null) {
      return null;
    }

    return new Positioned.fromRelativeRect(
      rect: positionInTransitionBox(topTrailing, from: topNavBarBox),
      child: new FadeTransition(
        opacity: fadeInFrom(0.4),
        child: topTrailing.child,
      ),
    );
  }

  Widget get topLargeTitle {
    final _RenderObjectFindingWidget topLargeTitle = topComponents.largeTitle;

    if (topLargeTitle == null) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topLargeTitle, from: topNavBarBox);

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

/// Navigation bars' hero flight shuttle builder.
HeroFlightShuttleBuilder _navBarHeroFlightShuttleBuilder = (
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  Hero fromWidget,
  Hero toWidget,
) {
  assert(animation != null);
  assert(flightDirection != null);
  assert(fromWidget != null);
  assert(toWidget != null);
  assert(fromWidget.child is _TransitionableNavigationBar);
  assert(toWidget.child is _TransitionableNavigationBar);
  final _TransitionableNavigationBar fromNavBar = fromWidget.child;
  final _TransitionableNavigationBar toNavBar = toWidget.child;
  assert(fromNavBar.components != null);
  assert(toNavBar.components != null);
  // These getters also make sure that the render boxes have been attached
  // which should be the case when used in Heros.
  assert(fromNavBar.renderBox != null);
  assert(toNavBar.renderBox != null);

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
