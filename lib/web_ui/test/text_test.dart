// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html';

import 'package:test/test.dart';

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'matchers.dart';

void main() async {
  const double baselineRatio = 1.1662499904632568;

  await webOnlyInitializeTestDomRenderer();

  String fallback;
  setUp(() {
    if (operatingSystem == OperatingSystem.macOs ||
        operatingSystem == OperatingSystem.iOs) {
      fallback = '-apple-system, BlinkMacSystemFont';
    } else {
      fallback = 'Arial';
    }
  });

  test('predictably lays out a single-line paragraph', () {
    for (double fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ));
      builder.addText('Test');
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 400.0));

      expect(paragraph.height, fontSize);
      expect(paragraph.width, 400.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 4.0);
      expect(paragraph.maxIntrinsicWidth, fontSize * 4.0);
      expect(paragraph.alphabeticBaseline, fontSize * .8);
      expect(
        paragraph.ideographicBaseline,
        within(
            distance: 0.001,
            from: paragraph.alphabeticBaseline * baselineRatio),
      );
    }
  });

  test('predictably lays out a multi-line paragraph', () {
    for (double fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ));
      builder.addText('Test Ahem');
      final Paragraph paragraph = builder.build();
      paragraph.layout(ParagraphConstraints(width: fontSize * 5.0));

      expect(paragraph.height, fontSize * 2.0); // because it wraps
      expect(paragraph.width, fontSize * 5.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 4.0);

      // TODO(yjbanov): due to https://github.com/flutter/flutter/issues/21965
      //                Flutter reports a different number. Ours is correct
      //                though.
      expect(paragraph.maxIntrinsicWidth, fontSize * 9.0);
      expect(paragraph.alphabeticBaseline, fontSize * .8);
      expect(
        paragraph.ideographicBaseline,
        within(
            distance: 0.001,
            from: paragraph.alphabeticBaseline * baselineRatio),
      );
    }
  });

  test('lay out unattached paragraph', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 14.0,
    ));
    builder.addText('How do you do this fine morning?');
    final EngineParagraph paragraph = builder.build();

    expect(paragraph.paragraphElement.parent, isNull);
    expect(paragraph.height, 0.0);
    expect(paragraph.width, -1.0);
    expect(paragraph.minIntrinsicWidth, 0.0);
    expect(paragraph.maxIntrinsicWidth, 0.0);
    expect(paragraph.alphabeticBaseline, -1.0);
    expect(paragraph.ideographicBaseline, -1.0);

    paragraph.layout(const ParagraphConstraints(width: 60.0));

    expect(paragraph.paragraphElement.parent, isNull);
    expect(paragraph.height, greaterThan(0.0));
    expect(paragraph.width, greaterThan(0.0));
    expect(paragraph.minIntrinsicWidth, greaterThan(0.0));
    expect(paragraph.maxIntrinsicWidth, greaterThan(0.0));
    expect(paragraph.minIntrinsicWidth, lessThan(paragraph.maxIntrinsicWidth));
    expect(paragraph.alphabeticBaseline, greaterThan(0.0));
    expect(paragraph.ideographicBaseline, greaterThan(0.0));
  });

  Paragraph measure(
      {String text = 'Hello', double fontSize = 14.0, double width = 50.0}) {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: fontSize,
    ));
    builder.addText(text);
    final Paragraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: width));
    return paragraph;
  }

  test('baseline increases with font size', () {
    Paragraph previousParagraph = measure(fontSize: 10.0);
    for (int i = 0; i < 6; i++) {
      final double fontSize = 20.0 + 10.0 * i;
      final Paragraph paragraph = measure(fontSize: fontSize);
      expect(paragraph.alphabeticBaseline,
          greaterThan(previousParagraph.alphabeticBaseline));
      expect(paragraph.ideographicBaseline,
          greaterThan(previousParagraph.ideographicBaseline));
      previousParagraph = paragraph;
    }
  });

  test('baseline does not depend on text', () {
    final Paragraph golden = measure(fontSize: 30.0);
    for (int i = 1; i < 30; i++) {
      final Paragraph paragraph = measure(text: 'hello ' * i, fontSize: 30.0);
      expect(paragraph.alphabeticBaseline, golden.alphabeticBaseline);
      expect(paragraph.ideographicBaseline, golden.ideographicBaseline);
    }
  });

  test('$ParagraphBuilder detects plain text', () {
    ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 15.0,
    ));
    builder.addText('hi');
    EngineParagraph paragraph = builder.build();
    expect(paragraph.plainText, isNotNull);
    expect(paragraph.geometricStyle.fontWeight, FontWeight.normal);

    builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 15.0,
    ));
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.addText('hi');
    paragraph = builder.build();
    expect(paragraph.plainText, isNotNull);
    expect(paragraph.geometricStyle.fontWeight, FontWeight.bold);
  });

  test('$ParagraphBuilder detects rich text', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 15.0,
    ));
    builder.addText('h');
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.addText('i');
    final EngineParagraph paragraph = builder.build();
    expect(paragraph.plainText, isNull);
    expect(paragraph.geometricStyle.fontWeight, FontWeight.normal);
  });

  test('$ParagraphBuilder treats empty text as plain', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 15.0,
    ));
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    final EngineParagraph paragraph = builder.build();
    expect(paragraph.plainText, '');
    expect(paragraph.geometricStyle.fontWeight, FontWeight.bold);
  });

  // Regression test for https://github.com/flutter/flutter/issues/34931.
  test('hit test on styled text returns correct span offset', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 15.0,
    ));
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    const String firstSpanText = 'XYZ';
    builder.addText(firstSpanText);
    builder.pushStyle(TextStyle(fontWeight: FontWeight.normal));
    const String secondSpanText = '1234';
    builder.addText(secondSpanText);
    builder.pushStyle(TextStyle(fontStyle: FontStyle.italic));
    builder.addText('followed by a link');
    final EngineParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 800.0));
    expect(paragraph.plainText, isNull);
    const int secondSpanStartPosition = firstSpanText.length;
    const int thirdSpanStartPosition =
        firstSpanText.length + secondSpanText.length;
    expect(paragraph.getPositionForOffset(const Offset(50, 0)).offset,
        secondSpanStartPosition);
    expect(paragraph.getPositionForOffset(const Offset(150, 0)).offset,
        thirdSpanStartPosition);
  });

  test('hit test on the nested text span and returns correct span offset', () {
    const fontFamily = 'sans-serif';
    const fontSize = 20.0;
    final style = TextStyle(fontFamily: fontFamily, fontSize: fontSize);
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
    ));

    const text00 = 'test test test test test te00 ';
    const text010 = 'test010 ';
    const text02 = 'test test test test te02 ';
    const text030 = 'test030 ';
    const text04 = 'test test test test test test test test test test te04 ';
    const text050 = 'test050 ';

    /* Logical arrangement: Tree

    Root TextSpan: 0
    */
    builder.pushStyle(style);
    {
      // 1st child TextSpan of Root: 0.0
      builder.pushStyle(style);
      builder.addText(text00);
      builder.pop();

      // 2nd child TextSpan of Root: 0.1
      builder.pushStyle(style);
      {
        // 1st child TextSpan of 0.1: 0.1.0
        builder.pushStyle(style);
        builder.addText(text010);
        builder.pop();
      }
      builder.pop();

      // 3rd child TextSpan of Root: 0.2
      builder.pushStyle(style);
      builder.addText(text02);
      builder.pop();

      // 4th child TextSpan of Root: 0.3
      builder.pushStyle(style);
      {
        // 1st child TextSpan of 0.3: 0.3.0
        builder.pushStyle(style);
        builder.addText(text030);
        builder.pop();
      }
      builder.pop();

      // 5th child TextSpan of Root: 0.4
      builder.pushStyle(style);
      builder.addText(text04);
      builder.pop();

      // 6th child TextSpan of Root: 0.5
      builder.pushStyle(style);
      {
        // 1st child TextSpan of 0.5: 0.5.0
        builder.pushStyle(style);
        builder.addText(text050);
        builder.pop();
      }
      builder.pop();
    }
    builder.pop();

    /* Display arrangement: Visible texts

    Because `const fontSize = 20.0`, the width of each character is 20 and the
    height is 20. `Display arrangement` squashes `Logical arrangement` to the
    (x, y) plane. That means `Display arrangement` only shows the visible texts.
    The order of texts is text00 --> text010 --> text02 --> text030 --> text04
    --> text050.

    The output is like that.

     |------------ 600 ------------| Begin of test010
     |--------------- 760 ----------------| End of test010
     |---------- 500 ---------| Begin of test030
     |------------- 660 -------------| End of test030
     |-- 180 --| Begin of test050
     |------ 360 -----| End of test050
    'test test test test test te00 test010 '
    'test test test test te02 test030 test '
    'test test test test test test test test '
    'test te04 test050 '
    */

    final Paragraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: 800));

    // Reference the offsets with the output of `Display arrangement`.
    const offset010 = text00.length;
    const offset030 = offset010 + text010.length + text02.length;
    const offset04 = offset030 + text030.length;
    const offset050 = offset04 + text04.length;
    // Tap text010.
    expect(paragraph.getPositionForOffset(Offset(700, 10)).offset, offset010);
    // Tap text030
    expect(paragraph.getPositionForOffset(Offset(600, 30)).offset, offset030);
    // Tap text050
    expect(paragraph.getPositionForOffset(Offset(220, 70)).offset, offset050);
    // Tap the left neighbor of text050
    expect(paragraph.getPositionForOffset(Offset(199, 70)).offset, offset04);
    // Tap the right neighbor of text050. No matter who the right neighbor of
    // text0505 is, it must not be text050 itself.
    expect(paragraph.getPositionForOffset(Offset(360, 70)).offset,
        isNot(offset050));
    // Tap the neighbor above text050
    expect(paragraph.getPositionForOffset(Offset(220, 59)).offset, offset04);
    // Tap the neighbor below text050. No matter who the neighbor above text050,
    // it must not be text050 itself.
    expect(paragraph.getPositionForOffset(Offset(220, 80)).offset,
        isNot(offset050));
  });

  // Regression test for https://github.com/flutter/flutter/issues/38972
  test(
      'should not set fontFamily to effectiveFontFamily for spans in rich text',
      () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Roboto',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 15.0,
    ));
    builder
        .pushStyle(TextStyle(fontFamily: 'Menlo', fontWeight: FontWeight.bold));
    const String firstSpanText = 'abc';
    builder.addText(firstSpanText);
    builder.pushStyle(TextStyle(fontSize: 30.0, fontWeight: FontWeight.normal));
    const String secondSpanText = 'def';
    builder.addText(secondSpanText);
    final EngineParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 800.0));
    expect(paragraph.plainText, isNull);
    final List<SpanElement> spans =
        paragraph.paragraphElement.querySelectorAll('span');
    expect(spans[0].style.fontFamily, 'Ahem, $fallback, sans-serif');
    // The nested span here should not set it's family to default sans-serif.
    expect(spans[1].style.fontFamily, 'Ahem, $fallback, sans-serif');
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50771
      // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      skip: (browserEngine == BrowserEngine.firefox ||
          browserEngine == BrowserEngine.edge));

  test('adds Arial and sans-serif as fallback fonts', () {
    // Set this to false so it doesn't default to 'Ahem' font.
    debugEmulateFlutterTesterEnvironment = false;

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'SomeFont',
      fontSize: 12.0,
    ));

    builder.addText('Hello');

    final EngineParagraph paragraph = builder.build();
    expect(paragraph.paragraphElement.style.fontFamily,
        'SomeFont, $fallback, sans-serif');

    debugEmulateFlutterTesterEnvironment = true;
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50771
      // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      skip: (browserEngine == BrowserEngine.firefox ||
          browserEngine == BrowserEngine.edge));

  test('does not add fallback fonts to generic families', () {
    // Set this to false so it doesn't default to 'Ahem' font.
    debugEmulateFlutterTesterEnvironment = false;

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'serif',
      fontSize: 12.0,
    ));

    builder.addText('Hello');

    final EngineParagraph paragraph = builder.build();
    expect(paragraph.paragraphElement.style.fontFamily, 'serif');

    debugEmulateFlutterTesterEnvironment = true;
  });

  test('can set font families that need to be quoted', () {
    // Set this to false so it doesn't default to 'Ahem' font.
    debugEmulateFlutterTesterEnvironment = false;

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'MyFont 2000',
      fontSize: 12.0,
    ));

    builder.addText('Hello');

    final EngineParagraph paragraph = builder.build();
    expect(paragraph.paragraphElement.style.fontFamily,
        '"MyFont 2000", $fallback, sans-serif');

    debugEmulateFlutterTesterEnvironment = true;
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50771
      skip: browserEngine == BrowserEngine.edge);

  group('TextRange', () {
    test('empty ranges are correct', () {
      const TextRange range = TextRange(start: -1, end: -1);
      expect(range, equals(const TextRange.collapsed(-1)));
      expect(range, equals(TextRange.empty));
    });
    test('isValid works', () {
      expect(TextRange.empty.isValid, isFalse);
      expect(const TextRange(start: 0, end: 0).isValid, isTrue);
      expect(const TextRange(start: 0, end: 10).isValid, isTrue);
      expect(const TextRange(start: 10, end: 10).isValid, isTrue);
      expect(const TextRange(start: -1, end: 10).isValid, isFalse);
      expect(const TextRange(start: 10, end: 0).isValid, isTrue);
      expect(const TextRange(start: 10, end: -1).isValid, isFalse);
    });
    test('isCollapsed works', () {
      expect(TextRange.empty.isCollapsed, isTrue);
      expect(const TextRange(start: 0, end: 0).isCollapsed, isTrue);
      expect(const TextRange(start: 0, end: 10).isCollapsed, isFalse);
      expect(const TextRange(start: 10, end: 10).isCollapsed, isTrue);
      expect(const TextRange(start: -1, end: 10).isCollapsed, isFalse);
      expect(const TextRange(start: 10, end: 0).isCollapsed, isFalse);
      expect(const TextRange(start: 10, end: -1).isCollapsed, isFalse);
    });
    test('isNormalized works', () {
      expect(TextRange.empty.isNormalized, isTrue);
      expect(const TextRange(start: 0, end: 0).isNormalized, isTrue);
      expect(const TextRange(start: 0, end: 10).isNormalized, isTrue);
      expect(const TextRange(start: 10, end: 10).isNormalized, isTrue);
      expect(const TextRange(start: -1, end: 10).isNormalized, isTrue);
      expect(const TextRange(start: 10, end: 0).isNormalized, isFalse);
      expect(const TextRange(start: 10, end: -1).isNormalized, isFalse);
    });
    test('textBefore works', () {
      expect(const TextRange(start: 0, end: 0).textBefore('hello'), isEmpty);
      expect(
          const TextRange(start: 1, end: 1).textBefore('hello'), equals('h'));
      expect(
          const TextRange(start: 1, end: 2).textBefore('hello'), equals('h'));
      expect(const TextRange(start: 5, end: 5).textBefore('hello'),
          equals('hello'));
      expect(const TextRange(start: 0, end: 5).textBefore('hello'), isEmpty);
    });
    test('textAfter works', () {
      expect(const TextRange(start: 0, end: 0).textAfter('hello'),
          equals('hello'));
      expect(
          const TextRange(start: 1, end: 1).textAfter('hello'), equals('ello'));
      expect(
          const TextRange(start: 1, end: 2).textAfter('hello'), equals('llo'));
      expect(const TextRange(start: 5, end: 5).textAfter('hello'), isEmpty);
      expect(const TextRange(start: 0, end: 5).textAfter('hello'), isEmpty);
    });
    test('textInside works', () {
      expect(const TextRange(start: 0, end: 0).textInside('hello'), isEmpty);
      expect(const TextRange(start: 1, end: 1).textInside('hello'), isEmpty);
      expect(
          const TextRange(start: 1, end: 2).textInside('hello'), equals('e'));
      expect(const TextRange(start: 5, end: 5).textInside('hello'), isEmpty);
      expect(const TextRange(start: 0, end: 5).textInside('hello'),
          equals('hello'));
    });
  });
}
