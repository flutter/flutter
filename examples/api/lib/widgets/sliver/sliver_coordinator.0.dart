// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const SliverCoordinatorExampleApp());
}

class SliverCoordinatorExampleApp extends StatelessWidget {
  const SliverCoordinatorExampleApp({ super.key });

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SliverCoordinatorExample());
  }
}

class SliverCoordinatorExample extends StatefulWidget {
  const SliverCoordinatorExample({ super.key });

  @override
  State<SliverCoordinatorExample> createState() => _SliverCoordinatorExampleState();
}

class _SliverCoordinatorExampleState extends State<SliverCoordinatorExample> {
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

  void autoScrollTo(double offset) {
    scrollController.position.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Called each time a scroll gesture ends. If the alignedItem overlaps
  // either end of the CustomScrollView's viewport we'll auto-scroll
  // so that it's aligned with the top or bottom.
  void maybeAutoScrollAlignedItem(SliverCoordinatorData data) {
    final SliverConstraints constraints = alignedItem.getSliverConstraints(data);
    final SliverGeometry geometry = alignedItem.getSliverGeometry(data);
    final double scrollOffset = constraints.scrollOffset;
    final double overflow = geometry.maxPaintExtent - geometry.paintExtent;
    if (overflow < geometry.scrollExtent) { // indicates partial visibility
      if (scrollOffset > 0) {
        autoScrollTo(constraints.precedingScrollExtent); // top
      } else if (scrollOffset == 0) {
        autoScrollTo(scrollController.position.pixels + overflow); // bottom
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 8);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SliverCoordinator(
            callback: (ScrollNotification notification, SliverCoordinatorData data) {
              if (notification is ScrollEndNotification && alignedItem.hasLayoutInfo(data)) {
                maybeAutoScrollAlignedItem(data);
              }
            },
            child: CustomScrollView(
              controller: scrollController,
              slivers: <Widget>[
                const SliverPadding(
                  padding: horizontalPadding,
                  sliver: ItemList(itemCount: 15),
                ),
                SliverPadding(
                  padding: horizontalPadding,
                  // Each time we scroll the SliverCoordinator's callback will run.
                  sliver: alignedItem = const CoordinatedSliver(
                    sliver: BigOrangeSliver(),
                  ),
                ),
                const SliverPadding(
                  padding: horizontalPadding,
                  sliver: ItemList(itemCount: 25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A big list item sliver that's easy to spot.
class BigOrangeSliver extends StatelessWidget {
  const BigOrangeSliver({ super.key });

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Card(
        color: Colors.orange,
        child: ListTile(
          textColor: Colors.white,
          title: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('Aligned Item'),
          ),
        ),
      ),
    );
  }
}

// A placeholder SliverList of 50 items.
class ItemList extends StatelessWidget {
  const ItemList({ super.key, this.itemCount = 50 });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Card(
            color: colorScheme.onSecondary,
            child: ListTile(
              textColor: colorScheme.secondary,
              title: Text('Item $index.$itemCount'),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }
}
