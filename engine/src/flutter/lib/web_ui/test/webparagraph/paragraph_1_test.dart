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
  const region = Rect.fromLTWH(0, 0, 1000, 1000);

  test('Draw WebParagraph text as a single image', () async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, region);
    canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);

    final arialStyle = WebParagraphStyle(
      fontFamily: 'Roboto',
      fontSize: 20,
      color: const Color(0xFF000000),
    );
    final builder = WebParagraphBuilder(arialStyle);
    builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
    builder.addText('Lorem ipsum dolor sit');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100));
    paragraph.fillAsSingleImage(canvas);
    paragraph.paintAsSingleImage(canvas, const Offset(100, 100));

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph_single_image.png', region: region);
  });
}
