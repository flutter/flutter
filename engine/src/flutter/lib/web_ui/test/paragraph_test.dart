// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'package:test/test.dart';

void testEachMeasurement(String description, VoidCallback body, {bool skip}) {
  test(description, () async {
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
}
