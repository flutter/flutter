// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [MenuAnchor].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MenuApp());

class MyRadioMenu extends StatefulWidget {
  const MyRadioMenu({super.key, required this.message});

  final String message;

  @override
  State<MyRadioMenu> createState() => _MyRadioMenuState();
}

class _MyRadioMenuState extends State<MyRadioMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  Color _backgroundColor = Colors.red;

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  void _setBackgroundColor(Color? color) {
    setState(() {
      _backgroundColor = color!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
          _setBackgroundColor(Colors.red);
        },
        const SingleActivator(LogicalKeyboardKey.keyG, control: true): () {
          _setBackgroundColor(Colors.green);
        },
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
          _setBackgroundColor(Colors.blue);
        },
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MenuAnchor(
            childFocusNode: _buttonFocusNode,
            menuChildren: <Widget>[
              RadioMenuButton<Color>(
                value: Colors.red,
                groupValue: _backgroundColor,
                onChanged: _setBackgroundColor,
                child: const Text('Red Background'),
              ),
              RadioMenuButton<Color>(
                value: Colors.green,
                groupValue: _backgroundColor,
                onChanged: _setBackgroundColor,
                child: const Text('Green Background'),
              ),
              RadioMenuButton<Color>(
                value: Colors.blue,
                groupValue: _backgroundColor,
                onChanged: _setBackgroundColor,
                child: const Text('BlueBackground'),
              ),
            ],
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return TextButton(
                focusNode: _buttonFocusNode,
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: const Text('OPEN MENU'),
              );
            },
          ),
          Expanded(
            child: ColoredBox(
              color: _backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  static const String kMessage = '"Talk less. Smile more." - A. Burr';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: MyRadioMenu(message: kMessage)),
    );
  }
}
