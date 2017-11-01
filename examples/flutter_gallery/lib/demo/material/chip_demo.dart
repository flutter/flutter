// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ChipDemo extends StatefulWidget {
  static const String routeName = '/material/chip';

  @override
  _ChipDemoState createState() => new _ChipDemoState();
}

class _ChipDemoState extends State<ChipDemo> {
  bool _showBananas = true;

  void _deleteBananas() {
    setState(() {
      _showBananas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      const Chip(
        label: const Text('Apple')
      ),
      const Chip(
        avatar: const CircleAvatar(child: const Text('B')),
        label: const Text('Blueberry'),
      ),
    ];

    if (_showBananas) {
      chips.add(new Chip(
        label: const Text('Bananas'),
        onDeleted: _deleteBananas
      ));
    }

    return new Scaffold(
      appBar: new AppBar(title: const Text('Chips')),
      body: new ListView(
        children: chips.map((Widget chip) {
          return new Container(
            height: 100.0,
            child: new Center(child: chip)
          );
        }).toList()
      )
    );
  }
}
