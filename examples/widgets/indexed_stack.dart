// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class IndexedStackDemo extends StatefulComponent {
  IndexedStackDemoState createState() => new IndexedStackDemoState();
}

class IndexedStackDemoState extends State<IndexedStackDemo> {
  int _itemCount = 7;
  int _itemIndex = 0;

  void _handleTap() {
    setState(() {
      _itemIndex = (_itemIndex + 1) % _itemCount;
    });
  }

  List<PopupMenuItem> _buildMenu() {
    TextStyle style = const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
    String pad = '';
    return new List<PopupMenuItem>.generate(_itemCount, (int i) {
      pad += '-';
      return new PopupMenuItem(value: i, child: new Text('$pad Hello World $i $pad', style: style));
    });
  }

  Widget build(BuildContext context) {
    List<PopupMenuItem> items = _buildMenu();
    IndexedStack indexedStack = new IndexedStack(items, index: _itemIndex, alignment: const FractionalOffset(0.5, 0.0));

    return new Scaffold(
      toolBar: new ToolBar(center: new Text('IndexedStackDemo Demo')),
      body: new GestureDetector(
        onTap: _handleTap,
        child: new Center(
          child: new Container(
            child: indexedStack,
            padding: const EdgeDims.all(8.0),
            decoration: new BoxDecoration(border: new Border.all(color: Theme.of(context).accentColor))
          )
        )
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'IndexedStackDemo',
    theme: new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent[200]
    ),
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new IndexedStackDemo(),
    }
  ));
}
