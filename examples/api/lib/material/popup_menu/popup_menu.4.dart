// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [PopupMenuButton].

// This is the type used by the popup menu below.
enum SampleItem { itemOne, itemTwo, itemThree }

void main() {
  runWidget(
    RegularWindow(
      controller: RegularWindowController(size: Size(1280, 720)),
      child: const PopupMenuApp(),
    ),
  );
}

class PopupMenuApp extends StatelessWidget {
  const PopupMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Note that useWindowingApi is set to true to enable the desktop windowing
    // API.
    return const MaterialApp(useWindowingApi: true, home: PopupMenuExample());
  }
}

class PopupMenuExample extends StatefulWidget {
  const PopupMenuExample({super.key});

  @override
  State<PopupMenuExample> createState() => _PopupMenuExampleState();
}

class _PopupMenuExampleState extends State<PopupMenuExample> {
  SampleItem? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopupMenuButton')),
      body: Center(
        child: PopupMenuButton<SampleItem>(
          initialValue: selectedItem,
          onSelected: (SampleItem item) {
            setState(() {
              selectedItem = item;
            });
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<SampleItem>>[
                const PopupMenuItem<SampleItem>(value: SampleItem.itemOne, child: Text('Item 1')),
                const PopupMenuItem<SampleItem>(value: SampleItem.itemTwo, child: Text('Item 2')),
                const PopupMenuItem<SampleItem>(value: SampleItem.itemThree, child: Text('Item 3')),
              ],
        ),
      ),
    );
  }
}
