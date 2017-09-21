// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'bottom_tab_bar.dart';

/// Implements a tabbed iOS application's root layout and behavior structure.
///
/// The scaffold lays out the tab bar at the bottom and the content between or
/// behind the tab bar.
///
/// A [tabBar] and a [tabBuilder] are required. The [CupertinoTabScaffold]
/// will automatically listen to the provided [CupertinoTabBar]'s tap callbacks
/// to change the active tab.
///
/// Tabs' contents are built with the provided [tabBuilder] at the active
/// tab index. [tabBuilder] must be able to build the same number of
/// pages as the [tabBar.items.length]. Inactive tabs will be moved [Offstage]
/// and its animations disabled.
///
/// Use [CupertinoTabView] as the content of each tab to support tabs with parallel
/// navigation state and history.
///
/// ## Sample code
///
/// A sample code implementing a typical iOS information architecture with tabs.
///
/// ```dart
/// new CupertinoTabScaffold(
///   tabBar: new CupertinoTabBar(
///     items: <BottomNavigationBarItem> [
///       // ...
///     ],
///   ),
///   tabBuilder: (BuildContext context, int index) {
///     return new CupertinoTabView(
///       builder: (BuildContext context) {
///         return new CupertinoPageScaffold(
///           navigationBar: new CupertinoNavigationBar(
///             middle: new Text('Page 1 of tab $index'),
///           ),
///           child: new Center(
///             child: new CupertinoButton(
///               child: const Text('Next page'),
///               onPressed: () {
///                 Navigator.of(context).push(
///                   new CupertinoPageRoute<Null>(
///                     builder: (BuildContext context) {
///                       return new CupertinoPageScaffold(
///                         navigationBar: new CupertinoNavigationBar(
///                           middle: new Text('Page 2 of tab $index'),
///                         ),
///                         child: new Center(
///                           child: new CupertinoButton(
///                             child: const Text('Back'),
///                             onPressed: () { Navigator.of(context).pop(); },
///                           ),
///                         ),
///                       );
///                     },
///                   ),
///                 );
///               },
///             ),
///           ),
///         );
///       },
///     );
///   },
/// )
/// ```
///
/// See also:
///
///  * [CupertinoTabBar] bottom tab bars inserted in the scaffold.
///  * [CupertinoTabView] a typical root content of each tap that holds its own
///    [Navigator] stack.
///  * [CupertinoPageRoute] a route hosting modal pages with iOS style transitions.
///  * [CupertinoPageScaffold] typical contents of an iOS modal page implementing
///    layout with a navigation bar on top.
class CupertinoTabScaffold extends StatefulWidget {
  const CupertinoTabScaffold({
    Key key,
    @required this.tabBar,
    @required this.tabBuilder,
  }) : assert(tabBar != null),
       assert(tabBuilder != null),
       super(key: key);

  /// The [tabBar] is a [CupertinoTabBar] drawn at the bottom of the screen
  /// that lets the user switch between different tabs in the main content area
  /// when present.
  ///
  /// When provided, [CupertinoTabBar.currentIndex] will be ignored and will
  /// be managed by the [CupertinoTabScaffold] to show the currently selected page
  /// as the active item index. If [CupertinoTabBar.onTap] is provided, it will
  /// still be called. [CupertinoTabScaffold] automatically also listen to the
  /// [CupertinoTabBar]'s `onTap` to change the [CupertinoTabBar]'s `currentIndex`
  /// and change the actively displayed tab in [CupertinoTabScaffold]'s own
  /// main content area.
  ///
  /// If translucent, the main content may slide behind it.
  /// Otherwise, the main content's bottom margin will be offset by its height.
  final CupertinoTabBar tabBar;

  /// An [IndexedWidgetBuilder] that's called when tabs become active.
  ///
  /// The widgets built by [IndexedWidgetBuilder] is typically a [CupertinoTabView]
  /// in order to achieve the parallel hierarchies information architecture seen
  /// on iOS apps with tab bars.
  ///
  /// When the tab becomes inactive, its content is still cached in the widget
  /// tree [Offstage] and its animations disabled.
  ///
  /// Content can slide under the [tabBar] when it's translucent.
  final IndexedWidgetBuilder tabBuilder;

  @override
  _CupertinoTabScaffoldState createState() => new _CupertinoTabScaffoldState();
}

class _CupertinoTabScaffoldState extends State<CupertinoTabScaffold> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    // The main content being at the bottom is added to the stack first.
    stacked.add(
      new Padding(
        padding: new EdgeInsets.only(bottom: widget.tabBar.opaque ? widget.tabBar.preferredSize.height : 0.0),
        child: new _TabView(
          currentTabIndex: _currentPage,
          tabNumber: widget.tabBar.items.length,
          tabBuilder: widget.tabBuilder,
        )
      ),
    );

    if (widget.tabBar != null) {
      stacked.add(new Align(
        alignment: FractionalOffset.bottomCenter,
        // Override the tab bar's currentIndex to the current tab and hook in
        // our own listener to update the _currentPage on top of a possibly user
        // provided callback.
        child: widget.tabBar.copyWith(
          currentIndex: _currentPage,
          onTap: (int newIndex) {
            setState(() {
              _currentPage = newIndex;
            });
            // Chain the user's original callback.
            if (widget.tabBar.onTap != null)
              widget.tabBar.onTap(newIndex);
          }
        ),
      ));
    }

    return new Stack(
      children: stacked,
    );
  }
}

/// An widget laying out multiple tabs with only one active tab being built
/// at a time and on stage. Off stage tabs' animations are stopped.
class _TabView extends StatefulWidget {
  _TabView({
    @required this.currentTabIndex,
    @required this.tabNumber,
    @required this.tabBuilder,
  }) : assert(currentTabIndex != null),
       assert(tabNumber != null && tabNumber > 0),
       assert(tabBuilder != null);

  final int currentTabIndex;
  final int tabNumber;
  final IndexedWidgetBuilder tabBuilder;

  @override
  _TabViewState createState() => new _TabViewState();
}

class _TabViewState extends State<_TabView> {
  List<Widget> tabs;

  @override
  void initState() {
    super.initState();
    tabs = new List<Widget>(widget.tabNumber);
  }

  @override
  Widget build(BuildContext context) {
    return new Stack(
      fit: StackFit.expand,
      children: new List<Widget>.generate(widget.tabNumber, (int index) {
        final bool active = index == widget.currentTabIndex;

        if (active || tabs[index] != null)
          tabs[index] = widget.tabBuilder(context, index);

        return new Offstage(
          offstage: !active,
          child: new TickerMode(
            enabled: active,
            child: tabs[index] ?? new Container(),
          ),
        );
      }),
    );
  }
}
