// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [KeepAlive].
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('KeepAlive Example')),
        body: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return KeepAlive(
              keepAlive: index.isEven,
              child: ListItem(index: index),
            );
          },
        ),
      ),
    );
  }
}

class ListItem extends StatefulWidget {
  const ListItem({super.key, required this.index});

  final int index;

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  late final String label;

  @override
  void initState() {
    super.initState();
    label = 'Item ${widget.index} (${widget.index.isEven ? 'kept alive' : 'can be disposed'})';
    print('Created: $label');
  }

  @override
  void dispose() {
    print('Disposed: $label');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      tileColor: widget.index.isEven ? Colors.lightBlue[50] : null,
    );
  }
}
