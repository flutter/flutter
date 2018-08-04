// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of nav_bar;

class CupertinoNavigationBarTransition extends StatelessWidget {
  CupertinoNavigationBarTransition({
    this.animation,
    this.topNavBar,
    this.bottomNavBar,
    this.topContext,
    this.bottomContext,
  }) : assert(
         topNavBar is CupertinoNavigationBar || topNavBar is CupertinoSliverNavigationBar,
         typeError,
       ),
       assert(
         bottomNavBar is CupertinoNavigationBar || bottomNavBar is CupertinoSliverNavigationBar,
         typeError,
       ),
       assert(topNavBar == topContext.widget),
       assert(bottomNavBar == bottomContext.widget),
       heightTween = new Tween<double>(
         begin: getNavBarHeight(bottomNavBar),
         end: getNavBarHeight(topNavBar),
       ),
       backgroundTween = new ColorTween(
         begin: getNavBarBackgroundColor(bottomNavBar),
         end: getNavBarBackgroundColor(topNavBar),
       ),
       borderTween = new BorderTween(
         begin: getNavBarBorder(bottomNavBar),
         end: getNavBarBorder(topNavBar),
       ),
       componentsTransition = new _CupertinoNavigationBarComponentsTransition(
         animation: animation,
         bottomNavBarComponents: getNavBarComponents(bottomContext),
         bottomNavBarBox: getNavBarBox(bottomContext),
         topNavBarComponents: getNavBarComponents(topContext),
         topNavBarBox: getNavBarBox(topContext),
       );

  static const String typeError =
      'Can only transition between CupertinoNavigationBars and CupertinoSliverNavigationBars';

  final Animation<double> animation;
  final Widget topNavBar;
  final Widget bottomNavBar;
  final BuildContext topContext;
  final BuildContext bottomContext;
  final _CupertinoNavigationBarComponentsTransition componentsTransition;

  final Tween<double> heightTween;
  final ColorTween backgroundTween;
  final BorderTween borderTween;

  static double getNavBarHeight(Widget navBar) {
    if (navBar is CupertinoNavigationBar) {
      return _kNavBarPersistentHeight;
    } else if (navBar is CupertinoSliverNavigationBar) {
      return _kNavBarPersistentHeight + _kNavBarLargeTitleHeightExtension;
    }

    assert(
      false,
      typeError,
    );
    return null;
  }

  static Color getNavBarBackgroundColor(Widget navBar) {
    if (navBar is CupertinoNavigationBar) {
      return navBar.backgroundColor;
    } else if (navBar is CupertinoSliverNavigationBar) {
      return navBar.backgroundColor;
    }

    assert(
      false,
      typeError,
    );
    return null;
  }

  static Border getNavBarBorder(Widget navBar) {
    if (navBar is CupertinoNavigationBar) {
      return navBar.border;
    } else if (navBar is CupertinoSliverNavigationBar) {
      return navBar.border;
    }

    assert(
      false,
      typeError,
    );
    return null;
  }

  static _CupertinoNavigationBarComponents getNavBarComponents(BuildContext context) {
    if (context is StatefulElement) {
      final State state = context.state;
      if (state is _CupertinoNavigationBarState) {
        return state._components;
      } else if (state is _CupertinoSliverNavigationBarState) {
        return state._components;
      }
    }

    assert(
      false,
      typeError,
    );
    return null;
  }

  static RenderBox getNavBarBox(BuildContext context) {
    if (context is StatefulElement) {
      final State state = context.state;
      if (state is _CupertinoNavigationBarState) {
        return context.findRenderObject();
      } else if (state is _CupertinoSliverNavigationBarState) {
        return state._boxKey.currentContext.findRenderObject();
      }
    }

    assert(
      false,
      typeError,
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      componentsTransition.bottomMiddle,
    ];

    children.removeWhere((Widget child) => child == null);

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _wrapWithBackground(
          annotate: false,
          backgroundColor: backgroundTween.evaluate(animation),
          border: borderTween.evaluate(animation),
          child: new SizedBox(
            height: heightTween.evaluate(animation) + MediaQuery.of(context).padding.top,
            width: double.infinity,
            child: new Stack(
              children: children,
            ),
          ),
        );
      },
    );
  }
}

@immutable
class _CupertinoNavigationBarComponentsTransition {
  const _CupertinoNavigationBarComponentsTransition({
    this.animation,
    this.bottomNavBarComponents,
    this.topNavBarComponents,
    this.bottomNavBarBox,
    this.topNavBarBox,
  });

  final Animation<double> animation;
  final _CupertinoNavigationBarComponents bottomNavBarComponents;
  final _CupertinoNavigationBarComponents topNavBarComponents;
  final RenderBox bottomNavBarBox;
  final RenderBox topNavBarBox;

  Widget get bottomMiddle {
    final _RenderObjectFindingWidget bottomMiddle = bottomNavBarComponents.middle;
    final _RenderObjectFindingWidget topBackLabel = topNavBarComponents.backLabel;

    if (bottomMiddle != null && topBackLabel != null) {
      final Rect from =
          bottomMiddle.renderBox.localToGlobal(
            Offset.zero,
            ancestor: bottomNavBarBox,
          ) & bottomMiddle.renderBox.size;
      final Rect to =
          topBackLabel.renderBox.localToGlobal(
            Offset.zero,
            ancestor: topNavBarBox,
          ) & bottomMiddle.renderBox.size;
      final RelativeRectTween positionTween = new RelativeRectTween(
        begin: new RelativeRect.fromRect(from, bottomNavBarBox.paintBounds),
        end: new RelativeRect.fromRect(to, topNavBarBox.paintBounds),
      );
      final Tween<double> opacityTween = new Tween<double>(
        begin: 1.0,
        end: 0.0,
      );

      return new PositionedTransition(
        rect: positionTween.animate(animation),
        child: new FadeTransition(
          opacity: opacityTween.animate(animation),
          child: new DefaultTextStyleTransition(
            style: TextStyleTween(
              begin: _kMiddleTitleTextStyle,
              end: topNavBarComponents._actionsStyle,
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

  Widget get topLargeTitle {

  }
}
