// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of nav_bar;

class _TransitionableNavigationBar extends _RenderObjectFindingWidget {
  _TransitionableNavigationBar({
    @required this.components,
    @required Widget child,
  }) : assert(components != null),
       super(child: child);

  final _NavigationBarComponents components;
}

class _NavigationBarTransition extends StatelessWidget {
  _NavigationBarTransition({
    @required this.animation,
    @required this.topNavBar,
    @required this.bottomNavBar,
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

  static const String typeError =
      'Can only transition between CupertinoNavigationBars and CupertinoSliverNavigationBars';

  final Animation<double> animation;
  final _TransitionableNavigationBar topNavBar;
  final _TransitionableNavigationBar bottomNavBar;
  final _NavigationBarComponentsTransition componentsTransition;

  final Tween<double> heightTween;
  final ColorTween backgroundTween;
  final BorderTween borderTween;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
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
      componentsTransition.bottomBackChevron,
      componentsTransition.bottomLeading,
      componentsTransition.bottomMiddle,
      componentsTransition.bottomLargeTitle,
      componentsTransition.bottomTrailing,
      componentsTransition.topBackChevron,
      componentsTransition.topMiddle,
      componentsTransition.topLargeTitle,
      componentsTransition.topTrailing,
    ];

    children.removeWhere((Widget child) => child == null);

    return new SizedBox(
      height: math.max(heightTween.begin, heightTween.end) + MediaQuery.of(context).padding.top,
      width: double.infinity,
      child: new Stack(
        children: children,
      ),
    );
  }
}

@immutable
class _NavigationBarComponentsTransition {
  _NavigationBarComponentsTransition({
    this.animation,
    this.bottomComponents,
    this.topComponents,
    this.bottomNavBarBox,
    this.topNavBarBox,
  }) : transitionBox = bottomNavBarBox.paintBounds.expandToInclude(topNavBarBox.paintBounds);

  static final Tween<double> fadeOut = new Tween<double>(
    begin: 1.0,
    end: 0.0,
  );
  static final Tween<double> fadeIn = new Tween<double>(
    begin: 0.0,
    end: 1.0,
  );

  final Animation<double> animation;
  final _NavigationBarComponents bottomComponents;
  final _NavigationBarComponents topComponents;
  final RenderBox bottomNavBarBox;
  final RenderBox topNavBarBox;

  final Rect transitionBox;

  RelativeRect positionInTransitionBox(
    _RenderObjectFindingWidget widget, {
    @required RenderBox from,
  }) {
    return new RelativeRect.fromRect(
      widget.renderBox.localToGlobal(Offset.zero, ancestor: from) & widget.renderBox.size,
      transitionBox,
    );
  }

  RelativeRectTween slideLeadingEdge({
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

  Animation<double> fadeInFrom(double t, { Curve curve = Curves.linear }) {
    return fadeIn.animate(
      new CurvedAnimation(curve: new Interval(t, 1.0, curve: curve), parent: animation),
    );
  }

  Animation<double> fadeOutBy(double t, { Curve curve = Curves.linear }) {
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
        opacity: fadeOutBy(0.6),
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
        child: bottomBackChevron.child,
      ),
    );
  }

  Widget get bottomMiddle {
    final _RenderObjectFindingWidget bottomMiddle = bottomComponents.middle;
    final _RenderObjectFindingWidget topBackLabel = topComponents.backLabel;

    // The middle component is non-null when the nav bar is a large title
    // nav bar but would be invisible when expanded.
    // TODO
    if (bottomComponents.large && !bottomComponents.hasUserMiddle) {
      return null;
    }

    if (bottomMiddle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideLeadingEdge(
          from: bottomMiddle,
          fromNavBarBox: bottomNavBarBox,
          to: topBackLabel,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: fadeOutBy(0.9),
          child: new DefaultTextStyleTransition(
            style: TextStyleTween(
              begin: _kMiddleTitleTextStyle,
              end: topComponents.actionsStyle,
            ).animate(animation),
            child: bottomMiddle.child,
          ),
        ),
      );
    }

    if (bottomMiddle != null && topBackLabel == null) {
      return bottomMiddle.child;
    }

    return null;
  }

  Widget get bottomLargeTitle {
    final _RenderObjectFindingWidget bottomLargeTitle = bottomComponents.largeTitle;
    final _RenderObjectFindingWidget topBackLabel = topComponents.backLabel;

    if (bottomLargeTitle != null && topBackLabel != null) {
      return new PositionedTransition(
        rect: slideLeadingEdge(
          from: bottomLargeTitle,
          fromNavBarBox: bottomNavBarBox,
          to: topBackLabel,
          toNavBarBox: topNavBarBox,
        ).animate(animation),
        child: new FadeTransition(
          opacity: fadeOutBy(0.9),
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
      );
    }

    if (bottomLargeTitle != null && topBackLabel == null) {
      return bottomLargeTitle.child;
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

  Widget get topBackChevron {
    final _RenderObjectFindingWidget topBackChevron = topComponents.backChevron;

    if (topBackChevron == null) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topBackChevron, from: topNavBarBox);
    RelativeRect from = to;

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
        opacity: fadeInFrom(0.4),
        child: topBackChevron.child,
      ),
    );
  }

  Widget get topMiddle {
    final _RenderObjectFindingWidget topMiddle = topComponents.middle;

    if (topMiddle == null) {
      return null;
    }

    // The middle component is non-null when the nav bar is a large title
    // nav bar but would be invisible when expanded.
    if (topComponents.large && !topComponents.hasUserMiddle) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topMiddle, from: topNavBarBox);

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

  Widget get topLargeTitle {
    final _RenderObjectFindingWidget topLargeTitle = topComponents.largeTitle;

    if (topLargeTitle == null) {
      return null;
    }

    final RelativeRect to = positionInTransitionBox(topLargeTitle, from: topNavBarBox);

    final RelativeRectTween positionTween = new RelativeRectTween(
      begin: to.shift(new Offset(topNavBarBox.size.width, 0.0)),
      end: to,
    );

    return new PositionedTransition(
      rect: positionTween.animate(animation),
      child: new FadeTransition(
        opacity: fadeInFrom(0.25),
        child: topLargeTitle.child,
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
}

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
