// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of nav_bar;

// class _CupertinoNavigationBarTransition extends StatelessWidget {
//   CupertinoNavigationBarTransition({
//     this.animation,
//     this.topNavBar,
//     this.bottomNavBar,
//     this.topRoute,
//     this.bottomRoute,
//   });

//   final Animation<double> animation;
//   final Widget topNavBar;
//   final Widget bottomNavBar;
//   final CupertinoPageRoute<dynamic> topRoute;
//   final CupertinoPageRoute<dynamic> bottomRoute;

//   double getNavBarHeight(Widget navBar) {
//     if (navBar is CupertinoNavigationBar) {
//       return _kNavBarPersistentHeight;
//     } else if (navBar is CupertinoSliverNavigationBar) {
//       return _kNavBarPersistentHeight + _kNavBarLargeTitleHeightExtension;
//     } else {
//       assert(
//         false,
//         'Can only transition between CupertinoNavigationBars and '
//         'CupertinoSliverNavigationBars',
//       );
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double topHeight = getNavBarHeight(topNavBar);
//     final double bottomHeight = getNavBarHeight(bottomNavBar);
//   }
// }

// class _RenderCupertinoNavigationBarTransition extends RenderBox {

//   double _topHeight;
//   double _bottomHeight;
// }