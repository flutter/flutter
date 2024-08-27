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

typedef _GlobalSpanRange = ({int startOffset, int endOffset});

class _MyHomePageState extends State<MyHomePage> {
  final ContextMenuController _menuController = ContextMenuController();
  final GlobalKey<SelectionAreaState> selectionAreaKey = GlobalKey<SelectionAreaState>();

  // The data of the top level TextSpans.
  Map<_GlobalSpanRange, TextSpan> dataSourceMap = <_GlobalSpanRange, TextSpan>{};
  // The data of the bulleted list contained within a TextSpan.
  Map<_GlobalSpanRange, TextSpan> bulletSourceMap = <_GlobalSpanRange, TextSpan>{};
  Map<_GlobalSpanRange, TextSpan> emphasizedTextMap = <_GlobalSpanRange, TextSpan>{};
  Map<int, Map<_GlobalSpanRange, TextSpan>> widgetSpanMaps = <int, Map<_GlobalSpanRange, TextSpan>>{};
  late final Map<_GlobalSpanRange, TextSpan> originSourceData;
  late final Map<_GlobalSpanRange, TextSpan> originBulletSourceData;
  late final Map<_GlobalSpanRange, TextSpan> originEmphasizedSourceData;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    const String bulletListTitle = 'This is some bulleted list:\n';
    const String textAfterBulletList = '\nSome text after the bulleted list.';
    const String emphasizedText = ' This text is emphasized.';
    const String endOfBulletTree = ' This is the end of the text widget.';
    final List<String> bullets = <String>[ 
      for (int i = 1; i <= 7; i += 1)
        '• Bullet $i'
    ];
    final String flattenedBulletedList = bulletListTitle + bullets.join();
    int currentOffset = 0;
    dataSourceMap[(startOffset: 0, endOffset: flattenedBulletedList.length + textAfterBulletList.length + emphasizedText.length + endOfBulletTree.length)] = TextSpan(
      text: bulletListTitle,
      children: <InlineSpan>[
        WidgetSpan(
          child: Column(
            children: <Widget>[
              for (final String bullet in bullets)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Text(bullet),
                )
            ],
          ),
        ),
        const TextSpan(
          text: textAfterBulletList,
          children: <InlineSpan>[
            WidgetSpan(
              child: Text(
                emphasizedText,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextSpan(text: endOfBulletTree),
          ],
        ),
      ],
    );
    currentOffset += bulletListTitle.length;
    widgetSpanMaps[currentOffset] = bulletSourceMap;
    for (final String bullet in bullets) {
      bulletSourceMap[(startOffset: currentOffset, endOffset: currentOffset + bullet.length)] = TextSpan(text: bullet);
      currentOffset += bullet.length;
    }
    currentOffset += textAfterBulletList.length;
    emphasizedTextMap[(startOffset: currentOffset, endOffset: currentOffset + emphasizedText.length)] = const TextSpan(text: emphasizedText, style: TextStyle(fontWeight: FontWeight.bold));
    widgetSpanMaps[currentOffset] = emphasizedTextMap;
    currentOffset += emphasizedText.length;
    currentOffset += endOfBulletTree.length;
    const TextSpan secondTextParagraph = TextSpan(
      text: 'This is some text in a text widget.',
      children: <InlineSpan>[TextSpan(text: ' This is some more text in the same text widget.')],
    );
    dataSourceMap[(startOffset: currentOffset, endOffset: currentOffset + secondTextParagraph.toPlainText(includeSemanticsLabels: false).length)] = secondTextParagraph;
    currentOffset += secondTextParagraph.toPlainText(includeSemanticsLabels: false).length;
    const TextSpan thirdTextParagraph = TextSpan(text: 'This is some text in another text widget.');
    dataSourceMap[(startOffset: currentOffset, endOffset: currentOffset + thirdTextParagraph.toPlainText(includeSemanticsLabels: false).length)] = thirdTextParagraph;
    // Save the origin data so we can revert our changes.
    originSourceData = <_GlobalSpanRange, TextSpan>{};
    for (final MapEntry<_GlobalSpanRange, TextSpan> entry in dataSourceMap.entries) {
      originSourceData[entry.key] = entry.value;
    }
    originBulletSourceData = <_GlobalSpanRange, TextSpan>{};
    for (final MapEntry<_GlobalSpanRange, TextSpan> entry in bulletSourceMap.entries) {
      originBulletSourceData[entry.key] = entry.value;
    }
    originEmphasizedSourceData = <_GlobalSpanRange, TextSpan>{};
    for (final MapEntry<_GlobalSpanRange, TextSpan> entry in emphasizedTextMap.entries) {
      originEmphasizedSourceData[entry.key] = entry.value;
    }
  }

