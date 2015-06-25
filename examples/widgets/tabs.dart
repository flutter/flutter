// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart';
import 'package:sky/theme/typography.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tabs.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';

class TabbedNavigatorApp extends App {
  static Iterable<String> items = const <String>["ONE", "TWO", "FREE", "FOUR"];
  final List<int> navigatorSelections = new List<int>.filled(items.length, 0);

  Widget buildTabNavigator(Iterable<TabLabel> labels, int navigatorIndex) {
    TabBar tabBar = new TabBar(
      labels: labels.toList(),
      selectedIndex: navigatorSelections[navigatorIndex],
      onChanged: (selectionIndex) {
        setState(() { 
          navigatorSelections[navigatorIndex] = selectionIndex;
        });
      }
    );

    return new Container(child: tabBar, margin: new EdgeDims.only(bottom: 16.0));
  }

  Widget build() {
    Iterable<TabLabel> textLabels = items
      .map((s) => new TabLabel(text: "ITEM " + s));

    Iterable<TabLabel> iconLabels = items
      .map((s) => new TabLabel(icon: 'action/search_white'));

    Iterable<TabLabel> textAndIconLabels = items
      .map((s) => new TabLabel(text: "ITEM " + s, icon: 'action/search_white'));

    var navigatorIndex = 0;
    Iterable<Widget> tabNavigators = [textLabels, iconLabels, textAndIconLabels]
      .map((labels) => buildTabNavigator(labels, navigatorIndex++));

    ToolBar toolbar = new ToolBar(
      center: new Text('Tabbed Navigator', style: white.title),
      backgroundColor: Blue[500]);

    return new Scaffold(
      toolbar: toolbar,
      body: new Material(
        child: new Center(child: new Block(tabNavigators.toList())),
        color: Grey[500]
      )
    );
  }
}

void main() {
  runApp(new TabbedNavigatorApp());
}
