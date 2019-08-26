// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:test/test.dart';

import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import 'matchers.dart';

void main() async {
  const double baselineRatio = 1.1662499904632568;

  await webOnlyInitializeTestDomRenderer();

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
    expect(spans[0].style.fontFamily, 'Ahem');
    // The nested span here should not set it's family to default sans-serif.
    expect(spans[1].style.fontFamily, 'Ahem');
  });
}
