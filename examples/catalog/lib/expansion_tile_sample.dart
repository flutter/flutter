// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ExpansionTileSample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ExpansionTile'),
        ),
        body: ListView.builder(
          itemBuilder: (BuildContext context, int index) => EntryItem(data[index]),
          itemCount: data.length,
        ),
      ),
    );
  }
}

// One entry in the multilevel list displayed by this app.
class Entry {
  Entry(this.title, [this.children = const <Entry>[]]);
  final String title;
  final List<Entry> children;
}

// The entire multilevel list displayed by this app.
final List<Entry> data = <Entry>[
  Entry('Chapter A',
    <Entry>[
      Entry('Section A0',
        <Entry>[
          Entry('Item A0.1'),
          Entry('Item A0.2'),
          Entry('Item A0.3'),
        ],
      ),
      Entry('Section A1'),
      Entry('Section A2'),
    ],
  ),
  Entry('Chapter B',
    <Entry>[
      Entry('Section B0'),
      Entry('Section B1'),
    ],
  ),
  Entry('Chapter C',
    <Entry>[
      Entry('Section C0'),
      Entry('Section C1'),
      Entry('Section C2',
        <Entry>[
          Entry('Item C2.0'),
          Entry('Item C2.1'),
          Entry('Item C2.2'),
          Entry('Item C2.3'),
        ],
      ),
    ],
  ),
];

// Displays one Entry. If the entry has children then it's displayed
// with an ExpansionTile.
class EntryItem extends StatelessWidget {
  const EntryItem(this.entry);

  final Entry entry;

  Widget _buildTiles(Entry root) {
    if (root.children.isEmpty)
      return ListTile(title: Text(root.title));
    return ExpansionTile(
      key: PageStorageKey<Entry>(root),
      title: Text(root.title),
      children: root.children.map<Widget>(_buildTiles).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(entry);
  }
}

void main() {
  runApp(ExpansionTileSample());
}

/*
Sample Catalog

Title: ExpansionTile

Summary: An ExpansionTile for building nested lists, with two or more levels.

Description:
This app displays hierarchical data with ExpansionTiles. Tapping a tile
expands or collapses the view of its children. When a tile is collapsed
its children are disposed so that the widget footprint of the list only
reflects what's visible.

When displayed within a scrollable that creates its list items lazily,
like a scrollable list created with `ListView.builder()`, ExpansionTiles
can be quite efficient, particularly for material design "expand/collapse"
lists.


Classes: ExpansionTile, ListView

Sample: ExpansionTileSample

See also:
  - The "expand/collapse" part of the material design specification:
    <https://material.io/guidelines/components/lists-controls.html#lists-controls-types-of-list-controls>
*/
