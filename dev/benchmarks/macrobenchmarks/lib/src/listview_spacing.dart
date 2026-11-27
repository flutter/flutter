// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../common.dart';

enum ListViewSpacingMode { spacing, separated, spacingVariedExtent, separatedVariedExtent }

class ListViewSpacingPage extends StatelessWidget {
  const ListViewSpacingPage({super.key, required this.mode});

  final ListViewSpacingMode mode;

  static const int _itemCount = 10000;
  static const double _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    final Widget listView = switch (mode) {
      ListViewSpacingMode.spacing => ListView.builder(
        key: const Key(kListViewSpacingScrollableKey),
        itemCount: _itemCount,
        spacing: _spacing,
        itemBuilder: _buildItem,
      ),
      ListViewSpacingMode.separated => ListView.separated(
        key: const Key(kListViewSpacingScrollableKey),
        itemCount: _itemCount,
        itemBuilder: _buildItem,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: _spacing),
      ),
      ListViewSpacingMode.spacingVariedExtent => ListView.builder(
        key: const Key(kListViewSpacingScrollableKey),
        itemCount: _itemCount,
        spacing: _spacing,
        itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
          return index.isEven ? 50.0 : 70.0;
        },
        itemBuilder: _buildItem,
      ),
      ListViewSpacingMode.separatedVariedExtent => ListView.separated(
        key: const Key(kListViewSpacingScrollableKey),
        itemCount: _itemCount,
        itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) {
          if (index.isOdd) {
            return _spacing;
          }
          return (index ~/ 2).isEven ? 50.0 : 70.0;
        },
        itemBuilder: _buildItem,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: _spacing),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text('ListView ${mode.name}')),
      body: listView,
    );
  }

  static Widget _buildItem(BuildContext context, int index) {
    final height = index.isEven ? 50.0 : 70.0;
    return ColoredBox(
      color: index.isEven ? Colors.blue.shade50 : Colors.blue.shade100,
      child: SizedBox(
        height: height,
        child: Align(alignment: Alignment.centerLeft, child: Text('Item $index')),
      ),
    );
  }
}
