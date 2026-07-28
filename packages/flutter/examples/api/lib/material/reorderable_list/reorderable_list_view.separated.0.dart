// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [ReorderableListView.separated].

void main() => runApp(const ReorderableApp());

class ReorderableApp extends StatelessWidget {
  const ReorderableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ReorderableListView.separated Sample'),
        ),
        body: const ReorderableExample(),
      ),
    );
  }
}

class ReorderableExample extends StatefulWidget {
  const ReorderableExample({super.key});

  @override
  State<ReorderableExample> createState() => _ReorderableExampleState();
}

class _ReorderableExampleState extends State<ReorderableExample> {
  final List<int> _items = List<int>.generate(20, (int index) => index);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withValues(alpha: 0.05);
    final Color evenItemColor = colorScheme.primary.withValues(alpha: 0.15);

    return ReorderableListView.separated(
      padding: const .symmetric(horizontal: 40.0),
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          // Key each tile by its item rather than by its position, so a tile's
          // identity follows the item it shows when the order changes.
          key: ValueKey<int>(_items[index]),
          tileColor: _items[index].isOdd ? oddItemColor : evenItemColor,
          title: Text('Item ${_items[index]}'),
        );
      },
      // The separator index is a boundary index: separator `index` sits between
      // the items built for `index` and `index + 1`, so it describes a position
      // in the list rather than a particular item. The thick dividers therefore
      // stay on the even boundaries no matter how the items are reordered, and
      // every divider stays visible while an item is being dragged.
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          height: 8.0,
          thickness: index.isEven ? 4.0 : 1.0,
          color: index.isEven
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        );
      },
      onReorderItem: (int oldIndex, int newIndex) {
        setState(() {
          final int item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
      },
    );
  }
}
