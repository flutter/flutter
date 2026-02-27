// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SliverList].

void main() => runApp(const SliverListExampleApp());

class SliverListExampleApp extends StatelessWidget {
  const SliverListExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SliverListExample());
  }
}

class SliverListExample extends StatefulWidget {
  const SliverListExample({super.key});

  @override
  State<SliverListExample> createState() => _SliverListExampleState();
}

class _SliverListExampleState extends State<SliverListExample> {
  int _itemCount = 5;

  void _addItem() {
    setState(() {
      _itemCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SliverList demo')),
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: ListTile(
              title: Text('Press on the button to add items to the list.'),
            ),
          ),
          SliverList.builder(
            itemCount: _itemCount,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text('Item $index'));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add item',
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
