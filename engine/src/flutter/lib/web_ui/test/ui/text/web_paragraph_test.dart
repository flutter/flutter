// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../../../lib/src/engine/dom.dart';
import '../../../lib/src/engine/web_paragraph/paragraph.dart';
import '../../common/test_initialization.dart';
import '../utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true);
  const Rect region = Rect.fromLTWH(0, 0, 300, 300);

  test('Draw WebParagraph on Canvas2D', () async {
    final DomCanvasElement canvas = createDomCanvasElement(width: 200, height: 200);
    domDocument.body!.append(canvas);

    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Ahem', fontSize: 10);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('Lorem ipsum');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: double.infinity));
    paragraph.paint(canvas, Offset.zero);

    await matchGoldenFile('web_paragraph_canvas_2d.png', region: region);
  });
}
