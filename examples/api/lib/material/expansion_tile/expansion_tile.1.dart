// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for [ExpansionTile] and [ExpansionTileController]

import 'package:flutter/material.dart';

void main() {
  runApp(const ExpansionTileControllerApp());
}

class ExpansionTileControllerApp extends StatefulWidget {
  const ExpansionTileControllerApp({ super.key });

  @override
  State<ExpansionTileControllerApp> createState() => _ExpansionTileControllerAppState();
}

class _ExpansionTileControllerAppState extends State<ExpansionTileControllerApp> {
  final ExpansionTileController controller = ExpansionTileController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Code Sample for ExpansionTileController.',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('ExpansionTileController Example')),
        body: ExpansionTile(
          controller: controller,
          title: const Text('ExpansionTile'),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: ElevatedButton(
                child: const Text('Collapse This Tile'),
                onPressed: () {
                  controller.collapse();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
