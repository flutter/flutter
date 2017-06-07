// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'bottom_tab_bar.dart';
import 'nav_bar.dart';

class CupertinoScaffold extends StatefulWidget {
  const CupertinoScaffold({
    Key key,
    this.navigationBar,
    @required this.child,
  }) : tabBar = null,
       pageBuilder = null,
       pageController = null,
       initialPage = null,
       super(key: key);

  const CupertinoScaffold.tabbed({
    Key key,
    this.navigationBar,
    @required this.tabBar,
    @required this.pageBuilder,
    this.pageController,
    this.initialPage,
  }) : assert(pageController ?? false || initialPage == null),
       child = null,
       super(key: key);

  final PreferredSizeWidget navigationBar;
  final PreferredSizeWidget tabBar;
  final IndexedWidgetBuilder pageBuilder;
  final PageController pageController;
  final int initialPage;
  final Widget child;

  @override
  _CupertinoScaffoldState createState() => new _CupertinoScaffoldState();
}

class _CupertinoScaffoldState extends State<CupertinoScaffold> {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = widget.pageController
        ?? new PageController(initialPage: widget.initialPage ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];
    if (widget.child != null) {
      stacked.add(_padMiddle(widget.child));
    } else if (widget.pageBuilder != null) {
      stacked.add(_padMiddle(
        new PageView.builder(
          controller: _pageController,
          itemBuilder: widget.pageBuilder,
          onPageChanged: (int newIndex) {
            // setState(() {});
          },
        ),
      ));
    }

    if (widget.navigationBar != null) {
      stacked.add(new Align(
        alignment: FractionalOffset.topCenter,
        child: widget.navigationBar,
      ));
    }

    if (widget.tabBar != null) {
      CupertinoTabBar managedTabBar;
      if (widget.tabBar.runtimeType == CupertinoTabBar) {
        managedTabBar = widget.tabBar;
        managedTabBar = managedTabBar.clone(
          _pageController.page.round(),
          (int newIndex) {
            _pageController.jumpToPage(newIndex);
          },
        );
      }

      stacked.add(new Align(
        alignment: FractionalOffset.bottomCenter,
        child: managedTabBar ?? widget.tabBar,
      ));
    }

    return new Stack(
      children: stacked,
    );
  }

  Widget _padMiddle(Widget middle) {
    double topPadding = 0.0;
    if (widget.navigationBar is CupertinoNavigationBar) {
      final CupertinoNavigationBar top = widget.navigationBar;
      if (top.opaque)
        topPadding = top.preferredSize.height;
    }

    double bottomPadding = 0.0;
    if (widget.tabBar is CupertinoTabBar) {
      final CupertinoTabBar bottom = widget.tabBar;
      if (bottom.opaque)
        bottomPadding = bottom.preferredSize.height;
    }

    if (topPadding == 0.0 && bottomPadding == 0.0) {
      return middle;
    } else {
      return new Padding(
        padding: new EdgeInsets.only(top: topPadding, bottom: bottomPadding),
        child: middle,
      );
    }
  }

}