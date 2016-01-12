// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _Page {
  _Page({this.label, this.color, this.icon});
  final String label;
  final Map<int, Color> color;
  final String icon;
  TabLabel get tabLabel => new TabLabel(text: label);
  bool get fabDefined => color != null && icon != null;
  Color get fabColor => color[400];
  Icon get fabIcon => new Icon(icon: icon);
  Key get fabKey => new ValueKey<Color>(fabColor);
}

List<_Page> _pages = <_Page>[
  new _Page(label: "Blue", color: Colors.indigo, icon: 'content/add'),
  new _Page(label: "Too", color: Colors.indigo, icon: 'content/add'),
  new _Page(label: "Eco", color: Colors.green, icon: 'content/create'),
  new _Page(label: "No"),
  new _Page(label: "Teal", color: Colors.teal, icon: 'content/add'),
  new _Page(label: "Red", color: Colors.red, icon: 'content/create')
];

class FabApp extends StatefulComponent {
  FabApp();

  FabAppState createState() => new FabAppState();
}

class FabAppState extends State<FabApp> {
  _Page selectedPage = _pages[0];
  void _handleTabSelection(_Page page) {
    setState(() {
      selectedPage = page;
    });
  }

  Widget buildTabView(_Page page) {
    return new Builder(
      builder: (BuildContext context) {
        final TextStyle textStyle = new TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 32.0,
          textAlign: TextAlign.center
        );

        return new Container(
          key: new ValueKey<String>(page.label),
          padding: const EdgeDims.TRBL(48.0, 48.0, 96.0, 48.0),
          child: new Card(
            child: new Center(
              child: new Text(page.label, style: textStyle)
            )
          )
        );
      }
    );
  }

  Widget build(BuildContext context) {
    return new TabBarSelection<_Page>(
      values: _pages,
      onChanged: _handleTabSelection,
      child: new Scaffold(
        toolBar: new ToolBar(
          elevation: 0,
          center: new Text('FAB Transition Demo'),
          tabBar: new TabBar<String>(
            labels: new Map.fromIterable(_pages, value: (_Page page) => page.tabLabel)
          )
        ),
        body: new TabBarView(children: _pages.map(buildTabView).toList()),
        floatingActionButton: !selectedPage.fabDefined ? null : new FloatingActionButton(
          key: selectedPage.fabKey,
          backgroundColor: selectedPage.fabColor,
          child: selectedPage.fabIcon
        )
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'FabApp',
    routes: {
      '/': (RouteArguments args) => new FabApp()
    }
  ));
}
