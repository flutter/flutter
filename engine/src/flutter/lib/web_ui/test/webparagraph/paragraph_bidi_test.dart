// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/layout.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph bidi 1 LTR only', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'Arial',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Arial, 30px;');
    final WebParagraph paragraph = builder.build();
    final TextLayout layout = paragraph.getLayout();
    layout.extractTextClusters();
    layout.extractBidiRuns();
    expect(layout.bidiRuns.length, 1);
  });

  test('Paragraph bidi 1 RTL only', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.rtl,
      fontFamily: 'Arial',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('بَالَكُمُ');
    final WebParagraph paragraph = builder.build();
    final TextLayout layout = paragraph.getLayout();
    layout.extractTextClusters();
    layout.extractBidiRuns();
    expect(layout.bidiRuns.length, 1);
  });

  test('Paragraph bidi mixed LTR/RTL + 1 style only', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'Arial',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('بَالَكُمُ');
    builder.addText('A');
    builder.addText('اللَّهُ');
    builder.addText('B');
    builder.addText('يَهْدِيْكُمُ');
    final WebParagraph paragraph = builder.build();
    final TextLayout layout = paragraph.getLayout();
    layout.extractTextClusters();
    layout.extractBidiRuns();
    expect(layout.bidiRuns.length, 5);
  });

  test('Paragraph BiDi order and layout within multi-span RTL bidi run', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'FlutterTest',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(ui.TextStyle(color: const ui.Color(0xFFFF0000)));
    builder.addText('BiDi ');
    builder.pop();

    builder.pushStyle(
      ui.TextStyle(fontWeight: ui.FontWeight.bold, color: const ui.Color(0xFF00FF00)),
    );
    builder.addText('مرحبا بالعالم');
    builder.pop();

    builder.addText(' & שלום · Emoji 👨👩👧👦 🏳️🌈 stay atomic.');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));

    final List<ui.TextBox> boxesBidi = paragraph.getBoxesForRange(0, 5);
    final List<ui.TextBox> boxesArabic = paragraph.getBoxesForRange(5, 18);
    final List<ui.TextBox> boxesNeutral = paragraph.getBoxesForRange(18, 21);
    final List<ui.TextBox> boxesHebrew = paragraph.getBoxesForRange(21, 25);
    final List<ui.TextBox> boxesSuffix = paragraph.getBoxesForRange(25, paragraph.text.length);

    // Visual left-to-right order must be: "BiDi " (0..5) -> "שלום" (21..25) ->
    // " & " (18..21) -> "مرحبا بالعالم" (5..18) -> " · Emoji ..." (25..end).
    expect(boxesBidi.single.left, closeTo(0.0, 0.001));
    expect(boxesHebrew.single.left, closeTo(boxesBidi.single.right, 0.001));
    expect(boxesNeutral.single.left, closeTo(boxesHebrew.single.right, 0.001));
    expect(boxesArabic.single.left, closeTo(boxesNeutral.single.right, 0.001));
    expect(boxesSuffix.single.left, closeTo(boxesArabic.single.right, 0.001));

    final ui.GlyphInfo glyphFinalMem = paragraph.getGlyphInfoAt(24)!;
    final ui.GlyphInfo glyphAmpersand = paragraph.getGlyphInfoAt(19)!;
    final ui.GlyphInfo glyphFirstArabic = paragraph.getGlyphInfoAt(5)!;
    expect(glyphFinalMem.writingDirection, ui.TextDirection.rtl);
    expect(glyphAmpersand.writingDirection, ui.TextDirection.rtl);
    expect(glyphFirstArabic.writingDirection, ui.TextDirection.rtl);
    expect(glyphFinalMem.graphemeClusterLayoutBounds.left, closeTo(boxesBidi.single.right, 0.001));
    expect(
      glyphAmpersand.graphemeClusterLayoutBounds.left,
      greaterThanOrEqualTo(boxesHebrew.single.right - 0.001),
    );
    expect(
      glyphAmpersand.graphemeClusterLayoutBounds.right,
      lessThanOrEqualTo(boxesArabic.single.left + 0.001),
    );

    final ui.TextPosition posHebrew = paragraph.getPositionForOffset(
      boxesHebrew.single.toRect().center,
    );
    final ui.TextPosition posNeutral = paragraph.getPositionForOffset(
      boxesNeutral.single.toRect().center,
    );
    final ui.TextPosition posArabic = paragraph.getPositionForOffset(
      boxesArabic.single.toRect().center,
    );
    expect(posHebrew.offset, inInclusiveRange(21, 25));
    expect(posNeutral.offset, inInclusiveRange(18, 21));
    expect(posArabic.offset, inInclusiveRange(5, 18));
  });

  test('Paragraph BiDi isolated neutral span between RTL spans in LTR paragraph', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'FlutterTest',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(ui.TextStyle(color: const ui.Color(0xFFFF0000)));
    builder.addText('مرحبا');
    builder.pop();

    builder.pushStyle(ui.TextStyle(fontWeight: ui.FontWeight.bold));
    builder.addText(' + ');
    builder.pop();

    builder.pushStyle(ui.TextStyle(color: const ui.Color(0xFF0000FF)));
    builder.addText('שלום');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));

    final List<ui.TextBox> boxesArabic = paragraph.getBoxesForRange(0, 5);
    final List<ui.TextBox> boxesNeutral = paragraph.getBoxesForRange(5, 8);
    final List<ui.TextBox> boxesHebrew = paragraph.getBoxesForRange(8, 12);

    // All three spans belong to a single RTL BidiRun (level = 1).
    // Visually from left to right: "שלום" -> " + " -> "مرحبا".
    expect(boxesHebrew.single.left, closeTo(0.0, 0.001));
    expect(boxesNeutral.single.left, closeTo(boxesHebrew.single.right, 0.001));
    expect(boxesArabic.single.left, closeTo(boxesNeutral.single.right, 0.001));
    expect(boxesNeutral.single.direction, ui.TextDirection.rtl);
  });

  test('Paragraph BiDi multi-span order in RTL paragraph', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.rtl,
      fontFamily: 'FlutterTest',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('שלום ');
    builder.pushStyle(ui.TextStyle(fontWeight: ui.FontWeight.bold));
    builder.addText('עולם');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));

    final ui.TextBox first = paragraph.getBoxesForRange(0, 5).single;
    final ui.TextBox second = paragraph.getBoxesForRange(5, 9).single;

    // The logically second span is visually on the left.
    expect(second.right, closeTo(first.left, 0.001));
    expect(first.direction, ui.TextDirection.rtl);
    expect(second.direction, ui.TextDirection.rtl);
  });

  test('Embedded multi-span LTR run inside RTL paragraph', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.rtl,
      fontFamily: 'FlutterTest',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Hello');
    builder.pushStyle(ui.TextStyle(fontWeight: ui.FontWeight.bold));
    builder.addText(' + ');
    builder.pop();
    builder.addText('World');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));

    final ui.TextBox first = paragraph.getBoxesForRange(0, 5).single;
    final ui.TextBox plus = paragraph.getBoxesForRange(5, 8).single;
    final ui.TextBox second = paragraph.getBoxesForRange(8, 13).single;

    // The embedded LTR run overrides the RTL paragraph direction for all three spans.
    expect(first.right, closeTo(plus.left, 0.001));
    expect(plus.right, closeTo(second.left, 0.001));
    expect(first.direction, ui.TextDirection.ltr);
    expect(plus.direction, ui.TextDirection.ltr);
    expect(second.direction, ui.TextDirection.ltr);
  });

  test('Multi-span RTL run with inline placeholder', () {
    final paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'FlutterTest',
      fontSize: 20,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('שלום');
    builder.addPlaceholder(10, 10, ui.PlaceholderAlignment.bottom);
    builder.addText('עולם');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000));

    final ui.TextBox first = paragraph.getBoxesForRange(0, 4).single;
    final List<ui.TextBox> ph = paragraph.getBoxesForPlaceholders();
    final ui.TextBox second = paragraph.getBoxesForRange(5, 9).single;

    expect(ph.length, 1);
    // Visually from left to right within the RTL run: second text -> placeholder -> first text.
    expect(second.right, closeTo(ph[0].left, 0.001));
    expect(ph[0].right, closeTo(first.left, 0.001));
    expect(first.direction, ui.TextDirection.rtl);
    expect(second.direction, ui.TextDirection.rtl);
  });
}
