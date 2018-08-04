// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of nav_bar;

class CupertinoNavigationBarTransition extends StatelessWidget {
  CupertinoNavigationBarTransition({
    this.animation,
    this.topNavBar,
    this.bottomNavBar,
    this.topRoute,
    this.bottomRoute,
  }) : assert(
         topNavBar is CupertinoNavigationBar || topNavBar is CupertinoSliverNavigationBar,
         typeError,
       ),
       assert(
         bottomNavBar is CupertinoNavigationBar || bottomNavBar is CupertinoSliverNavigationBar,
         typeError,
       ),
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
       );

  static const String typeError =
      'Can only transition between CupertinoNavigationBars and CupertinoSliverNavigationBars';

  final Animation<double> animation;
  final Widget topNavBar;
  final Widget bottomNavBar;
  final CupertinoPageRoute<dynamic> topRoute;
  final CupertinoPageRoute<dynamic> bottomRoute;

  final Tween<double> heightTween;
  final ColorTween backgroundTween;
  final BorderTween borderTween;

  static double getNavBarHeight(Widget navBar) {
    if (navBar is CupertinoNavigationBar) {
      return _kNavBarPersistentHeight;
    } else if (navBar is CupertinoSliverNavigationBar) {
      return _kNavBarPersistentHeight + _kNavBarLargeTitleHeightExtension;
    } else {
      assert(
        false,
        typeError,
      );
      return null;
    }
  }

  static Color getNavBarBackgroundColor(Widget navBar) {
    if (navBar is CupertinoNavigationBar) {
      return navBar.backgroundColor;
    } else if (navBar is CupertinoSliverNavigationBar) {
      return navBar.backgroundColor;
    } else {
      assert(
        false,
        typeError,
      );
      return null;
    }
  }

  static Border getNavBarBorder(Widget navBar) {
    if (navBar is CupertinoNavigationBar) {
      return navBar.border;
    } else if (navBar is CupertinoSliverNavigationBar) {
      return navBar.border;
    } else {
      assert(
        false,
        typeError,
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
  });

  final Animation<double> animation;
  final _CupertinoNavigationBarComponents bottomNavBarComponents;
  final _CupertinoNavigationBarComponents topNavBarComponents;

  Widget get bottomMiddle {
    final Widget bottomMiddle = bottomNavBarComponents.middle;
    final Widget topBackLabel = topNavBarComponents.backLabel;

    if (bottomMiddle != null && topBackLabel != null) {
      // bottomNavBarComponents.middleRenderBox.globalToLocal(point)
      return new DefaultTextStyleTransition(
        style: TextStyleTween(
          begin: _kMiddleTitleTextStyle,
          end: topNavBarComponents._actionsStyle,
        ).animate(animation),
        child: bottomMiddle,
      );
    }

    if (bottomMiddle != null && topBackLabel == null) {
      return bottomMiddle;
    }

    return null;
  }
}

class _RenderCupertinoNavigationBarTransition extends RenderBox {

  double _topHeight;
  double _bottomHeight;
}