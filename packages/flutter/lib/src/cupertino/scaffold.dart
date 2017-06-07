// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'bottom_tab_bar.dart';
import 'nav_bar.dart';

/// Implements the basic iOS application's layout and behavior structure.
///
/// The scaffold lays out the navigation bar on top, the tab bar at the bottom
/// and tabbed or untabbed content between or behind the bars.
///
/// For tabbed scaffolds, the tab's active item and the actively showing tab
/// in the content area are automatically connected.
// TODO(xster): describe navigator handlings.
// TODO(xster): add an example.
class CupertinoScaffold extends StatefulWidget {
  /// Construct a [CupertinoScaffold] without tabs.
  // TODO(xster): document that page transitions will happen behind the navigation
  // bar.
  const CupertinoScaffold({
    Key key,
    this.navigationBar,
    @required this.child,
  }) : tabBar = null,
       rootPageBuilder = null,
       super(key: key);

  /// Construct a [CupertinoScaffold] with tabs. A [tabBar] and a [rootPageBuilder]
  /// are required. The [CupertinoScaffold] will automatically listen to the
  /// provide [CupertinoTabBar]'s tap callbacks to change the active tab.
  ///
  /// Tabs' contents is built with the provided [rootPageBuilder] at the active
  /// tab index.
  const CupertinoScaffold.tabbed({
    Key key,
    this.navigationBar,
    @required this.tabBar,
    @required this.rootPageBuilder,
  }) : assert(tabBar != null),
       assert(rootPageBuilder != null),
       child = null,
       super(key: key);

  /// The [navigationBar], typically a [CupertinoNavigationBar] is drawn at the
  /// top of the screen.
  ///
  /// If translucent, the main content may slide behind it.
  /// Otherwise, the main content's top margin will be offset by its height.
  // TODO(xster): document its page transition animation when ready
  final PreferredSizeWidget navigationBar;

  /// The [tabBar] is a [CupertinoTabBar] drawn at the bottom of the screen
  /// that lets the user switch between different tabs in the main content area
  /// when present.
  ///
  /// When provided, [CupertinoTabBar.currentIndex] will be ignored and and will
  /// be managed by the [CupertinoScaffold] to show the currently selected page
  /// as the active index. [CupertinoTabBar.onTap] will still be called but
  /// chained after an automatic handler from [CupertinoScaffold] to change
  /// the current tab in the main content area.
  ///
  /// If translucent, the main content may slide behind it.
  /// Otherwise, the main content's bottom margin will be offset by its height.
  final CupertinoTabBar tabBar;

  /// An [IndexedWidgetBuilder] that's called when tabs become active. Used
  /// when a tabbed scaffold is constructed via the [.tabbed] constructor.
  ///
  /// Content can slide under the [navigationBar] or the [tabBar] when they're
  /// translucent.
  final IndexedWidgetBuilder rootPageBuilder;

  /// Widget to show in the main content area when the scaffold is used without
  /// tabs.
  ///
  /// Content can slide under the [navigationBar] or the [tabBar] when they're
  /// translucent.
  final Widget child;

  @override
  _CupertinoScaffoldState createState() => new _CupertinoScaffoldState();
}

class _CupertinoScaffoldState extends State<CupertinoScaffold> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    // The main content being at the bottom is added to the stack first.
    if (widget.child != null) {
      stacked.add(_padMiddle(widget.child));
    } else if (widget.rootPageBuilder != null) {
      stacked.add(_padMiddle(
        new IndexedStack(
          index: _currentPage,
          children: new List<Widget>.generate(
            widget.tabBar.items.length,
            (int index) {
              return new Builder(
                builder: (BuildContext context) {
                  return widget.rootPageBuilder(context, index);
                },
              );
            }
          ),
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
      stacked.add(new Align(
        alignment: FractionalOffset.bottomCenter,
        child: widget.tabBar.clone(
          withCurrentIndex: _currentPage,
          withOnTap: (int newIndex) {
            setState(() { _currentPage = newIndex; });
          },
        ),
      ));
    }

    return new Stack(
      children: stacked,
    );
  }

  Widget _padMiddle(Widget middle) {
    double topPadding = MediaQuery.of(context).padding.top;
    if (widget.navigationBar is CupertinoNavigationBar) {
      final CupertinoNavigationBar top = widget.navigationBar;
      if (top.opaque)
        topPadding += top.preferredSize.height;
    }

    double bottomPadding = 0.0;
    if (widget.tabBar?.opaque ?? false)
      bottomPadding = widget.tabBar.preferredSize.height;

    return new Padding(
      padding: new EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: middle,
    );
  }

}