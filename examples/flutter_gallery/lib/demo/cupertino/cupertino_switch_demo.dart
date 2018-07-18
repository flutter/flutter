// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoSwitchDemo extends StatefulWidget {
  static const String routeName = '/cupertino/switch';

  @override
  _CupertinoSwitchDemoState createState() => new _CupertinoSwitchDemoState();
}

class _CupertinoSwitchDemoState extends State<CupertinoSwitchDemo> {

  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Cupertino Switch'),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            new Column(
              children: <Widget>[
                new CupertinoSwitch(
                  value: _switchValue,
                  onChanged: (bool value) {
                    setState(() {
                      _switchValue = value;
                    });
                  },
                ),
                const Text(
                  'Active'
                ),
              ],
            ),
            new Column(
              children: const <Widget>[
                const CupertinoSwitch(
                  value: true,
                  onChanged: null,
                ),
                const Text(
                  'Disabled'
                ),
              ],
            ),
            new Column(
              children: const <Widget>[
                const CupertinoSwitch(
                  value: false,
                  onChanged: null,
                ),
                const Text(
                  'Disabled'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
