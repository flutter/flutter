// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _Page {
  _Page({ this.label });

  final GlobalKey<ScrollableState<Scrollable>> key = new GlobalKey<ScrollableState<Scrollable>>();
  final String label;
}

final List<_Page> _pages = <_Page>[
  new _Page(label: 'ONE'),
  new _Page(label: 'TWO'),
  new _Page(label: 'FREE'),
  new _Page(label: 'FOUR')
];

class TabsDemo extends StatefulWidget {
  static const String routeName = '/tabs';

  @override
  TabsDemoState createState() => new TabsDemoState();
}

class TabsDemoState extends State<TabsDemo> {
  _Page _selectedPage;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedPage = _pages[0];
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return new TabBarSelection<_Page>(
      values: _pages,
      onChanged: (_Page value) {
        setState(() {
          _selectedPage = value;
          _selectedPage.key.currentState.scrollTo(_scrollOffset);
        });
      },
      child: new Scaffold(
        appBarBehavior: AppBarBehavior.under,
        appBar: new AppBar(
          title: new Text('Tabs and scrolling'),
          tabBar: new TabBar<_Page>(
            labels: new Map<_Page, TabLabel>.fromIterable(_pages, value: (_Page page) {
              return new TabLabel(text: page.label);
            })
          )
        ),
        body: new TabBarView<_Page>(
          children: _pages.map((_Page page) {
            return new ClampOverscrolls(
              value: true,
              child: new Block(
                padding: new EdgeInsets.only(top: kTextTabBarHeight + kToolBarHeight + statusBarHeight),
                scrollableKey: page.key,
                onScroll: (double value) { _scrollOffset = value; },
                children: new List<Widget>.generate(6, (int i) {
                  return new Container(
                    padding: const EdgeInsets.all(8.0),
                    height: 192.0,
                    child: new Card(
                      child: new Center(
                        child: new Text('Tab $page.label, item $i')
                      )
                    )
                  );
                })
              )
            );
          }).toList()
        )
      )
    );
  }
}
