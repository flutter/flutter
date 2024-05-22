// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SelectionArea].

void main() => runApp(const SelectionAreaComplexEmphasizeTextExampleApp());

class SelectionAreaComplexEmphasizeTextExampleApp extends StatelessWidget {
  const SelectionAreaComplexEmphasizeTextExampleApp({super.key});

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

  String _trimPlaceholders(String text) {
    return text.replaceAll(String.fromCharCode(PlaceholderSpan.placeholderCodeUnit), '');
  }

  void _emphasizeText(List<SelectedContentController>? controllers) {
    if (controllers == null || controllers.isEmpty) {
      return;
    }
    for (int index = 0; index < controllers.length; index += 1) {
      // TODO(Renzo-Olivares): Should provide whether a controller is a text
      // controller or not.
      final SelectedContentController contentController = controllers[index];
      final String plainText = (contentController.value as TextSpan).toPlainText(includeSemanticsLabels: false);
      String collectedSelection = '';
      String beforeSelection = '';
      String afterSelection = '';
      final int startOffset = min(contentController.startOffset, contentController.endOffset);
      final int endOffset = max(contentController.startOffset, contentController.endOffset);
      // Collect text before selection.
      for (int j = 0; j < startOffset; j += 1) {
        beforeSelection += String.fromCharCode(plainText.codeUnitAt(j));
      }
      beforeSelection = _trimPlaceholders(beforeSelection);
      // Collect text inside selection.
      for (int j = startOffset; j < endOffset; j += 1) {
        final String currentChar = String.fromCharCode(plainText.codeUnitAt(j));
        if (currentChar == String.fromCharCode(PlaceholderSpan.placeholderCodeUnit)) {
          // There is a placeholder within the selection, we should consider checking
          // the children controllers if we would like to edit it more granularly.
          _emphasizeText(contentController.children);
          continue;
        }
        collectedSelection += currentChar;
      }
      collectedSelection = _trimPlaceholders(collectedSelection);
      // Collect text after selection.
      for (int j = endOffset; j < plainText.length; j += 1) {
        afterSelection += String.fromCharCode(plainText.codeUnitAt(j));
      }
      afterSelection = _trimPlaceholders(afterSelection);
      List<InlineSpan> concreteSpans = <InlineSpan>[];
      final TextSpan beforeSpan = TextSpan(text: beforeSelection);
      final TextSpan selectionSpan = TextSpan(text: collectedSelection, style: const TextStyle(color: Colors.red));
      final TextSpan afterSpan = TextSpan(text: afterSelection);
      // Check if any span is empty, if a span is empty do not include it in the
      // new span tree. Move any retained bullet children to the very last span.
      if (beforeSelection.isNotEmpty) {
        concreteSpans.add(beforeSpan);
      }
      if (collectedSelection.isNotEmpty) {
        concreteSpans.add(selectionSpan);
      }
      if (collectedSelection.isNotEmpty) {
        concreteSpans.add(afterSpan);
      }
      TextSpan lastSpan = concreteSpans.last as TextSpan;
      List<InlineSpan> collectedChildren = <InlineSpan>[];
      if ((contentController.value as TextSpan).children != null) {
        for (int i = 0; i < (contentController.value as TextSpan).children!.length; i += 1) {
          if (((contentController.value as TextSpan).children![i] as TextSpan).children != null) {
            collectedChildren.addAll(((contentController.value as TextSpan).children![i] as TextSpan).children!);
          }
        }
      }
      if (collectedChildren.isNotEmpty) {
        // Retain any children and place them in the last span.
        lastSpan = TextSpan(text: _trimPlaceholders(lastSpan.toPlainText(includeSemanticsLabels: false)), children: collectedChildren);
      }
      concreteSpans[concreteSpans.length - 1] = lastSpan;
      final TextSpan newSpan = TextSpan(
        style: (contentController.value as TextSpan).style,
        children: concreteSpans,
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
                        _emphasizeText(selectedContent.controllers);
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  text: 'This is some bulleted list:\n',
                  children: <InlineSpan>[
                    WidgetSpan(
                      child: Column(
                        children: <Widget>[
                          for (int i = 1; i <= 7; i += 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text('• Bullet $i'),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Text('This is some text in a text widget.'),
              const Text('Some more text in a different text widget.'),
            ],
          ),
        ),
      ),
    );
  }
}
