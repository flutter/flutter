// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class DropdownDemo extends StatefulComponent {
  DropdownDemo();

  DropdownDemoState createState() => new DropdownDemoState();
}

class DropdownDemoState extends State<DropdownDemo> {
  String _value = "Free";

  List<DropdownMenuItem> _buildItems() {
    return ["One", "Two", "Free", "Four"].map((String value) {
      return new DropdownMenuItem<String>(value: value, child: new Text(value));
    })
    .toList();
  }

  Widget build(BuildContext context) {
    Widget dropdown = new DropdownButton<String>(
      items: _buildItems(),
      value: _value,
      onChanged: (String newValue) {
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
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new DropdownDemo(),
    }
  ));
}
