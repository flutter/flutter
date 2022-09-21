// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'semantics_tester.dart';

void main() {
  testWidgets('Text respects media query', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(textScaleFactor: 1.3),
      child: Center(
        child: Text('Hello', textDirection: TextDirection.ltr),
      ),
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);

    await tester.pumpWidget(const Center(
      child: Text('Hello', textDirection: TextDirection.ltr),
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
  });

  testWidgets('Text respects textScaleFactor with default font size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(child: Text('Hello', textDirection: TextDirection.ltr)),
    );

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final Size baseSize = tester.getSize(find.byType(RichText));
    expect(baseSize.width, equals(70.0));
    expect(baseSize.height, equals(14.0));

    await tester.pumpWidget(const Center(
      child: Text(
        'Hello',
        textScaleFactor: 1.5,
        textDirection: TextDirection.ltr,
      ),
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.5);
    final Size largeSize = tester.getSize(find.byType(RichText));
    expect(largeSize.width, 105.0);
    expect(largeSize.height, equals(21.0));
  });

  testWidgets('Text respects textScaleFactor with explicit font size', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
      child: Text(
        'Hello',
        style: TextStyle(fontSize: 20.0),
        textDirection: TextDirection.ltr,
      ),
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final Size baseSize = tester.getSize(find.byType(RichText));
    expect(baseSize.width, equals(100.0));
    expect(baseSize.height, equals(20.0));

    await tester.pumpWidget(const Center(
      child: Text(
        'Hello',
        style: TextStyle(fontSize: 20.0),
        textScaleFactor: 1.3,
        textDirection: TextDirection.ltr,
      ),
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);
    final Size largeSize = tester.getSize(find.byType(RichText));
    expect(largeSize.width, anyOf(131.0, 130.0));
    expect(largeSize.height, equals(26.0));
  });

  testWidgets("Text throws a nice error message if there's no Directionality", (WidgetTester tester) async {
    await tester.pumpWidget(const Text('Hello'));
    final String message = tester.takeException().toString();
    expect(message, contains('Directionality'));
    expect(message, contains(' Text '));
  });

  testWidgets('Text can be created from TextSpans and uses defaultTextStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const DefaultTextStyle(
        style: TextStyle(
          fontSize: 20.0,
        ),
        child: Text.rich(
          TextSpan(
            text: 'Hello',
            children: <TextSpan>[
              TextSpan(
                text: ' beautiful ',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text: 'world',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    final RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.text.style!.fontSize, 20.0);
  });

  testWidgets('inline widgets works with ellipsis', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/35869
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(
              text: 'a very very very very very very very very very very long line',
            ),
            WidgetSpan(
              child: SizedBox(
                width: 20,
                height: 40,
                child: Card(
                  child: RichText(
                    text: const TextSpan(text: 'widget should be truncated'),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    expect(tester.takeException(), null);
  });

  testWidgets('inline widgets hitTest works with ellipsis', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/68559
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(
              text: 'a very very very very very very very very very very long line',
            ),
            WidgetSpan(
              child: SizedBox(
                width: 20,
                height: 40,
                child: Card(
                  child: RichText(
                    text: const TextSpan(text: 'widget should be truncated'),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    await tester.tap(find.byType(Text));

    expect(tester.takeException(), null);
  });

  testWidgets('inline widgets works with textScaleFactor', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/59316
    final UniqueKey key = UniqueKey();
    double textScaleFactor = 1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('title')),
          body: Center(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  WidgetSpan(
                    child: RichText(
                      text: const TextSpan(text: 'widget should be truncated'),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
              key: key,
              textDirection: TextDirection.ltr,
              textScaleFactor: textScaleFactor,
            ),
          ),
        ),
      ),
    );
    RenderBox renderText = tester.renderObject(find.byKey(key));
    final double singleLineHeight = renderText.size.height;
    // Now, increases the text scale factor by 5 times.
    textScaleFactor = textScaleFactor * 5;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('title')),
          body: Center(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  WidgetSpan(
                    child: RichText(
                      text: const TextSpan(text: 'widget should be truncated'),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
              key: key,
              textDirection: TextDirection.ltr,
              textScaleFactor: textScaleFactor,
            ),
          ),
        ),
      ),
    );

    renderText = tester.renderObject(find.byKey(key));
    // The RichText in the widget span should wrap into three lines.
    expect(renderText.size.height, singleLineHeight * textScaleFactor * 3);
  });

  testWidgets('semanticsLabel can override text label', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      const Text(
        r'$$',
        semanticsLabel: 'Double dollars',
        textDirection: TextDirection.ltr,
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          label: 'Double dollars',
          textDirection: TextDirection.ltr,
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text(r'$$', semanticsLabel: 'Double dollars'),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('semanticsLabel can be shorter than text', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            const TextSpan(
              text: 'Some Text',
              semanticsLabel: '',
            ),
            TextSpan(
              text: 'Clickable',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
          ],
        ),
      ),
    ));
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'Clickable',
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('recognizers split semantic node', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            const TextSpan(text: 'hello '),
            TextSpan(
              text: 'world',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
            const TextSpan(text: ' this is a '),
            const TextSpan(text: 'cat-astrophe'),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'hello ',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'world',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
            ),
            TestSemantics(
              label: ' this is a cat-astrophe',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('semantic nodes of offscreen recognizers are marked hidden', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/100395.
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem', fontSize: 200);
    const String onScreenText = 'onscreen\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n';
    const String offScreenText = 'off screen';
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      SingleChildScrollView(
        controller: controller,
        child: Text.rich(
          TextSpan(
            children: <TextSpan>[
              const TextSpan(text: onScreenText),
              TextSpan(
                text: offScreenText,
                recognizer: TapGestureRecognizer()..onTap = () { },
              ),
            ],
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
          actions: <SemanticsAction>[SemanticsAction.scrollUp],
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  label: onScreenText,
                  textDirection: TextDirection.ltr,
                ),
                TestSemantics(
                  label: offScreenText,
                  textDirection: TextDirection.ltr,
                  actions: <SemanticsAction>[SemanticsAction.tap],
                  flags: <SemanticsFlag>[SemanticsFlag.isLink, SemanticsFlag.isHidden],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );

    // Test show on screen.
    expect(controller.offset, 0.0);
    tester.binding.pipelineOwner.semanticsOwner!.performAction(4, SemanticsAction.showOnScreen);
    await tester.pumpAndSettle();
    expect(controller.offset != 0.0, isTrue);

    semantics.dispose();
  });

  testWidgets('recognizers split semantic node when TextSpan overflows', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      SizedBox(
        height: 10,
        child: Text.rich(
          TextSpan(
            children: <TextSpan>[
              const TextSpan(text: '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n'),
              TextSpan(
                text: 'world',
                recognizer: TapGestureRecognizer()..onTap = () { },
              ),
            ],
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'world',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('recognizers split semantic nodes with text span labels', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            const TextSpan(text: 'hello '),
            TextSpan(
              text: 'world',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
            const TextSpan(text: ' this is a '),
            const TextSpan(
              text: 'cat-astrophe',
              semanticsLabel: 'regrettable event',
            ),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'hello ',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'world',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
            ),
            TestSemantics(
              label: ' this is a regrettable event',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );
    semantics.dispose();
  });


  testWidgets('recognizers split semantic node - bidi', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      RichText(
        text: TextSpan(
          style: textStyle,
          children: <TextSpan>[
            const TextSpan(text: 'hello world${Unicode.RLE}${Unicode.RLO} '),
            TextSpan(
              text: 'BOY',
              recognizer: LongPressGestureRecognizer()..onLongPress = () { },
            ),
            const TextSpan(text: ' HOW DO${Unicode.PDF} you ${Unicode.RLO} DO '),
            TextSpan(
              text: 'SIR',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
            const TextSpan(text: '${Unicode.PDF}${Unicode.PDF} good bye'),
          ],
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    // The expected visual order of the text is:
    //   hello world RIS OD you OD WOH YOB good bye
    // There are five unique text areas, they are, in visual order but
    // showing the logical text:
    //   [hello world][SIR][HOW DO you DO][BOY][good bye]
    // The direction of each varies based on the first bit of that area.
    // The presence of the bidi formatting characters in the text is a
    // bit dubious, but that's what we do currently, and it's not really
    // clear what the perfect behavior would be...
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
          children: <TestSemantics>[
            TestSemantics(
              rect: const Rect.fromLTRB(-4.0, -4.0, 480.0, 18.0),
              label: 'hello world${Unicode.RLE}${Unicode.RLO} ',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(416.0, -4.0, 466.0, 18.0),
              label: 'BOY',
              textDirection: TextDirection.rtl,
              actions: <SemanticsAction>[SemanticsAction.longPress],
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(192.0, -4.0, 424.0, 18.0),
              label: ' HOW DO${Unicode.PDF} you ${Unicode.RLO} DO ',
              textDirection: TextDirection.rtl,
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(150.0, -4.0, 200.0, 18.0),
              label: 'SIR',
              textDirection: TextDirection.rtl,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(472.0, -4.0, 606.0, 18.0),
              label: '${Unicode.PDF}${Unicode.PDF} good bye',
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
      ),
    );
    semantics.dispose();
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/62945

  testWidgets('TapGesture recognizers contribute link semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: 'click me',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'click me',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(
      expectedSemantics,
      ignoreTransform: true,
      ignoreId: true,
      ignoreRect: true,
    ));
    semantics.dispose();
  });

  testWidgets('inline widgets generate semantic nodes', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: 'a '),
            TextSpan(
              text: 'pebble',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
            const TextSpan(text: ' in the '),
            WidgetSpan(
              child: SizedBox(
                width: 20,
                height: 40,
                child: Card(
                  child: RichText(
                    text: const TextSpan(text: 'INTERRUPTION'),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),
            const TextSpan(text: 'sky'),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'a ',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'pebble',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
            ),
            TestSemantics(
              label: ' in the ',
              textDirection: TextDirection.ltr,
            ),
            TestSemantics(
              label: 'INTERRUPTION',
              textDirection: TextDirection.rtl,
            ),
            TestSemantics(
              label: 'sky',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );
    semantics.dispose();
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/62945

  testWidgets('inline widgets semantic nodes scale', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: 'a '),
            TextSpan(
              text: 'pebble',
              recognizer: TapGestureRecognizer()..onTap = () { },
            ),
            const TextSpan(text: ' in the '),
            WidgetSpan(
              child: SizedBox(
                width: 20,
                height: 40,
                child: Card(
                  child: RichText(
                    text: const TextSpan(text: 'INTERRUPTION'),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),
            const TextSpan(text: 'sky'),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        textScaleFactor: 2,
      ),
    );
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
          children: <TestSemantics>[
            TestSemantics(
              label: 'a ',
              textDirection: TextDirection.ltr,
              rect: const Rect.fromLTRB(-4.0, 48.0, 60.0, 84.0),
            ),
            TestSemantics(
              label: 'pebble',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[SemanticsAction.tap],
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
              rect: const Rect.fromLTRB(52.0, 48.0, 228.0, 84.0),
            ),
            TestSemantics(
              label: ' in the ',
              textDirection: TextDirection.ltr,
              rect: const Rect.fromLTRB(220.0, 48.0, 452.0, 84.0),
            ),
            TestSemantics(
              label: 'INTERRUPTION',
              textDirection: TextDirection.rtl,
              rect: const Rect.fromLTRB(0.0, 0.0, 40.0, 80.0),
            ),
            TestSemantics(
              label: 'sky',
              textDirection: TextDirection.ltr,
              rect: const Rect.fromLTRB(484.0, 48.0, 576.0, 84.0),
            ),
          ],
        ),
      ],
    );
    expect(
      semantics,
      hasSemantics(
        expectedSemantics,
        ignoreTransform: true,
        ignoreId: true,
      ),
    );
    semantics.dispose();
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/62945

  testWidgets('Overflow is clipping correctly - short text with overflow: clip', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.clip,
      text: 'Hi',
    );

    expect(find.byType(Text), isNot(paints..clipRect()));
  });

  testWidgets('Overflow is clipping correctly - long text with overflow: ellipsis', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.ellipsis,
      text: 'a long long long long text, should be clip',
    );

    expect(
      find.byType(Text),
      paints..clipRect(rect: const Rect.fromLTWH(0, 0, 50, 50)),
    );
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87878

  testWidgets('Overflow is clipping correctly - short text with overflow: ellipsis', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.ellipsis,
      text: 'Hi',
    );

    expect(find.byType(Text), isNot(paints..clipRect()));
  });

  testWidgets('Overflow is clipping correctly - long text with overflow: fade', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.fade,
      text: 'a long long long long text, should be clip',
    );

    expect(
      find.byType(Text),
      paints..clipRect(rect: const Rect.fromLTWH(0, 0, 50, 50)),
    );
  });

  testWidgets('Overflow is clipping correctly - short text with overflow: fade', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.fade,
      text: 'Hi',
    );

    expect(find.byType(Text), isNot(paints..clipRect()));
  });

  testWidgets('Overflow is clipping correctly - long text with overflow: visible', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.visible,
      text: 'a long long long long text, should be clip',
    );

    expect(find.byType(Text), isNot(paints..clipRect()));
  });

  testWidgets('Overflow is clipping correctly - short text with overflow: visible', (WidgetTester tester) async {
    await _pumpTextWidget(
      tester: tester,
      overflow: TextOverflow.visible,
      text: 'Hi',
    );

    expect(find.byType(Text), isNot(paints..clipRect()));
  });

  testWidgets('textWidthBasis affects the width of a Text widget', (WidgetTester tester) async {
    Future<void> createText(TextWidthBasis textWidthBasis) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              // Each word takes up more than a half of a line. Together they
              // wrap onto two lines, but leave a lot of extra space.
              child: Text(
                'twowordsthateachtakeupmorethanhalfof alineoftextsothattheywrapwithlotsofextraspace',
                textDirection: TextDirection.ltr,
                textWidthBasis: textWidthBasis,
              ),
            ),
          ),
        ),
      );
    }

    const double fontHeight = 14.0;
    const double screenWidth = 800.0;

    // When textWidthBasis is parent, takes up full screen width.
    await createText(TextWidthBasis.parent);
    final Size textSizeParent = tester.getSize(find.byType(Text));
    expect(textSizeParent.width, equals(screenWidth));
    expect(textSizeParent.height, equals(fontHeight * 2));

    // When textWidthBasis is longestLine, sets the width to as small as
    // possible for the two lines.
    await createText(TextWidthBasis.longestLine);
    final Size textSizeLongestLine = tester.getSize(find.byType(Text));
    expect(textSizeLongestLine.width, equals(630.0));
    expect(textSizeLongestLine.height, equals(fontHeight * 2));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/44020

  testWidgets('textWidthBasis with textAlign still obeys parent alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text(
                  'LEFT ALIGNED, PARENT',
                  textAlign: TextAlign.left,
                  textWidthBasis: TextWidthBasis.parent,
                ),
                Text(
                  'RIGHT ALIGNED, PARENT',
                  textAlign: TextAlign.right,
                  textWidthBasis: TextWidthBasis.parent,
                ),
                Text(
                  'LEFT ALIGNED, LONGEST LINE',
                  textAlign: TextAlign.left,
                  textWidthBasis: TextWidthBasis.longestLine,
                ),
                Text(
                  'RIGHT ALIGNED, LONGEST LINE',
                  textAlign: TextAlign.right,
                  textWidthBasis: TextWidthBasis.longestLine,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // All Texts have the same horizontal alignment.
    final double offsetX = tester.getTopLeft(find.text('LEFT ALIGNED, PARENT')).dx;
    expect(tester.getTopLeft(find.text('RIGHT ALIGNED, PARENT')).dx, equals(offsetX));
    expect(tester.getTopLeft(find.text('LEFT ALIGNED, LONGEST LINE')).dx, equals(offsetX));
    expect(tester.getTopLeft(find.text('RIGHT ALIGNED, LONGEST LINE')).dx, equals(offsetX));

    // All Texts are less than or equal to the width of the Column.
    final double width = tester.getSize(find.byType(Column)).width;
    expect(tester.getSize(find.text('LEFT ALIGNED, PARENT')).width, lessThan(width));
    expect(tester.getSize(find.text('RIGHT ALIGNED, PARENT')).width, lessThan(width));
    expect(tester.getSize(find.text('LEFT ALIGNED, LONGEST LINE')).width, lessThan(width));
    expect(tester.getSize(find.text('RIGHT ALIGNED, LONGEST LINE')).width, equals(width));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/44020

  testWidgets(
    'textWidthBasis.longestLine confines the width of the paragraph '
    'when given loose constraints',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/62550.
      await tester.pumpWidget(
          Center(
            child: SizedBox(
              width: 400,
              child: Center(
                child: RichText(
                  text: const TextSpan(text: 'fwefwefwewfefewfwe fwfwfwefweabcdefghijklmnopqrstuvwxyz'),
                  textWidthBasis: TextWidthBasis.longestLine,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        );

      expect(find.byType(RichText), paints..something((Symbol method, List<dynamic> arguments) {
        if (method != #drawParagraph) {
          return false;
        }
        final ui.Paragraph paragraph = arguments[0] as ui.Paragraph;
        if (paragraph.longestLine > paragraph.width) {
          throw 'paragraph width (${paragraph.width}) greater than its longest line (${paragraph.longestLine}).';
        }
        if (paragraph.width >= 400) {
          throw 'paragraph.width (${paragraph.width}) >= 400';
        }
        return true;
      }));
    },
    skip: isBrowser, // https://github.com/flutter/flutter/issues/44020
  );

  testWidgets('Paragraph.getBoxesForRange returns nothing when selection range is zero length', (WidgetTester tester) async {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle());
    builder.addText('hello');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));
    expect(paragraph.getBoxesForRange(2, 2), isEmpty);
    paragraph.dispose();
  });

  // Regression test for https://github.com/flutter/flutter/issues/65818
  testWidgets('WidgetSpans with no semantic information are elided from semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    // Without the fix for this bug the pump widget will throw a RangeError.
    await tester.pumpWidget(
      RichText(
        textDirection: TextDirection.ltr,
        text: TextSpan(children: <InlineSpan>[
          const WidgetSpan(child: SizedBox.shrink()),
          TextSpan(
            text: 'HELLO',
            style: const TextStyle(color: Colors.black),
            recognizer: TapGestureRecognizer()..onTap = () {},
          ),
        ]),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          id: 1,
          rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
          transform: Matrix4(
            3.0,0.0,0.0,0.0,
            0.0,3.0,0.0,0.0,
            0.0,0.0,1.0,0.0,
            0.0,0.0,0.0,1.0,
          ),
          children: <TestSemantics>[
            TestSemantics(
              rect: const Rect.fromLTRB(-4.0, -4.0, 74.0, 18.0),
              id: 2,
              label: 'HELLO',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
              flags: <SemanticsFlag>[
                SemanticsFlag.isLink,
              ],
            ),
          ],
        ),
      ],
    )));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87877

  // Regression test for https://github.com/flutter/flutter/issues/69787
  testWidgets('WidgetSpans with no semantic information are elided from semantics - case 2', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(children: <InlineSpan>[
            const WidgetSpan(child: SizedBox.shrink()),
            const WidgetSpan(child: Text('included')),
            TextSpan(
              text: 'HELLO',
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
            const WidgetSpan(child: Text('included2')),
          ]),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(label: 'included'),
            TestSemantics(
              label: 'HELLO',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
              flags: <SemanticsFlag>[
                SemanticsFlag.isLink,
              ],
            ),
            TestSemantics(label: 'included2'),
          ],
        ),
      ],
    ),
    ignoreId: true,
    ignoreRect: true,
    ignoreTransform: true,
    ));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87877

  // Regression test for https://github.com/flutter/flutter/issues/69787
  testWidgets('WidgetSpans with no semantic information are elided from semantics - case 3', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(children: <InlineSpan>[
            const WidgetSpan(child: SizedBox.shrink()),
            WidgetSpan(
              child: Row(
                children: <Widget>[
                  Semantics(
                    container: true,
                    child: const Text('foo'),
                  ),
                  Semantics(
                    container: true,
                    child: const Text('bar'),
                  ),
                ],
              ),
            ),
            TextSpan(
              text: 'HELLO',
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ]),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(label: 'foo'),
            TestSemantics(label: 'bar'),
            TestSemantics(
              label: 'HELLO',
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
              flags: <SemanticsFlag>[
                SemanticsFlag.isLink,
              ],
            ),
          ],
        ),
      ],
    ),
    ignoreId: true,
    ignoreRect: true,
    ignoreTransform: true,
    ));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87877

  // Regression test for https://github.com/flutter/flutter/issues/69787
  testWidgets('WidgetSpans with no semantic information are elided from semantics - case 4', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ClipRect(
            child: Container(
              color: Colors.green,
              height: 100,
              width: 100,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: double.infinity,
                child: RichText(
                  text: TextSpan(
                    children: <InlineSpan>[
                      const WidgetSpan(
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          semanticLabel: 'not clipped',
                        ),
                      ),
                      TextSpan(
                        text: 'next WS is clipped',
                        recognizer: TapGestureRecognizer()..onTap = () { },
                      ),
                      const WidgetSpan(
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          semanticLabel: 'clipped',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics(label: 'not clipped'),
            TestSemantics(
              label: 'next WS is clipped',
              flags: <SemanticsFlag>[SemanticsFlag.isLink],
              actions: <SemanticsAction>[SemanticsAction.tap],
            ),
          ],
        ),
      ],
    ),
    ignoreId: true,
    ignoreRect: true,
    ignoreTransform: true,
    ));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/87877

  testWidgets('RenderParagraph intrinsic width', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 100,
            child: IntrinsicWidth(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, height: 1),
                  children: <InlineSpan>[
                    const TextSpan(text: 'S '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Wrap(
                        direction: Axis.vertical,
                        children: const <Widget>[
                          SizedBox(width: 200, height: 100),
                          SizedBox(width: 200, height: 30),
                        ],
                      ),
                    ),
                    const TextSpan(text: ' E'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(RichText)).width, 200 + 4 * 16.0);
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.byType(RichText));
    // The inline spans are rendered on one (horizontal) line, the sum of the widths is the max intrinsic width.
    expect(paragraph.getMaxIntrinsicWidth(0.0), 200 + 4 * 16.0);
    // The inline spans are rendered in one vertical run, the widest one determines the min intrinsic width.
    expect(paragraph.getMinIntrinsicWidth(0.0), 200);
  });

  testWidgets('Text uses TextStyle.overflow', (WidgetTester tester) async {
    const TextOverflow overflow = TextOverflow.fade;

    await tester.pumpWidget(const Text(
      'Hello World',
      textDirection: TextDirection.ltr,
      style: TextStyle(overflow: overflow),
    ));

    final RichText richText = tester.firstWidget(find.byType(RichText));

    expect(richText.overflow, overflow);
    expect(richText.text.style!.overflow, overflow);
  });

  testWidgets(
    'Text can be hit-tested without layout or paint being called in a frame',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/85108.
      await tester.pumpWidget(
        const Opacity(
          opacity: 1.0,
          child: Text(
            'Hello World',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: Color(0xFF123456)),
          ),
        ),
      );

      // The color changed and the opacity is set to 0:
      //  * 0 opacity will prevent RenderParagraph.paint from being called.
      //  * Only changing the color will prevent RenderParagraph.performLayout
      //    from being called.
      //  The underlying TextPainter should not evict its layout cache in this
      //  case, for hit-testing.
      await tester.pumpWidget(
        const Opacity(
          opacity: 0.0,
          child: Text(
            'Hello World',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: Color(0x87654321)),
          ),
        ),
      );

      await tester.tap(find.text('Hello World'));
      expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpTextWidget({
  required WidgetTester tester,
  required String text,
  required TextOverflow overflow,
}) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 50.0,
          height: 50.0,
          child: Text(
            text,
            overflow: overflow,
          ),
        ),
      ),
    ),
  );
}
