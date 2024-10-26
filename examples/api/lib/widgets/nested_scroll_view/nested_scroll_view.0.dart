// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [NestedScrollView].

void main() => runApp(const NestedScrollViewExampleApp());

class NestedScrollViewExampleApp extends StatelessWidget {
  const NestedScrollViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NestedScrollViewExample(),
    );
  }
}

class NestedScrollViewExample extends StatefulWidget {
  const NestedScrollViewExample({super.key});

  @override
  State<NestedScrollViewExample> createState() =>
      NestedScrollViewExampleState();
}

class NestedScrollViewExampleState extends State<NestedScrollViewExample>
    with TickerProviderStateMixin {
  final List<String> _tabs = <String>['Tab 1', 'Tab 2'];

  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: _selectedIndex,
      vsync: this,
      length: _tabs.length,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          // These are the slivers that show up in the "outer" scroll view.
          return <Widget>[
            SliverOverlapAbsorber(
              // This widget takes the overlapping behavior of the SliverAppBar,
              // and redirects it to the SliverOverlapInjector below. If it is
              // missing, then it is possible for the nested "inner" scroll view
              // below to end up under the SliverAppBar even when the inner
              // scroll view thinks it has not been scrolled.
              // This is not necessary if the "headerSliverBuilder" only builds
              // widgets that do not overlap the next sliver.
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                title: const Text('Books'), // This is the title in the app bar.
                pinned: true,
                expandedHeight: 150.0,
                // The "forceElevated" property causes the SliverAppBar to show
                // a shadow. The "innerBoxIsScrolled" parameter is true when the
                // inner scroll view is scrolled beyond its "zero" point, i.e.
                // when it appears to be scrolled below the SliverAppBar.
                // Without this, there are cases where the shadow would appear
                // or not appear inappropriately, because the SliverAppBar is
                // not actually aware of the precise position of the inner
                // scroll views.
                forceElevated: innerBoxIsScrolled,
                bottom: TabBar(
                  controller: _tabController,
                  // These are the widgets to put in each tab in the tab bar.
                  tabs: <Widget>[
                    for (final String name in _tabs) Tab(text: name),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          // These are the contents of the tab views, below the tabs.
          children: <Widget>[
            for (final (int index, String name) in _tabs.indexed)
              TabViewContentExample(
                name: name,
                isSelected: index == _selectedIndex,
              ),
          ],
        ),
      ),
    );
  }
}

class TabViewContentExample extends StatefulWidget {
  const TabViewContentExample({
    required this.name,
    required this.isSelected,
    super.key,
  });

  final String name;
  final bool isSelected;

  @override
  State<TabViewContentExample> createState() => TabViewContentExampleState();
}

class TabViewContentExampleState extends State<TabViewContentExample>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        // This Builder is needed to provide a BuildContext that is "inside"
        // the NestedScrollView, so that sliverOverlapAbsorberHandleFor() can
        // find the NestedScrollView.
        builder: (BuildContext context) {
          final ScrollController scrollController = PrimaryScrollController.of(context);
          return CustomScrollView(
            // When this inner scroll view is associated with the
            // PrimaryScrollController, the NestedScrollView can control it.
            // If the "controller" property is set, then this scroll view will
            // not be associated with the NestedScrollView.
            // The PageStorageKey should be unique to this ScrollView;
            // it allows the list to remember its scroll position when
            // the tab view is not on the screen.
            controller:
                widget.isSelected ? scrollController : _scrollController,
            key: PageStorageKey<String>(widget.name),
            slivers: <Widget>[
              SliverOverlapInjector(
                // This is the flip side of the SliverOverlapAbsorber above.
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                // In this example, the inner scroll view has fixed-height list
                // items, hence the use of SliverFixedExtentList. However, one
                // could use any sliver widget here, e.g. SliverList or
                // SliverGrid.
                sliver: SliverFixedExtentList(
                  // The items in this example are fixed to 48 pixels high.
                  // This matches the Material Design spec for ListTile widgets.
                  itemExtent: 48.0,
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      // This builder is called for each child.
                      // In this example, we just number each list item.
                      return ListTile(
                        title: Text('Item $index'),
                      );
                    },
                    // The childCount of the SliverChildBuilderDelegate
                    // specifies how many children this inner list has.
                    // In this example, each tab has a list of exactly 30 items,
                    // but this is arbitrary.
                    childCount: 30,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
