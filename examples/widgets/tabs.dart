// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class TabbedNavigatorApp extends StatefulComponent {
  TabbedNavigatorAppState createState() => new TabbedNavigatorAppState();
}

class TabbedNavigatorAppState extends State<TabbedNavigatorApp> {
  // The index of the selected tab for each of the TabNavigators constructed below.
  List<int> selectedIndices = new List<int>.filled(5, 0);

  TabNavigator _buildTabNavigator(int n, List<TabNavigatorView> views, Key key, {isScrollable: false}) {
    return new TabNavigator(
      key: key,
      views: views,
      selectedIndex: selectedIndices[n],
      isScrollable: isScrollable,
      onChanged: (int tabIndex) {
        setState(() { selectedIndices[n] = tabIndex; } );
      }
    );
  }

  Widget _buildContent(String label) {
    return new Center(
      child: new Text(label, style: const TextStyle(fontSize: 48.0, fontWeight: FontWeight.w800))
    );
  }

  TabNavigator _buildTextLabelsTabNavigator(int n) {
    Iterable<TabNavigatorView> views = ["ONE", "TWO", "FREE", "FOUR"]
      .map((text) {
        return new TabNavigatorView(
          label: new TabLabel(text: text),
          builder: (BuildContext context) => _buildContent(text)
        );
      });
    return _buildTabNavigator(n, views.toList(), const ValueKey<String>('textLabelsTabNavigator'));
  }

  TabNavigator _buildIconLabelsTabNavigator(int n) {
    Iterable<TabNavigatorView> views = ["event", "home", "android", "alarm", "face", "language"]
      .map((icon_name) {
        return new TabNavigatorView(
          label: new TabLabel(icon: "action/$icon_name"),
          builder: (BuildContext context) => _buildContent(icon_name)
        );
      });
    return _buildTabNavigator(n, views.toList(), const ValueKey<String>('iconLabelsTabNavigator'));
  }

  TabNavigator _buildTextAndIconLabelsTabNavigator(int n) {
    List<TabNavigatorView> views = <TabNavigatorView>[
      new TabNavigatorView(
        label: const TabLabel(text: 'STOCKS', icon: 'action/list'),
        builder: (BuildContext context) => _buildContent("Stocks")
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'PORTFOLIO', icon: 'action/account_circle'),
        builder: (BuildContext context) => _buildContent("Portfolio")
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'SUMMARY', icon: 'action/assessment'),
        builder: (BuildContext context) => _buildContent("Summary")
      )
    ];
    return _buildTabNavigator(n, views, const ValueKey<String>('textAndIconLabelsTabNavigator'));
  }

  TabNavigator _buildScrollableTabNavigator(int n) {
    Iterable<TabNavigatorView> views = [
      "MIN WIDTH",
      "THIS TAB LABEL IS SO WIDE THAT IT OCCUPIES TWO LINES",
      "THIS TAB IS PRETTY WIDE TOO",
      "MORE",
      "TABS",
      "TO",
      "STRETCH",
      "OUT",
      "THE",
      "TAB BAR"
      ]
      .map((text) {
        return new TabNavigatorView(
          label: new TabLabel(text: text),
          builder: (BuildContext context) => _buildContent(text)
        );
      });
    return _buildTabNavigator(n, views.toList(), const ValueKey<String>('scrollableTabNavigator'), isScrollable: true);
  }


  Container _buildCard(BuildContext context, TabNavigator tabNavigator) {
    return new Container(
      padding: const EdgeDims.all(12.0),
      child: new Card(child: new Padding(child: tabNavigator, padding: const EdgeDims.all(8.0)))
    );
  }

  Widget build(BuildContext context) {
    List<TabNavigatorView> views = <TabNavigatorView>[
      new TabNavigatorView(
        label: const TabLabel(text: 'TEXT'),
        builder: (BuildContext context) => _buildCard(context, _buildTextLabelsTabNavigator(0))
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'ICONS'),
        builder: (BuildContext context) => _buildCard(context, _buildIconLabelsTabNavigator(1))
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'BOTH'),
        builder: (BuildContext context) => _buildCard(context, _buildTextAndIconLabelsTabNavigator(2))
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'SCROLL'),
        builder: (BuildContext context) => _buildCard(context, _buildScrollableTabNavigator(3))
      )
    ];

    TabNavigator tabNavigator = _buildTabNavigator(4, views, const ValueKey<String>('tabs'));
    assert(selectedIndices.length == 5);

    ToolBar toolbar = new ToolBar(
      center: new Text('Tabbed Navigator', style: Typography.white.title)
    );

    return new Scaffold(
      toolBar: toolbar,
      body: tabNavigator
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Tabs',
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new TabbedNavigatorApp(),
    }
  ));
}
