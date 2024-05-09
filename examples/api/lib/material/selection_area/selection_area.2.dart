// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() => runApp(const SelectionAreaInsertContentExampleApp());

class SelectionAreaInsertContentExampleApp extends StatelessWidget {
  const SelectionAreaInsertContentExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _aboutLorem =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin ac turpis vitae felis varius '
    'mattis. Nulla facilisi. Pellentesque habitant morbi tristique senectus et netus et malesuada '
    'fames ac turpis egestas. Aenean sit amet cursus turpis. Suspendisse potenti. Quisque vel '
    'libero ac ligula cursus tincidunt id vel metus. Vivamus at sapien sit amet quam feugiat '
    'fermentum sit amet nec velit.\n'
    '\n'
    'Vestibulum nec dui non odio fermentum consequat non id felis. Integer vel massa ut nunc '
    'congue cursus. Nunc eu lacus eros. Aliquam erat volutpat. Vivamus posuere libero at ligula '
    'ultrices, at volutpat risus auctor. Nullam ac mauris quis justo auctor tempor. Nulla quis '
    'lobortis nisi, ut bibendum felis. Duis ac libero sit amet magna varius sagittis vel in arcu.\n'
    '\n'
    'Etiam varius, eros ac gravida sagittis, mi justo vulputate mauris, non posuere lacus sapien '
    'quis lectus. Donec non felis et libero malesuada ultricies. Nulla facilisi. Vestibulum sed '
    'nulla ac libero venenatis ullamcorper. Integer fringilla diam eu eros euismod, a congue purus '
    'vulputate. Sed at urna in urna faucibus elementum. Curabitur eget orci at lacus efficitur '
    'dictum. Duis gravida bibendum sapien, sed fermentum libero vestibulum sed.\n'
    '\n'
    'Praesent congue ex et magna vehicula, nec fringilla dui sollicitudin. Quisque at erat et mi '
    'facilisis accumsan id a felis. Cras a interdum lacus, non bibendum libero. Nulla facilisi. '
    'Donec a dui sapien. Suspendisse potenti. Integer et risus quis arcu facilisis dignissim. '
    'Suspendisse potenti. Nam ac orci nec arcu malesuada vulputate.\n'
    '\n'
    'Sed vestibulum libero sit amet dolor fringilla, at aliquet purus sollicitudin. Donec sed '
    'nunc venenatis, bibendum libero ut, condimentum libero. Vivamus dictum lectus sit amet purus '
    'accumsan convallis. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere '
    'cubilia curae; Mauris volutpat, nisl a scelerisque vestibulum, dui felis varius mauris, et '
    'eleifend orci justo id lectus. Integer sagittis, lorem nec molestie condimentum, tortor nisl '
    'aliquam velit, eget efficitur justo mauris a ante.';

  final ContextMenuController _menuController = ContextMenuController();
  late final List<Widget> _textWidgets;
  final Map<Key, TextSpan> dataSourceMap = <Key, TextSpan>{};
  final GlobalKey<SelectionAreaState> selectionAreaKey = GlobalKey<SelectionAreaState>();

  @override
  void initState() {
    super.initState();
    _textWidgets = _initWidgets(_aboutLorem);
  }

  List<Widget> _initWidgets(String text) {
    final ParagraphBoundary paragraphBoundary = ParagraphBoundary(text);
    final List<Widget> paragraphWidgets = <Widget>[];
    int currentPosition = 0;

    while (currentPosition < text.length) {
      final int? start = paragraphBoundary.getLeadingTextBoundaryAt(currentPosition);
      final int? end = paragraphBoundary.getTrailingTextBoundaryAt(currentPosition);
      if (start == null || end == null) {
        break;
      }
      final String paragraphText = text.substring(start, end);
      final Key currentSelectableId = UniqueKey();
      dataSourceMap[currentSelectableId] = TextSpan(text: paragraphText.trim());
      paragraphWidgets.add(
        Text.rich(
          dataSourceMap[currentSelectableId]!,
          key: currentSelectableId,
        ),
      );
      currentPosition = end;
    }

    return paragraphWidgets;
  }

