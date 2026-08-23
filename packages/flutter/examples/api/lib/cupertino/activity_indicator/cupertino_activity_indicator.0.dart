// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoActivityIndicator].

void main() => runApp(const CupertinoIndicatorApp());

class CupertinoIndicatorApp extends StatelessWidget {
  const CupertinoIndicatorApp({super.key});

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
        middle: Text('CupertinoActivityIndicator Sample'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: .spaceEvenly,
          children: <Widget>[
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                // Cupertino activity indicator with default properties.
                CupertinoActivityIndicator(),
                SizedBox(height: 10),
                Text('Default'),
              ],
            ),
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                // Cupertino activity indicator with custom radius, color, and
                // tick count.
                CupertinoActivityIndicator(
                  radius: 20.0,
                  color: CupertinoColors.activeBlue,
                  tickCount: 12,
                ),
                SizedBox(height: 10),
                Text(
                  'radius: 20.0\ncolor: CupertinoColors.activeBlue\ntickCount: 12',
                  textAlign: .center,
                ),
              ],
            ),
            Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                // Cupertino activity indicator with custom radius and disabled
                // animation.
                CupertinoActivityIndicator(
                  radius: 20.0,
                  animating: false,
                  tickCount: 16,
                ),
                SizedBox(height: 10),
                Text(
                  'radius: 20.0\nanimating: false\ntickCount: 16',
                  textAlign: .center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
