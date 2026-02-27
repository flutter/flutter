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
      theme: CupertinoThemeData(brightness: Brightness.light),
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
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(progress: 0),
                SizedBox(height: 10),
                Text('Progress: 0'),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(progress: 0.2),
                SizedBox(height: 10),
                Text('Progress: 0.2', textAlign: TextAlign.center),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(progress: 0.4, height: 10),
                SizedBox(height: 10),
                Text('Height: 10', textAlign: TextAlign.center),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CupertinoLinearActivityIndicator(
                  progress: 0.6,
                  color: CupertinoColors.activeGreen,
                ),
                SizedBox(height: 10),
                Text('Color: green', textAlign: TextAlign.center),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
