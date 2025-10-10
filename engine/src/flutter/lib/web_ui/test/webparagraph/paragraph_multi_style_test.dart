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

  test('Paragraph with multiple styles', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final WebTextStyle arial30Style = WebTextStyle(fontFamily: 'Arial', fontSize: 30);
    final WebTextStyle arial50Style = WebTextStyle(fontFamily: 'Arial', fontSize: 50);
    final WebTextStyle robotoStyle = WebTextStyle(fontFamily: 'Roboto', fontSize: 40);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.pushStyle(arial30Style);
    builder.addText('Arial, 30px;');
    builder.pop();
    builder.pushStyle(robotoStyle);
    builder.addText('Roboto, 40px;');
    builder.pop();
    builder.pushStyle(arial50Style);
    builder.addText('Arial, 50px;');
    builder.pop();
    final WebParagraph paragraph = builder.build();
    expect(paragraph.text, 'Arial, 30px;Roboto, 40px;Arial, 50px;');
    expect(paragraph.spans, hasLength(3));

    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
  });
}
