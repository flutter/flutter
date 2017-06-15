// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        title: const Text('Cupertino Buttons'),
      ),
      body: new Column(
        children: <Widget> [
          const Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'iOS themed buttons are flat. They can have borders or backgrounds but '
              'only when necessary.'
            ),
          ),
          new Expanded(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                new Text(_pressedCount > 0
                    ? 'Button pressed $_pressedCount time${_pressedCount == 1 ? "" : "s"}'
                    : ' '),
                const Padding(padding: const EdgeInsets.all(12.0)),
                new Align(
                  alignment: const FractionalOffset(0.5, 0.4),
                  child: new Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new CupertinoButton(
                        child: const Text('Cupertino Button'),
                        onPressed: () {
                          setState(() { _pressedCount += 1; });
                        }
                      ),
                      const CupertinoButton(
                        child: const Text('Disabled'),
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
                const Padding(padding: const EdgeInsets.all(12.0)),
                new CupertinoButton(
                  child: const Text('With Background'),
                  color: CupertinoColors.activeBlue,
                  onPressed: () {
                    setState(() { _pressedCount += 1; });
                  }
                ),
                const Padding(padding: const EdgeInsets.all(12.0)),
                const CupertinoButton(
                  child: const Text('Disabled'),
                  color: CupertinoColors.activeBlue,
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
