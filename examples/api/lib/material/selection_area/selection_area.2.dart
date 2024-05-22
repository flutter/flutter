// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SelectionArea].

void main() => runApp(const SelectionAreaEmphasizeTextExampleApp());

class SelectionAreaEmphasizeTextExampleApp extends StatelessWidget {
  const SelectionAreaEmphasizeTextExampleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ContextMenuController _menuController = ContextMenuController();
  final SelectionController _selectionController = SelectionController();

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  void _emphasizeText(SelectedContent content) {
    if (content.controllers == null) {
      return;
    }
    for (int index = 0; index < content.controllers!.length; index += 1) {
      // TODO(Renzo-Olivares): Should provide whether a controller is a text
      // controller or not.
      final SelectedContentController contentController = content.controllers![index];
      final String plainText = (contentController.value as TextSpan).toPlainText();
      String collectedSelection = '';
      String beforeSelection = '';
      String afterSelection = '';
      // Collect text before selection.
      for (int j = 0; j < contentController.startOffset; j += 1) {
        beforeSelection += String.fromCharCode(plainText.codeUnitAt(j));
      } 
      // Collect text inside selection.
      for (int j = contentController.startOffset; j < contentController.endOffset; j += 1) {
        collectedSelection += String.fromCharCode(plainText.codeUnitAt(j));
      }
      // Collect text after selection.
      for (int j = contentController.endOffset; j < plainText.length; j += 1) {
        afterSelection += String.fromCharCode(plainText.codeUnitAt(j));
      }
      final TextSpan beforeSpan = TextSpan(text: beforeSelection);
      final TextSpan selectionSpan = TextSpan(text: collectedSelection, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
      final TextSpan afterSpan = TextSpan(text: afterSelection);
      final TextSpan newSpan = TextSpan(
        style: (contentController.value as TextSpan).style,
        children: <InlineSpan>[
          beforeSpan,
          selectionSpan,
          afterSpan,
        ],
      );
      contentController.value = newSpan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SelectionArea(
        controller: _selectionController,
        onSelectionChanged: (SelectedContent? selectedContent) {
            if (selectedContent == null 
                || selectedContent.plainText.isEmpty
                || (selectedContent.geometry.startSelectionPoint == null
                || selectedContent.geometry.endSelectionPoint == null)) {
            return;
          }
          _menuController.show(
            context: context,
            contextMenuBuilder: (BuildContext context) {
              return TapRegion(
                onTapOutside: (PointerDownEvent event) {
                  if (_menuController.isShown) {
                    ContextMenuController.removeAny();
                  }
                },
                child: AdaptiveTextSelectionToolbar.buttonItems(
                  buttonItems: <ContextMenuButtonItem>[
                    ContextMenuButtonItem(
                      onPressed: () {
                        ContextMenuController.removeAny();
                        _emphasizeText(selectedContent);
                        _selectionController.clear();
                      },
                      label: 'Emphasize Text',
                    ),
                  ],
                  anchors: TextSelectionToolbarAnchors(
                    primaryAnchor: selectedContent.geometry.endSelectionPoint!.localPosition,
                  ),
                ),
              );
            },
          );
        },
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('This is some text in a text widget.'),
              Text('This is some text in another text widget.'),
              Text('This is another text widget.'),
            ],
          ),
        ),
      ),
    );
  }
}
