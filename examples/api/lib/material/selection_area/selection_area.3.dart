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
    'Whether it\'s exploring the depths of the backyard or bravely venturing into unknown '
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
    'Steve’s intelligence is another trait that can\'t be overlooked. He’s not just skilled at '
    'learning tricks and following commands; Steve seems to understand the emotions and needs of '
    'his family, responding in ways that are both helpful and heartwarming. This emotional '
    'intelligence, combined with his playful antics, makes every interaction with him both '
    'meaningful and entertaining. Whether it’s playing fetch or simply lying by your side, Steve '
    'knows how to make the most of every moment.\n'
    '\n'
    'Socially, Steve is a star. His friendly demeanor and playful spirit make him a favorite among '
    'both dogs and humans alike. At the park, he\'s often seen leading the pack, initiating games, '
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
      paragraphWidgets.add(Text(paragraphText.trim()));
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

  void _insertContent(List<SelectedContentController> controllers, String plainText) {
    int count = 0;
    for (final SelectedContentController selectionInstance in controllers) {
      if (selectionInstance.value is! TextSpan) {
        // Do not edit the controller if it is not text.
        return;
      }
      final List<InlineSpan> newSpans = <InlineSpan>[];
      final int start = min(selectionInstance.startOffset, selectionInstance.endOffset);
      final int end = max(selectionInstance.startOffset, selectionInstance.endOffset);
      final String fullSpanText = selectionInstance.value.toPlainText(includeSemanticsLabels: false);
      final String dataBeforeInsertionOffset = fullSpanText.substring(0, start);
      final String dataAfterInsertionOffset = fullSpanText.substring(end, fullSpanText.length);
      final List<InlineSpan> spansBeforeInsertionOffset = _initSpans(dataBeforeInsertionOffset);
      final List<InlineSpan> spansAfterInsertionOffset = _initSpans(dataAfterInsertionOffset);
      newSpans.addAll(spansBeforeInsertionOffset);
      if (count == 0) {
        newSpans.add(const TextSpan(text: '\n'));
        newSpans.add(const TextSpan(text: '\n'));
        // Can either wrap with a SelectionArea so the WidgetSpan can have its
        // own contained selection. Or a SelectionContainer.disabled to completely
        // disable the selection of the WidgetSpan contents.
        newSpans.add(WidgetSpan(child: SelectionArea(child: DetailBox(children: _initSpans(plainText)))));
        if (controllers.length == 1) {
          newSpans.add(const TextSpan(text: '\n'));
          newSpans.add(const TextSpan(text: '\n'));
        }
      }
      newSpans.addAll(spansAfterInsertionOffset);
      selectionInstance.value = newSpans.isEmpty ? const TextSpan(text: '', style: TextStyle(fontSize: 0.0)) : TextSpan(children: newSpans, style: const TextStyle(color: Colors.black));
      count += 1;
    }
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
