// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for MenuBar

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SampleApp());

enum MenuSelection {
  about,
  showMessage,
  colorMenu,
  colorRed,
  colorGreen,
  colorBlue,
  quit,
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  static const String _title = 'MenuBar Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: Scaffold(body: MyMenuBarApp()),
    );
  }
}

class MyMenuBarApp extends StatefulWidget {
  const MyMenuBarApp({super.key});

  @override
  State<MyMenuBarApp> createState() => _MyMenuBarAppState();
}

class _MyMenuBarAppState extends State<MyMenuBarApp> {
  bool get showMessage => _showMessage;
  bool _showMessage = false;
  set showMessage(bool value) {
    if (_showMessage != value) {
      setState(() {
        _showMessage = value;
      });
    }
  }

  Color get backgroundColor => _backgroundColor;
  Color _backgroundColor = Colors.red;
  set backgroundColor(Color value) {
    if (_backgroundColor != value) {
      setState(() {
        _backgroundColor = value;
      });
    }
  }

  void _activate(MenuSelection selection) {
    switch (selection) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Test',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.showMessage:
        showMessage = !showMessage;
        break;
      case MenuSelection.quit:
        exit(0);
      case MenuSelection.colorMenu:
        break;
      case MenuSelection.colorRed:
        backgroundColor = Colors.red;
        break;
      case MenuSelection.colorGreen:
        backgroundColor = Colors.green;
        break;
      case MenuSelection.colorBlue:
        backgroundColor = Colors.blue;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        MenuBar(
          menus: <PlatformMenu>[
            MenuBarMenu(
              autofocus: true,
              label: 'Test App',
              menus: <MenuItem>[
                MenuBarItem(
                  label: 'About',
                  onSelected: () => _activate(MenuSelection.about),
                ),
                MenuBarItem(
                  // Add a builder so that that call to MenuBarController.of will be using
                  // the correct context.
                  leadingIcon: Builder(builder: (BuildContext context) {
                    return Checkbox(
                      value: _showMessage,
                      onChanged: (bool? value) {
                        showMessage = value ?? false;
                      },
                    );
                  }),
                  label: 'Show Message',
                  onSelected: () {
                    showMessage = !showMessage;
                  },
                ),
                MenuBarMenu(
                  label: 'Background Color',
                  menus: <MenuItem>[
                    MenuItemGroup(members: <MenuItem>[
                      MenuBarItem(
                        onSelected: () => _activate(MenuSelection.colorRed),
                        label: 'Red Background',
                        shortcut: const SingleActivator(LogicalKeyboardKey.keyR, control: true),
                      ),
                      MenuBarItem(
                        onSelected: () => _activate(MenuSelection.colorGreen),
                        label: 'Green Background',
                        shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
                      ),
                    ]),
                    MenuBarItem(
                      onSelected: () => _activate(MenuSelection.colorBlue),
                      label: 'Blue Background',
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
                    ),
                  ],
                ),
                // Only include the "quit" item on non-web platforms.
                if (!kIsWeb)
                  MenuBarItem(
                    onSelected: () => _activate(MenuSelection.quit),
                    label: 'Quit',
                  ),
              ],
            ),
          ],
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            color: backgroundColor,
            child: Text(_showMessage ? 'Message' : 'Application Body'),
          ),
        ),
      ],
    );
  }
}
