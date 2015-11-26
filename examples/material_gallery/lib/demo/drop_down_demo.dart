// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class DropDownDemo extends StatefulComponent {
  _DropDownDemoState createState() => new _DropDownDemoState();
}

class _DropDownDemoState extends State<DropDownDemo> {
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

    return new Center(child: dropdown);
  }
}

final WidgetDemo kDropDownDemo = new WidgetDemo(
  title: 'Drop Down Button',
  routeName: '/dropdown',
  builder: (_) => new DropDownDemo()
);
