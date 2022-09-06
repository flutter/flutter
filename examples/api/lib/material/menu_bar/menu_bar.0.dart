// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [MenuBar]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kMessage = '"Talk less. Smile more." - A. Burr';

void main() => runApp(const MenuBarApp());

class MenuSelection {
  const MenuSelection({required this.label, this.shortcut, this.onPressed, this.menuChildren});

  final String label;
  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuSelection>? menuChildren;

  static List<Widget> build(List<MenuSelection> selections) {
    Widget buildSelection(MenuSelection selection) {
      if (selection.menuChildren != null) {
        return MenuButton(
          menuChildren: MenuSelection.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(List<MenuSelection> selections) {
    final Map<MenuSerializableShortcut, Intent> result = <MenuSerializableShortcut, Intent>{};
    for (final MenuSelection selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuSelection.shortcuts(selection.menuChildren!));
      } else {
        if (selection.shortcut != null && selection.onPressed != null) {
          result[selection.shortcut!] = VoidCallbackIntent(selection.onPressed!);
        }
      }
    }
    return result;
  }
}

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MenuBar Sample',
      home: Scaffold(body: MyMenuBar()),
    );
  }
}

class MyMenuBar extends StatefulWidget {
  const MyMenuBar({super.key});

  @override
  State<MyMenuBar> createState() => _MyMenuBarState();
}

class _MyMenuBarState extends State<MyMenuBar> {
  ShortcutRegistryEntry? _shortcutsEntry;
  String? _lastSelection;

  bool get showingMessage => _showMessage;
  bool _showMessage = false;
  set showingMessage(bool value) {
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

  List<MenuSelection> _getMenus() {
    final List<MenuSelection> result = <MenuSelection>[
      MenuSelection(
        label: 'Menu Demo',
        menuChildren: <MenuSelection>[
          MenuSelection(
            label: 'About',
            onPressed: () {
              setState(() {
                showAboutDialog(
                  context: context,
                  applicationName: 'MenuBar Sample',
                  applicationVersion: '1.0.0',
                );
                _lastSelection = 'About';
              });
            },
          ),
          // Toggles the message.
          MenuSelection(
            label: showingMessage ? 'Hide Message' : 'Show Message',
            onPressed: () {
              setState(() {
                _lastSelection = showingMessage ? 'Hide Message' : 'Show Message';
                showingMessage = !showingMessage;
              });
            },
            shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
          ),
          // Hides the message, but is only enabled if the message isn't
          // already hidden.
          MenuSelection(
            label: 'Reset Message',
            onPressed: showingMessage
                ? () {
                    setState(() {
                      debugDumpRenderTree();
                      _lastSelection = 'Reset Message';
                      showingMessage = false;
                    });
                  }
                : null,
            shortcut: const SingleActivator(LogicalKeyboardKey.escape),
          ),
          MenuSelection(
            label: 'Background Color',
            menuChildren: <MenuSelection>[
              MenuSelection(
                label: 'Red Background',
                onPressed: () {
                  setState(() {
                    _lastSelection = 'Red Background';
                    backgroundColor = Colors.red;
                  });
                },
                shortcut: const SingleActivator(LogicalKeyboardKey.keyR, control: true),
              ),
              MenuSelection(
                label: 'Green Background',
                onPressed: () {
                  setState(() {
                    _lastSelection = 'Green Background';
                    backgroundColor = Colors.green;
                  });
                },
                shortcut: const SingleActivator(LogicalKeyboardKey.keyG, control: true),
              ),
              MenuSelection(
                label: 'Blue Background',
                onPressed: () {
                  setState(() {
                    _lastSelection = 'Blue Background';
                    backgroundColor = Colors.blue;
                  });
                },
                shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
              ),
            ],
          ),
        ],
      ),
    ];
    // (Re-)register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application, and update them if they've changed.
    _shortcutsEntry?.dispose();
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(MenuSelection.shortcuts(result));
    return result;
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: MenuBar(
                children: MenuSelection.build(_getMenus()),
              ),
            ),
          ],
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            color: backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    showingMessage ? kMessage : '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Text(_lastSelection != null ? 'Last Selected: $_lastSelection' : ''),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
