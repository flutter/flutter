// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

class CupertinoButtonsDemo extends StatefulWidget {
  static const String routeName = '/cupertino/buttons';

  @override
  _CupertinoButtonDemoState createState() => _CupertinoButtonDemoState();
}

class _CupertinoButtonDemoState extends State<CupertinoButtonsDemo> {
  int _pressedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cupertino Buttons'),
        actions: <Widget>[MaterialDemoDocumentationButton(CupertinoButtonsDemo.routeName)],
      ),
      body: Column(
        children: <Widget> [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'iOS themed buttons are flat. They can have borders or backgrounds but '
              'only when necessary.'
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                Text(_pressedCount > 0
                    ? 'Button pressed $_pressedCount time${_pressedCount == 1 ? "" : "s"}'
                    : ' '),
                const Padding(padding: EdgeInsets.all(12.0)),
                Align(
                  alignment: const Alignment(0.0, -0.2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CupertinoButton(
                        child: const Text('Cupertino Button'),
                        onPressed: () {
                          setState(() { _pressedCount += 1; });
                        }
                      ),
                      const CupertinoButton(
                        child: Text('Disabled'),
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.all(12.0)),
                CupertinoButton(
                  child: const Text('With Background'),
                  color: CupertinoColors.activeBlue,
                  onPressed: () {
                    setState(() { _pressedCount += 1; });
                  }
                ),
                const Padding(padding: EdgeInsets.all(12.0)),
                const CupertinoButton(
                  child: Text('Disabled'),
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
