// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum TabsDemoStyle {
  iconsAndText,
  iconsOnly,
  textOnly
}

class _Page {
  _Page({ this.icon, this.text });
  final IconData icon;
  final String text;
}

final List<_Page> _allPages = <_Page>[
  new _Page(icon: Icons.event, text: 'EVENT'),
  new _Page(icon: Icons.home, text: 'HOME'),
  new _Page(icon: Icons.android, text: 'ANDROID'),
  new _Page(icon: Icons.alarm, text: 'ALARM'),
  new _Page(icon: Icons.face, text: 'FACE'),
  new _Page(icon: Icons.language, text: 'LANGAUGE'),
];

class ScrollableTabsDemo extends StatefulWidget {
  static const String routeName = '/material/scrollable-tabs';

  @override
  ScrollableTabsDemoState createState() => new ScrollableTabsDemoState();
}

class ScrollableTabsDemoState extends State<ScrollableTabsDemo> with SingleTickerProviderStateMixin {
  TabController _controller;
  TabsDemoStyle _demoStyle = TabsDemoStyle.iconsAndText;

  @override
  void initState() {
    super.initState();
    _controller = new TabController(vsync: this, length: _allPages.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void changeDemoStyle(TabsDemoStyle style) {
    setState(() {
      _demoStyle = style;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Theme.of(context).accentColor;
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Scrollable tabs'),
        actions: <Widget>[
          new PopupMenuButton<TabsDemoStyle>(
            onSelected: changeDemoStyle,
            itemBuilder: (BuildContext context) => <PopupMenuItem<TabsDemoStyle>>[
              const PopupMenuItem<TabsDemoStyle>(
                value: TabsDemoStyle.iconsAndText,
                child: const Text('Icons and text')
              ),
              const PopupMenuItem<TabsDemoStyle>(
                value: TabsDemoStyle.iconsOnly,
                child: const Text('Icons only')
              ),
              const PopupMenuItem<TabsDemoStyle>(
                value: TabsDemoStyle.textOnly,
                child: const Text('Text only')
              ),
            ],
          ),
        ],
        bottom: new TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: _allPages.map((_Page page) {
            switch(_demoStyle) {
              case TabsDemoStyle.iconsAndText:
                return new Tab(text: page.text, icon: new Icon(page.icon));
              case TabsDemoStyle.iconsOnly:
                return new Tab(icon: new Icon(page.icon));
              case TabsDemoStyle.textOnly:
                return new Tab(text: page.text);
            }
          }).toList(),
        ),
      ),
      body: new TabBarView(
        controller: _controller,
        children: _allPages.map((_Page page) {
          return new Container(
            key: new ObjectKey(page.icon),
            padding: const EdgeInsets.all(12.0),
            child:new Card(
              child: new Center(
                child: new Icon(
                  page.icon,
                  color: iconColor,
                  size: 128.0,
                ),
              ),
            ),
          );
        }).toList()
      ),
    );
  }
}
