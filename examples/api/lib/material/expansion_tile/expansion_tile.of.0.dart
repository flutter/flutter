// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Scaffold.of

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Code Sample for ExpansionTile.of.',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: const ExpansionTile(
          title: Text('ExpansionTile'),
          children: [
            MyExpansionTileBody(),
          ],
        ),
        appBar: AppBar(title: const Text('ExpansionTile.of Example')),
      ),
      color: Colors.white,
    );
  }
}

class MyExpansionTileBody extends StatelessWidget {
  const MyExpansionTileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('COLLAPSE TILE'),
      onPressed: () {
        ExpansionTile.of(context).collapse();
      },
    );
  }
}
