// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Flutter code sample for [SelectionArea].

void main() => runApp(const SelectionAreaColorTextRedExampleApp());

class SelectionAreaColorTextRedExampleApp extends StatelessWidget {
  const SelectionAreaColorTextRedExampleApp({super.key});

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
  final GlobalKey<SelectionAreaState> selectionAreaKey = GlobalKey<SelectionAreaState>();

  Map<int, TextSpan> dataSourceMap = <int, TextSpan>{};
  Map<int, TextSpan> bulletSourceMap = <int, TextSpan>{};
  Map<int, SelectionDetails> selectionDetailsMap = <int, SelectionDetails>{};
  Map<int, SelectionDetails> bulletSelectionDetails = <int, SelectionDetails>{};
  late final Map<int, TextSpan> originSourceData;
  late final Map<int, TextSpan> originBulletSourceData;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    for (int i = 0; i <= 6; i += 1) {
      bulletSourceMap[i] = TextSpan(text: '• Bullet ${i + 1}');
    }
    dataSourceMap[0] = TextSpan(
      text: 'This is some bulleted list:\n',
      children: <InlineSpan>[
        WidgetSpan(
          child: Column(
            children: <Widget>[
              for (final MapEntry<int, TextSpan> entry in bulletSourceMap.entries)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: SelectionListener(
                    onSelectionChanged: (SelectionDetails selectionDetails) {
                      bulletSelectionDetails[entry.key] = selectionDetails;
                    },
                    child: Text.rich(
                      bulletSourceMap[entry.key]!,
                    ),
                  ),
                )
            ],
          ),
        ),
      ],
    );
    dataSourceMap[1] = const TextSpan(
      text: 'This is some text in a text widget.',
      children: <InlineSpan>[TextSpan(text: ' This is some more text in the same text widget.')],
    );
    dataSourceMap[2] = const TextSpan(text: 'This is some text in another text widget.');
    // Save the origin data so we can revert our changes.
    originSourceData = <int, TextSpan>{};
    originBulletSourceData = <int, TextSpan>{};
    for (final MapEntry<int, TextSpan> entry in dataSourceMap.entries) {
      originSourceData[entry.key] = entry.value;
    }
    for (final MapEntry<int, TextSpan> entry in bulletSourceMap.entries) {
      originBulletSourceData[entry.key] = entry.value;
    }
  }

  void _colorSelectionRed(
    List<SelectedContentRange> ranges, {
    required Map<int, TextSpan> dataMap,
    required bool coloringChildSpan,
    required int indexOfText,
  }) {
    if (ranges.isEmpty) {
      return;
    }
    for (int index = 0; index < ranges.length; index += 1) {
      final SelectedContentRange contentRange = ranges[index];
      final TextSpan rawSpan = dataMap[indexOfText]!;
      final int startOffset = min(contentRange.startOffset, contentRange.endOffset);
      final int endOffset = max(contentRange.startOffset, contentRange.endOffset);
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
            if (contentRange.children == null || bulletSelectionDetails.isEmpty) {
              count += 1;
              return true;
            }
            for (final MapEntry<int, SelectionDetails> entry in bulletSelectionDetails.entries) {
              if (!entry.value.selectionFinalized) {
                bulletSelectionDetails.clear();
                count += 1;
                return true;
              }
            }
            // Update bulleted list data.
            for (final MapEntry<int, SelectionDetails> entry in bulletSelectionDetails.entries) {
              _colorSelectionRed(
                entry.value.ranges,
                dataMap: bulletSourceMap,
                coloringChildSpan: true,
                indexOfText: entry.key,
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
                        child: SelectionListener(
                          onSelectionChanged: (SelectionDetails selectionDetails) {
                            bulletSelectionDetails[entry.key] = selectionDetails;
                          },
                          child: Text.rich(
                            bulletSourceMap[entry.key]!,
                          ),
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
      dataMap[indexOfText] = TextSpan(
        style: dataMap[indexOfText]!.style,
        children: <InlineSpan>[
          ...beforeSelection,
          ...insideSelection,
          ...afterSelection,
        ],
      );
    }
    // Avoid clearing the selection and setting the state
    // before we have colored all parts of the selection.
    if (!coloringChildSpan) {
      setState(() {});
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
        key: selectionAreaKey,
        child: Center(
          child: SelectionListener(
            onSelectionChanged: (SelectionDetails selectionDetails) {
              if (_menuController.isShown) {
                ContextMenuController.removeAny();
              }
              if (selectionDetails.status != SelectionStatus.uncollapsed || !selectionDetails.selectionFinalized || selectionDetailsMap.isEmpty) {
                selectionDetailsMap.clear();
                return;
              }
              if (selectionAreaKey.currentState == null
                  || !selectionAreaKey.currentState!.mounted
                  || selectionAreaKey.currentState!.selectableRegion.contextMenuAnchors.secondaryAnchor == null) {
                return;
              }
              for (final MapEntry<int, SelectionDetails> entry in selectionDetailsMap.entries) {
                if (!entry.value.selectionFinalized) {
                  selectionDetailsMap.clear();
                  return;
                }
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
                            for (final MapEntry<int, SelectionDetails> entry in selectionDetailsMap.entries) {
                              _colorSelectionRed(entry.value.ranges, dataMap: dataSourceMap, coloringChildSpan: false, indexOfText: entry.key);
                            }
                            selectionAreaKey.currentState!.selectableRegion.clearSelection();
                            selectionDetailsMap.clear();
                            bulletSelectionDetails.clear();
                          },
                          label: 'Color Text Red',
                        ),
                      ],
                      anchors: TextSelectionToolbarAnchors(primaryAnchor: selectionAreaKey.currentState!.selectableRegion.contextMenuAnchors.secondaryAnchor!),
                    ),
                  );
                },
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SelectionListener(
                  onSelectionChanged: (SelectionDetails selectionDetails) {
                    selectionDetailsMap[0] = selectionDetails;
                  },
                  child: Text.rich(
                    dataSourceMap[0]!,
                  ),
                ),
                SelectionListener(
                  onSelectionChanged: (SelectionDetails selectionDetails) {
                    selectionDetailsMap[1] = selectionDetails;
                  },
                  child: Text.rich(
                    dataSourceMap[1]!,
                  ),
                ),
                SelectionListener(
                  onSelectionChanged: (SelectionDetails selectionDetails) {
                    selectionDetailsMap[2] = selectionDetails;
                  },
                  child: Text.rich(
                    dataSourceMap[2]!,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Resets the state to the origin data.
            for (final MapEntry<int, TextSpan> entry in originSourceData.entries) {
              dataSourceMap[entry.key] = entry.value;
            }
            for (final MapEntry<int, TextSpan> entry in originBulletSourceData.entries) {
              bulletSourceMap[entry.key] = entry.value;
            }
          });
        },
        child: const Icon(Icons.undo),
      ),
    );
  }
}
