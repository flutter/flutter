// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example demonstrates a custom context menu in non-editable text using
// SelectionArea.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const String text = 'I am some text inside of SelectionArea. Right click or long press me to show the customized context menu.';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _showDialog (BuildContext context) {
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) =>
          const AlertDialog(title: Text('You clicked print!')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Context menu anywhere'),
        ),
        body: Center(
          child: SizedBox(
            width: 200.0,
            child: SelectionArea(
              contextMenuBuilder: (
                BuildContext context,
                SelectableRegionState selectableRegionState,
              ) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: <ContextMenuButtonItem>[
                    ...selectableRegionState.contextMenuButtonItems,
                    ContextMenuButtonItem(
                      onPressed: () {
                        ContextMenuController.removeAny();
                        _showDialog(context);
                      },
                      label: 'Print',
                    ),
                  ],
                );
              },
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 20.0),
                  Text(text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
