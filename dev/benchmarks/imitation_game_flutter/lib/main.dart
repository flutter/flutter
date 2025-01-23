// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(InfiniteScrollApp());
}

class InfiniteScrollApp extends StatelessWidget {
  const InfiniteScrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Scrolling Flutter',
      home: InfiniteScrollList(),
    );
  }
}

class InfiniteScrollList extends StatefulWidget {
  const InfiniteScrollList({super.key});

  @override
  InfiniteScrollListState createState() => InfiniteScrollListState();
}

class InfiniteScrollListState extends State<InfiniteScrollList> {
  List<String> items = List.generate(50, (index) => "Hello"); // Initial 50 rows
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final int _loadMoreThreshold = 5;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                _loadMoreThreshold *
                    50 && // 50 is the approximate height of an row
        !isLoadingMore) {
      loadMoreItems();
    }
  }

  Future<void> loadMoreItems() async {
    setState(() {
      isLoadingMore = true;
    });

    // Generate 20 new items
    List<String> newItems = List.generate(20, (index) => "Hello");
    setState(() {
      items.addAll(newItems);
      isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Infinite Scrolling List")),
      body: ListView.builder(
        controller: _scrollController,
        itemCount:
            items.length + (isLoadingMore ? 1 : 0), // +1 for loading indicator
        itemBuilder: (context, index) {
          if (index < items.length) {
            return ListTile(title: Text(items[index]));
          } else {
            // Display loading indicator at the bottom
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
