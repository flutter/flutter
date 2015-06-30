// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tabs.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

class TabbedNavigatorApp extends App {
  int selectedIndex = 0;

  Widget _buildContent(String label) {
    return new Center(
      child: new Text(label, style: const TextStyle(fontSize: 48.0, fontWeight: FontWeight.w800))
    );
  }

  Widget build() {
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

    TabNavigator tabNavigator = new TabNavigator(
      views: views,
      selectedIndex: selectedIndex,
      onChanged: (tabIndex) {
        setState(() { selectedIndex = tabIndex; } );
      }
    );

    ToolBar toolbar = new ToolBar(
      center: new Text('Tabbed Navigator', style: typography.white.title)
    );

    return new Scaffold(
      toolbar: toolbar,
      body: new Material(
        color: colors.Grey[50],
        child: tabNavigator
      )
    );
  }
}

void main() {
  runApp(new TabbedNavigatorApp());
}
