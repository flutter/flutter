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
        body: ExpansionTile(
          title: const Text('ExpansionTile'),
          children: <Widget>[
            Builder(
              // Create an inner BuildContext so that the onPressed methods
              // can refer to the ExpansionTile with ExpansionTile.of().
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('COLLAPSE TILE'),
                  onPressed: () {
                    ExpansionTile.of(context).collapse();
                  },
                );
              },
            ),
          ],
        ),
        appBar: AppBar(title: const Text('ExpansionTile.of Example')),
      ),
      color: Colors.white,
    );
  }
}
