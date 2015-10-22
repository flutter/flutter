// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class DropdownDemo extends StatefulComponent {
  DropdownDemo();

  DropdownDemoState createState() => new DropdownDemoState();
}

class DropdownDemoState extends State<DropdownDemo> {
  dynamic _value = 0;

  List <DropdownMenuItem> _buildItems() {
    return ["One", "Two", "Free", "Four"].map((String label) {
      return new DropdownMenuItem(value: label, child: new Text(label));
    })
    .toList();
  }

  Widget build(BuildContext context) {
    Widget dropdown = new DropdownButton(
      items: _buildItems(),
      value: _value,
      onChanged: (dynamic newValue) {
        setState(() {
          if (newValue != null)
            _value = newValue;
        });
      }
    );

    return new Scaffold(
      toolBar: new ToolBar(center: new Text('DropdownDemo Demo')),
      body: new Container(
        decoration: new BoxDecoration(backgroundColor: Theme.of(context).primarySwatch[50]),
        child: new Center(child: dropdown)
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'DropdownDemo',
    theme: new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent[200]
    ),
    routes: {
      '/': (RouteArguments args) => new DropdownDemo(),
    }
  ));
}
