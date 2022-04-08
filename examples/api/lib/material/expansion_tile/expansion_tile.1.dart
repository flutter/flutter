// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ExpansionTile

import 'package:flutter/material.dart';

void main() => runApp(const ExpansionTileApp());

class ExpansionTileApp extends StatelessWidget {
  const ExpansionTileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ExpansionTile Sample')),
        body: const ExpansionTileExample(),
      ),
    );
  }
}

class ExpansionTileExample extends StatelessWidget {
  const ExpansionTileExample({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
    final Color evenItemColor = colorScheme.primary.withOpacity(0.15);

    return SingleChildScrollView(
      child: ExpansionTile(
        key: const PageStorageKey<String>('ExpansionTileKey'),
        title: const Text('ExpansionTile'),
        subtitle: const Text('Trailing expansion arrow icon'),
        children: <Widget>[
          ListView.builder(
            key: const PageStorageKey<String>('ListViewKey'),
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                key: Key('$index'),
                tileColor: index.isOdd ? oddItemColor : evenItemColor,
                title: Text('Item $index'),
              );
            },
          ),
        ],
      ),
    );
  }
}
