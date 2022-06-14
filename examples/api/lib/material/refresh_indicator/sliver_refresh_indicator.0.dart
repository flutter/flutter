// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for SliverRefreshIndicator

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SliverRefreshIndicatorExample(),
    );
  }
}

class SliverRefreshIndicatorExample extends StatefulWidget {
  const SliverRefreshIndicatorExample({super.key});

  @override
  State<SliverRefreshIndicatorExample> createState() => _SliverRefreshIndicatorExampleState();
}

class _SliverRefreshIndicatorExampleState extends State<SliverRefreshIndicatorExample> {
  List<Color> colors = <Color>[
    Colors.amber,
    Colors.orange,
    Colors.pink,
  ];
  List<Widget> items = <Widget>[
    Container(color: Colors.pink, height: 100.0),
    Container(color: Colors.orange, height: 100.0),
    Container(color: Colors.amber, height: 100.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          const SliverAppBar(
            title: Text('Scroll down'),
          ),
          SliverRefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(milliseconds: 1000),
              );
              setState(() {
                items.insert(
                  0,
                  Container(color: colors[items.length % 3], height: 100.0),
                );
              });
            },
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => items[index],
              childCount: items.length,
            ),
          ),
        ],
      ),
    );
  }
}
