// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class ChipDemo extends StatefulComponent {
  _ChipDemoState createState() => new _ChipDemoState();
}

class _ChipDemoState extends State<ChipDemo> {
  bool _showBananas = true;

  void _deleteBananas() {
    setState(() {
      _showBananas = false;
    });
  }

  Widget build(BuildContext context) {
    List<Widget> chips = <Widget>[
      new Chip(
        label: new Text('Apple')
      ),
      new Chip(
        avatar: new CircleAvatar(label: 'B'),
        label: new Text('Blueberry')
      ),
    ];

    if (_showBananas) {
      chips.add(new Chip(
        label: new Text('Bananas'),
        onDeleted: _deleteBananas
      ));
    }

    return new Block(chips.map((Widget widget) {
      return new Container(
        height: 100.0,
        child: new Center(
          child: widget
        )
      );
    }).toList());
  }
}

final WidgetDemo kChipDemo = new WidgetDemo(
  title: 'Chips',
  routeName: '/chips',
  builder: (_) => new ChipDemo()
);
