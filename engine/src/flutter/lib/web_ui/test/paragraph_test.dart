// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:test/test.dart';

void testEachMeasurement(String description, VoidCallback body, {bool skip}) {
  test('$description (dom measurement)', () async {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      return body();
    } finally {
      TextMeasurementService.clearCache();
    }
  }, skip: skip);
  test('$description (canvas measurement)', () async {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      TextMeasurementService.enableExperimentalCanvasImplementation = true;
      return body();
    } finally {
      TextMeasurementService.enableExperimentalCanvasImplementation = false;
      TextMeasurementService.clearCache();
    }
  }, skip: skip);
}

void main() async {
  await webOnlyInitializeTestDomRenderer();

  // Ahem font uses a constant ideographic/alphabetic baseline ratio.
  const double kAhemBaselineRatio = 1.25;

  testEachMeasurement('predictably lays out a single-line paragraph', () {
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

      expect(paragraph.height, closeTo(fontSize, 0.001));
      expect(paragraph.width, closeTo(400.0, 0.001));
      expect(paragraph.minIntrinsicWidth, closeTo(fontSize * 4.0, 0.001));
      expect(paragraph.maxIntrinsicWidth, closeTo(fontSize * 4.0, 0.001));
      expect(paragraph.alphabeticBaseline, closeTo(fontSize * .8, 0.001));
      expect(
        paragraph.ideographicBaseline,
        closeTo(paragraph.alphabeticBaseline * kAhemBaselineRatio, 3.0),
      );
    }
  });

  testEachMeasurement('predictably lays out a multi-line paragraph', () {
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

      expect(
          paragraph.height, closeTo(fontSize * 2.0, 0.001)); // because it wraps
      expect(paragraph.width, closeTo(fontSize * 5.0, 0.001));
      expect(paragraph.minIntrinsicWidth, closeTo(fontSize * 4.0, 0.001));

      // TODO(yjbanov): see https://github.com/flutter/flutter/issues/21965
      expect(paragraph.maxIntrinsicWidth, closeTo(fontSize * 9.0, 0.001));
      expect(paragraph.alphabeticBaseline, closeTo(fontSize * .8, 0.001));
      expect(
        paragraph.ideographicBaseline,
        closeTo(paragraph.alphabeticBaseline * kAhemBaselineRatio, 3.0),
      );
    }
  });

  testEachMeasurement('predictably lays out a single-line rich paragraph', () {
    for (double fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ));
      builder.addText('span1');
      builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
      builder.addText('span2');
      final Paragraph paragraph = builder.build();
      paragraph.layout(ParagraphConstraints(width: fontSize * 10.0));

      expect(paragraph.height, fontSize);
      expect(paragraph.width, fontSize * 10.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 10.0);
      expect(paragraph.maxIntrinsicWidth, fontSize * 10.0);
    }
  }, // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      skip: (browserEngine == BrowserEngine.firefox));

  testEachMeasurement('predictably lays out a multi-line rich paragraph', () {
    for (double fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ));
      builder.addText('12345 ');
      builder.addText('67890 ');
      builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
      builder.addText('bold');
      final Paragraph paragraph = builder.build();
      paragraph.layout(ParagraphConstraints(width: fontSize * 5.0));

      expect(paragraph.height, fontSize * 3.0); // because it wraps
      expect(paragraph.width, fontSize * 5.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 5.0);
      expect(paragraph.maxIntrinsicWidth, fontSize * 16.0);
    }
  }, // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      skip: (browserEngine == BrowserEngine.firefox));

  testEachMeasurement('getPositionForOffset single-line', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.ltr,
    ));
    builder.addText('abcd efg');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));

    // At the beginning of the line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 5)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // Below the line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 12)),
      TextPosition(offset: 8, affinity: TextAffinity.upstream),
    );
    // Above the line.
    expect(
      paragraph.getPositionForOffset(Offset(0, -5)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // At the end of the line.
    expect(
      paragraph.getPositionForOffset(Offset(80, 5)),
      TextPosition(offset: 8, affinity: TextAffinity.upstream),
    );
    // On the left side of "b".
    expect(
      paragraph.getPositionForOffset(Offset(14, 5)),
      TextPosition(offset: 1, affinity: TextAffinity.downstream),
    );
    // On the right side of "b".
    expect(
      paragraph.getPositionForOffset(Offset(16, 5)),
      TextPosition(offset: 2, affinity: TextAffinity.upstream),
    );
  });

  test('getPositionForOffset multi-line', () {
    // [Paragraph.getPositionForOffset] for multi-line text doesn't work well
    // with dom-based measurement.
    TextMeasurementService.enableExperimentalCanvasImplementation = true;
    TextMeasurementService.initialize(rulerCacheCapacity: 2);

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.ltr,
    ));
    builder.addText('abcd\n');
    builder.addText('abcdefg\n');
    builder.addText('ab');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));

    // First line: "abcd\n"

    // At the beginning of the first line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 5)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // Above the first line.
    expect(
      paragraph.getPositionForOffset(Offset(0, -5)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // At the end of the first line.
    expect(
      paragraph.getPositionForOffset(Offset(50, 5)),
      TextPosition(offset: 5, affinity: TextAffinity.upstream),
    );
    // On the left side of "b" in the first line.
    expect(
      paragraph.getPositionForOffset(Offset(14, 5)),
      TextPosition(offset: 1, affinity: TextAffinity.downstream),
    );
    // On the right side of "b" in the first line.
    expect(
      paragraph.getPositionForOffset(Offset(16, 5)),
      TextPosition(offset: 2, affinity: TextAffinity.upstream),
    );


    // Second line: "abcdefg\n"

    // At the beginning of the second line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 15)),
      TextPosition(offset: 5, affinity: TextAffinity.downstream),
    );
    // At the end of the second line.
    expect(
      paragraph.getPositionForOffset(Offset(100, 15)),
      TextPosition(offset: 13, affinity: TextAffinity.upstream),
    );
    // On the left side of "e" in the second line.
    expect(
      paragraph.getPositionForOffset(Offset(44, 15)),
      TextPosition(offset: 9, affinity: TextAffinity.downstream),
    );
    // On the right side of "e" in the second line.
    expect(
      paragraph.getPositionForOffset(Offset(46, 15)),
      TextPosition(offset: 10, affinity: TextAffinity.upstream),
    );


    // Last (third) line: "ab"

    // At the beginning of the last line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 25)),
      TextPosition(offset: 13, affinity: TextAffinity.downstream),
    );
    // At the end of the last line.
    expect(
      paragraph.getPositionForOffset(Offset(40, 25)),
      TextPosition(offset: 15, affinity: TextAffinity.upstream),
    );
    // Below the last line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 32)),
      TextPosition(offset: 15, affinity: TextAffinity.upstream),
    );
    // On the left side of "b" in the last line.
    expect(
      paragraph.getPositionForOffset(Offset(12, 25)),
      TextPosition(offset: 14, affinity: TextAffinity.downstream),
    );
    // On the right side of "a" in the last line.
    expect(
      paragraph.getPositionForOffset(Offset(9, 25)),
      TextPosition(offset: 14, affinity: TextAffinity.upstream),
    );

    TextMeasurementService.clearCache();
    TextMeasurementService.enableExperimentalCanvasImplementation = false;
  });

  testEachMeasurement('getBoxesForRange returns a box', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.rtl,
    ));
    builder.addText('abcd');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(
      paragraph.getBoxesForRange(1, 2).single,
      const TextBox.fromLTRBD(
        10,
        0,
        20,
        10,
        TextDirection.rtl,
      ),
    );
  });

  testEachMeasurement(
      'getBoxesForRange return empty list for zero-length range', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    ));
    builder.addText('abcd');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.getBoxesForRange(0, 0), isEmpty);
  });

  test('longestLine', () {
    // [Paragraph.longestLine] is only supported by canvas-based measurement.
    TextMeasurementService.enableExperimentalCanvasImplementation = true;
    TextMeasurementService.initialize(rulerCacheCapacity: 2);

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    ));
    builder.addText('abcd\nabcde abc');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 80.0));
    expect(paragraph.longestLine, 50.0);

    TextMeasurementService.clearCache();
    TextMeasurementService.enableExperimentalCanvasImplementation = false;
  });

  testEachMeasurement('getLineBoundary (single-line)', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    ));
    builder.addText('One single line');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400.0));

    // "One single line".length == 15
    for (int i = 0; i < 15; i++) {
      expect(
        paragraph.getLineBoundary(TextPosition(offset: i)),
        TextRange(start: 0, end: 15),
        reason: 'failed at offset $i',
      );
    }
  });

  test('getLineBoundary (multi-line)', () {
    // [Paragraph.getLineBoundary] for multi-line paragraphs is only supported
    // by canvas-based measurement.
    TextMeasurementService.enableExperimentalCanvasImplementation = true;
    TextMeasurementService.initialize(rulerCacheCapacity: 2);

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    ));
    builder.addText('First line\n');
    builder.addText('Second line\n');
    builder.addText('Third line');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400.0));

    // "First line\n".length == 11
    for (int i = 0; i < 11; i++) {
      expect(
        paragraph.getLineBoundary(TextPosition(offset: i)),
        TextRange(start: 0, end: 11),
        reason: 'failed at offset $i',
      );
    }

    // "Second line\n".length == 12
    for (int i = 11; i < 23; i++) {
      expect(
        paragraph.getLineBoundary(TextPosition(offset: i)),
        TextRange(start: 11, end: 23),
        reason: 'failed at offset $i',
      );
    }

    // "Third line".length == 10
    for (int i = 23; i < 33; i++) {
      expect(
        paragraph.getLineBoundary(TextPosition(offset: i)),
        TextRange(start: 23, end: 33),
        reason: 'failed at offset $i',
      );
    }

    TextMeasurementService.clearCache();
    TextMeasurementService.enableExperimentalCanvasImplementation = false;
  });

  testEachMeasurement('width should be a whole integer', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.ltr,
    ));
    builder.addText('abc');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 30.8));

    expect(paragraph.width, 30);
    expect(paragraph.height, 10);
  });
}
