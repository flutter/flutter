// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _explanatoryText =
  "When the Scaffold's floating action button changes, the new button fades and "
  'turns into view. In this demo, changing tabs can cause the app to be rebuilt '
  'with a FloatingActionButton that the Scaffold distinguishes from the others '
  'by its key.';

class _Page {
  _Page({ this.label, this.colors, this.icon });

  final String label;
  final MaterialColor colors;
  final IconData icon;

  Color get labelColor => colors != null ? colors.shade300 : Colors.grey.shade300;
  bool get fabDefined => colors != null && icon != null;
  Color get fabColor => colors.shade400;
  Icon get fabIcon => new Icon(icon);
  Key get fabKey => new ValueKey<Color>(fabColor);
}

final List<_Page> _allPages = <_Page>[
  new _Page(label: 'Blue', colors: Colors.indigo, icon: Icons.add),
  new _Page(label: 'Eco', colors: Colors.green, icon: Icons.create),
  new _Page(label: 'No'),
  new _Page(label: 'Teal', colors: Colors.teal, icon: Icons.add),
  new _Page(label: 'Red', colors: Colors.red, icon: Icons.create),
];

class TabsFabDemo extends StatefulWidget {
  static const String routeName = '/material/tabs-fab';

  @override
  _TabsFabDemoState createState() => new _TabsFabDemoState();
}

class _TabsFabDemoState extends State<TabsFabDemo> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  TabController _controller;
  _Page _selectedPage;

  @override
  void initState() {
    super.initState();
    _controller = new TabController(vsync: this, length: _allPages.length);
    _controller.addListener(_handleTabSelection);
    _selectedPage = _allPages[0];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedPage = _allPages[_controller.index];
    });
  }

  void _showExplanatoryText() {
    _scaffoldKey.currentState.showBottomSheet<Null>((BuildContext context) {
      return new Container(
        decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Theme.of(context).dividerColor))
        ),
        child: new Padding(
          padding: const EdgeInsets.all(32.0),
          child: new Text(_explanatoryText, style: Theme.of(context).textTheme.subhead)
        )
      );
    });
  }

  Widget buildTabView(_Page page) {
    return new Builder(
      builder: (BuildContext context) {
        return new Container(
          key: new ValueKey<String>(page.label),
          padding: const EdgeInsets.fromLTRB(48.0, 48.0, 48.0, 96.0),
          child: new Card(
            child: new Center(
              child: new Text(page.label,
                style: new TextStyle(
                  color: page.labelColor,
                  fontSize: 32.0
                ),
                textAlign: TextAlign.center
              )
            )
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('FAB per tab'),
        bottom: new TabBar(
          controller: _controller,
          tabs: _allPages.map((_Page page) => new Tab(text: page.label.toUpperCase())).toList(),
        )
      ),
      floatingActionButton: !_selectedPage.fabDefined ? null : new FloatingActionButton(
        key: _selectedPage.fabKey,
        tooltip: 'Show explanation',
        backgroundColor: _selectedPage.fabColor,
        child: _selectedPage.fabIcon,
        onPressed: _showExplanatoryText
      ),
      body: new TabBarView(
        controller: _controller,
        children: _allPages.map(buildTabView).toList()
      ),
    );
  }
}
