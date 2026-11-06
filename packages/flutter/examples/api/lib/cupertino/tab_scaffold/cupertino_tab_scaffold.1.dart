// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoTabScaffold] repeat-tap tab behavior.

void main() => runApp(const RepeatTapTabScaffoldApp());

class RepeatTapTabScaffoldApp extends StatelessWidget {
  const RepeatTapTabScaffoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: RepeatTapTabScaffoldExample(),
    );
  }
}

class RepeatTapTabScaffoldExample extends StatefulWidget {
  const RepeatTapTabScaffoldExample({super.key});

  @override
  State<RepeatTapTabScaffoldExample> createState() =>
      _RepeatTapTabScaffoldExampleState();
}

class _RepeatTapTabScaffoldExampleState
    extends State<RepeatTapTabScaffoldExample> {
  final CupertinoTabController _tabController = CupertinoTabController();

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      <GlobalKey<NavigatorState>>[
        GlobalKey<NavigatorState>(),
        GlobalKey<NavigatorState>(),
      ];

  final List<ScrollController> _scrollControllers = <ScrollController>[
    ScrollController(),
    ScrollController(),
  ];

  @override
  void dispose() {
    _tabController.dispose();
    for (final ScrollController controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    // If the active tab was re-tapped, perform iOS-idiomatic repeat-tap actions.
    if (index == _tabController.index) {
      final NavigatorState? currentNavigator =
          _navigatorKeys[index].currentState;
      if (currentNavigator != null && currentNavigator.canPop()) {
        // Pop back to the root page of this tab.
        currentNavigator.popUntil((Route<dynamic> route) => route.isFirst);
      } else if (_scrollControllers[index].hasClients) {
        // Already at root; smoothly scroll back to top.
        _scrollControllers[index].animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        onTap: _onTabTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          navigatorKey: _navigatorKeys[index],
          builder: (BuildContext context) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text('Tab ${index == 0 ? "Home" : "Search"}'),
              ),
              child: SafeArea(
                child: ListView.builder(
                  controller: _scrollControllers[index],
                  itemCount: 50,
                  itemBuilder: (BuildContext context, int itemIndex) {
                    if (itemIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CupertinoButton.filled(
                          child: const Text('Push Sub-Page'),
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                builder: (BuildContext context) {
                                  return CupertinoPageScaffold(
                                    navigationBar: const CupertinoNavigationBar(
                                      middle: Text('Sub-Page'),
                                    ),
                                    child: const Center(
                                      child: Text('Deep Route Content'),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return CupertinoListTile(title: Text('Item $itemIndex'));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
