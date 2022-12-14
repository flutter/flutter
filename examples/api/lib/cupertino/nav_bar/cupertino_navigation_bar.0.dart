// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CupertinoNavigationBar

import 'package:flutter/cupertino.dart';

void main() => runApp(const NavBarApp());

class NavBarApp extends StatelessWidget {
  const NavBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: NavBarExample(),
    );
  }
}

class NavBarExample extends StatefulWidget {
  const NavBarExample({super.key});

  @override
  State<NavBarExample> createState() => _NavBarExampleState();
}

class _NavBarExampleState extends State<NavBarExample> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        // Try removing opacity to observe the lack of a blur effect and of sliding content.
        backgroundColor: CupertinoColors.systemGrey.withOpacity(0.5),
        middle: const Text('CupertinoNavigationBar Sample'),
      ),
      child: Column(
        children: <Widget>[
          Container(height: 50, color: CupertinoColors.systemRed),
          Container(height: 50, color: CupertinoColors.systemGreen),
          Container(height: 50, color: CupertinoColors.systemBlue),
          Container(height: 50, color: CupertinoColors.systemYellow),
        ],
      ),
    );
  }
}
