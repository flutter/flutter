// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [SliverOpacity].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  static const List<Widget> _listItems = <Widget>[
    ListTile(title: Text('Now you see me,')),
    ListTile(title: Text("Now you don't!")),
  ];

  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SliverOpacity demo'),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: ListTile(title: Text('Press on the button to toggle the list visibilty.')),
          ),
          const SliverToBoxAdapter(
            child: ListTile(title: Text('Before the list...')),
          ),
          SliverOpacity(
            opacity: _visible ? 1.0 : 0.0,
            sliver: SliverList(
              delegate: SliverChildListDelegate(_listItems),
            ),
          ),
          const SliverToBoxAdapter(
            child: ListTile(title: Text('Before the list...')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.disabled_visible),
        onPressed: () {
          setState(() {
            _visible = !_visible;
          });
        },
      ),
    );
  }
}
