// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for a [CupertinoMenuAnchor] that shows a basic menu.
void main() => runApp(const CupertinoSimpleMenuApp());

class CupertinoSimpleMenuApp extends StatelessWidget {
  const CupertinoSimpleMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      localizationsDelegates: <LocalizationsDelegate<MaterialLocalizations>>[
        DefaultMaterialLocalizations.delegate,
      ],
      home: Material(
        child: CupertinoPageScaffold(
          navigationBar:
              CupertinoNavigationBar(middle: Text('CupertinoMenuAnchor Example')),
          child: SafeArea(
            child: MenuExample(),
          ),
        ),
      ),
    );
  }
}

class MenuExample extends StatefulWidget {
  const MenuExample({super.key});

  @override
  State<MenuExample> createState() => _MenuExampleState();
}

class _MenuExampleState extends State<MenuExample> {
  // Optional: Create a focus node to control the menu button.
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  String _pressedItem = '';

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CupertinoMenuAnchor(
            childFocusNode: _buttonFocusNode,
            menuChildren: <Widget>[
              // Doesn't close the menu when pressed.
              CupertinoMenuItem(
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Regular Item';
                  });
                },
                subtitle: const Text('Subtitle'),
                child: const Text('Regular Item'),
              ),
              CupertinoMenuItem(
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Colorful Item';
                  });
                },
                hoveredColor: const CupertinoDynamicColor.withBrightness(
                  color: Color(0xFF880000),
                  darkColor: Color(0xFFAA0000),
                ),
                focusedColor: const Color(0xFF0000AA),
                pressedColor: const Color(0xFF006600),
                child: const Text('Colorful Item'),
              ),
              CupertinoMenuItem(
                trailing: const Icon(CupertinoIcons.add),
                isDefaultAction: true,
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Default Item';
                  });
                },
                child: const Text('Default Item'),
              ),
              CupertinoMenuItem(
                trailing: const Icon(CupertinoIcons.delete),
                isDestructiveAction: true,
                child: const Text('Destructive Item'),
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Destructive Item';
                  });
                },
              )
            ],
            builder: (
              BuildContext context,
              CupertinoMenuController controller,
              Widget? child,
            ) {
              return TextButton(
                focusNode: _buttonFocusNode,
                onPressed: () {
                  if (controller.menuStatus
                      case MenuStatus.opening || MenuStatus.opened) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: const Text('OPEN MENU'),
              );
            },
          ),
          if (_pressedItem.isNotEmpty)
            Text(
              'You Pressed: $_pressedItem',
              style: CupertinoTheme.of(context).textTheme.textStyle,
            ),
        ],
      ),
    );
  }
}
