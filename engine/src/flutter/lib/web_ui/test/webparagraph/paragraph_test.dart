// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  const region = Rect.fromLTWH(0, 0, 500, 500);

  test('Draw WebParagraph LTR text 1 line', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final redPaint = Paint()..color = const Color(0xFFFF0000);
    final bluePaint = Paint()..color = const Color(0xFF0000FF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), bluePaint);
    final arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paint(canvas, const Offset(0, 100));
    canvas.drawRect(const Rect.fromLTWH(250, 0, 100, 200), redPaint);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.ltr_1.png', region: region);
  });

  test('Draw WebParagraph LTR text with multiple lines', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText(
      'World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multiline_ltr.png', region: region);
  });

  test('Draw WebParagraph RTL text 1 line', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.rtl,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('عالم');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.rtl_1.png', region: region);
  });

  // Small line breaking difference with Chrome
  test('Draw WebParagraph RTL with multiple lines', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      textDirection: TextDirection.rtl,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('إنالسيطرةعلىالعالمعبارةقبيحةللغاية-أفضلأنأسميهاتحسينالعالم');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multiline_rtl.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL 1 Line in ltr', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      textDirection: TextDirection.ltr,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('ABC لم def');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.mix_1_ltr.png', region: region);
  });

  for (final dir in <String>['ltr', 'rtl']) {
    test('Draw mixed WebParagraph multi Line with `$dir` default', () async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder, region);
      canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

      final arialStyle = WebParagraphStyle(
        fontFamily: 'Arial',
        fontSize: 50,
        textDirection: TextDirection.values.byName(dir),
      );
      final builder = WebParagraphBuilder(arialStyle);
      builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
      builder.addText('لABC لم def لل لم ghi');
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 300));
      paragraph.paint(canvas, Offset.zero);
      await drawPictureUsingCurrentRenderer(recorder.endRecording());
      await matchGoldenFile('web_paragraph.mix_multiline_$dir.png', region: region);
    });

    for (final align in <String>['left', 'right']) {
      test('Draw mixed WebParagraph multi Line with `$dir` default $align aligned', () async {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder, region);
        canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

        final arialStyle = WebParagraphStyle(
          textDirection: TextDirection.values.byName(dir),
          textAlign: TextAlign.values.byName(align),
          fontFamily: 'Arial',
          fontSize: 50,
          color: const Color(0xFF000000),
        );
        final builder = WebParagraphBuilder(arialStyle);
        builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
        builder.addText(
          'إنالسيطرةعلىاxyz لعالمعباvwx رةقبيحةstu للغاpqr ية-أmno فضلأjkl نأسميهاghi تحسيناdef لعاabc لم',
        );
        final WebParagraph paragraph = builder.build();
        paragraph.layout(const ParagraphConstraints(width: 300));
        paragraph.paint(canvas, Offset.zero);
        await drawPictureUsingCurrentRenderer(recorder.endRecording());
        await matchGoldenFile(
          'web_paragraph.mix_multiline_${dir}_align_$align.png',
          region: region,
        );
      });
    }
  }

  test('Draw WebParagraph multicolored text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final redPaint = Paint()..color = const Color(0xFFFF0000);
    final bluePaint = Paint()..color = const Color(0xFF0000FF);

    final blackStyle = WebTextStyle(foreground: blackPaint, fontSize: 20, fontFamily: 'Roboto');
    final blueStyle = WebTextStyle(foreground: bluePaint, fontSize: 20, fontFamily: 'Roboto');
    final redStyle = WebTextStyle(foreground: redPaint, fontSize: 20, fontFamily: 'Roboto');
    final builder = WebParagraphBuilder(WebParagraphStyle());
    builder.pushStyle(blackStyle);

    builder.pushStyle(redStyle);
    builder.addText('Red color ');
    builder.pop();
    builder.pushStyle(blueStyle);
    builder.addText('Blue color ');
    builder.pop();
    builder.addText('Black color ');
    builder.pushStyle(redStyle);
    builder.addText('Red color ');
    builder.pop();
    builder.pushStyle(blueStyle);
    builder.addText('Blue color ');
    builder.pop();
    builder.addText('Black color ');
    builder.pushStyle(redStyle);
    builder.addText('Red color ');
    builder.pop();
    builder.pushStyle(blueStyle);
    builder.addText('Blue color ');
    builder.pop();
    builder.addText('Black color ');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multicolor.png', region: region);
  });

  test('Draw WebParagraph multicolored background text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final redPaint = Paint()..color = const Color(0xFFFF0000);
    final bluePaint = Paint()..color = const Color(0xFF0000FF);
    final greyPaint1 = Paint()..color = const Color(0xFF666666);
    final greyPaint2 = Paint()..color = const Color(0xFF888888);
    final greyPaint3 = Paint()..color = const Color(0xFFAAAAAA);

    final blackStyle = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: blackPaint,
      background: greyPaint3,
    );
    final blueStyle = WebTextStyle(
      foreground: bluePaint,
      background: greyPaint2,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final redStyle = WebTextStyle(
      foreground: redPaint,
      background: greyPaint1,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final builder = WebParagraphBuilder(WebParagraphStyle());
    builder.pushStyle(blackStyle);

    builder.pushStyle(redStyle);
    builder.addText('Red color ');
    builder.pop();
    builder.pushStyle(blueStyle);
    builder.addText('Blue color ');
    builder.pop();
    builder.addText('Black color ');
    builder.pushStyle(redStyle);
    builder.addText('Red color ');
    builder.pop();
    builder.pushStyle(blueStyle);
    builder.addText('Blue color ');
    builder.pop();
    builder.addText('Black color ');
    builder.pushStyle(redStyle);
    builder.addText('Red color ');
    builder.pop();
    builder.pushStyle(blueStyle);
    builder.addText('Blue color ');
    builder.pop();
    builder.addText('Black color ');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multicolor_background.png', region: region);
  });

  test('Draw WebParagraph multiple font styles text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);

    final defaultStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 20, foreground: blackPaint);

    final normalNormal = WebTextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.normal);

    final normalBold = WebTextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.bold);

    final normalThin = WebTextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight.w100);

    final italicNormal = WebTextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.normal);

    final italicBold = WebTextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold);

    final italicThin = WebTextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w100);

    final builder = WebParagraphBuilder(WebParagraphStyle());
    builder.pushStyle(defaultStyle);

    builder.pushStyle(normalNormal);
    builder.addText('Normal normal\n');
    builder.pop();

    builder.pushStyle(normalBold);
    builder.addText('Normal bold\n');
    builder.pop();

    builder.pushStyle(normalThin);
    builder.addText('Normal thin\n');
    builder.pop();

    builder.pushStyle(italicNormal);
    builder.addText('Italic normal\n');
    builder.pop();

    builder.pushStyle(italicBold);
    builder.addText('Italic bold\n');
    builder.pop();

    builder.pushStyle(italicThin);
    builder.addText('Italic thin\n');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multifontstyle.png', region: region);
  });

  test('Draw WebParagraph multiple shadows text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);

    final paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 40);
    final defaultStyle = WebTextStyle(foreground: blackPaint);

    final allShadows = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [
        Shadow(color: Color(0xFF00FF00), offset: Offset(0, -10), blurRadius: 2.0),
        Shadow(color: Color(0xFFFF0000), offset: Offset(-15, 0), blurRadius: 2.0),
        Shadow(color: Color(0xFF0000FF), offset: Offset(20, 0), blurRadius: 2.0),
        Shadow(color: Color(0xFFFF00FF), offset: Offset(0, 25), blurRadius: 2.0),
      ],
    );
    final leftShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFFFF0000), offset: Offset(-15, 0), blurRadius: 2.0)],
    );
    final topShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFF00FF00), offset: Offset(0, -10), blurRadius: 2.0)],
    );
    final rightShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFF0000FF), offset: Offset(20, 0), blurRadius: 2.0)],
    );
    final bottomShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFFFF00FF), offset: Offset(0, 25), blurRadius: 2.0)],
    );

    final goodShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFF444444), offset: Offset(5, 5), blurRadius: 5.0)],
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(allShadows);
    builder.addText('All shadows. ');
    builder.pop();

    builder.addText('Text without shadows. ');

    builder.pushStyle(leftShadow);
    builder.addText('Left Shadow. -15, 0. ');
    builder.pop();

    builder.pushStyle(topShadow);
    builder.addText('Top Shadow. 0, -10. ');
    builder.pop();

    builder.pushStyle(rightShadow);
    builder.addText('Right Shadow. 20, 0. ');
    builder.pop();

    builder.pushStyle(bottomShadow);
    builder.addText('Bottom Shadow. 0, 25. ');
    builder.pop();

    builder.pushStyle(goodShadow);
    builder.addText('Good Shadow. 5, 5. ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400));
    paragraph.paint(canvas, const Offset(50, 50));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multishadows.png', region: region);
  });

  test('Draw WebParagraph multiple decorations on text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    const redColor = Color(0xFFFF0000);
    const blueColor = Color(0xFF0000FF);
    const greenColor = Color(0xFF00FF00);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      color: const Color(0xFF000000),
    );

    final defaultStyle = WebTextStyle(foreground: blackPaint);

    final underlined = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationThickness: 1,
      decorationColor: redColor,
    );

    final through = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.lineThrough,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.dashed,
      decorationColor: blueColor,
    );

    final overlined = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.overline,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.double,
      decorationColor: greenColor,
    );

    final wavy = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.underline,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: blackPaint.color,
    );

    final dotted = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.underline,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: blackPaint.color,
    );

    final dashed = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.underline,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.dashed,
      decorationColor: blackPaint.color,
    );

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(underlined);
    builder.addText('Underlined solid red decoration. ');
    builder.pop();

    builder.pushStyle(through);
    builder.addText('Through dashed blue decoration. ');
    builder.pop();

    builder.pushStyle(overlined);
    builder.addText('Overlined double green decoration. ');
    builder.pop();

    builder.pushStyle(wavy);
    builder.addText('Underlined wavy black decoration. ');
    builder.pop();

    builder.pushStyle(dotted);
    builder.addText('Underlined dotted black decoration. ');
    builder.pop();

    builder.pushStyle(dashed);
    builder.addText('Underlined dashed black decoration. ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multidecoration.png', region: region);
  });

  test('Draw WebParagraph multiple fonts text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final redPaint = Paint()..color = const Color(0xFFFF0000);
    final bluePaint = Paint()..color = const Color(0xFF0000FF);
    final greenPaint = Paint()..color = const Color(0xFF00FF00);

    final paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);

    final defaultStyle = WebTextStyle(foreground: blackPaint);

    final roboto10 = WebTextStyle(fontFamily: 'Roboto', fontSize: 10, foreground: redPaint);

    final arial10 = WebTextStyle(fontFamily: 'Arial', fontSize: 10, foreground: bluePaint);

    final roboto20 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20, foreground: greenPaint);

    final arial20 = WebTextStyle(fontFamily: 'Arial', fontSize: 20, foreground: bluePaint);

    final roboto40 = WebTextStyle(fontFamily: 'Roboto', fontSize: 40, foreground: redPaint);

    final arial40 = WebTextStyle(fontFamily: 'Arial', fontSize: 40, foreground: bluePaint);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(roboto10);
    builder.addText('Roboto 10 red.');
    builder.pop();

    builder.pushStyle(arial40);
    builder.addText('Arial 40 blue.');
    builder.pop();

    builder.pushStyle(roboto20);
    builder.addText('Roboto 20 green.');
    builder.pop();

    builder.pushStyle(arial20);
    builder.addText('Arial 20 blue');
    builder.pop();

    builder.pushStyle(roboto40);
    builder.addText('Roboto 40 red.');
    builder.pop();

    builder.pushStyle(arial10);
    builder.addText('Arial 10 blue.');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.multifont.png', region: region);
  });

  test('Draw WebParagraph letter/word spacing text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);

    final paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final defaultStyle = WebTextStyle(foreground: blackPaint);
    final letter5 = WebTextStyle(letterSpacing: 5.0);
    final letter10 = WebTextStyle(letterSpacing: 10.0);
    final word10 = WebTextStyle(wordSpacing: 10.0);
    final word20 = WebTextStyle(wordSpacing: 20.0);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(letter5);
    builder.addText('Letter spacing 5. ');
    builder.pop();
    builder.pushStyle(letter10);
    builder.addText('Letter spacing 10. ');
    builder.pop();
    builder.pushStyle(word10);
    builder.addText('Word spacing 10, word spacing 10. ');
    builder.pop();
    builder.pushStyle(word20);
    builder.addText('Word spacing 20, word spacing 20. ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.letter_word_spacing.png', region: region);
  });

  test('Query WebParagraph.GetBoxesForRange LTR text 1 line', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final redPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final bluePaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final greenPaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final robotoStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      color: const Color(0xFF000000),
    );
    final heightStyle = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      height: 2.0,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(robotoStyle);
    builder.pushStyle(heightStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, Offset.zero);

    {
      final List<TextBox> rects = paragraph.getBoxesForRange(
        0,
        paragraph.text.length,
        boxHeightStyle: BoxHeightStyle.includeLineSpacingTop,
        //boxWidthStyle: ui.BoxWidthStyle.tight,
      );
      for (final rect in rects) {
        canvas.drawRect(rect.toRect(), bluePaint);
      }
    }

    {
      final List<TextBox> rects = paragraph.getBoxesForRange(
        0,
        paragraph.text.length,
        boxHeightStyle: BoxHeightStyle.includeLineSpacingBottom,
        //boxWidthStyle: ui.BoxWidthStyle.tight,
      );
      for (final rect in rects) {
        canvas.drawRect(rect.toRect(), redPaint);
      }
    }

    {
      final List<TextBox> rects = paragraph.getBoxesForRange(
        0,
        paragraph.text.length,
        boxHeightStyle: BoxHeightStyle.includeLineSpacingMiddle,
        //boxWidthStyle: ui.BoxWidthStyle.tight,
      );
      for (final rect in rects) {
        canvas.drawRect(rect.toRect(), greenPaint);
      }
    }

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.query_boxes_ltr_1.png', region: region);
  });

  test('Query WebParagraph.Placeholders', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.ltr,
      color: const Color(0xFF000000),
    );
    final textStyle1 = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(textStyle1);
    builder.addText('Alphabetic 20 on baseline:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.baseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 above baseline:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.aboveBaseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 below baseline:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.belowBaseline,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 middle:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.middle,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 top:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.top,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    builder.pushStyle(textStyle1);
    builder.addText('\nAlphabetic 20 bottom:');
    builder.pop();
    builder.pushStyle(textStyle2);
    builder.addPlaceholder(
      20,
      20,
      PlaceholderAlignment.bottom,
      baselineOffset: 0.0,
      baseline: TextBaseline.alphabetic,
    );
    builder.pop();
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, Offset.zero);

    final List<TextBox> rects = paragraph.getBoxesForPlaceholders();
    paragraph.getBoxesForRange(0, paragraph.text.length);
    final bluePaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final rect in rects) {
      canvas.drawRect(rect.toRect(), bluePaint);
    }

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.placeholders_1_line.png', region: region);
  });

  test('Draw WebParagraph with fontFeatures', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final defaultStyle = WebTextStyle(foreground: blackPaint);
    final noLiga = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontFeatures: const [FontFeature('liga', 0)],
    );
    final smcp = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontFeatures: const [FontFeature('smcp' /*1*/)],
    );
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(noLiga);
    builder.addText('fi ffi. ');
    builder.pop();
    builder.addText('fi ffi.\n');
    builder.pushStyle(smcp);
    builder.addText('LeTteRs. ');
    builder.pop();
    builder.addText('LeTteRs.\n');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.font_features.png', region: region);
  });

  test('Draw WebParagraph with fontVariations', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final defaultStyle = WebTextStyle(foreground: blackPaint);
    final wght = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontVariations: const [FontVariation('wght', 625)],
    );
    final slnt = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontVariations: const [FontVariation('slnt', 12)],
    );
    final ital = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontVariations: const [FontVariation('ital', 1)],
    );
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(wght);
    builder.addText('Heavy weight. ');
    builder.pop();
    builder.addText('Heavy weight.\n');
    builder.pushStyle(slnt);
    builder.addText('Slant. ');
    builder.pop();
    builder.addText('Slant.\n');
    builder.pushStyle(ital);
    builder.addText('Italic. ');
    builder.pop();
    builder.addText('Italic.\n');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.font_variations.png', region: region);
  });

  test('Draw WebParagraph multicolored background text', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final blackStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 20, foreground: blackPaint);
    final whiteStyle = WebTextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 20,
      fontFamily: 'Roboto',
    );

    final builder = WebParagraphBuilder(paragraphStyle);

    builder.pushStyle(blackStyle);
    builder.addText('Black on transparent ');
    builder.pop();
    builder.pushStyle(whiteStyle);
    builder.addText('Black on white ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.black_and_white_background.png', region: region);
  });

  test('Pixels', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: const Color(0xFF000000),
    );
    final style30 = WebTextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 30,
      fontFamily: 'Roboto',
    );

    {
      final builder = WebParagraphBuilder(paragraphStyle);

      builder.pushStyle(style30);
      builder.addText('SsWwTt 30px');
      builder.pop();
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 800));
      paragraph.paint(canvas, const Offset(100, 100));
    }
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.pixels.png', region: region);
  });

  test('Ellipsis LTR', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: const Color(0xFF000000),
      ellipsis: '...',
      maxLines: 1,
    );
    final style30 = WebTextStyle(foreground: blackPaint, background: whitePaint, fontSize: 40);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(style30);
    builder.addText('This is a long text that should be ellipsized at the end');
    builder.pop();
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 350));
    paragraph.paint(canvas, const Offset(20, 20));

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile(
      'web_paragraph.ellipsis_ltr.png',
      region: const Rect.fromLTWH(0, 0, 500, 200),
    );
  });

  test('Ellipsis RTL', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: const Color(0xFF000000),
      ellipsis: '...',
      maxLines: 1,
      textDirection: TextDirection.rtl,
    );
    final style30 = WebTextStyle(foreground: blackPaint, background: whitePaint, fontSize: 40);

    final builder = WebParagraphBuilder(paragraphStyle);

    builder.pushStyle(style30);
    builder.addText('إن السيطرة على العالم عبارة قبيحة للغاية - أفضل أن أسميها تحسين العالم');
    builder.pop();
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 350));
    paragraph.paint(canvas, const Offset(20, 20));

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile(
      'web_paragraph.ellipsis_rtl.png',
      region: const Rect.fromLTWH(0, 0, 500, 200),
    );
  });

  test('MaxLines, no ellipsis', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: const Color(0xFF000000),
      maxLines: 2,
    );
    final style30 = WebTextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 30,
      fontFamily: 'Roboto',
    );

    {
      final builder = WebParagraphBuilder(paragraphStyle);

      builder.pushStyle(style30);
      builder.addText(
        'This is a long text cut on the second line and starting from "and" it should show up.',
      );
      builder.pop();
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 300));
      paragraph.paint(canvas, const Offset(100, 100));
    }
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.max_lines_2.png', region: region);
  });

  test('Paragraph with different locales for the same language', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);

    final paragraphStyle = WebParagraphStyle(fontFamily: 'Noto Sans', fontSize: 20);
    final styleCN = WebTextStyle(locale: const Locale('zh', 'CN'));
    final styleTW = WebTextStyle(locale: const Locale('zh', 'TW'));
    final styleHK = WebTextStyle(locale: const Locale('zh', 'HK'));
    final styleJP = WebTextStyle(locale: const Locale('ja', 'JP'));
    const text = 'Command 刃';

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(styleCN);
    builder.addText('$text in ${styleCN.locale?.languageCode}-${styleCN.locale?.countryCode}.\n');
    builder.pop();
    builder.pushStyle(styleTW);
    builder.addText('$text in ${styleTW.locale?.languageCode}-${styleTW.locale?.countryCode}.\n');
    builder.pop();
    builder.pushStyle(styleJP);
    builder.addText('$text in ${styleJP.locale?.languageCode}-${styleJP.locale?.countryCode}.\n');
    builder.pop();

    builder.pushStyle(styleHK);
    builder.addText('$text in ${styleHK.locale?.languageCode}-${styleHK.locale?.countryCode}.');
    builder.pop();
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, const Offset(100, 100));

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.locales.png', region: region);
  });

  test('NoHeightMultiplier', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = ParagraphStyle();
    final style = TextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 40,
      fontFamily: 'sans-serif',
      height: 1.0,
    );

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(style);
    builder.addText('Some text long enough to be on two lines');
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    //printParagraphMetrics(paragraph);
    canvas.drawParagraph(paragraph, Offset.zero);

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.no_height_multiplier.png', region: region);
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
  });

  test('HeightMultiplier143', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = ParagraphStyle();
    final style = TextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 40,
      fontFamily: 'Arial',
      height: 1.43,
    );

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(style);
    builder.addText('Some text long enough to be on two lines');
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    //printParagraphMetrics(paragraph);
    canvas.drawParagraph(paragraph, Offset.zero);

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.height_multiplier_143.png', region: region);
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
  });

  test('Zoom2', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.0);
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = ParagraphStyle();
    final style = TextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 40,
      fontFamily: 'Arial',
      height: 1.43,
    );

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(style);
    builder.addText('Some text long enough to be on two lines');
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    canvas.drawParagraph(paragraph, Offset.zero);
    //printParagraphMetrics(paragraph);

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.zoom_2.png', region: region);
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
  });

  test('Zoom05', () async {
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(0.5);
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);

    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final paragraphStyle = ParagraphStyle();
    final style = TextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 40,
      fontFamily: 'Arial',
      height: 1.43,
    );

    final builder = ParagraphBuilder(paragraphStyle);
    builder.pushStyle(style);
    builder.addText('Some text long enough to be on two lines');
    builder.pop();
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    //printParagraphMetrics(paragraph);
    canvas.drawParagraph(paragraph, Offset.zero);

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.zoom_05.png', region: region);
    EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
  });

  test('paint overflows', () async {
    final recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final canvas = Canvas(recorder, region);

    // canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final blackPaint = Paint()..color = const Color(0xFF000000);
    final lightbluePaint = Paint()..color = const Color(0xFFDDEEFF);
    final redPaint = Paint()..color = const Color(0xFFFF0000);
    final bluePaint = Paint()..color = const Color(0xFF0000FF);

    final paragraphStyle = ParagraphStyle();
    final style = TextStyle(
      foreground: blackPaint,
      background: lightbluePaint,
      fontSize: 60,
      fontFamily: 'sans-serif',
      fontStyle: FontStyle.italic,
    );

    Paragraph drawParagraph(String text, Offset offset) {
      final builder = ParagraphBuilder(paragraphStyle);
      builder.pushStyle(style);
      builder.addText(text);
      builder.pop();
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: double.infinity));
      final double fullWidth = paragraph.maxIntrinsicWidth;
      paragraph.layout(ParagraphConstraints(width: fullWidth));
      canvas.drawParagraph(paragraph, offset);

      final paragraphRect = Rect.fromLTWH(offset.dx, offset.dy, fullWidth, paragraph.height);
      canvas.drawRect(paragraphRect, redPaint..style = PaintingStyle.stroke);

      final Rect paintRect = (paragraph as WebParagraph).paintBounds.shift(offset);
      canvas.drawRect(paintRect, bluePaint..style = PaintingStyle.stroke);

      return paragraph;
    }

    var offset = const Offset(20, 20);
    final Paragraph paragraph1 = drawParagraph('Top shelf', offset);
    offset = offset.translate(0.0, paragraph1.height + 20.0);
    final Paragraph paragraph2 = drawParagraph('no descent', offset);

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile(
      'web_paragraph.paint_overflows.png',
      region: Rect.fromLTWH(
        0,
        0,
        offset.dx + math.max(paragraph1.maxIntrinsicWidth, paragraph2.maxIntrinsicWidth) + 20.0,
        offset.dy + paragraph2.height + 20.0,
      ),
    );
  });
}
