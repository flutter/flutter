// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// This example demonstrates how to use the [AutomaticKeepAliveClientMixin]
/// to keep the state of individual items alive even when they are scrolled
/// out of view in a ListView.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AutomaticKeepAliveClientMixin Example')),
        body: const ItemList(),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 100,
      itemBuilder: (context, index) {
        return KeepAliveItem(index: index);
      },
    );
  }
}

class KeepAliveItem extends StatefulWidget {
  final int index;

  const KeepAliveItem({required this.index, super.key});

  @override
  _KeepAliveItemState createState() => _KeepAliveItemState();
}

class _KeepAliveItemState extends State<KeepAliveItem> with AutomaticKeepAliveClientMixin<KeepAliveItem> {
  bool _keepAlive = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important to call super.build to manage the keep-alive state

    return ListTile(
      title: Text('Item ${widget.index}'),
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Keep me alive: $_keepAlive'),
          ElevatedButton(
            child: const Text('Toggle Keep Alive'),
            onPressed: () {
              setState(() {
                _keepAlive = !_keepAlive;
                updateKeepAlive(); // Important to call to update the keep-alive status
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => _keepAlive; // Keep the state based on button toggle
}
