// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [KeepAlive].
///
/// This example demonstrates how to use the [KeepAlive] to preserve the state
/// of individual list items in a `ListView` when they are scrolled out of view.
/// Each item has a counter that maintains its state.
void main() {
  runApp(const KeepAliveExampleApp());
}

class KeepAliveExampleApp extends StatelessWidget {
  const KeepAliveExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('KeepAlive Example')),
        body: ListView.builder(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return KeepAlive(
              keepAlive: index.isEven,
              child: _KeepAliveItem(index: index),
            );
          },
        ),
      ),
    );
  }
}

class _KeepAliveItem extends StatefulWidget {
  const _KeepAliveItem({required this.index});

  final int index;

  @override
  State<_KeepAliveItem> createState() => _KeepAliveItemState();
}

class _KeepAliveItemState extends State<_KeepAliveItem> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Item ${widget.index}: $_counter'),
      trailing: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _counter++;
          });
        },
      ),
    );
  }
}
