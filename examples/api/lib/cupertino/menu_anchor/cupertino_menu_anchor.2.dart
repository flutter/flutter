// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter code sample for [CupertinoMenuAnchor] that shows a context menu at
/// the location of a secondary tap.
void main() {
  runApp(const CupertinoContextMenuApp());
}

/// An enhanced enum to define the available menus.
///
/// Using an enum for menu definition is not required, but this illustrates how
/// they could be used for simple menu systems.
enum MenuEntry {
  about('About'),
  showMessage('Show Message'),
  hideMessage('Hide Message');
  const MenuEntry(this.label);
  final String label;
}

class ContextMenuExample extends StatefulWidget {
  const ContextMenuExample({super.key, required this.message});
  final String message;

  @override
  State<ContextMenuExample> createState() => _ContextMenuExampleState();
}

class _ContextMenuExampleState extends State<ContextMenuExample> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  final CupertinoMenuController _menuController = CupertinoMenuController();
  bool _menuWasEnabled = false;
  MenuEntry? _lastSelection;

  bool get showingMessage => _showingMessage;
  bool _showingMessage = false;
  set showingMessage(bool value) {
    if (_showingMessage != value) {
      setState(() {
        _showingMessage = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _disableContextMenu();
  }

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    _reenableContextMenu();
    super.dispose();
  }

  Future<void> _disableContextMenu() async {
    if (!kIsWeb) {
      // Does nothing on non-web platforms.
      return;
    }
    _menuWasEnabled = BrowserContextMenu.enabled;
    if (_menuWasEnabled) {
      await BrowserContextMenu.disableContextMenu();
    }
  }

  void _reenableContextMenu() {
    if (!kIsWeb) {
      // Does nothing on non-web platforms.
      return;
    }
    if (_menuWasEnabled && !BrowserContextMenu.enabled) {
      BrowserContextMenu.enableContextMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onSecondaryTapDown: _handleSecondaryTapDown,
        child: CupertinoMenuAnchor(
          // Top left corner of the menu. Slightly offset to prevent the cursor
          // from overlapping the menu.
          menuAlignment: const Alignment(-1.025, -1.025),
          controller: _menuController,
          menuChildren: <Widget>[
            CupertinoMenuItem(
              child: Text(MenuEntry.about.label),
              onPressed: () => _activate(MenuEntry.about),
            ),
            if (_showingMessage)
              CupertinoMenuItem(
                onPressed: () => _activate(MenuEntry.hideMessage),
                child: Text(MenuEntry.hideMessage.label),
              ),
            if (!_showingMessage)
              CupertinoMenuItem(
                onPressed: () => _activate(MenuEntry.showMessage),
                child: Text(MenuEntry.showMessage.label),
              ),
          ],
          child: Container(
            color: CupertinoColors.systemGrey2.resolveFrom(context),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      'Right-click anywhere on the background to show the menu.'),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    showingMessage ? widget.message : '',
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                  ),
                ),
                Text(
                  _lastSelection != null
                      ? 'Last Selected: ${_lastSelection!.label}'
                      : '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _activate(MenuEntry selection) {
    setState(() {
      _lastSelection = selection;
    });
    switch (selection) {
      case MenuEntry.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Sample',
          applicationVersion: '1.0.0',
        );
      case MenuEntry.showMessage:
      case MenuEntry.hideMessage:
        showingMessage = !showingMessage;
    }
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    _menuController.open(position: details.localPosition);
  }

  void _handleTapDown(TapDownDetails details) {
    if (_menuController.isOpen) {
      _menuController.close();
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // Don't open the menu on these platforms with a Ctrl-tap (or a
        // tap).
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Only open the menu on these platforms if the control button is down
        // when the tap occurs.
        if (HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlLeft) ||
            HardwareKeyboard.instance.logicalKeysPressed
                .contains(LogicalKeyboardKey.controlRight)) {
          _menuController.open(position: details.localPosition);
        }
    }
  }
}

class CupertinoContextMenuApp extends StatelessWidget {
  const CupertinoContextMenuApp({super.key});

  static const String kMessage = 'Howdy, World!';

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      // Need to add DefaultMaterialLocalizations delegate to support shortcuts
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
      ],
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('CupertinoMenuAnchor Example'),
        ),
        child: SafeArea(
          child: ContextMenuExample(message: kMessage),
        ),
      ),
    );
  }
}
