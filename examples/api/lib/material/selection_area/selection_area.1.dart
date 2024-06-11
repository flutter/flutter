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
  final int _text1Id = SelectableRegionState.nextSelectableId;
  final int _text2Id = SelectableRegionState.nextSelectableId;
  final int _text3Id = SelectableRegionState.nextSelectableId;

  Map<int, TextSpan> dataSourceMap = <int, TextSpan>{};
  Map<int, TextSpan> bulletSourceMap = <int, TextSpan>{};
  late final Map<int, TextSpan> originSourceData;
  late final Map<int, TextSpan> originBulletSourceData;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  void _initData() {
    for (int i = 1; i <= 7; i += 1) {
      final int currentSelectableId = SelectableRegionState.nextSelectableId;
      bulletSourceMap[currentSelectableId] = TextSpan(text: '• Bullet $i');
    }
    dataSourceMap[_text1Id] = TextSpan(
      text: 'This is some bulleted list:\n',
      children: <InlineSpan>[
        WidgetSpan(
          child: Column(
            children: <Widget>[
              for (final MapEntry<int, TextSpan> entry in bulletSourceMap.entries)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text.rich(
                    bulletSourceMap[entry.key]!,
                    selectableId: entry.key,
                  ),
                )
            ],
          ),
        ),
      ],
    );
    dataSourceMap[_text2Id] = const TextSpan(
      text: 'This is some text in a text widget.',
      children: <InlineSpan>[TextSpan(text: ' This is some more text in the same text widget.')],
    );
    dataSourceMap[_text3Id] = const TextSpan(text: 'This is some text in another text widget.');
    // Save the origin data so we can revert our changes.
    originSourceData = <int, TextSpan>{ ...dataSourceMap };
    originBulletSourceData = <int, TextSpan>{ ...bulletSourceMap };
  }

  void _emphasizeText(List<SelectedContentController<Object>>? controllers, { Map<int, TextSpan>? dataMap }) {
    if (controllers == null || controllers.isEmpty) {
      return;
    }
    for (int index = 0; index < controllers.length; index += 1) {
      final SelectedContentController<Object> contentController = controllers[index];
      if (contentController.content is! TextSpan || contentController.selectableId == null) {
        // Do not edit the controller if it is not text or if a selectable id has not been provided.
        return;
      }
      final TextSpan rawSpan = contentController.content as TextSpan;
      final int startOffset = min(contentController.startOffset, contentController.endOffset);
      final int endOffset = max(contentController.startOffset, contentController.endOffset);
      final List<InlineSpan> beforeSelection = <InlineSpan>[];
      final List<InlineSpan> insideSelection = <InlineSpan>[];
      final List<InlineSpan> afterSelection = <InlineSpan>[];
      int count = 0;
      rawSpan.visitChildren((InlineSpan child) {
        if (child is TextSpan) {
          final String? rawText = child.text;
          if (rawText != null) {
            if (count < startOffset) {
              final int newStart = min(startOffset - count, rawText.length);
              final int globalNewStart = count + newStart;
              // Collect spans before selection.
              beforeSelection.add(
                TextSpan(
                  style: child.style,
                  text: rawText.substring(0, newStart),
                ),
              );
              // Check if this span also contains the selection.
              if (globalNewStart == startOffset && newStart < rawText.length) {
                final int newStartAfterSelection = min(newStart + (endOffset - startOffset), rawText.length);
                final int globalNewStartAfterSelection = count + newStartAfterSelection;
                insideSelection.add(
                  TextSpan(
                    style: const TextStyle(color: Colors.red),
                    text: rawText.substring(newStart, newStartAfterSelection),
                  ),
                );
                // Check if this span contains content after the selection.
                if (globalNewStartAfterSelection == endOffset && newStartAfterSelection < rawText.length) {
                  afterSelection.add(
                    TextSpan(
                      style: child.style,
                      text: rawText.substring(newStartAfterSelection),
                    ),
                  );
                }
              }
            } else if (count >= endOffset) {
              // Collect spans after selection.
              afterSelection.add(TextSpan(style: child.style, text: rawText));
            } else {
              // Collect spans inside selection.
              final int newStart = min(endOffset - count, rawText.length);
              final int globalNewStart = count + newStart;
              insideSelection.add(TextSpan(style: const TextStyle(color: Colors.red), text: rawText.substring(0, newStart)));
              // Check if this span contains content after the selection.
              if (globalNewStart == endOffset && newStart < rawText.length) {
                afterSelection.add(TextSpan(style: child.style, text: rawText.substring(newStart)));
              }
            }
            count += rawText.length;
          }
        } else if (child is WidgetSpan) {
          if (count < startOffset) {
            beforeSelection.add(child);
          } else if (count >= endOffset) {
            afterSelection.add(child);
          } else {
            // Update bulleted list data.
            for (final SelectedContentController<Object> controller in contentController.children) {
              _emphasizeText(
                <SelectedContentController<Object>>[controller],
                dataMap: bulletSourceMap,
              );
            }
            // Re-create bulleted list.
            insideSelection.add(
              WidgetSpan(
                child: Column(
                  children: <Widget>[
                    for (final MapEntry<int, TextSpan> entry in bulletSourceMap.entries)
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text.rich(
                          bulletSourceMap[entry.key]!,
                          selectableId: entry.key,
                        ),
                      )
                  ],
                ),
              ),
            );
          }
          count += 1;
        }
        return true;
      });
      if (dataMap != null) {
        dataMap[contentController.selectableId!] = TextSpan(
          style: (contentController.content as TextSpan).style,
          children: <InlineSpan>[
            ...beforeSelection,
            ...insideSelection,
            ...afterSelection,
          ],
        );
      } else {
        dataSourceMap[contentController.selectableId!] = TextSpan(
          style: (contentController.content as TextSpan).style,
          children: <InlineSpan>[
            ...beforeSelection,
            ...insideSelection,
            ...afterSelection,
          ],
        );
      }
    }
    _selectionController.clear();
    setState(() {});
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
                selectableId: _text1Id,
                dataSourceMap[_text1Id]!,
              ),
              Text.rich(
                selectableId: _text2Id,
                dataSourceMap[_text2Id]!,
              ),
              Text.rich(
                selectableId: _text3Id,
                dataSourceMap[_text3Id]!,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Resets the state to the origin data.
          for (final MapEntry<int, TextSpan> entry in originSourceData.entries) {
            dataSourceMap[entry.key] = entry.value;
          }
          for (final MapEntry<int, TextSpan> entry in originBulletSourceData.entries) {
            bulletSourceMap[entry.key] = entry.value;
          }
          setState(() {});
        },
        child: const Icon(Icons.undo),
      ),
    );
  }
}
