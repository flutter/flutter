// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SliverChildBuilderDelegate Example')),
        body: const MyCustomScrollView(),
      ),
    );
  }
}

class MyCustomScrollView extends StatelessWidget {
  const MyCustomScrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return MyListItem(index: index);
            },
            childCount: 100,
            // The default value of addAutomaticKeepAlives is true, so we can remove it
            // Set to false to observe the loss of state in each item when scrolled
            // out of view. Selected items will revert to their default state if false.
          ),
        ),
      ],
    );
  }
}

/// A stateful list item that maintains its state when scrolled out of view
/// due to AutomaticKeepAliveClientMixin.
class MyListItem extends StatefulWidget {
  const MyListItem({
    super.key,
    required this.index,
  });

  final int index;

  @override
  State<MyListItem> createState() => MyListItemState();
}

class MyListItemState extends State<MyListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListTile(
      title: Text('Item ${widget.index}'),
    );
  }
}
