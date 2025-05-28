// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../../common/test_initialization.dart';
import '../utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  const Rect region = Rect.fromLTWH(0, 0, 500, 500);
  /*
  // This is no a correct paragraph paint implementation and only serve a purpose to compare
  // the results with the normal paint. It does not do the paragraph positioning right but
  // it does not matter.
  test('Draw WebParagraph on Canvas2D', () async {
    final engine.DomHTMLCanvasElement canvas = engine.createDomCanvasElement(
      width: 500,
      height: 500,
    );
    engine.domDocument.body!.append(canvas);
    final engine.DomCanvasRenderingContext2D context = canvas.context2D;

    context.fillStyle = 'blue';
    context.fillRect(0, 0, 200, 200);

    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paintOnCanvas2D(canvas, const Offset(0, 100));

    context.fillStyle = 'red';
    context.fillRect(250, 0, 100, 200);
    await matchGoldenFile('web_paragraph_canvas2d.png', region: region);
  });
  */

  test('Draw WebParagraph LTR text 1 line', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);

    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), bluePaint);
    final WebParagraphStyle arialStyle = WebParagraphStyle(fontFamily: 'Roboto', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 100));
    canvas.drawRect(const Rect.fromLTWH(250, 0, 100, 200), redPaint);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_ltr_1.png', region: region);
  });

  test('Draw WebParagraph LTR text with multiple lines', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText(
      'World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_multilined.png', region: region);
  });

  test('Draw WebParagraph RTL text 1 line', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 50,
      textDirection: TextDirection.rtl,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText('عالم');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_rtl_1.png', region: region);
  });

  // Small line breaking difference with Chrome
  test('Draw WebParagraph RTL with multiple lines', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText('إنالسيطرةعلىالعالمعبارةقبيحةللغاية-أفضلأنأسميهاتحسينالعالم');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_rtl_multilined.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL 1 Line in ltr', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      textDirection: TextDirection.ltr,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);

    builder.addText('لABC لم def لل لم ghi');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix1_multilined_ltr.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL 1 Line in rtl', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Arial',
      fontSize: 50,
      textDirection: TextDirection.rtl,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);

    builder.addText('لABC لم def لل لم ghi');
    //لABC لم def لل لم ghi
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix1_multilined_rtl.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL multi Line with LTR by default', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      fontFamily: 'Arial',
      fontSize: 50,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText(
      'إنالسيطرةعلىاxyz لعالمعباvwx رةقبيحةstu للغاpqr ية-أmno فضلأjkl نأسميهاghi تحسيناdef لعاabc لم',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix_multilined_ltr.png', region: region);
  });

  test('Draw WebParagraph LTR/RTL multi Line with RTL by default', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      fontFamily: 'Arial',
      fontSize: 50,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText(
      'إنالسيطرةعلىاxyz لعالمعباvwx رةقبيحةstu للغاpqr ية-أmno فضلأjkl نأسميهاghi تحسيناdef لعاabc لم',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, Offset.zero);
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix_multilined_rtl.png', region: region);
  });

  test('Draw WebParagraph multicolored text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);

    final WebParagraphStyle blackStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: blackPaint,
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
    final WebParagraphBuilder builder = WebParagraphBuilder(blackStyle);

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
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multicolored.png', region: region);
  });

  test('Draw WebParagraph multicolored background text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);
    final Paint greyPaint1 = Paint()..color = const Color(0xFF666666);
    final Paint greyPaint2 = Paint()..color = const Color(0xFF888888);
    final Paint greyPaint3 = Paint()..color = const Color(0xFFAAAAAA);

    final WebParagraphStyle blackStyle = WebParagraphStyle(
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
    final WebParagraphBuilder builder = WebParagraphBuilder(blackStyle);

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
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multicolored_background.png', region: region);
  });

  test('Draw WebParagraph multiple font styles text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: blackPaint,
    );

    final WebTextStyle normal_normal = WebTextStyle(
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
    );

    final WebTextStyle normal_bold = WebTextStyle(
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

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);

    builder.pushStyle(normal_normal);
    builder.addText('Normal normal\n');
    builder.pop();

    builder.pushStyle(normal_bold);
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
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multifontstyled.png', region: region);
  });

  test('Draw WebParagraph multiple shadows text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      foreground: blackPaint,
    );

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
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(50, 50));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multishadows.png', region: region);
  });

  test('Draw WebParagraph multiple decorations on text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    expect(recorder, isA<engine.CkPictureRecorder>());
    expect(canvas, isA<engine.CanvasKitCanvas>());
    final Paint blackPaint = Paint()..color = const Color(0xFF000000);
    const Color redColor = Color(0xFFFF0000);
    const Color blueColor = Color(0xFF0000FF);
    const Color greenColor = Color(0xFF00FF00);

    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      foreground: blackPaint,
    );

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

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);

    builder.pushStyle(underlined);
    builder.addText('Underlined solid red decoration. ');
    builder.pop();

    builder.pushStyle(through);
    builder.addText('Through dashed blue decoration. ');
    builder.pop();

    builder.pushStyle(overlined);
    builder.addText('Overlined double green decoration. ');
    builder.pop();

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 400));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_multidecorated.png', region: region);
  });
}
