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

  // This widget is the root of your application.
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
  static const String _aboutSteve =
    'Steve is a dog whose personality is as unique as his name. Not your average canine, '
    'Steve exudes a sense of adventure and curiosity that sets him apart from his peers. '
    'Whether it is exploring the depths of the backyard or bravely venturing into unknown '
    'territories during his walks, Steve approaches life with a wagging tail and an eager heart. '
    'His keen senses and intuitive nature often lead him to discover things that would otherwise '
    'go unnoticed, making every day an exciting adventure.\n'
    '\n'
    'At home, Steve is the epitome of loyalty and companionship. His family knows they can always '
    'count on him for comfort and joy, especially on the days when they need it the most. With a '
    'gentle nudge of his nose or a comforting rest of his head on their lap, Steve has a way of '
    'making problems seem less daunting. His presence in the house is like a beacon of warmth and '
    'love, illuminating the lives of those around him.\n'
    '\n'
    'Steve’s intelligence is another trait that can not be overlooked. He’s not just skilled at '
    'learning tricks and following commands; Steve seems to understand the emotions and needs of '
    'his family, responding in ways that are both helpful and heartwarming. This emotional '
    'intelligence, combined with his playful antics, makes every interaction with him both '
    'meaningful and entertaining. Whether it’s playing fetch or simply lying by your side, Steve '
    'knows how to make the most of every moment.\n'
    '\n'
    'Socially, Steve is a star. His friendly demeanor and playful spirit make him a favorite among '
    'both dogs and humans alike. At the park, he is often seen leading the pack, initiating games, '
    'and making new friends. Steve’s ability to get along with everyone, coupled with his '
    'infectious energy, often turns a simple outing into an unforgettable experience for everyone '
    'involved.\n'
    '\n'
    'As the seasons change, so do the adventures and stories that come with Steve. From basking in '
    'the summer sun to leaving paw prints in the winter snow, each season offers new opportunities '
    'for discovery and fun. Steve embraces these changes with enthusiasm, reminding everyone of '
    'the joy and wonder that the world has to offer. Through his eyes, life is an endless '
    'adventure, full of moments to be cherished and explored.';

  final ContextMenuController _menuController = ContextMenuController();
  final SelectionController _selectionController = SelectionController();
  late final List<Widget> _textWidgets;
  final Map<int, TextSpan> dataSourceMap = <int, TextSpan>{};

  @override
  void initState() {
    super.initState();
    _textWidgets = _initWidgets(_aboutSteve);
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
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
      final int currentSelectableId = SelectableRegionState.nextSelectableId;
      dataSourceMap[currentSelectableId] = TextSpan(text: paragraphText.trim());
      paragraphWidgets.add(
        Text.rich(
          dataSourceMap[currentSelectableId]!,
          selectableId: currentSelectableId,
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

  void _insertContent(List<SelectedContentController<Object>> controllers, String plainText) {
    int controllerIndex = 0;
    final List<Widget> newText = <Widget>[];
    for (final SelectedContentController<Object> contentController in controllers) {
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
                if (controllerIndex == 0) {
                  insideSelection.add(const TextSpan(text: '\n'));
                  insideSelection.add(const TextSpan(text: '\n'));
                  // Can either wrap with a SelectionArea so the WidgetSpan can have its
                  // own contained selection. Or a SelectionContainer.disabled to completely
                  // disable the selection of the WidgetSpan contents.
                  insideSelection.add(WidgetSpan(child: SelectionArea(child: DetailBox(children: _initSpans(plainText)))));
                  if (controllers.length == 1) {
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
              final int newStart = min(endOffset - startOffset, rawText.length); 
              final int globalNewStart = count + newStart;
              if (controllerIndex == 0) {
                insideSelection.add(const TextSpan(text: '\n'));
                insideSelection.add(const TextSpan(text: '\n'));
                // Can either wrap with a SelectionArea so the WidgetSpan can have its
                // own contained selection. Or a SelectionContainer.disabled to completely
                // disable the selection of the WidgetSpan contents.
                insideSelection.add(WidgetSpan(child: SelectionArea(child: DetailBox(children: _initSpans(plainText)))));
                if (controllers.length == 1) {
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
          count += 1;
          if (count < startOffset) {
            beforeSelection.add(child);
          } else if (count >= endOffset) {
            afterSelection.add(child);
          } else {
            insideSelection.add(child);
          }
        }
        return true;
      });
      dataSourceMap[contentController.selectableId!] = TextSpan(
        style: (contentController.content as TextSpan).style,
        children: <InlineSpan>[
          ...beforeSelection,
          ...insideSelection,
          ...afterSelection,
        ],
      );
      controllerIndex += 1;
    }
    // Rebuild column contents.
    for (final MapEntry<int, TextSpan> entry in dataSourceMap.entries) {
      newText.add(
        Text.rich(
          entry.value,
          selectableId: entry.key,
        ),
      );
    }
    _textWidgets.clear();
    _textWidgets.addAll(newText);
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
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
                        if (selectedContent.controllers != null) {
                          _insertContent(selectedContent.controllers!, selectedContent.plainText);
                        }
                        _selectionController.clear();
                      },
                      label: 'Insert Content',
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
