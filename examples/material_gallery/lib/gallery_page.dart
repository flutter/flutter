// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class GalleryPage extends StatelessComponent {
  GalleryPage({ this.demos, this.active });

  final List<WidgetDemo> demos;
  final WidgetDemo active;

  void _showDrawer(BuildContext context) {
    List<Widget> items = <Widget>[
      new DrawerHeader(child: new Text('Material demos')),
    ];

    for (WidgetDemo demo in demos) {
      items.add(new DrawerItem(
        onPressed: () {
          Navigator.of(context).pushNamed(demo.routeName);
        },
        child: new Text(demo.title)
      ));
    }

    showDrawer(context: context, child: new Block(items));
  }

  Widget _body(BuildContext context) {
    if (active != null)
      return active.builder(context);
    return new Material(
      child: new Center(
        child: new Text('Select a demo from the drawer')
      )
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        left: new IconButton(
          icon: 'navigation/menu',
          onPressed: () { _showDrawer(context); }
        ),
        center: new Text(active?.title ?? 'Material gallery')
      ),
      body: _body(context)
    );
  }
}
