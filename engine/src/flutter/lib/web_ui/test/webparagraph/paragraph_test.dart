// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  const Rect region = Rect.fromLTWH(0, 0, 500, 500);

  test('Draw WebParagraph LTR text 1 line', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), bluePaint);
    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paint(canvas, const Offset(0, 100));
    canvas.drawRect(const Rect.fromLTWH(250, 0, 100, 200), redPaint);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_ltr_1.png', region: region);
  });

  test('Draw WebParagraph LTR text with multiple lines', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText(
      'World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_multilined_ltr.png', region: region);
  });

  test('Draw WebParagraph RTL text 1 line', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.rtl,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('عالم');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_1_rtl.png', region: region);
  });

  // Small line breaking difference with Chrome
  test('Draw WebParagraph RTL with multiple lines', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('إنالسيطرةعلىالعالمعبارةقبيحةللغاية-أفضلأنأسميهاتحسينالعالم');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_multilined_rtl.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL 1 Line in ltr', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      textDirection: TextDirection.ltr,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('لABC لم def لل لم ghi');
    await matchGoldenFile('web_paragraph_canvas_mix_1_ltr.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL 1 Line', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('ABC لم def');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix1_multilined_ltr.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL multi Line with RTL default left aligned', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      textDirection: TextDirection.rtl,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('لABC لم def لل لم ghi');
    //لABC لم def لل لم ghi
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix1_multilined_rtl.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL multi Line with LTR left aligned', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      fontFamily: 'Arial',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText(
      'إنالسيطرةعلىاxyz لعالمعباvwx رةقبيحةstu للغاpqr ية-أmno فضلأjkl نأسميهاghi تحسيناdef لعاabc لم',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix_multilined_ltr.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL multi Line with RTL right aligned', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      fontFamily: 'Arial',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText(
      'إنالسيطرةعلىاxyz لعالمعباvwx رةقبيحةstu للغاpqr ية-أmno فضلأjkl نأسميهاghi تحسيناdef لعاabc لم',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix_multilined_rtl.png', region: region);
  });

  test('Draw WebParagraph multicolored text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);

    final WebTextStyle blackStyle = WebTextStyle(
      foreground: blackPaint,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final WebTextStyle blueStyle = WebTextStyle(
      foreground: bluePaint,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final WebTextStyle redStyle = WebTextStyle(
      foreground: redPaint,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(WebParagraphStyle());
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
    await matchGoldenFile('web_paragraph_multicolored.png', region: region);
  });

  test('Draw WebParagraph multicolored background text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);
    final Paint greyPaint1 = Paint()..color = const Color(0xFF666666);
    final Paint greyPaint2 = Paint()..color = const Color(0xFF888888);
    final Paint greyPaint3 = Paint()..color = const Color(0xFFAAAAAA);

    final WebTextStyle blackStyle = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: blackPaint,
      background: greyPaint3,
    );
    final WebTextStyle blueStyle = WebTextStyle(
      foreground: bluePaint,
      background: greyPaint2,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final WebTextStyle redStyle = WebTextStyle(
      foreground: redPaint,
      background: greyPaint1,
      fontSize: 20,
      fontFamily: 'Roboto',
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(WebParagraphStyle());
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
    await matchGoldenFile('web_paragraph_multicolored_background.png', region: region);
  });

  test('Draw WebParagraph multiple font styles text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebTextStyle defaultStyle = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: blackPaint,
    );

    final WebTextStyle normalNormal = WebTextStyle(
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
    );

    final WebTextStyle normalBold = WebTextStyle(
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.bold,
    );

    final WebTextStyle normalThin = WebTextStyle(
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w100,
    );

    final WebTextStyle italicNormal = WebTextStyle(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.normal,
    );

    final WebTextStyle italicBold = WebTextStyle(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
    );

    final WebTextStyle italicThin = WebTextStyle(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w100,
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(WebParagraphStyle());
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
    await matchGoldenFile('web_paragraph_multifontstyled.png', region: region);
  });

  test('Draw WebParagraph multiple shadows text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 40);
    final WebTextStyle defaultStyle = WebTextStyle(foreground: blackPaint);

    final WebTextStyle allShadows = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [
        Shadow(color: Color(0xFF00FF00), offset: Offset(0, -10), blurRadius: 2.0),
        Shadow(color: Color(0xFFFF0000), offset: Offset(-10, 0), blurRadius: 2.0),
        Shadow(color: Color(0xFF0000FF), offset: Offset(10, 0), blurRadius: 2.0),
        Shadow(color: Color(0xFF888888), offset: Offset(0, 10), blurRadius: 2.0),
      ],
    );
    final WebTextStyle leftShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFFFF0000), offset: Offset(-10, 0), blurRadius: 2.0)],
    );
    final WebTextStyle topShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFF00FF00), offset: Offset(0, -10), blurRadius: 2.0)],
    );
    final WebTextStyle rightShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFF0000FF), offset: Offset(10, 0), blurRadius: 2.0)],
    );
    final WebTextStyle bottomShadow = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      shadows: const [Shadow(color: Color(0xFFFF00FF), offset: Offset(0, 10), blurRadius: 2.0)],
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(defaultStyle);

    builder.pushStyle(allShadows);
    builder.addText('All shadows. ');
    builder.pop();

    builder.addText('Text without shadows. ');

    builder.pushStyle(leftShadow);
    builder.addText('Left Shadow. ');
    builder.pop();

    builder.pushStyle(topShadow);
    builder.addText('Top Shadow. ');
    builder.pop();

    builder.pushStyle(rightShadow);
    builder.addText('Right Shadow. ');
    builder.pop();

    builder.pushStyle(bottomShadow);
    builder.addText('Bottom Shadow. ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400));
    paragraph.paint(canvas, const Offset(50, 50));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multishadows.png', region: region);
  });

  test('Draw WebParagraph multiple decorations on text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    const Color redColor = Color(0xFFFF0000);
    const Color blueColor = Color(0xFF0000FF);
    const Color greenColor = Color(0xFF00FF00);
    const Color grayColor = Color(0xFF888888);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebTextStyle defaultStyle = WebTextStyle(foreground: blackPaint);

    final WebTextStyle underlined = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationThickness: 1,
      decorationColor: redColor,
    );

    final WebTextStyle through = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.lineThrough,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.dashed,
      decorationColor: blueColor,
    );

    final WebTextStyle overlined = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.overline,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.double,
      decorationColor: greenColor,
    );

    final WebTextStyle wavy = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      decoration: TextDecoration.underline,
      decorationThickness: 1,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: grayColor,
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    builder.addText('Underlined wavy gray decoration. ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400));
    paragraph.paint(canvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multidecorated.png', region: region);
  });

  test('Draw WebParagraph multiple fonts text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);
    final Paint greenPaint = Paint()..color = const Color(0xFF00FF00);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);

    final WebTextStyle defaultStyle = WebTextStyle(foreground: blackPaint);

    final WebTextStyle roboto10 = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 10,
      foreground: redPaint,
    );

    final WebTextStyle arial10 = WebTextStyle(
      fontFamily: 'Arial',
      fontSize: 10,
      foreground: bluePaint,
    );

    final WebTextStyle roboto20 = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: greenPaint,
    );

    final WebTextStyle arial20 = WebTextStyle(
      fontFamily: 'Arial',
      fontSize: 20,
      foreground: bluePaint,
    );

    final WebTextStyle roboto40 = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      foreground: redPaint,
    );

    final WebTextStyle arial40 = WebTextStyle(
      fontFamily: 'Arial',
      fontSize: 40,
      foreground: bluePaint,
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    await matchGoldenFile('web_paragraph_multiplefont.png', region: region);
  });

  test('Draw WebParagraph letter/word spacing text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebTextStyle defaultStyle = WebTextStyle(foreground: blackPaint);
    final WebTextStyle letter5 = WebTextStyle(letterSpacing: 5.0);
    final WebTextStyle letter10 = WebTextStyle(letterSpacing: 10.0);
    final WebTextStyle word10 = WebTextStyle(wordSpacing: 10.0);
    final WebTextStyle word20 = WebTextStyle(wordSpacing: 20.0);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    await matchGoldenFile('web_paragraph_letter_word_spacing.png', region: region);
  });

  test('Query WebParagraph.GetBoxesForRange LTR text 1 line', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final Paint redPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final WebParagraphStyle robotoStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      color: const Color(0xFF000000),
    );
    final WebTextStyle heightStyle = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      height: 2.0,
      color: const Color(0xFF000000),
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(robotoStyle);
    builder.pushStyle(heightStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    paragraph.paint(canvas, Offset.zero);

    {
      final rects = paragraph.getBoxesForRange(
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
      final rects = paragraph.getBoxesForRange(
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
      final rects = paragraph.getBoxesForRange(
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
    await matchGoldenFile('web_paragraph_query_boxes_ltr_1.png', region: region);
  });

  test('Query WebParagraph.Placeholders', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.ltr,
      color: const Color(0xFF000000),
    );
    final WebTextStyle textStyle1 = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final WebTextStyle textStyle2 = WebTextStyle(fontFamily: 'Roboto', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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

    final rects = paragraph.getBoxesForPlaceholders();
    paragraph.getBoxesForRange(0, paragraph.text.length);
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF0000FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final rect in rects) {
      canvas.drawRect(rect.toRect(), bluePaint);
    }

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_placeholders_1_line.png', region: region);
  });

  test('Draw WebParagraph with fontFeatures', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final WebTextStyle defaultStyle = WebTextStyle(foreground: blackPaint);
    final WebTextStyle noLiga = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontFeatures: const [FontFeature('liga', 0)],
    );
    final WebTextStyle smcp = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontFeatures: const [FontFeature('smcp' /*1*/)],
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    await matchGoldenFile('web_paragraph_font_features.png', region: region);
  });

  test('Draw WebParagraph with fontVariations', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final WebTextStyle defaultStyle = WebTextStyle(foreground: blackPaint);
    final WebTextStyle wght = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontVariations: const [FontVariation('wght', 625)],
    );
    final WebTextStyle slnt = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontVariations: const [FontVariation('slnt', 12)],
    );
    final WebTextStyle ital = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      fontVariations: const [FontVariation('ital', 1)],
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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

    //final WebParagraph paragraph = builder.build();
    //paragraph.layout(const ParagraphConstraints(width: 250));
    //paragraph.paintOnCanvasKit(canvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_font_variations.png', region: region);
  });

  test('Draw WebParagraph multicolored background text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      color: const Color(0xFF000000),
    );
    final WebTextStyle blackStyle = WebTextStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: blackPaint,
    );
    final WebTextStyle whiteStyle = WebTextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 20,
      fontFamily: 'Roboto',
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);

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
    await matchGoldenFile('web_paragraph_black_and_white_background.png', region: region);
  });

  test('Pixels', () async {
    final PictureRecorder recorder = PictureRecorder();
    const region = Rect.fromLTWH(0, 0, 1000, 500);
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFF0000), BlendMode.src);
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: const Color(0xFF000000),
    );
    final WebTextStyle style30 = WebTextStyle(
      foreground: blackPaint,
      background: whitePaint,
      fontSize: 30,
      fontFamily: 'Roboto',
    );

    {
      final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);

      builder.pushStyle(style30);
      builder.addText('SsWwTt 30px');
      builder.pop();
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 800));
      paragraph.paint(canvas, const Offset(100, 100));
    }
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('pixels.png', region: region);
  });
}