  void _colorSelectionRed(
    SelectionDetails selectionDetails, {
    required Map<_GlobalSpanRange, TextSpan> dataMap,
    required bool coloringChildSpan,
  }) {
    for (final MapEntry<_GlobalSpanRange, TextSpan> entry in dataMap.entries) {
      final _GlobalSpanRange entryGlobalRange = entry.key;
      final int normalizedStartOffset = min(selectionDetails.globalStartOffset, selectionDetails.globalEndOffset);
      final int normalizedEndOffset = max(selectionDetails.globalStartOffset, selectionDetails.globalEndOffset);
      if (normalizedStartOffset > entryGlobalRange.endOffset) {
        continue;
      }
      if (normalizedEndOffset < entryGlobalRange.startOffset) {
        continue;
      }
      // The selection details is covering the current entry so let's color the range red.
      final TextSpan rawSpan = entry.value;
      // Determine local ranges.
      final int clampedGlobalStart = normalizedStartOffset < entryGlobalRange.startOffset ? entryGlobalRange.startOffset : normalizedStartOffset;
      final int clampedGlobalEnd = normalizedEndOffset > entryGlobalRange.endOffset ? entryGlobalRange.endOffset : normalizedEndOffset;
      final int startOffset = (clampedGlobalStart - entryGlobalRange.startOffset).abs();
      final int endOffset = startOffset + (clampedGlobalEnd - clampedGlobalStart).abs();
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
                    style: const TextStyle(color: Colors.red).merge(entry.value.style),
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
          if (!widgetSpanMaps.containsKey(count)) {
            // We have arrived at a WidgetSpan but it is unaccounted for.
            return true;
          }
          final Map<_GlobalSpanRange, TextSpan> widgetSpanSourceMap = widgetSpanMaps[count]!;
          if (count < startOffset && count + (widgetSpanSourceMap.keys.last.endOffset - widgetSpanSourceMap.keys.first.startOffset).abs() < startOffset) {
            // When the count is less than the startOffset and we are at a widgetspan
            // it is still possible that the startOffset is somewhere within the widgetspan,
            // so we should try to color the selection red for the widgetspan.
            //
            // If the calculated widgetspan length would not extend the count past the
            // startOffset then add this widgetspan to the beforeSelection, and
            // continue walking the tree.
            beforeSelection.add(child);
            count += (widgetSpanSourceMap.keys.last.endOffset - widgetSpanSourceMap.keys.first.startOffset).abs();
            return true;
          } else if (count >= endOffset) {
            afterSelection.add(child);
            count += (widgetSpanSourceMap.keys.last.endOffset - widgetSpanSourceMap.keys.first.startOffset).abs();
            return true;
          }
          // Update widgetspan data.
          _colorSelectionRed(
            selectionDetails,
            dataMap: widgetSpanSourceMap,
            coloringChildSpan: true,
          );
          // Re-create widgetspan.
          if (count == 28) {
            insideSelection.add(
              WidgetSpan(
                child: Column(
                  children: <Widget>[
                    for (final MapEntry<_GlobalSpanRange, TextSpan> entry in widgetSpanSourceMap.entries)
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text.rich(
                          widgetSpanSourceMap[entry.key]!,
                        ),
                      )
                  ],
                ),
              ),
            );
          }
          if (count == 133) {
            insideSelection.add(
              WidgetSpan(
                child: Text.rich(
                  widgetSpanSourceMap.entries.first.value,
                ),
              ),
            );
          }
          count += (widgetSpanSourceMap.keys.last.endOffset - widgetSpanSourceMap.keys.first.startOffset).abs();
          return true;
        }
        return true;
      });
      dataMap[entry.key] = TextSpan(
        style: dataMap[entry.key]!.style,
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
        child: SelectionListener(
          onSelectionChanged: (SelectionDetails selectionDetails) {
            if (_menuController.isShown) {
              ContextMenuController.removeAny();
            }
            if (selectionDetails.status != SelectionStatus.uncollapsed
               || !selectionDetails.selectionFinalized) {
              return;
            }
            if (selectionAreaKey.currentState == null
                || !selectionAreaKey.currentState!.mounted
                || selectionAreaKey.currentState!.selectableRegion.contextMenuAnchors.secondaryAnchor == null) {
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
                          _colorSelectionRed(
                            selectionDetails,
                            dataMap: dataSourceMap,
                            coloringChildSpan: false,
                          );
                          selectionAreaKey.currentState!.selectableRegion.clearSelection();
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final MapEntry<_GlobalSpanRange, TextSpan> entry in dataSourceMap.entries)
                  Text.rich(
                    entry.value,
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
            for (final MapEntry<_GlobalSpanRange, TextSpan> entry in originSourceData.entries) {
              dataSourceMap[entry.key] = entry.value;
            }
            for (final MapEntry<_GlobalSpanRange, TextSpan> entry in originBulletSourceData.entries) {
              bulletSourceMap[entry.key] = entry.value;
            }
            for (final MapEntry<_GlobalSpanRange, TextSpan> entry in originEmphasizedSourceData.entries) {
              emphasizedTextMap[entry.key] = entry.value;
            }
          });
        },
        child: const Icon(Icons.undo),
      ),
    );
  }
}
