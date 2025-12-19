// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [TabBar.onScrollControllerCreated].

void main() => runApp(const TabBarApp());

class TabBarApp extends StatelessWidget {
  const TabBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TabBarExample());
  }
}

class TabBarExample extends StatefulWidget {
  const TabBarExample({super.key});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

class _TabBarExampleState extends State<TabBarExample> {
  ScrollController? _scrollController;
  bool isRightSide = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 10,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TabBar Sample'),
          bottom: TabBar(
            isScrollable: true,
            onScrollControllerCreated: (ScrollController controller) {
              _scrollController = controller;
            },
            tabs: List<Widget>.generate(
              10,
              (int index) => Tab(text: 'Tab $index'),
            ),
          ),
        ),
        body: TabBarView(
          children: List<Widget>.generate(
            10,
            (int index) => Center(child: Text('Content of Tab $index')),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _scrollBar(),
          child: Icon(isRightSide ? Icons.arrow_back : Icons.arrow_forward),
        ),
      ),
    );
  }

  // Use the exposed controller to programmatically scroll.
  void _scrollBar() {
    if (!isRightSide) {
      _scrollController?.animateTo(
        _scrollController?.position.maxScrollExtent ?? 300,
        duration: Durations.medium1,
        curve: Curves.bounceIn,
      );
    } else {
      _scrollController?.animateTo(
        _scrollController?.position.minScrollExtent ?? 0,
        duration: Durations.medium1,
        curve: Curves.bounceIn,
      );
    }
    setState(() {
      isRightSide = !isRightSide;
    });
  }
}
