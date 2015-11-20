// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class DropDownDemo extends StatefulComponent {
  DropDownDemoState createState() => new DropDownDemoState();
}

class DropDownDemoState extends State<DropDownDemo> {
  String _value = "Free";

  List<DropDownMenuItem<String>> _buildItems() {
    return ["One", "Two", "Free", "Four"].map((String value) {
      return new DropDownMenuItem<String>(value: value, child: new Text(value));
    })
    .toList();
  }

  Widget build(BuildContext context) {
    Widget dropdown = new DropDownButton<String>(
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
      toolBar: new ToolBar(center: new Text('DropDownDemo Demo')),
      body: new Container(
        decoration: new BoxDecoration(backgroundColor: Theme.of(context).primarySwatch[50]),
        child: new Center(child: dropdown)
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'DropDownDemo',
    theme: new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent[200]
    ),
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new DropDownDemo(),
    }
  ));
}
