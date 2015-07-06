// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tabs.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

class TabbedNavigatorApp extends App {
  // The index of the selected tab for each of the TabNavigators constructed below.
  List<int> selectedIndices = new List<int>.filled(5, 0);

  TabNavigator _buildTabNavigator(int n, List<TabNavigatorView> views, {scrollable: false}) {
    return new TabNavigator(
      views: views,
      selectedIndex: selectedIndices[n],
      scrollable: scrollable,
      onChanged: (tabIndex) {
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
          builder: () => _buildContent(text)
        );
      });
    return _buildTabNavigator(n, views.toList());
  }

  TabNavigator _buildIconLabelsTabNavigator(int n) {
    Iterable<TabNavigatorView> views = ["event", "home", "android", "alarm", "face", "language"]
      .map((icon_name) {
        return new TabNavigatorView(
          label: new TabLabel(icon: "action/${icon_name}_white"),
          builder: () => _buildContent(icon_name)
        );
      });
    return _buildTabNavigator(n, views.toList());
  }

  TabNavigator _buildTextAndIconLabelsTabNavigator(int n) {
    List<TabNavigatorView> views = <TabNavigatorView>[
      new TabNavigatorView(
        label: const TabLabel(text: 'STOCKS', icon: 'action/list_white'),
        builder: () => _buildContent("Stocks")
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'PORTFOLIO', icon: 'action/account_circle_white'),
        builder: () => _buildContent("Portfolio")
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'SUMMARY', icon: 'action/assessment_white'),
        builder: () => _buildContent("Summary")
      )
    ];
    return _buildTabNavigator(n, views);
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
          builder: () => _buildContent(text)
        );
      });
    return _buildTabNavigator(n, views.toList(), scrollable: true);
  }


  Container _buildCard(TabNavigator tabNavigator) {
    return new Container(
     child: new Card(child: new Padding(child: tabNavigator, padding: const EdgeDims.all(8.0))),
     padding: const EdgeDims.all(12.0),
     decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50])
    );
  }

  Widget build() {
    List<TabNavigatorView> views = <TabNavigatorView>[
      new TabNavigatorView(
        label: const TabLabel(text: 'TEXT'),
        builder: () => _buildCard(_buildTextLabelsTabNavigator(0))
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'ICONS'),
        builder: () => _buildCard(_buildIconLabelsTabNavigator(1))
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'BOTH'),
        builder: () => _buildCard(_buildTextAndIconLabelsTabNavigator(2))
      ),
      new TabNavigatorView(
        label: const TabLabel(text: 'SCROLL'),
        builder: () => _buildCard(_buildScrollableTabNavigator(3))
      )
    ];

    TabNavigator tabNavigator = _buildTabNavigator(4, views);
    assert(selectedIndices.length == 5);

    ToolBar toolbar = new ToolBar(
      center: new Text('Tabbed Navigator', style: typography.white.title)
    );

    return new Scaffold(
      toolbar: toolbar,
      body: tabNavigator
    );
  }
}

void main() {
  runApp(new TabbedNavigatorApp());
}