  List<InlineSpan> _initSpans(String text) {
    final ParagraphBoundary paragraphBoundary = ParagraphBoundary(text);
    final List<TextSpan> paragraphSpans = <TextSpan>[];
    int currentPosition = 0;

    while (currentPosition < text.length) {
      final int? start = paragraphBoundary.getLeadingTextBoundaryAt(currentPosition);
      final int? end = paragraphBoundary.getTrailingTextBoundaryAt(currentPosition);
      if (start == null || end == null) {
        break;
      }
      final String paragraphText = text.substring(start, end);
      paragraphSpans.add(TextSpan(text: paragraphText.trim()));
      currentPosition = end;
    }

    return paragraphSpans;
  }

  void _insertContent(List<SelectedContentRange> ranges, String plainText) {
    int rangeIndex = 0;
    final List<Widget> newText = <Widget>[];
    for (final SelectedContentRange contentRange in ranges) {
      if (contentRange.selectableId == null || !dataSourceMap.containsKey(contentRange.selectableId)) {
        // Cannot replace content at range if a selectable id has not been provided or if the selectableId
        // is not in the data model.
        return;
      }
      final TextSpan rawSpan = dataSourceMap[contentRange.selectableId]!;
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
                if (rangeIndex == 0) {
                  insideSelection.add(const TextSpan(text: '\n'));
                  insideSelection.add(const TextSpan(text: '\n'));
                  // Can either wrap with a SelectionArea so the WidgetSpan can have its
                  // own contained selection. Or a SelectionContainer.disabled to completely
                  // disable the selection of the WidgetSpan contents.
                  insideSelection.add(WidgetSpan(child: SelectionArea(child: DetailBox(children: _initSpans(plainText)))));
                  if (ranges.length == 1) {
                    insideSelection.add(const TextSpan(text: '\n'));
                    insideSelection.add(const TextSpan(text: '\n'));
                  }
                }
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
              if (rangeIndex == 0) {
                insideSelection.add(const TextSpan(text: '\n'));
                insideSelection.add(const TextSpan(text: '\n'));
                // Can either wrap with a SelectionArea so the WidgetSpan can have its
                // own contained selection. Or a SelectionContainer.disabled to completely
                // disable the selection of the WidgetSpan contents.
                insideSelection.add(WidgetSpan(child: SelectionArea(child: DetailBox(children: _initSpans(plainText)))));
                if (ranges.length == 1) {
                  insideSelection.add(const TextSpan(text: '\n'));
                  insideSelection.add(const TextSpan(text: '\n'));
                }
              }
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
            insideSelection.add(child);
          }
          count += 1;
        }
        return true;
      });
      dataSourceMap[contentRange.selectableId! as Key] = TextSpan(
        style: dataSourceMap[contentRange.selectableId]!.style,
        children: <InlineSpan>[
          ...beforeSelection,
          ...insideSelection,
          ...afterSelection,
        ],
      );
      rangeIndex += 1;
    }
    // Rebuild column contents.
    for (final MapEntry<Key, TextSpan> entry in dataSourceMap.entries) {
      newText.add(
        Text.rich(
          entry.value,
          key: entry.key,
        ),
      );
    }
    _textWidgets.clear();
    _textWidgets.addAll(newText);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
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
                          _insertContent(selectionDetails.ranges, 'Inserted Content');
                          selectionAreaKey.currentState!.selectableRegion.clearSelection();
                        },
                        label: 'Insert Content',
                      ),
                    ],
                    anchors: TextSelectionToolbarAnchors(primaryAnchor: selectionAreaKey.currentState!.selectableRegion.contextMenuAnchors.secondaryAnchor!),
                  ),
                );
              },
            );
          },
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
              height: 300.0,
              width: 300.0,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: _textWidgets,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailBox extends StatelessWidget {
  const DetailBox({
    super.key,
    required this.children,
  });

  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 75),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (
        BuildContext context,
        double value,
        Widget? child,
      ) {
        return Container(
          decoration: ShapeDecoration(
            color: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          height: value,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Text.rich(
                TextSpan(children: children),
                textAlign: TextAlign.start,
              ),
            ),
          ),
        );
      },
    );
  }
}
