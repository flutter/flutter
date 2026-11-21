// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoLinearActivityIndicator].

void main() => runApp(const CupertinoLinearActivityIndicatorApp());

class CupertinoLinearActivityIndicatorApp extends StatelessWidget {
  const CupertinoLinearActivityIndicatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: .light),
      home: CupertinoIndicatorExample(),
    );
  }
}

class CupertinoIndicatorExample extends StatelessWidget {
  const CupertinoIndicatorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('CupertinoLinearActivityIndicator Sample'),
      ),
      child: Padding(
        padding: .all(8.0),
        child: Column(
          mainAxisAlignment: .spaceEvenly,
          children: <Widget>[
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(progress: 0),
                SizedBox(height: 10),
                Text('Progress: 0'),
              ],
            ),
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(progress: 0.2),
                SizedBox(height: 10),
                Text('Progress: 0.2', textAlign: .center),
              ],
            ),
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(progress: 0.4, height: 10),
                SizedBox(height: 10),
                Text('Height: 10', textAlign: .center),
              ],
            ),
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(
                  progress: 0.6,
                  color: CupertinoColors.activeGreen,
                ),
                SizedBox(height: 10),
                Text('Color: green', textAlign: .center),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
