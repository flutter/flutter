// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [AutomaticKeepAlive].
///
/// This example demonstrates how to use the `AutomaticKeepAliveClientMixin`
/// to preserve the state of individual list items in a `ListView` when they
/// are scrolled out of view. Each item has a counter that maintains its
/// state even after scrolling off-screen.

void main() {
  runApp(const AutomaticKeepAliveApp());
}

class AutomaticKeepAliveApp extends StatelessWidget {
  const AutomaticKeepAliveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AutomaticKeepAliveExample(),
    );
  }
}

class AutomaticKeepAliveExample extends StatelessWidget {
  const AutomaticKeepAliveExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutomaticKeepAlive Example'),
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) {
          // Each child in the ListView applies AutomaticKeepAliveClientMixin
          return KeepAliveItem(index: index);
        },
      ),
    );
  }
}

class KeepAliveItem extends StatefulWidget {
  final int index;
  const KeepAliveItem({Key? key, required this.index}) : super(key: key);

  @override
  _KeepAliveItemState createState() => _KeepAliveItemState();
}

class _KeepAliveItemState extends State<KeepAliveItem> with AutomaticKeepAliveClientMixin<KeepAliveItem> {
  int _counter = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important to call super.build to preserve the state

    return ListTile(
      title: Text('Item ${widget.index} - Counter: $_counter'),
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
