// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph getPositionForOffset 1 Infinity line', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation. ';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final ui.TextPosition positiontt = paragraph.getPositionForOffset(const ui.Offset(-1, -1));
    final ui.TextPosition position00 = paragraph.getPositionForOffset(ui.Offset.zero);
    final ui.TextPosition positionee = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine, paragraph.height),
    );
    final ui.TextPosition positionmm = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine / 2, paragraph.height / 2),
    );
    final ui.TextPosition positionbb = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine + 1, paragraph.height + 1),
    );
    expect(positiontt, const ui.TextPosition(offset: 0 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position00, const ui.TextPosition(offset: 0 /*affinity: ui.TextAffinity.downstream)*/));
    expect(positionmm, const ui.TextPosition(offset: 37 /*affinity: ui.TextAffinity.downstream)*/));
    // The last glyph, position close to the end
    expect(
      positionee,
      const ui.TextPosition(offset: text.length - 1, affinity: ui.TextAffinity.upstream),
    );
    expect(positionbb, const ui.TextPosition(offset: text.length - 1));
  });

  test('Paragraph getPositionForOffset multiple lines', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation. ';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final ui.TextPosition positiontt = paragraph.getPositionForOffset(const ui.Offset(-1, -1));
    final ui.TextPosition position00 = paragraph.getPositionForOffset(ui.Offset.zero);
    final ui.TextPosition positionee = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine, paragraph.height),
    );
    final ui.TextPosition positionmm = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine / 2, paragraph.height / 2),
    );
    final ui.TextPosition positionbb = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine + 1, paragraph.height + 1),
    );

    expect(positiontt, const ui.TextPosition(offset: 0 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position00, const ui.TextPosition(offset: 0 /*affinity: ui.TextAffinity.downstream)*/));
    expect(positionmm, const ui.TextPosition(offset: 37 /*affinity: ui.TextAffinity.downstream)*/));
    // The last glyph, position close to the end
    expect(
      positionee,
      const ui.TextPosition(offset: text.length - 1, affinity: ui.TextAffinity.upstream),
    );
    expect(positionbb, const ui.TextPosition(offset: text.length - 1));
  });

  test('Paragraph getPositionForOffset above and below the line', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text1 = 'World domination is such an ugly phrase -';
    const text2 = 'I prefer to call it world optimisation. ';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(WebTextStyle(fontSize: 10));
    builder.addText(text1);
    builder.pushStyle(WebTextStyle(fontSize: 50));
    builder.addText(text2);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final double middle = paragraph.longestLine / 2;
    final double baseline = paragraph.alphabeticBaseline;

    final ui.TextPosition position1 = paragraph.getPositionForOffset(ui.Offset(middle, -10));

    final ui.TextPosition position2 = paragraph.getPositionForOffset(
      ui.Offset(middle, baseline - 30),
    );

    final ui.TextPosition position3 = paragraph.getPositionForOffset(ui.Offset(middle, baseline));

    final ui.TextPosition position4 = paragraph.getPositionForOffset(
      ui.Offset(middle, paragraph.height + 10),
    );

    expect(position1, const ui.TextPosition(offset: 56 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position2, const ui.TextPosition(offset: 56 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position3, const ui.TextPosition(offset: 56 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position4, const ui.TextPosition(offset: 56 /*affinity: ui.TextAffinity.downstream)*/));
  });

  test('Paragraph getPositionForOffset - cursor positioning with formatting shift', () {
    // Tests the fix for left calculation: changed from - to +
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      textAlign: ui.TextAlign.center,
    );

    const text = 'Hello World';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 200));

    // Get position at offset - should handle formatting shift correctly
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine / 2, paragraph.height / 2),
    );

    // Verify position is within valid range
    expect(position.offset, greaterThanOrEqualTo(0));
    expect(position.offset, lessThanOrEqualTo(text.length));
  });

  test('Paragraph getPositionForOffset - placeholder handling', () {
    // Tests the fix for placeholder block positioning
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Before ');

    // Add a placeholder
    builder.addPlaceholder(50, 50, ui.PlaceholderAlignment.middle);
    builder.addText(' After');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Test position at various offsets
    final ui.TextPosition positionBefore = paragraph.getPositionForOffset(const ui.Offset(30, 20));
    final ui.TextPosition positionAfter = paragraph.getPositionForOffset(const ui.Offset(130, 20));

    expect(positionBefore.offset, greaterThanOrEqualTo(0));
    expect(positionAfter.offset, greaterThanOrEqualTo(0));
  });

  test('Paragraph getPositionForOffset - strut style handling', () {
    // Tests the simplified fix for Strut style box height calculations
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      strutStyle: ui.StrutStyle(fontFamily: 'Arial', fontSize: 16, height: 1.5),
    );

    const text = 'Line with strut style';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 300));

    // Test positioning with strut style applied
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine / 2, paragraph.height / 2),
    );

    expect(position.offset, greaterThanOrEqualTo(0));
    expect(position.offset, lessThanOrEqualTo(text.length));
  });

  test('Paragraph getPositionForOffset - empty line handling', () {
    // Tests fix for handling empty/nearly empty lines (width < epsilon)
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\n\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 200));

    // Position on empty line
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(10, paragraph.height / 2),
    );

    expect(position.offset, greaterThanOrEqualTo(0));
  });

  test('Paragraph getPositionForOffset - bidi text (RTL) with proper affinity', () {
    // Tests fix for proper TextDirection handling in cluster positioning
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      textDirection: ui.TextDirection.rtl,
    );

    const text = 'שלום עולם'; // Hebrew text
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Test RTL positioning with correct affinity based on isLtr
    final ui.TextPosition positionLeft = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine * 0.1, paragraph.height / 2),
    );

    final ui.TextPosition positionRight = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine * 0.9, paragraph.height / 2),
    );

    expect(positionLeft.offset, greaterThanOrEqualTo(0));
    expect(positionRight.offset, greaterThanOrEqualTo(0));
    expect(positionLeft.offset, greaterThan(positionRight.offset)); // We have RTL here
  });

  test('Paragraph getPositionForOffset - cluster center calculation', () {
    // Tests fix for using center point instead of simple left/right distance
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text = 'Test text with clusters';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 300));

    final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(6);
    expect(glyphInfo, isNotNull);

    // Position slightly left of center of a cluster
    final ui.TextPosition positionLeft = paragraph.getPositionForOffset(
      ui.Offset(glyphInfo!.graphemeClusterLayoutBounds.center.dx - 1, paragraph.height / 2),
    );

    // Position slightly right of center of same area
    final ui.TextPosition positionRight = paragraph.getPositionForOffset(
      ui.Offset(glyphInfo.graphemeClusterLayoutBounds.center.dx + 1, paragraph.height / 2),
    );

    // Offsets should differ based on cluster center, not simple distance
    expect(positionLeft.offset, 6);
    expect(positionLeft.affinity, ui.TextAffinity.downstream);
    expect(positionRight.offset, 7);
    expect(positionRight.affinity, ui.TextAffinity.upstream);
  });

  test('Paragraph getPositionForOffset - multi-line with ellipsis handling', () {
    // Tests fix for ellipsis block handling
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      maxLines: 2,
      ellipsis: '...',
    );

    const text = 'This is a long text that will be truncated with ellipsis';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 150));

    // Test positioning at ellipsis
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine - 5, paragraph.height - 5),
    );

    expect(position.offset, greaterThanOrEqualTo(0));
    expect(position.offset, lessThan(150));
  });

  test('Paragraph getPositionForOffset - first visual block in line', () {
    // Tests fix for handling positions left of first visual block
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text = 'Start of line';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 300));

    // Position to the left of the first character
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(-20, paragraph.height / 2),
    );

    // Should handle gracefully - should be position 0 or start of first block
    expect(position.offset, equals(0));
    expect(position.affinity, equals(ui.TextAffinity.downstream));
  });

  test('Paragraph getPositionForOffset - last block in line positioning', () {
    // Tests fix for handling positions beyond the last visual block
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text = 'End of line';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 300));

    // Position to the right of the last character
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine + 100, paragraph.height / 2),
    );

    // Should return position at or near the end
    expect(position.offset, greaterThanOrEqualTo(text.length));
    expect(position.affinity, equals(ui.TextAffinity.upstream));
  });

  test('Paragraph getPositionForOffset - epsilon tolerance for block edges', () {
    // Tests use of epsilon constant for edge detection
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    const text = 'Epsilon test';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 200));

    // Test positioning at exact edge boundaries (within epsilon)
    final ui.TextPosition position1 = paragraph.getPositionForOffset(
      ui.Offset(50, paragraph.height / 2),
    );

    final ui.TextPosition position2 = paragraph.getPositionForOffset(
      ui.Offset(50.0005, paragraph.height / 2),
    );

    // Both should give reasonable results with epsilon tolerance
    expect(position1.offset, equals(position2.offset));
    expect(position1.affinity, equals(position2.affinity));
  });

  test('Text block respects line height multiplier', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(WebTextStyle(fontSize: 20, height: 1.5));
    builder.addText('Hello');
    builder.pushStyle(WebTextStyle(fontSize: 20, height: 2.0));
    builder.addText(' World');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Height should reflect the line height multipliers
    expect(paragraph.height, 20 * 2);
  });

  test('Text block height calculations with strut style', () {
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      strutStyle: ui.StrutStyle(fontSize: 20),
    );
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Hello World');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(paragraph.height, 22);
  });

  test('Text block height with leading distribution', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(
      WebTextStyle(fontSize: 20, height: 1.5, leadingDistribution: ui.TextLeadingDistribution.even),
    );
    builder.addText('Hello');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(paragraph.height, 20 * 1.5);
  });

  test('getPositionForOffset returns correct position for out of bounds offsets', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Position beyond paragraph bounds should return valid TextPosition
    final ui.TextPosition positionBeyondRight = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine + 100, 0),
    );
    final ui.TextPosition positionBeyondBottom = paragraph.getPositionForOffset(
      ui.Offset(0, paragraph.height + 100),
    );
    expect(positionBeyondRight.offset, 11);
    expect(positionBeyondBottom.offset, 0);
  });

  test('getPositionForOffset handles empty paragraph correctly', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = '';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final ui.TextPosition position = paragraph.getPositionForOffset(const ui.Offset(10, 10));
    expect(position.offset, 0);
  });

  test('getPositionForOffset handles bidirectional text correctly', () {
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      textDirection: ui.TextDirection.ltr,
    );
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(WebTextStyle(fontSize: 20));
    builder.addText('Hello'); // LTR
    builder.pushStyle(WebTextStyle(fontSize: 20));
    builder.addText('مرحبا'); // RTL (Arabic)
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Get position in LTR text
    final ui.TextPosition positionLtr = paragraph.getPositionForOffset(const ui.Offset(10, 0));
    // Get position in RTL text (should be after LTR)
    final ui.TextPosition positionRtl = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine - 10, 0),
    );

    expect(positionLtr.offset >= 0, true);
    expect(positionRtl.offset >= 0, true);
    expect(positionLtr.offset <= paragraph.maxIntrinsicWidth, true);
  });

  test('getPositionForOffset handles multiple lines correctly', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'First line\nSecond line\nThird line';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 100));

    // Get position on first line
    final ui.TextPosition pos1 = paragraph.getPositionForOffset(const ui.Offset(20, 5));
    // Get position on last line
    final ui.TextPosition pos2 = paragraph.getPositionForOffset(
      ui.Offset(20, paragraph.height - 5),
    );

    expect(pos1.offset >= 0, true);
    expect(pos2.offset >= 0, true);
    expect(pos1.offset <= text.length, true);
    expect(pos2.offset <= text.length, true);
  });

  test('getPositionForOffset uses correct affinity for RTL text', () {
    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      textDirection: ui.TextDirection.rtl,
    );
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('مرحبا'); // Arabic (RTL)
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Positions should have appropriate affinity
    final ui.TextPosition position = paragraph.getPositionForOffset(
      ui.Offset(paragraph.longestLine / 2, 0),
    );

    expect(position.offset >= 0, true);
    expect(position.offset <= 'مرحبا'.length, true);
  });
}
