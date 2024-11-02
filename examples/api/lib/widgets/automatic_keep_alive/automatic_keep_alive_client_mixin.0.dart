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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AutomaticKeepAliveClientMixin Example'),
        ),
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
      itemBuilder: (BuildContext context, int index) {
        return KeepAliveItem(index: index);
      },
    );
  }
}

/// A widget that demonstrates the usage of AutomaticKeepAliveClientMixin
class KeepAliveItem extends StatefulWidget {
  const KeepAliveItem({super.key, required this.index});

  final int index;

  @override
  State<KeepAliveItem> createState() => KeepAliveItemState();
}

class KeepAliveItemState extends State<KeepAliveItem>
    with AutomaticKeepAliveClientMixin<KeepAliveItem> {
  @override
  bool wantKeepAlive = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important to call super.build to manage the keep-alive state

    return ListTile(
      title: Text('Item ${widget.index}'),
      subtitle: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Keep me alive: $_keepAlive'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _keepAlive = !_keepAlive;
                updateKeepAlive(); // Important to call to update the keep-alive status
              });
            },
            child: const Text('Toggle Keep Alive'),
          ),
        ],
      ),
    );
  }
}
