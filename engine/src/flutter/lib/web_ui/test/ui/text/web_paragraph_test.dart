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
  /*
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
*/
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
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 300));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_mix1_multilined_rtl.png', region: region);
  });
  /*
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

  test('Draw WebParagraph One line text', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);
    //canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    //final Paint greyPaint = Paint()..color = const Color(0xFF444444);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);

    final WebParagraphStyle arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      foreground: bluePaint,
    );
    final WebParagraphBuilder builder = WebParagraphBuilder(arialStyle);
    builder.addText('Red color Blue color Black color Red color Blue color ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    //canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 50), greyPaint);
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 0));
    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_canvas_text.png', region: region);
  });
*/
}
