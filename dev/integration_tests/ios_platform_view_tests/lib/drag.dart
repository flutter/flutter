// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DragScreen extends StatefulWidget {
  const DragScreen({super.key});

  @override
  State<DragScreen> createState() => _DragScreenState();
}

class _DragScreenState extends State<DragScreen> {
  List<int> items = <int>[1, 2, 3, 4, 5];

  // Target order for Maestro drag-and-drop test validation.
  static const List<int> targetOrder = <int>[3, 1, 4, 5, 2];

  bool get isCorrectOrder => listEquals(items, targetOrder);

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final int item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drag Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Reorder items to: ${targetOrder.join(", ")}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Current order: ${items.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: items.length,
              onReorderItem: _onReorder,
              buildDefaultDragHandles: false,
              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                return Material(elevation: 4, color: Colors.transparent, child: child);
              },
              itemBuilder: (BuildContext context, int index) {
                final int item = items[index];
                return ReorderableDragStartListener(
                  key: ValueKey<int>(item),
                  index: index,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(
                        'Item $item',
                        style: const TextStyle(fontSize: 18),
                        semanticsLabel: 'Item $item',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isCorrectOrder)
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.green,
              width: double.infinity,
              child: const Text(
                'Drag Success',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
