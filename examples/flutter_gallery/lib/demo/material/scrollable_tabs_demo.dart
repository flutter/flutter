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
  const _Page({ this.icon, this.text });
  final IconData icon;
  final String text;
}

const List<_Page> _allPages = <_Page>[
  _Page(icon: Icons.grade, text: 'TRIUMPH'),
  _Page(icon: Icons.playlist_add, text: 'NOTE'),
  _Page(icon: Icons.check_circle, text: 'SUCCESS'),
  _Page(icon: Icons.question_answer, text: 'OVERSTATE'),
  _Page(icon: Icons.sentiment_very_satisfied, text: 'SATISFACTION'),
  _Page(icon: Icons.camera, text: 'APERTURE'),
  _Page(icon: Icons.assignment_late, text: 'WE MUST'),
  _Page(icon: Icons.assignment_turned_in, text: 'WE CAN'),
  _Page(icon: Icons.group, text: 'ALL'),
  _Page(icon: Icons.block, text: 'EXCEPT'),
  _Page(icon: Icons.sentiment_very_dissatisfied, text: 'CRYING'),
  _Page(icon: Icons.error, text: 'MISTAKE'),
  _Page(icon: Icons.loop, text: 'TRYING'),
  _Page(icon: Icons.cake, text: 'CAKE'),
];

class ScrollableTabsDemo extends StatefulWidget {
  static const String routeName = '/material/scrollable-tabs';

  @override
  ScrollableTabsDemoState createState() => new ScrollableTabsDemoState();
}

class ScrollableTabsDemoState extends State<ScrollableTabsDemo> with SingleTickerProviderStateMixin {
  TabController _controller;
  TabsDemoStyle _demoStyle = TabsDemoStyle.iconsAndText;
  bool _customIndicator = false;

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

  Decoration getIndicator() {
    if (!_customIndicator)
      return const UnderlineTabIndicator();

    switch(_demoStyle) {
      case TabsDemoStyle.iconsAndText:
        return new ShapeDecoration(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            side: BorderSide(
              color: Colors.white24,
              width: 2.0,
            ),
          ) + const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            side: BorderSide(
              color: Colors.transparent,
              width: 4.0,
            ),
          ),
        );

      case TabsDemoStyle.iconsOnly:
        return new ShapeDecoration(
          shape: const CircleBorder(
            side: BorderSide(
              color: Colors.white24,
              width: 4.0,
            ),
          ) + const CircleBorder(
            side: BorderSide(
              color: Colors.transparent,
              width: 4.0,
            ),
          ),
        );

      case TabsDemoStyle.textOnly:
        return new ShapeDecoration(
          shape: const StadiumBorder(
            side: BorderSide(
              color: Colors.white24,
              width: 2.0,
            ),
          ) + const StadiumBorder(
            side: BorderSide(
              color: Colors.transparent,
              width: 4.0,
            ),
          ),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Theme.of(context).accentColor;
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Scrollable tabs'),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.sentiment_very_satisfied),
            onPressed: () {
              setState(() {
                _customIndicator = !_customIndicator;
              });
            },
          ),
          new PopupMenuButton<TabsDemoStyle>(
            onSelected: changeDemoStyle,
            itemBuilder: (BuildContext context) => <PopupMenuItem<TabsDemoStyle>>[
              const PopupMenuItem<TabsDemoStyle>(
                value: TabsDemoStyle.iconsAndText,
                child: Text('Icons and text')
              ),
              const PopupMenuItem<TabsDemoStyle>(
                value: TabsDemoStyle.iconsOnly,
                child: Text('Icons only')
              ),
              const PopupMenuItem<TabsDemoStyle>(
                value: TabsDemoStyle.textOnly,
                child: Text('Text only')
              ),
            ],
          ),
        ],
        bottom: new TabBar(
          controller: _controller,
          isScrollable: true,
          indicator: getIndicator(),
          tabs: _allPages.map<Tab>((_Page page) {
            assert(_demoStyle != null);
            switch (_demoStyle) {
              case TabsDemoStyle.iconsAndText:
                return new Tab(text: page.text, icon: new Icon(page.icon));
              case TabsDemoStyle.iconsOnly:
                return new Tab(icon: new Icon(page.icon));
              case TabsDemoStyle.textOnly:
                return new Tab(text: page.text);
            }
            return null;
          }).toList(),
        ),
      ),
      body: new TabBarView(
        controller: _controller,
        children: _allPages.map((_Page page) {
          return new SafeArea(
            top: false,
            bottom: false,
            child: new Container(
              key: new ObjectKey(page.icon),
              padding: const EdgeInsets.all(12.0),
              child: new Card(
                child: new Center(
                  child: new Icon(
                    page.icon,
                    color: iconColor,
                    size: 128.0,
                    semanticLabel: 'Placeholder for ${page.text} tab',
                  ),
                ),
              ),
            ),
          );
        }).toList()
      ),
    );
  }
}
