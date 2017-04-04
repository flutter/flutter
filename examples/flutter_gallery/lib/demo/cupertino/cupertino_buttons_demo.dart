// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const Color _kBlue = const Color(0xFF007AFF);

class CupertinoButtonsDemo extends StatefulWidget {
  static const String routeName = '/cupertino/buttons';

  @override
  _CupertinoButtonDemoState createState() => new _CupertinoButtonDemoState();
}

class _CupertinoButtonDemoState extends State<CupertinoButtonsDemo> {
  int _pressedCount = 0;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Cupertino Buttons'),
      ),
      body: new Column(
        children: <Widget> [
          new Padding(
            padding: const EdgeInsets.all(16.0),
            child: new Text('iOS themed buttons are flat. They can have borders or backgrounds but '
                'only when necessary.'),
          ),
          new Expanded(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                new Text(_pressedCount > 0 ? "Button pressed $_pressedCount times" : " "),
                new Padding(padding: const EdgeInsets.all(12.0)),
                new Align(
                  alignment: const FractionalOffset(0.5, 0.4),
                  child: new Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new CupertinoButton(
                        child: new Text('Cupertino Button'),
                        onPressed: () {
                          setState(() {_pressedCount++;});
                        }
                      ),
                      new CupertinoButton(
                        child: new Text('Disabled'),
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
                new Padding(padding: const EdgeInsets.all(12.0)),
                new CupertinoButton(
                  child: new Text('With Background'),
                  color: _kBlue,
                  onPressed: () {
                    setState(() {_pressedCount++;});
                  }
                ),
                new Padding(padding: const EdgeInsets.all(12.0)),
                new CupertinoButton(
                  child: new Text('Disabled'),
                  color: _kBlue,
                  onPressed: null,
                ),
              ],
            )
          ),
        ],
      )
    );
  }
}
