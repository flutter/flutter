// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SliverChildListDelegate Example')),
        body: const MyCustomScrollView(),
      ),
    );
  }
}

class MyCustomScrollView extends StatelessWidget {
  const MyCustomScrollView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate(
            List<Widget>.generate(
              100,
              (int index) {
                return MyListItem(index: index);
              },
            ),
            // Set to true to keep the state of each item alive while scrolling.
            // Change this to false to observe the loss of state in each item
            // when it is scrolled out of view. Selected items will revert to
            // their default state if this is false.
            addAutomaticKeepAlives: true, // Change this to false to see the impact
          ),
        ),
      ],
    );
  }
}

class MyListItem extends StatefulWidget {
  final int index;

  const MyListItem({required this.index, Key? key}) : super(key: key);

  @override
  _MyListItemState createState() => _MyListItemState();
}

class _MyListItemState extends State<MyListItem>
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
