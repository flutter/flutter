// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A mobile [ReorderableListView] fixture that starts a drag after a long press.
class ReorderableListSemanticsScreen extends StatefulWidget {
  const ReorderableListSemanticsScreen({super.key});

  @override
  State<ReorderableListSemanticsScreen> createState() => _ReorderableListSemanticsScreenState();
}

class _ReorderableListSemanticsScreenState extends State<ReorderableListSemanticsScreen> {
  final List<String> _items = <String>['Item 1', 'Item 2', 'Item 3', 'Item 4'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reorderable list semantics test')),
      body: ReorderableListView.builder(
        itemCount: _items.length,
        itemBuilder: (BuildContext context, int index) {
          final String item = _items[index];
          return Semantics(
            container: true,
            explicitChildNodes: true,
            key: ValueKey<String>(item),
            child: ListTile(title: Text(item)),
          );
        },
        onReorderItem: (int oldIndex, int newIndex) {
          setState(() {
            _items.insert(newIndex, _items.removeAt(oldIndex));
          });
        },
      ),
    );
  }
}
