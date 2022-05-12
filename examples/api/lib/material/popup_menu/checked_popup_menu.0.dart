// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CheckedPopupMenuItem

import 'package:flutter/material.dart';

// This is the menu item type used by the popup menu below.
enum Menu { rounded, bordered, large, all  }

void main() => runApp(const CheckedMenuItemApp());

class CheckedMenuItemApp extends StatelessWidget {
  const CheckedMenuItemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CheckedMenuItemExample(),
    );
  }
}

class CheckedMenuItemExample extends StatefulWidget {
  const CheckedMenuItemExample({super.key});

  @override
  State<CheckedMenuItemExample> createState() => _CheckedMenuItemExampleState();
}

class _CheckedMenuItemExampleState extends State<CheckedMenuItemExample> {
  bool rounded = false;
  bool bordered = false;
  bool large = false;
  bool all = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CheckedPopupMenuItem Sample') ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: large || all ? 150.0 : 75.0,
                  width: large || all ? 150.0 : 75.0,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: rounded || all ? BorderRadius.circular(24.0) : BorderRadius.zero,
                    border: bordered || all ? Border.all(width: 6.0) : null,
                  ),
                ),
                // This button presents the popup menu items.
                PopupMenuButton<Menu>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (Menu item) {
                    // Callback that sets the selected popup menu item.
                    setState(() {
                      switch (item.name) {
                        case 'rounded':
                          rounded = !rounded;
                          all = false;
                          break;
                        case 'bordered':
                          bordered = !bordered;
                          all = false;
                          break;
                        case 'large':
                          large = !large;
                          all = false;
                          break;
                        case 'all':
                          if (rounded && bordered && large){
                            rounded = false;
                            bordered = false;
                            large = false;
                          } else {
                            rounded = true;
                            bordered = true;
                            large = true;
                          }
                          break;
                      }
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                    CheckedPopupMenuItem<Menu>(
                      value: Menu.rounded,
                      checked: rounded,
                      child: const Text('Rounded'),
                    ),
                    CheckedPopupMenuItem<Menu>(
                      value: Menu.bordered,
                      checked: bordered,
                      child: const Text('Bordered'),
                    ),
                    CheckedPopupMenuItem<Menu>(
                      value: Menu.large,
                      checked: large,
                      child: const Text('Large'),
                    ),
                    const PopupMenuDivider(),
                    CheckedPopupMenuItem<Menu>(
                      value: Menu.all,
                      checked: rounded && bordered && large,
                      child: const Text('All of the above'),
                    ),
                  ],
                )
              ],
          ),
        ),
      ),
    );
  }
}
