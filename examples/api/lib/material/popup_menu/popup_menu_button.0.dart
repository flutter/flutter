// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for PopupMenuButton

import 'package:flutter/material.dart';

// This is the menu item type used by the popup menu below.
enum Menu { itemOne, itemTwo, itemThree, itemFour }

void main() => runApp(const PopupMenuButtonApp());

class PopupMenuButtonApp extends StatelessWidget {
  const PopupMenuButtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PopupMenuButtonExample(),
    );
  }
}

class PopupMenuButtonExample extends StatefulWidget {
  const PopupMenuButtonExample({super.key});

  @override
  State<PopupMenuButtonExample> createState() => _PopupMenuButtonExampleState();
}

class _PopupMenuButtonExampleState extends State<PopupMenuButtonExample> {
  String? selectedMenu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopupMenuButton Sample')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            iconColor: Colors.blue[700],
            tileColor: Colors.blue[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0)
            ),
            title: Text(
              selectedMenu == null ? 'Select an item' : 'Selected item: $selectedMenu',
              style: TextStyle(color: Colors.blue[700]),
            ),
            // This button presents popup menu items.
            trailing: PopupMenuButton<Menu>(
              icon: const Icon(Icons.more_vert),
              onSelected: (Menu item) {
                // Callback that sets the selected popup menu item.
                setState(() {
                  selectedMenu = item.name;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                const PopupMenuItem<Menu>(
                  value: Menu.itemOne,
                  child: Text('Item 1'),
                ),
                const PopupMenuItem<Menu>(
                  value: Menu.itemTwo,
                  child: Text('Item 2'),
                ),
                const PopupMenuItem<Menu>(
                  value: Menu.itemThree,
                  child: Text('Item 3'),
                ),
                const PopupMenuItem<Menu>(
                  value: Menu.itemFour,
                  child: Text('Item 4'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
