// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoButtonsDemo extends StatelessWidget {
  static const String routeName = '/cupertino_buttons';

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
                new Align(
                  alignment: const FractionalOffset(0.5, 0.4),
                  child: new Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new CupertinoButton(
                        child: new Text('Cupertino Button'),
                        onPressed: () {
                          // Perform some action
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
                  color: CupertinoButton.kCupertinoBlue,
                  onPressed: () {
                    // Perform some action
                  }
                ),
                new Padding(padding: const EdgeInsets.all(12.0)),
                new CupertinoButton(
                  child: new Text('Disabled'),
                  color: CupertinoButton.kCupertinoBlue,
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
