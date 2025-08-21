// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const int count = 1000;

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('First layout small text', () async {
    final buildWatch = Stopwatch();
    final layoutWatch = Stopwatch();
    Duration codeUnitFlagsDuration = Duration.zero;
    Duration textClustersDuration = Duration.zero;
    Duration bidiRunsDuration = Duration.zero;
    Duration lineBreaksDuration = Duration.zero;
    Duration measureTextDuration = Duration.zero;
    Duration getTextClustersDuration = Duration.zero;
    Duration queryTextMetricsDuration = Duration.zero;
    Duration mappingDuration = Duration.zero;
    Duration skiaDuration = Duration.zero;
    Duration chromeDuration = Duration.zero;
    for (int i = 0; i < count; i++) {
      buildWatch.start();
      final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
      final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
      builder.addText('Small text$i.');
      final Paragraph paragraph = builder.build();
      buildWatch.stop();
      layoutWatch.start();
      paragraph.layout(const ParagraphConstraints(width: 500));
      layoutWatch.stop();
      if (paragraph is WebParagraph) {
        final (
          Duration d1,
          Duration d2,
          Duration d3,
          Duration d4,
          Duration d5,
          Duration d6,
          Duration d7,
          Duration d8,
        ) = paragraph
            .getLayoutDurations();
        codeUnitFlagsDuration += d1;
        textClustersDuration += d2;
        bidiRunsDuration += d3;
        lineBreaksDuration += d4;
        measureTextDuration += d5;
        getTextClustersDuration += d6;
        queryTextMetricsDuration += d7;
        mappingDuration += d8;
        skiaDuration += paragraph.skiaDuration;
        chromeDuration += paragraph.chromeDuration;
      }
    }
    print('build("{Small text}*#N") * $count executed in ${buildWatch.elapsed}');
    print('layout("{Small text}*#N") * $count executed in ${layoutWatch.elapsed}');
    print('codeUnitFlags: $codeUnitFlagsDuration');
    print('   Skia queries: $skiaDuration');
    print('   Chrome queries: $chromeDuration');
    print('textClusters: $textClustersDuration');
    print('   getTextClusters: $getTextClustersDuration');
    print('   queryTextMetrics: $queryTextMetricsDuration');
    print('   mapping: $mappingDuration');
    print('bidiRuns: $bidiRunsDuration');
    print('lineBreaks: $lineBreaksDuration');
    print('measureText: $measureTextDuration');
  });

  test('First layout medium text no cache', () async {
    final buildWatch = Stopwatch();
    final layoutWatch = Stopwatch();
    Duration codeUnitFlagsDuration = Duration.zero;
    Duration textClustersDuration = Duration.zero;
    Duration bidiRunsDuration = Duration.zero;
    Duration lineBreaksDuration = Duration.zero;
    Duration measureTextDuration = Duration.zero;
    Duration getTextClustersDuration = Duration.zero;
    Duration queryTextMetricsDuration = Duration.zero;
    Duration mappingDuration = Duration.zero;
    Duration skiaDuration = Duration.zero;
    Duration chromeDuration = Duration.zero;
    for (int i = 0; i < count; i++) {
      buildWatch.start();
      final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
      final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
      builder.addText(
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz$i.',
      );
      final Paragraph paragraph = builder.build();
      buildWatch.stop();
      layoutWatch.start();
      paragraph.layout(const ParagraphConstraints(width: 500));
      layoutWatch.stop();
      if (paragraph is WebParagraph) {
        final (
          Duration d1,
          Duration d2,
          Duration d3,
          Duration d4,
          Duration d5,
          Duration d6,
          Duration d7,
          Duration d8,
        ) = paragraph
            .getLayoutDurations();
        codeUnitFlagsDuration += d1;
        textClustersDuration += d2;
        bidiRunsDuration += d3;
        lineBreaksDuration += d4;
        measureTextDuration += d5;
        getTextClustersDuration += d6;
        queryTextMetricsDuration += d7;
        mappingDuration += d8;
        skiaDuration += paragraph.skiaDuration;
        chromeDuration += paragraph.chromeDuration;
      }
    }
    print('build("{Medium text}*#N") * $count executed in ${buildWatch.elapsed}');
    print('layout("{Medium text}*#N") * $count executed in ${layoutWatch.elapsed}');
    print('codeUnitFlags: $codeUnitFlagsDuration');
    print('   Skia queries: $skiaDuration');
    print('   Chrome queries: $chromeDuration');
    print('textClusters: $textClustersDuration');
    print('   getTextClusters: $getTextClustersDuration');
    print('   queryTextMetrics: $queryTextMetricsDuration');
    print('   mapping: $mappingDuration');
    print('bidiRuns: $bidiRunsDuration');
    print('lineBreaks: $lineBreaksDuration');
    print('measureText: $measureTextDuration');
  });

  test('First large medium text no cache', () async {
    final buildWatch = Stopwatch();
    final layoutWatch = Stopwatch();
    Duration codeUnitFlagsDuration = Duration.zero;
    Duration textClustersDuration = Duration.zero;
    Duration bidiRunsDuration = Duration.zero;
    Duration lineBreaksDuration = Duration.zero;
    Duration measureTextDuration = Duration.zero;
    Duration getTextClustersDuration = Duration.zero;
    Duration queryTextMetricsDuration = Duration.zero;
    Duration mappingDuration = Duration.zero;
    Duration skiaDuration = Duration.zero;
    Duration chromeDuration = Duration.zero;
    for (int i = 0; i < count; i++) {
      buildWatch.start();
      final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
      final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
      builder.addText(
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
        'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz$i.',
      );
      final Paragraph paragraph = builder.build();
      buildWatch.stop();
      layoutWatch.start();
      paragraph.layout(const ParagraphConstraints(width: 500));
      layoutWatch.stop();
      if (paragraph is WebParagraph) {
        final (
          Duration d1,
          Duration d2,
          Duration d3,
          Duration d4,
          Duration d5,
          Duration d6,
          Duration d7,
          Duration d8,
        ) = paragraph
            .getLayoutDurations();
        codeUnitFlagsDuration += d1;
        textClustersDuration += d2;
        bidiRunsDuration += d3;
        lineBreaksDuration += d4;
        measureTextDuration += d5;
        getTextClustersDuration += d6;
        queryTextMetricsDuration += d7;
        mappingDuration += d8;
        skiaDuration += paragraph.skiaDuration;
        chromeDuration += paragraph.chromeDuration;
      }
    }
    print('build("{Large text}*#N") * $count executed in ${buildWatch.elapsed}');
    print('layout("{Large text}*#N") * $count executed in ${layoutWatch.elapsed}');
    print('codeUnitFlags: $codeUnitFlagsDuration');
    print('   Skia queries: $skiaDuration');
    print('   Chrome queries: $chromeDuration');
    print('textClusters: $textClustersDuration');
    print('   getTextClusters: $getTextClustersDuration');
    print('   queryTextMetrics: $queryTextMetricsDuration');
    print('   mapping: $mappingDuration');
    print('bidiRuns: $bidiRunsDuration');
    print('lineBreaks: $lineBreaksDuration');
    print('measureText: $measureTextDuration');
  });

  test('Subsequent layout small text no cache', () async {
    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText('Small text.');
    final Paragraph paragraph = builder.build();
    final layoutWatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      paragraph.layout(ParagraphConstraints(width: 495 + (i.isEven ? 0 : 5)));
    }
    layoutWatch.stop();
    print('layout("Small text#N") * $count executed in ${layoutWatch.elapsed}');
  });

  test('Subsequent layout medium text no cache', () async {
    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText(
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.',
    );
    final Paragraph paragraph = builder.build();
    final layoutWatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      paragraph.layout(ParagraphConstraints(width: 495 + (i.isEven ? 0 : 5)));
    }
    layoutWatch.stop();
    print('layout("{Medium text}*#N") * $count executed in ${layoutWatch.elapsed}');
  });

  test('Subsequent large medium text no cache', () async {
    final ParagraphStyle arialStyle = ParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final ParagraphBuilder builder = ParagraphBuilder(arialStyle);
    builder.addText(
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. '
      'Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz. Abcdef ghijkl mnopqrs tuvwxyz.',
    );
    final Paragraph paragraph = builder.build();
    final layoutWatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      paragraph.layout(ParagraphConstraints(width: 495 + (i.isEven ? 0 : 5)));
    }
    layoutWatch.stop();
    print('layout("{Large text}*#N") * $count executed in ${layoutWatch.elapsed}');
  });
}
