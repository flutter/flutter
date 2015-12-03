// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'demo/widget_demo.dart';

class GalleryPage extends StatefulComponent {
  GalleryPage({ this.demos, this.active, this.onThemeChanged });

  final List<WidgetDemo> demos;
  final WidgetDemo active;
  final ValueChanged<ThemeData> onThemeChanged;

  _GalleryPageState createState() => new _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Widget _buildDrawer() {
    List<Widget> items = <Widget>[
      new DrawerHeader(child: new Text('Material demos')),
    ];

    for (WidgetDemo demo in config.demos) {
      items.add(new DrawerItem(
        onPressed: () {
          Navigator.pushNamed(context, demo.routeName);
        },
        child: new Text(demo.title)
      ));
    }

    return new Drawer(child: new Block(items));
  }

  Widget _buildBody() {
    if (config.active != null)
      return config.active.builder(context);
    return new Material(
      child: new Center(
        child: new Text('Select a demo from the drawer')
      )
    );
  }

  Widget _buildTabBar() {
    final WidgetBuilder builder = config.active?.tabBarBuilder;
    return builder != null ? builder(context) : null;
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      toolBar: new ToolBar(
        left: new IconButton(
          icon: 'navigation/menu',
          onPressed: () { _scaffoldKey.currentState?.openDrawer(); }
        ),
        center: new Text(config.active?.title ?? 'Material gallery'),
        tabBar: _buildTabBar()
      ),
      drawer: _buildDrawer(),
      body: _buildBody()
    );
  }
}
