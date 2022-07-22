// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example demonstrates showing the default buttons, but customizing their
// appearance.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Custom button appearance'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(height: 20.0),
              TextField(
                contextMenuBuilder: (BuildContext context, EditableTextState editableTextState, Offset primaryAnchor, [Offset? secondaryAnchor]) {
                  return EditableTextContextMenuButtonDatasBuilder(
                    editableTextState: editableTextState,
                    builder: (BuildContext context, List<ContextMenuButtonData> buttonDatas) {
                      return DefaultTextSelectionToolbar(
                        primaryAnchor: primaryAnchor,
                        secondaryAnchor: secondaryAnchor,
                        // Build the default buttons, but make them look custom.
                        // Note that in a real project you may want to build
                        // different buttons depending on the platform.
                        children: buttonDatas.map((ContextMenuButtonData buttonData) {
                          assert(debugCheckHasCupertinoLocalizations(context));
                          final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
                          return CupertinoButton(
                            borderRadius: null,
                            color: const Color(0xffaaaa00),
                            disabledColor: const Color(0xffaaaaff),
                            onPressed: buttonData.onPressed,
                            padding: const EdgeInsets.all(10.0),
                            pressedOpacity: 0.7,
                            child: SizedBox(
                              width: 200.0,
                              child: Text(
                                CupertinoTextSelectionToolbarButtonsBuilder.getButtonLabel(context, buttonData),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
