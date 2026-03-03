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
    expect(
      positionbb,
      const ui.TextPosition(offset: text.length, affinity: ui.TextAffinity.upstream),
    );
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
    expect(
      positionbb,
      const ui.TextPosition(offset: text.length, affinity: ui.TextAffinity.upstream),
    );
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

    expect(position1, const ui.TextPosition(offset: 0 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position4, const ui.TextPosition(offset: 81, affinity: ui.TextAffinity.upstream));
    expect(position2, const ui.TextPosition(offset: 56 /*affinity: ui.TextAffinity.downstream)*/));
    expect(position3, const ui.TextPosition(offset: 56 /*affinity: ui.TextAffinity.downstream)*/));
  });
}
