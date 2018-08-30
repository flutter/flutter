// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Text respects media query', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(textScaleFactor: 1.3),
      child: Center(
        child: Text('Hello', textDirection: TextDirection.ltr)
      )
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);

    await tester.pumpWidget(const Center(
      child: Text('Hello', textDirection: TextDirection.ltr)
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
      child: Text('Hello', textScaleFactor: 1.5, textDirection: TextDirection.ltr)
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
      child: Text('Hello',
        style: TextStyle(fontSize: 20.0), textDirection: TextDirection.ltr)
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
        textDirection: TextDirection.ltr)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);
    final Size largeSize = tester.getSize(find.byType(RichText));
    expect(largeSize.width, anyOf(131.0, 130.0));
    expect(largeSize.height, equals(26.0));
  });

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
              TextSpan(text: ' beautiful ', style: TextStyle(fontStyle: FontStyle.italic)),
              TextSpan(text: 'world', style: TextStyle(fontWeight: FontWeight.bold)),
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

  testWidgets('semanticsLabel can override text label', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      const Text('\$\$', semanticsLabel: 'Double dollars', textDirection: TextDirection.ltr)
    );
    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          label: 'Double dollars',
          textDirection: TextDirection.ltr,
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true, ignoreRect: true));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('\$\$', semanticsLabel: 'Double dollars')),
    );

    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true, ignoreRect: true));
    semantics.dispose();
  });

  testWidgets('recognizers split semantic node', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      new Text.rich(
        new TextSpan(
          children: <TextSpan>[
            const TextSpan(text: 'hello '),
            new TextSpan(text: 'world', recognizer: new TapGestureRecognizer()..onTap = () {}),
            const TextSpan(text: ' this is a '),
            const TextSpan(text: 'cat-astrophe'),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          children: <TestSemantics>[
            new TestSemantics(
              label: 'hello ',
              textDirection: TextDirection.ltr,
            ),
            new TestSemantics(
              label: 'world',
              textDirection: TextDirection.ltr,
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),
            new TestSemantics(
              label: ' this is a cat-astrophe',
              textDirection: TextDirection.ltr,
            )
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true, ignoreRect: true));
    semantics.dispose();
  });

  testWidgets('recognizers split semantic node - bidi', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    const TextStyle textStyle = TextStyle(fontFamily: 'Ahem');
    await tester.pumpWidget(
      new RichText(
        text: new TextSpan(
          style: textStyle,
          children: <TextSpan>[
            const TextSpan(text: 'hello world${Unicode.RLE}${Unicode.RLO} '),
            new TextSpan(text: 'BOY', recognizer: new LongPressGestureRecognizer()..onLongPress = () {}),
            const TextSpan(text: ' HOW DO${Unicode.PDF} you ${Unicode.RLO} DO '),
            new TextSpan(text: 'SIR', recognizer: new TapGestureRecognizer()..onTap = () {}),
            const TextSpan(text: '${Unicode.PDF}${Unicode.PDF} good bye'),
          ],
        ),
        textDirection: TextDirection.ltr,
      )
    );
    // The expected visual order of the text is:
    //   hello world RIS OD you OD WOH YOB good bye
    final TestSemantics expectedSemantics = new TestSemantics.root(
      children: <TestSemantics>[
        new TestSemantics.rootChild(
          rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
          children: <TestSemantics>[
            new TestSemantics(
              rect: new Rect.fromLTRB(-4.0, -4.0, 480.0, 18.0),
              label: 'hello world ',
              textDirection: TextDirection.ltr, // text direction is declared as LTR.
            ),
            new TestSemantics(
              rect: new Rect.fromLTRB(150.0, -4.0, 200.0, 18.0),
              label: 'RIS',
              textDirection: TextDirection.rtl,  // in the last string we switched to RTL using RLE.
              actions: <SemanticsAction>[
                SemanticsAction.tap,
              ],
            ),
            new TestSemantics(
              rect: new Rect.fromLTRB(192.0, -4.0, 424.0, 18.0),
              label: ' OD you OD WOH ', // Still RTL.
              textDirection: TextDirection.rtl,
            ),
            new TestSemantics(
              rect: new Rect.fromLTRB(416.0, -4.0, 466.0, 18.0),
              label: 'YOB',
              textDirection: TextDirection.rtl, // Still RTL.
              actions: <SemanticsAction>[
                SemanticsAction.longPress,
              ],
            ),
            new TestSemantics(
              rect: new Rect.fromLTRB(472.0, -4.0, 606.0, 18.0),
              label: ' good bye',
              textDirection: TextDirection.rtl, // Begin as RTL but pop to LTR.
            ),
          ],
        ),
      ],
    );
    expect(semantics, hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true));
    semantics.dispose();
  }, skip: true); // TODO(jonahwilliams): correct once https://github.com/flutter/flutter/issues/20891 is resolved.
}
