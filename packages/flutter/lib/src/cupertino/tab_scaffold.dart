// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
/// tab index. The [tabBuilder] must be able to build the same number of
/// pages as there are [tabBar.items]. Inactive tabs will be moved [Offstage]
/// and their animations disabled.
///
/// Use [CupertinoTabView] as the content of each tab to support tabs with parallel
/// navigation state and history.
///
/// {@tool sample}
///
/// A sample code implementing a typical iOS information architecture with tabs.
///
/// ```dart
/// CupertinoTabScaffold(
///   tabBar: CupertinoTabBar(
///     items: <BottomNavigationBarItem> [
///       // ...
///     ],
///   ),
///   tabBuilder: (BuildContext context, int index) {
///     return CupertinoTabView(
///       builder: (BuildContext context) {
///         return CupertinoPageScaffold(
///           navigationBar: CupertinoNavigationBar(
///             middle: Text('Page 1 of tab $index'),
///           ),
///           child: Center(
///             child: CupertinoButton(
///               child: const Text('Next page'),
///               onPressed: () {
///                 Navigator.of(context).push(
///                   CupertinoPageRoute<void>(
///                     builder: (BuildContext context) {
///                       return CupertinoPageScaffold(
///                         navigationBar: CupertinoNavigationBar(
///                           middle: Text('Page 2 of tab $index'),
///                         ),
///                         child: Center(
///                           child: CupertinoButton(
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
/// {@end-tool}
///
/// To push a route above all tabs instead of inside the currently selected one
/// (such as when showing a dialog on top of this scaffold), use
/// `Navigator.of(rootNavigator: true)` from inside the [BuildContext] of a
/// [CupertinoTabView].
///
/// See also:
///
///  * [CupertinoTabBar], the bottom tab bar inserted in the scaffold.
///  * [CupertinoTabView], the typical root content of each tab that holds its own
///    [Navigator] stack.
///  * [CupertinoPageRoute], a route hosting modal pages with iOS style transitions.
///  * [CupertinoPageScaffold], typical contents of an iOS modal page implementing
///    layout with a navigation bar on top.
class CupertinoTabScaffold extends StatefulWidget {
  /// Creates a layout for applications with a tab bar at the bottom.
  ///
  /// The [tabBar], [tabBuilder] and [currentTabIndex] arguments must not be null.
  ///
  /// The [currentTabIndex] argument can be used to programmatically change the
  /// currently selected tab.
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
  /// Setting and changing [CupertinoTabBar.currentIndex] programmatically will
  /// change the currently selected tab item in the [tabBar] as well as change
  /// the currently focused tab from the [tabBuilder].

  /// If [CupertinoTabBar.onTap] is provided, it will still be called.
  /// [CupertinoTabScaffold] automatically also listen to the
  /// [CupertinoTabBar]'s `onTap` to change the [CupertinoTabBar]'s `currentIndex`
  /// and change the actively displayed tab in [CupertinoTabScaffold]'s own
  /// main content area.
  ///
  /// If translucent, the main content may slide behind it.
  /// Otherwise, the main content's bottom margin will be offset by its height.
  ///
  /// Must not be null.
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
  /// Content can slide under the [tabBar] when they're translucent.
  /// In that case, the child's [BuildContext]'s [MediaQuery] will have a
  /// bottom padding indicating the area of obstructing overlap from the
  /// [tabBar].
  ///
  /// Must not be null.
  final IndexedWidgetBuilder tabBuilder;

  @override
  _CupertinoTabScaffoldState createState() => _CupertinoTabScaffoldState();
}

class _CupertinoTabScaffoldState extends State<CupertinoTabScaffold> {
  int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.tabBar.currentIndex;
  }

  @override
  void didUpdateWidget(CupertinoTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabBar.currentIndex != oldWidget.tabBar.currentIndex) {
      _currentPage = widget.tabBar.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    Widget content = _TabSwitchingView(
      currentTabIndex: _currentPage,
      tabNumber: widget.tabBar.items.length,
      tabBuilder: widget.tabBuilder,
    );

    if (widget.tabBar != null) {
      final MediaQueryData existingMediaQuery = MediaQuery.of(context);

      // TODO(xster): Use real size after partial layout instead of preferred size.
      // https://github.com/flutter/flutter/issues/12912
      final double bottomPadding = widget.tabBar.preferredSize.height
          + existingMediaQuery.padding.bottom;

      // If tab bar opaque, directly stop the main content higher. If
      // translucent, let main content draw behind the tab bar but hint the
      // obstructed area.
      if (widget.tabBar.opaque) {
        content = Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: content,
        );
      } else {
        content = MediaQuery(
          data: existingMediaQuery.copyWith(
            padding: existingMediaQuery.padding.copyWith(
              bottom: bottomPadding,
            ),
          ),
          child: content,
        );
      }
    }

    // The main content being at the bottom is added to the stack first.
    stacked.add(content);

    if (widget.tabBar != null) {
      stacked.add(Align(
        alignment: Alignment.bottomCenter,
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

    return Stack(
      children: stacked,
    );
  }
}

/// A widget laying out multiple tabs with only one active tab being built
/// at a time and on stage. Off stage tabs' animations are stopped.
class _TabSwitchingView extends StatefulWidget {
  const _TabSwitchingView({
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
  _TabSwitchingViewState createState() => _TabSwitchingViewState();
}

class _TabSwitchingViewState extends State<_TabSwitchingView> {
  List<Widget> tabs;
  List<FocusScopeNode> tabFocusNodes;

  @override
  void initState() {
    super.initState();
    tabs = List<Widget>(widget.tabNumber);
    tabFocusNodes = List<FocusScopeNode>.generate(
      widget.tabNumber,
      (int index) => FocusScopeNode(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusActiveTab();
  }

  @override
  void didUpdateWidget(_TabSwitchingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focusActiveTab();
  }

  void _focusActiveTab() {
    FocusScope.of(context).setFirstFocus(tabFocusNodes[widget.currentTabIndex]);
  }

  @override
  void dispose() {
    for (FocusScopeNode focusScopeNode in tabFocusNodes) {
      focusScopeNode.detach();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(widget.tabNumber, (int index) {
        final bool active = index == widget.currentTabIndex;

        if (active || tabs[index] != null) {
          tabs[index] = widget.tabBuilder(context, index);
        }

        return Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: FocusScope(
              node: tabFocusNodes[index],
              child: tabs[index] ?? Container(),
            ),
          ),
        );
      }),
    );
  }
}
