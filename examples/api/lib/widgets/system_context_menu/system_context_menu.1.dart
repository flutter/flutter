// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SystemContextMenu] with custom menu items.

void main() => runApp(const SystemContextMenuExampleApp());

class SystemContextMenuExampleApp extends StatelessWidget {
  const SystemContextMenuExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Context Menu Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom Context Menu Example')),
        body: const Center(child: SystemContextMenuExample()),
      ),
    );
  }
}

class SystemContextMenuExample extends StatefulWidget {
  const SystemContextMenuExample({super.key});

  @override
  State<SystemContextMenuExample> createState() => _SystemContextMenuExampleState();
}

class _SystemContextMenuExampleState extends State<SystemContextMenuExample> {
  final TextEditingController _controller = TextEditingController(
    text: 'Long press to see custom menu items',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Text Field with Custom Context Menu',
          helperText: 'Long press to see custom menu items (iOS 16.0+)',
        ),
        contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
          if (!MediaQuery.of(context).supportsShowingSystemContextMenu) {
            return AdaptiveTextSelectionToolbar.editableText(editableTextState: editableTextState);
          }

          return SystemContextMenu.editableText(
            editableTextState: editableTextState,
            items: <IOSSystemContextMenuItem>[
              IOSSystemContextMenuItemCustom(
                title: 'Clear Text',
                onPressed: () {
                  _controller.clear();
                  _showMessage('Text cleared');
                },
              ),
              IOSSystemContextMenuItemCustom(
                title: 'Add Heart',
                onPressed: () {
                  final TextSelection selection = _controller.selection;
                  final String text = _controller.text;
                  _controller.value = TextEditingValue(
                    text: text.replaceRange(selection.start, selection.end, '❤️'),
                    selection: TextSelection.collapsed(offset: selection.start + 2),
                  );
                  _showMessage('Heart added');
                },
              ),
              IOSSystemContextMenuItemCustom(
                title: 'Uppercase',
                onPressed: () {
                  final TextSelection selection = _controller.selection;
                  if (selection.isValid && !selection.isCollapsed) {
                    final String selectedText = _controller.text.substring(
                      selection.start,
                      selection.end,
                    );
                    _controller.text = _controller.text.replaceRange(
                      selection.start,
                      selection.end,
                      selectedText.toUpperCase(),
                    );
                    _showMessage('Text converted to uppercase');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
