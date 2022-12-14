// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for PopupMenuButton

import 'package:flutter/material.dart';

// This is the type used by the popup menu below.
enum Menu { itemOne, itemTwo, itemThree, itemFour }

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  String _selectedMenu = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          // This button presents popup menu items.
          PopupMenuButton<Menu>(
          // Callback that sets the selected popup menu item.
          onSelected: (Menu item) {
            setState(() {
              _selectedMenu = item.name;
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
          ]),
        ],
      ),
      body: Center(
        child: Text('_selectedMenu: $_selectedMenu'),
      ),
    );
  }
}
