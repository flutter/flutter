// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [createMaterialMenu].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const ContextMenuApp());

/// An enhanced enum to define the available menus and their shortcuts.
///
/// Using an enum for menu definition is not required, but this illustrates how
/// they could be used for simple menu systems.
enum MenuSelection {
  about('About'),
  showMessage('Show Message', SingleActivator(LogicalKeyboardKey.keyS, control: true)),
  resetMessage('Reset Message', SingleActivator(LogicalKeyboardKey.escape)),
  hideMessage('Hide Message'),
  colorMenu('Color Menu'),
  colorRed('Red Background', SingleActivator(LogicalKeyboardKey.keyR, control: true)),
  colorGreen('Green Background', SingleActivator(LogicalKeyboardKey.keyG, control: true)),
  colorBlue('Blue Background', SingleActivator(LogicalKeyboardKey.keyB, control: true));

  const MenuSelection(this.label, [this.shortcut]);
  final String label;
  final MenuSerializableShortcut? shortcut;
}

class ContextMenuApp extends StatelessWidget {
  const ContextMenuApp({super.key});

  static const String kMessage = '"Talk less. Smile more." - A. Burr';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: MyContextMenu(message: kMessage)),
    );
  }
}

class MyContextMenu extends StatefulWidget {
  const MyContextMenu({super.key, required this.message});

  final String message;

  @override
  State<MyContextMenu> createState() => _MyContextMenuState();
}

class _MyContextMenuState extends State<MyContextMenu> {
  MenuSelection? _lastSelection;
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  late MenuHandle _menuHandle;
  ShortcutRegistryEntry? _shortcutsEntry;

  void _updateMenu() {
    _menuHandle = createMaterialMenu(
      buttonFocusNode: _buttonFocusNode,
      children: <Widget>[
        MenuItemButton(
          child: Text(MenuSelection.about.label),
          onPressed: () => _activate(MenuSelection.about),
        ),
        // Toggles the message.
        MenuItemButton(
          onPressed: () => _activate(MenuSelection.showMessage),
          shortcut: MenuSelection.showMessage.shortcut,
          child: Text(
            showingMessage ? MenuSelection.hideMessage.label : MenuSelection.showMessage.label,
          ),
        ),
        // Hides the message, but is only enabled if the message isn't already
        // hidden.
        MenuItemButton(
          onPressed: showingMessage ? () => _activate(MenuSelection.resetMessage) : null,
          shortcut: MenuSelection.resetMessage.shortcut,
          child: Text(MenuSelection.resetMessage.label),
        ),
        MenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              onPressed: () => _activate(MenuSelection.colorRed),
              shortcut: MenuSelection.colorRed.shortcut,
              child: Text(MenuSelection.colorRed.label),
            ),
            MenuItemButton(
              onPressed: () => _activate(MenuSelection.colorGreen),
              shortcut: MenuSelection.colorGreen.shortcut,
              child: Text(MenuSelection.colorGreen.label),
            ),
            MenuItemButton(
              onPressed: () => _activate(MenuSelection.colorBlue),
              shortcut: MenuSelection.colorBlue.shortcut,
              child: Text(MenuSelection.colorBlue.label),
            ),
          ],
          child: const Text('Background Color'),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dispose of any previously registered shortcuts, since they are about to
    // be replaced.
    _shortcutsEntry?.dispose();
    // Collect the shortcuts from the different menu selections so that they can
    // be registered to apply to the entire app. Menus don't register their
    // shortcuts, they only display the shortcut hint text.
    final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{
      for (final MenuSelection item in MenuSelection.values)
        if (item.shortcut != null) item.shortcut!: VoidCallbackIntent(() => _activate(item)),
    };
    // Register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application.
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    _menuHandle.dispose();
    _buttonFocusNode.dispose();
    super.dispose();
  }

  bool get showingMessage => _showingMessage;
  bool _showingMessage = false;
  set showingMessage(bool value) {
    if (_showingMessage != value) {
      setState(() {
        _showingMessage = value;
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
    setState(() {
      _lastSelection = selection;
    });
    switch (selection) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Sample',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.showMessage:
        showingMessage = !showingMessage;
        break;
      case MenuSelection.resetMessage:
      case MenuSelection.hideMessage:
        showingMessage = false;
        break;
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

  void _handleTapDown(TapDownDetails details) {
    if (!HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) &&
        !HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight)) {
      return;
    }
    _menuHandle.open(context, position: details.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    _updateMenu();
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: Container(
        alignment: Alignment.center,
        color: backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Ctrl-click anywhere on the background to show the menu.'),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                showingMessage ? widget.message : '',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(_lastSelection != null ? 'Last Selected: ${_lastSelection!.label}' : ''),
          ],
        ),
      ),
    );
  }
}
