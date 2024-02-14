// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/demos/material/material_demo_types.dart';

class TabsDemo extends StatelessWidget {
  const TabsDemo({super.key, required this.type});

  final TabsDemoType type;

  @override
  Widget build(BuildContext context) {
    Widget tabs;
    switch (type) {
      case TabsDemoType.scrollable:
        tabs = _TabsScrollableDemo();
        break;
      case TabsDemoType.nonScrollable:
        tabs = _TabsNonScrollableDemo();
    }
    return tabs;
  }
}

// BEGIN tabsScrollableDemo

class _TabsScrollableDemo extends StatefulWidget {
  @override
  __TabsScrollableDemoState createState() => __TabsScrollableDemoState();
}

class __TabsScrollableDemoState extends State<_TabsScrollableDemo>
    with SingleTickerProviderStateMixin, RestorationMixin {
  TabController? _tabController;

  final RestorableInt tabIndex = RestorableInt(0);

  @override
  String get restorationId => 'tab_scrollable_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(tabIndex, 'tab_index');
    _tabController!.index = tabIndex.value;
  }

  @override
  void initState() {
    _tabController = TabController(
      initialIndex: 0,
      length: 12,
      vsync: this,
    );
    _tabController!.addListener(() {
      // When the tab controller's value is updated, make sure to update the
      // tab index value, which is state restorable.
      setState(() {
        tabIndex.value = _tabController!.index;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    final tabs = [
      localizations.colorsRed,
      localizations.colorsOrange,
      localizations.colorsGreen,
      localizations.colorsBlue,
      localizations.colorsIndigo,
      localizations.colorsPurple,
      localizations.colorsRed,
      localizations.colorsOrange,
      localizations.colorsGreen,
      localizations.colorsBlue,
      localizations.colorsIndigo,
      localizations.colorsPurple,
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.demoTabsScrollingTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final tab in tabs) Tab(text: tab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final tab in tabs)
            Center(
              child: Text(tab),
            ),
        ],
      ),
    );
  }
}

// END

// BEGIN tabsNonScrollableDemo

class _TabsNonScrollableDemo extends StatefulWidget {
  @override
  __TabsNonScrollableDemoState createState() => __TabsNonScrollableDemoState();
}

class __TabsNonScrollableDemoState extends State<_TabsNonScrollableDemo>
    with SingleTickerProviderStateMixin, RestorationMixin {
  late TabController _tabController;

  final RestorableInt tabIndex = RestorableInt(0);

  @override
  String get restorationId => 'tab_non_scrollable_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(tabIndex, 'tab_index');
    _tabController.index = tabIndex.value;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 3,
      vsync: this,
    );
    _tabController.addListener(() {
      // When the tab controller's value is updated, make sure to update the
      // tab index value, which is state restorable.
      setState(() {
        tabIndex.value = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = GalleryLocalizations.of(context)!;
    final tabs = [
      localizations.colorsRed,
      localizations.colorsOrange,
      localizations.colorsGreen,
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          localizations.demoTabsNonScrollingTitle,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [
            for (final tab in tabs) Tab(text: tab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final tab in tabs)
            Center(
              child: Text(tab),
            ),
        ],
      ),
    );
  }
}

// END
