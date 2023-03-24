// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpAll(() async {
    await ui.webOnlyInitializePlatform();
  });

  group('font variation', () {
    test('is correctly rendered', () async {
      const double testWidth = 300;
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
      final CkParagraphBuilder builder =
        CkParagraphBuilder(CkParagraphStyle(
          fontSize: 40.0,
          textDirection: ui.TextDirection.ltr,
        ));

      builder.pushStyle(CkTextStyle(
          fontFamily: 'RobotoVariable',
      ));
      builder.addText('Normal\n');
      builder.pop();

      ui.FontVariation weight(double w) => ui.FontVariation('wght', w);
      builder.pushStyle(CkTextStyle(
          fontFamily: 'RobotoVariable',
          fontVariations: <ui.FontVariation>[weight(900)],
      ));
      builder.addText('Heavy\n');
      builder.pop();

      builder.pushStyle(CkTextStyle(
          fontFamily: 'RobotoVariable',
          fontVariations: <ui.FontVariation>[weight(100)],
      ));
      builder.addText('Light\n');
      builder.pop();

      final CkParagraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: testWidth - 20));
      canvas.drawParagraph(paragraph, const ui.Offset(10, 10));
      final CkPicture picture = recorder.endRecording();
      await matchPictureGolden(
        'font_variation.png',
        picture,
        region: ui.Rect.fromLTRB(0, 0, testWidth, paragraph.height + 20),
      );
    });
  });
}
