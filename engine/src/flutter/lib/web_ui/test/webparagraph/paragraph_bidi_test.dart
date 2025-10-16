// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph bidi 1 LTR only', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'Arial',
      fontSize: 20,
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Arial, 30px;');
    final WebParagraph paragraph = builder.build();
    final layout = paragraph.getLayout();
    layout.extractTextClusters();
    layout.extractBidiRuns();
    expect(layout.bidiRuns.length, 1);
  });

  test('Paragraph bidi 1 RTL only', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.rtl,
      fontFamily: 'Arial',
      fontSize: 20,
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('بَالَكُمُ');
    final WebParagraph paragraph = builder.build();
    final layout = paragraph.getLayout();
    layout.extractTextClusters();
    layout.extractBidiRuns();
    expect(layout.bidiRuns.length, 1);
  });

  test('Paragraph bidi mixed LTR/RTL + 1 style only', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(
      textDirection: ui.TextDirection.ltr,
      fontFamily: 'Arial',
      fontSize: 20,
    );

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('بَالَكُمُ');
    builder.addText('A');
    builder.addText('اللَّهُ');
    builder.addText('B');
    builder.addText('يَهْدِيْكُمُ');
    final WebParagraph paragraph = builder.build();
    final layout = paragraph.getLayout();
    layout.extractTextClusters();
    layout.extractBidiRuns();
    expect(layout.bidiRuns.length, 5);
  });
}
