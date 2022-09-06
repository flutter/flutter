// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [createMaterialMenu].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String kMessage = '"Talk less. Smile more." - A. Burr';

void main() => runApp(const MenuBarApp());

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

class MenuBarApp extends StatelessWidget {
  const MenuBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'createMaterialMenu Sample',
      home: Scaffold(body: MyCascadingMenu()),
    );
  }
}

class MyCascadingMenu extends StatefulWidget {
  const MyCascadingMenu({super.key});

  @override
  State<MyCascadingMenu> createState() => _MyCascadingMenuState();
}

class _MyCascadingMenuState extends State<MyCascadingMenu> {
  MenuSelection? _lastSelection;
  final MenuController _controller = MenuController();
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  late MenuHandle _menuHandle;
  ShortcutRegistryEntry? _shortcutsEntry;

  // This is the global key that the menu uses to determine which themes should
  // be used for the menus, as well as determining what the bounding box is for
  // the widget that is hosting the menu, so that the menu knows where to
  // appear.
  final GlobalKey _buttonKey = GlobalKey();

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
        if (item.shortcut != null)
          item.shortcut!: VoidCallbackIntent(
            () => _activate(item),
          ),
    };
    // Register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application.
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    _menuHandle.dispose();
    _controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    _menuHandle = createMaterialMenu(
      buttonFocusNode: _buttonFocusNode,
      controller: _controller,
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
        // Hides the message, but is only enabled if the message isn't already hidden.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The controlling widget for the menu must be wrapped by a TapRegion
        // with the MenuController that the menu is using as its group ID. This
        // prevents tapping on the button when the menu is open from closing the
        // menu by activating the "tap outside" action of the menu.
        TapRegion(
          groupId: _controller,
          child: MenuAnchor(
            builder: (BuildContext context) {
              return TextButton(
                key: _buttonKey,
                focusNode: _buttonFocusNode,
                onPressed: () {
                  if (_menuHandle.isOpen) {
                    _menuHandle.close();
                  } else {
                    _menuHandle.open(context);
                  }
                },
                child: const Text('OPEN MENU'),
              );
            },
          ),
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
                Text(
                  _lastSelection != null ? 'Last Selected: ${_lastSelection!.label}' : '',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
