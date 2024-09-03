// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [ListTile].

void main() => runApp(const CupertinoListTileApp());

class CupertinoListTileApp extends StatelessWidget {
  const CupertinoListTileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoListTileExample(),
    );
  }
}

class CupertinoListTileExample extends StatelessWidget {
  const CupertinoListTileExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
          middle: Text('CupertinoListTile Sample')),
      child: ListView(
        children: const <Widget>[
           CupertinoListTile(
              leading: Icon(Icons.leaderboard),
              title: Text('Here is the title'),
              backgroundColor: Colors.red,
              backgroundColorActivated: Colors.green,
              subtitle: Text('Here is a second line'),
              trailing: Icon(Icons.more_vert),
              additionalInfo: Icon(Icons.add)),
        ],
      ),
    );
  }
}
