// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('Paragraph getWordBoundary', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final SegmentationResult result = segmentText(paragraph.text!);
    int start = 0;
    for (final end in result.words.skip(1)) {
      for (int i = start; i < end; i++) {
        expect(
          paragraph.getWordBoundary(
            ui.TextPosition(offset: i, affinity: ui.TextAffinity.downstream),
          ),
          ui.TextRange(start: start, end: end),
        );
      }
      expect(
        paragraph.getWordBoundary(ui.TextPosition(offset: end, affinity: ui.TextAffinity.upstream)),
        ui.TextRange(start: start, end: end),
      );
      start = end;
    }
  });

  test('Paragraph getWordBoundary outside of the text', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(
      paragraph.getWordBoundary(ui.TextPosition(offset: 0, affinity: ui.TextAffinity.upstream)),
      ui.TextRange(start: 0, end: 0),
    );
    expect(
      paragraph.getWordBoundary(ui.TextPosition(offset: -1, affinity: ui.TextAffinity.downstream)),
      ui.TextRange(start: 0, end: 0),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text!.length + 1, affinity: ui.TextAffinity.upstream),
      ),
      ui.TextRange(start: paragraph.text!.length, end: paragraph.text!.length),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text!.length, affinity: ui.TextAffinity.downstream),
      ),
      ui.TextRange(start: paragraph.text!.length, end: paragraph.text!.length),
    );
  });

  test('Paragraph getWordBoundary empty text', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: 0),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 1 /* affinity: ui.TextAffinity.upstream */),
      ),
      const ui.TextRange(start: 0, end: 0),
    );
  });

  test('Paragraph getWordBoundary only whitespaces', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('                     ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      ui.TextRange(start: 0, end: paragraph.text!.length),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text!.length, affinity: ui.TextAffinity.upstream),
      ),
      ui.TextRange(start: 0, end: paragraph.text!.length),
    );
  });
}
