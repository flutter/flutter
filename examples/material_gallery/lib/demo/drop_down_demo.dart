// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class DropDownDemo extends StatefulWidget {
  static const String routeName = '/dropdown';

  @override
  _DropDownDemoState createState() => new _DropDownDemoState();
}

class _DropDownDemoState extends State<DropDownDemo> {
  String _value = "Free";

  List<DropDownMenuItem<String>> buildItems() {
    return <String>["One", "Two", "Free", "Four"].map((String value) {
      return new DropDownMenuItem<String>(value: value, child: new Text(value));
    })
    .toList();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Drop-down button')),
      body: new Center(
        child: new DropDownButton<String>(
          items: buildItems(),
          value: _value,
          onChanged: (String newValue) {
            setState(() {
              if (newValue != null)
                _value = newValue;
            });
          }
        )
      )
    );
  }
}
