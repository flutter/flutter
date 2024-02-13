// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(const AppBarPartsApp());
}

class AppBarPartsApp extends StatelessWidget {
  const AppBarPartsApp({ super.key });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const AppBarParts(),
    );
  }
}

class AppBarParts extends StatefulWidget {
  const AppBarParts({ super.key });

  @override
  State<AppBarParts> createState() => _AppBarPartsState();
}

class _AppBarPartsState extends State<AppBarParts> {
  late final ScrollController scrollController;
  late CoordinatedSliver alignedItem;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 8);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SliverCoordinator(
            // A CoordinatedSliver that auto-scrolls to align itself with the
            // top of the viewport when a scroll gesture leaves it partially visible.
            //
            // This demo must be run in a simulator or on a mobile device
            callback: (ScrollNotification notification, SliverCoordinatorData data) {
              final SliverLayoutInfo? info = alignedItem.getLayoutInfo(data);
              if (info == null) {
                return;
              }
              final double scrollOffset = info.constraints.scrollOffset;
              final double itemExtent = info.geometry.scrollExtent;
              if (notification is ScrollEndNotification) {
                if (scrollOffset > 0 && scrollOffset < itemExtent) {
                  scrollController.position.animateTo(
                    info.constraints.precedingScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut
                  );
                }
              }
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                const SliverPadding(
                  padding: horizontalPadding,
                  sliver: ItemList(
                    startColor: Colors.blue,
                    endColor: Colors.red,
                    itemCount: 5,
                  ),
                ),
                SliverPadding(
                  padding: horizontalPadding,
                  sliver: alignedItem = const CoordinatedSliver(
                    child: SliverToBoxAdapter(
                      child: Item(
                        title: 'AlignedItem',
                        color: Colors.orange
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: horizontalPadding,
                  sliver: ItemList(
                    startColor: Colors.blue,
                    endColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Item extends StatelessWidget {
  const Item({ super.key, required this.title, required this.color });

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: ListTile(
        textColor: Colors.white,
        title: Text(title),
      ),
    );
  }
}

// A placeholder SliverList of 50 items.
class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
    required this.startColor,
    required this.endColor,
    this.itemCount = 50,
  });

  final Color startColor;
  final Color endColor;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Item(
            title: 'Item $index',
            color: Color.lerp(startColor, endColor, index / itemCount)!
          );
        },
        childCount: itemCount,
      ),
    );
  }
}
