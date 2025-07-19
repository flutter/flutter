// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const ReorderableListTestApp());
}

class ReorderableListTestApp extends StatelessWidget {
  const ReorderableListTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ReorderableList Animation Test',
      home: ReorderableListTestPage(),
    );
  }
}

class ReorderableListTestPage extends StatefulWidget {
  const ReorderableListTestPage({super.key});

  @override
  State<ReorderableListTestPage> createState() => _ReorderableListTestPageState();
}

class _ReorderableListTestPageState extends State<ReorderableListTestPage> {
  final List<String> _items = ['Item 0', 'Item 1'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReorderableList Test'),
      ),
      body: ReorderableListView(
              buildDefaultDragHandles: false, // Don't use default drag handles
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final String item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
              },
              children: _items.map((String item) {
                final index = _items.indexOf(item);
                return Container(
                  key: ValueKey<String>(item),
                  height: 100.0, // Each item is exactly 100px tall
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    title: Text(
                      item,
                      key: Key('text_$item'), // Key for finding in tests
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        key: Key('drag_handle_$index'),
                      ),
                    ),
                  ),
                );
              }).toList(),
      ),
    );
  }
}