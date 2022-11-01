// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example demonstrates showing the default buttons, but customizing their
// appearance.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final TextEditingController _controller = TextEditingController(
    text: 'Right click or long press to see the menu with custom buttons.',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Custom button appearance'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20.0),
              TextField(
                controller: _controller,
                contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                  return AdaptiveTextSelectionToolbar(
                    anchors: editableTextState.contextMenuAnchors,
                    // Build the default buttons, but make them look custom.
                    // In a real project you may want to build different
                    // buttons depending on the platform.
                    children: editableTextState.contextMenuButtonItems.map((ContextMenuButtonItem buttonItem) {
                      return CupertinoButton(
                        borderRadius: null,
                        color: const Color(0xffaaaa00),
                        disabledColor: const Color(0xffaaaaff),
                        onPressed: buttonItem.onPressed,
                        padding: const EdgeInsets.all(10.0),
                        pressedOpacity: 0.7,
                        child: SizedBox(
                          width: 200.0,
                          child: Text(
                            CupertinoTextSelectionToolbarButton.getButtonLabel(context, buttonItem),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
