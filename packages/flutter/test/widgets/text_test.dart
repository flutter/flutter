// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
      const Center(child: Text('Hello', textDirection: TextDirection.ltr))
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
  }, skip: isBrowser);

  testWidgets('Text respects textScaleFactor with explicit font size', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
      child: Text('Hello',
        style: TextStyle(fontSize: 20.0), textDirection: TextDirection.ltr),
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final Size baseSize = tester.getSize(find.byType(RichText));
    expect(baseSize.width, equals(100.0));
    expect(baseSize.height, equals(20.0));

    await tester.pumpWidget(const Center(
      child: Text('Hello',
        style: TextStyle(fontSize: 20.0),
        textScaleFactor: 1.3,
        textDirection: TextDirection.ltr),
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);
    final Size largeSize = tester.getSize(find.byType(RichText));
    expect(largeSize.width, anyOf(131.0, 130.0));
    expect(largeSize.height, equals(26.0));
  }, skip: isBrowser);

  testWidgets('Text throws a nice error message if there\'s no Directionality', (WidgetTester tester) async {
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
    expect(text.text.style.fontSize, 20.0);
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

  testWidgets('semanticsLabel can override text label', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      const Text(
        '\$\$',
        semanticsLabel: 'Double dollars',
        textDirection: TextDirection.ltr,
      )
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
        child: Text('\$\$', semanticsLabel: 'Double dollars')),
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
        ]),
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
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
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
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
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
  }, skip: isBrowser);


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
    final TestSemantics expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          rect: const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
          children: <TestSemantics>[
            TestSemantics(
              rect: const Rect.fromLTRB(-4.0, -4.0, 480.0, 18.0),
              label: 'hello world ',
              textDirection: TextDirection.ltr, // text direction is declared as LTR.
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(150.0, -4.0, 200.0, 18.0),
              label: 'RIS',
              textDirection: TextDirection.rtl,  // in the last string we switched to RTL using RLE.
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(192.0, -4.0, 424.0, 18.0),
              label: ' OD you OD WOH ', // Still RTL.
              textDirection: TextDirection.rtl,
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(416.0, -4.0, 466.0, 18.0),
              label: 'YOB',
              textDirection: TextDirection.rtl, // Still RTL.
              actions: <SemanticsAction>[
                SemanticsAction.longPress,
              ],
            ),
            TestSemantics(
              rect: const Rect.fromLTRB(472.0, -4.0, 606.0, 18.0),
              label: ' good bye',
              textDirection: TextDirection.rtl, // Begin as RTL but pop to LTR.
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
  }, skip: true); // TODO(jonahwilliams): correct once https://github.com/flutter/flutter/issues/20891 is resolved.

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
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
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
  }, skip: isBrowser);

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
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
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
  }, skip: isBrowser);

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
  }, skip: isBrowser);

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
              child: Container(
                // Each word takes up more than a half of a line. Together they
                // wrap onto two lines, but leave a lot of extra space.
                child: Text(
                  'twowordsthateachtakeupmorethanhalfof alineoftextsothattheywr'
                    'apwithlotsofextraspace',
                  textDirection: TextDirection.ltr,
                  textWidthBasis: textWidthBasis,
                ),
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
  }, skip: isBrowser);
}

Future<void> _pumpTextWidget({ WidgetTester tester, String text, TextOverflow overflow }) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
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
