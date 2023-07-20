// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ReorderableListView].

void main() {
  runApp(const ReorderableApp());
}

class ReorderableApp extends StatelessWidget {
  const ReorderableApp({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('ReorderableListView Example')),
        body: const ReorderableExample(),
      ),
    );
  }
}

class ReorderableExample extends StatefulWidget {
  const ReorderableExample({ super.key });

  @override
  State<ReorderableExample> createState() => _ReorderableExampleState();
}

class _ReorderableExampleState extends State<ReorderableExample> {
  final List<Widget> items = List<Widget>.generate(20, (int index) {
    final Color color = Color.lerp(Colors.blue, Colors.orange, index / 20)!;
    // The Material wiget is needed to ensure that the ListTile's
    // tileColor Ink is rendered correctly when the tile occupies the
    // reorderable list's "gap".
    return Material(
      key: ValueKey<int>(index),
      child: ListTile(
        tileColor: color,
        selectedTileColor: color,
        title: Text('$index $color'),
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          items.insert(newIndex, items.removeAt(oldIndex));
        });
      },
      children: items,
    );
  }
}
