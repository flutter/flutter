// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  const Rect region = Rect.fromLTWH(0, 0, 500, 500);

  test('Draw WebParagraph on Canvas2D', () async {
    final engine.DomCanvasElement canvas = engine.createDomCanvasElement(width: 500, height: 500);
    engine.domDocument.body!.append(canvas);
    final engine.DomCanvasRenderingContext2D context = canvas.context2D;

    context.fillStyle = 'red';
    context.fillRect(0, 0, 200, 200);

    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paintOnCanvas2D(canvas, const Offset(0, 100));

    context.fillStyle = 'blue';
    context.fillRect(250, 0, 100, 200);

    await matchGoldenFile('web_paragraph_canvas2d.png', region: region);
  });

  test('Draw WebParagraph in Canvas', () async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder, region);

    final Paint redPaint = Paint()..color = const Color(0xFFFF0000);
    final Paint bluePaint = Paint()..color = const Color(0xFF0000FF);

    canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 200), redPaint);

    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    paragraph.paintOnCanvasKit(canvas as engine.CanvasKitCanvas, const Offset(0, 100));

    canvas.drawRect(const Rect.fromLTWH(250, 0, 100, 200), bluePaint);
    await matchGoldenFile('web_paragraph_canvas.png', region: region);
  });
}
