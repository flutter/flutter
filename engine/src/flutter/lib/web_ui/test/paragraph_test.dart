// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' hide window;

import 'package:test/test.dart';

void testEachMeasurement(String description, VoidCallback body, {bool skip}) {
  test('$description (dom measurement)', () async {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      WebExperiments.instance.useCanvasText = false;
      return body();
    } finally {
      WebExperiments.instance.useCanvasText = null;
      TextMeasurementService.clearCache();
    }
  }, skip: skip);
  test('$description (canvas measurement)', () async {
    try {
      TextMeasurementService.initialize(rulerCacheCapacity: 2);
      WebExperiments.instance.useCanvasText = true;
      return body();
    } finally {
      WebExperiments.instance.useCanvasText = null;
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
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50771
      // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
      skip: (browserEngine != BrowserEngine.blink));

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
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50771
      skip: (browserEngine != BrowserEngine.blink));

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
    WebExperiments.instance.useCanvasText = true;
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
    paragraph.layout(const ParagraphConstraints(width: 100));

    // First line: "abcd\n"

    // At the beginning of the first line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 5)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // Above the first line.
    expect(
      paragraph.getPositionForOffset(Offset(0, -15)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // At the end of the first line.
    expect(
      paragraph.getPositionForOffset(Offset(50, 5)),
      TextPosition(offset: 4, affinity: TextAffinity.upstream),
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
      TextPosition(offset: 12, affinity: TextAffinity.upstream),
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
      paragraph.getPositionForOffset(Offset(100, 25)),
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
    WebExperiments.instance.useCanvasText = null;
  });

  test('getPositionForOffset multi-line centered', () {
    WebExperiments.instance.useCanvasText = true;
    TextMeasurementService.initialize(rulerCacheCapacity: 2);

    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    ));
    builder.addText('abcd\n');
    builder.addText('abcdefg\n');
    builder.addText('ab');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100));

    // First line: "abcd\n"

    // At the beginning of the first line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 5)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // Above the first line.
    expect(
      paragraph.getPositionForOffset(Offset(0, -15)),
      TextPosition(offset: 0, affinity: TextAffinity.downstream),
    );
    // At the end of the first line.
    expect(
      paragraph.getPositionForOffset(Offset(100, 5)),
      TextPosition(offset: 4, affinity: TextAffinity.upstream),
    );
    // On the left side of "b" in the first line.
    expect(
      // The line is centered so it's shifted to the right by "30.0px".
      paragraph.getPositionForOffset(Offset(30.0 + 14, 5)),
      TextPosition(offset: 1, affinity: TextAffinity.downstream),
    );
    // On the right side of "b" in the first line.
    expect(
      // The line is centered so it's shifted to the right by "30.0px".
      paragraph.getPositionForOffset(Offset(30.0 + 16, 5)),
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
      TextPosition(offset: 12, affinity: TextAffinity.upstream),
    );
    // On the left side of "e" in the second line.
    expect(
      // The line is centered so it's shifted to the right by "15.0px".
      paragraph.getPositionForOffset(Offset(15.0 + 44, 15)),
      TextPosition(offset: 9, affinity: TextAffinity.downstream),
    );
    // On the right side of "e" in the second line.
    expect(
      // The line is centered so it's shifted to the right by "15.0px".
      paragraph.getPositionForOffset(Offset(15.0 + 46, 15)),
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
      paragraph.getPositionForOffset(Offset(100, 25)),
      TextPosition(offset: 15, affinity: TextAffinity.upstream),
    );
    // Below the last line.
    expect(
      paragraph.getPositionForOffset(Offset(0, 32)),
      TextPosition(offset: 15, affinity: TextAffinity.upstream),
    );
    // On the left side of "b" in the last line.
    expect(
      // The line is centered so it's shifted to the right by "40.0px".
      paragraph.getPositionForOffset(Offset(40.0 + 12, 25)),
      TextPosition(offset: 14, affinity: TextAffinity.downstream),
    );
    // On the right side of "a" in the last line.
    expect(
      // The line is centered so it's shifted to the right by "40.0px".
      paragraph.getPositionForOffset(Offset(40.0 + 9, 25)),
      TextPosition(offset: 14, affinity: TextAffinity.upstream),
    );

    TextMeasurementService.clearCache();
    WebExperiments.instance.useCanvasText = null;
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
        970,
        0,
        980,
        10,
        TextDirection.rtl,
      ),
    );
  });

  testEachMeasurement('getBoxesForRange returns a box for rich text', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.ltr,
    ));
    builder.addText('abcd');
    builder.pushStyle(TextStyle(fontWeight: FontWeight.bold));
    builder.addText('xyz');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 1000));
    expect(
      paragraph.getBoxesForRange(1, 2).single,
      const TextBox.fromLTRBD(0, 0, 0, 10, TextDirection.ltr),
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

  testEachMeasurement('getBoxesForRange multi-line', () {
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
    paragraph.layout(const ParagraphConstraints(width: 100));

    // First line: "abcd\n"

    // At the beginning of the first line.
    expect(
      paragraph.getBoxesForRange(0, 0),
      <TextBox>[],
    );
    // At the end of the first line.
    expect(
      paragraph.getBoxesForRange(4, 4),
      <TextBox>[],
    );
    // Between "b" and "c" in the first line.
    expect(
      paragraph.getBoxesForRange(2, 2),
      <TextBox>[],
    );
    // The range "ab" in the first line.
    expect(
      paragraph.getBoxesForRange(0, 2),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 20.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "bc" in the first line.
    expect(
      paragraph.getBoxesForRange(1, 3),
      <TextBox>[
        TextBox.fromLTRBD(10.0, 0.0, 30.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "d" in the first line.
    expect(
      paragraph.getBoxesForRange(3, 4),
      <TextBox>[
        TextBox.fromLTRBD(30.0, 0.0, 40.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "\n" in the first line.
    expect(
      paragraph.getBoxesForRange(4, 5),
      <TextBox>[
        TextBox.fromLTRBD(40.0, 0.0, 40.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "cd\n" in the first line.
    expect(
      paragraph.getBoxesForRange(2, 5),
      <TextBox>[
        TextBox.fromLTRBD(20.0, 0.0, 40.0, 10.0, TextDirection.ltr),
      ],
    );

    // Second line: "abcdefg\n"

    // At the beginning of the second line.
    expect(
      paragraph.getBoxesForRange(5, 5),
      <TextBox>[],
    );
    // At the end of the second line.
    expect(
      paragraph.getBoxesForRange(12, 12),
      <TextBox>[],
    );
    // The range "efg" in the second line.
    expect(
      paragraph.getBoxesForRange(9, 12),
      <TextBox>[
        TextBox.fromLTRBD(40.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );
    // The range "bcde" in the second line.
    expect(
      paragraph.getBoxesForRange(6, 10),
      <TextBox>[
        TextBox.fromLTRBD(10.0, 10.0, 50.0, 20.0, TextDirection.ltr),
      ],
    );
    // The range "fg\n" in the second line.
    expect(
      paragraph.getBoxesForRange(10, 13),
      <TextBox>[
        TextBox.fromLTRBD(50.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );

    // Last (third) line: "ab"

    // At the beginning of the last line.
    expect(
      paragraph.getBoxesForRange(13, 13),
      <TextBox>[],
    );
    // At the end of the last line.
    expect(
      paragraph.getBoxesForRange(15, 15),
      <TextBox>[],
    );
    // The range "a" in the last line.
    expect(
      paragraph.getBoxesForRange(14, 15),
      <TextBox>[
        TextBox.fromLTRBD(10.0, 20.0, 20.0, 30.0, TextDirection.ltr),
      ],
    );
    // The range "ab" in the last line.
    expect(
      paragraph.getBoxesForRange(13, 15),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 20.0, 20.0, 30.0, TextDirection.ltr),
      ],
    );


    // Combine multiple lines

    // The range "cd\nabc".
    expect(
      paragraph.getBoxesForRange(2, 8),
      <TextBox>[
        TextBox.fromLTRBD(20.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 30.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "\nabcd".
    expect(
      paragraph.getBoxesForRange(4, 9),
      <TextBox>[
        TextBox.fromLTRBD(40.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 40.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "d\nabcdefg\na".
    expect(
      paragraph.getBoxesForRange(3, 14),
      <TextBox>[
        TextBox.fromLTRBD(30.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 20.0, 10.0, 30.0, TextDirection.ltr),
      ],
    );

    // The range "abcd\nabcdefg\n".
    expect(
      paragraph.getBoxesForRange(0, 13),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "abcd\nabcdefg\nab".
    expect(
      paragraph.getBoxesForRange(0, 15),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 20.0, 20.0, 30.0, TextDirection.ltr),
      ],
    );
  });

  testEachMeasurement('getBoxesForRange with maxLines', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    ));
    builder.addText('abcd\n');
    builder.addText('abcdefg\n');
    builder.addText('ab');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100));

    // First line: "abcd\n"

    // At the beginning of the first line.
    expect(
      paragraph.getBoxesForRange(0, 0),
      <TextBox>[],
    );
    // At the end of the first line.
    expect(
      paragraph.getBoxesForRange(4, 4),
      <TextBox>[],
    );
    // Between "b" and "c" in the first line.
    expect(
      paragraph.getBoxesForRange(2, 2),
      <TextBox>[],
    );
    // The range "ab" in the first line.
    expect(
      paragraph.getBoxesForRange(0, 2),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 20.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "bc" in the first line.
    expect(
      paragraph.getBoxesForRange(1, 3),
      <TextBox>[
        TextBox.fromLTRBD(10.0, 0.0, 30.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "d" in the first line.
    expect(
      paragraph.getBoxesForRange(3, 4),
      <TextBox>[
        TextBox.fromLTRBD(30.0, 0.0, 40.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "\n" in the first line.
    expect(
      paragraph.getBoxesForRange(4, 5),
      <TextBox>[
        TextBox.fromLTRBD(40.0, 0.0, 40.0, 10.0, TextDirection.ltr),
      ],
    );
    // The range "cd\n" in the first line.
    expect(
      paragraph.getBoxesForRange(2, 5),
      <TextBox>[
        TextBox.fromLTRBD(20.0, 0.0, 40.0, 10.0, TextDirection.ltr),
      ],
    );

    // Second line: "abcdefg\n"

    // At the beginning of the second line.
    expect(
      paragraph.getBoxesForRange(5, 5),
      <TextBox>[],
    );
    // At the end of the second line.
    expect(
      paragraph.getBoxesForRange(12, 12),
      <TextBox>[],
    );
    // The range "efg" in the second line.
    expect(
      paragraph.getBoxesForRange(9, 12),
      <TextBox>[
        TextBox.fromLTRBD(40.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );
    // The range "bcde" in the second line.
    expect(
      paragraph.getBoxesForRange(6, 10),
      <TextBox>[
        TextBox.fromLTRBD(10.0, 10.0, 50.0, 20.0, TextDirection.ltr),
      ],
    );
    // The range "fg\n" in the second line.
    expect(
      paragraph.getBoxesForRange(10, 13),
      <TextBox>[
        TextBox.fromLTRBD(50.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );

    // Last (third) line: "ab"

    // At the beginning of the last line.
    expect(
      paragraph.getBoxesForRange(13, 13),
      <TextBox>[],
    );
    // At the end of the last line.
    expect(
      paragraph.getBoxesForRange(15, 15),
      <TextBox>[],
    );
    // The range "a" in the last line.
    expect(
      paragraph.getBoxesForRange(14, 15),
      <TextBox>[],
    );
    // The range "ab" in the last line.
    expect(
      paragraph.getBoxesForRange(13, 15),
      <TextBox>[],
    );


    // Combine multiple lines

    // The range "cd\nabc".
    expect(
      paragraph.getBoxesForRange(2, 8),
      <TextBox>[
        TextBox.fromLTRBD(20.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 30.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "\nabcd".
    expect(
      paragraph.getBoxesForRange(4, 9),
      <TextBox>[
        TextBox.fromLTRBD(40.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 40.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "d\nabcdefg\na".
    expect(
      paragraph.getBoxesForRange(3, 14),
      <TextBox>[
        TextBox.fromLTRBD(30.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "abcd\nabcdefg\n".
    expect(
      paragraph.getBoxesForRange(0, 13),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );

    // The range "abcd\nabcdefg\nab".
    expect(
      paragraph.getBoxesForRange(0, 15),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
      ],
    );
  });

  testEachMeasurement('getBoxesForRange includes trailing spaces', () {
    const String text = 'abcd abcde  ';
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    ));
    builder.addText(text);
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getBoxesForRange(0, text.length),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 120.0, 10.0, TextDirection.ltr),
      ],
    );
  });

  testEachMeasurement('getBoxesForRange multi-line includes trailing spaces', () {
    const String text = 'abcd\nabcde  \nabc';
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle(
      fontFamily: 'Ahem',
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: 10,
    ));
    builder.addText(text);
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getBoxesForRange(0, text.length),
      <TextBox>[
        TextBox.fromLTRBD(0.0, 0.0, 40.0, 10.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 10.0, 70.0, 20.0, TextDirection.ltr),
        TextBox.fromLTRBD(0.0, 20.0, 30.0, 30.0, TextDirection.ltr),
      ],
    );
  });

  test('longestLine', () {
    // [Paragraph.longestLine] is only supported by canvas-based measurement.
    WebExperiments.instance.useCanvasText = true;
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
    WebExperiments.instance.useCanvasText = null;
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
    WebExperiments.instance.useCanvasText = true;
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
    WebExperiments.instance.useCanvasText = null;
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
