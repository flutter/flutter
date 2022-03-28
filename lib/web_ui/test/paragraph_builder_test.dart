// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  await webOnlyInitializePlatform();

  test('Should be able to build and layout a paragraph', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle());
    builder.addText('Hello');
    final Paragraph paragraph = builder.build();
    expect(paragraph, isNotNull);

    paragraph.layout(const ParagraphConstraints(width: 800.0));
    expect(paragraph.width, isNonZero);
    expect(paragraph.height, isNonZero);
  });

  test('pushStyle should not segfault after build()', () {
    final ParagraphBuilder paragraphBuilder =
        ParagraphBuilder(ParagraphStyle());
    paragraphBuilder.build();
    paragraphBuilder.pushStyle(TextStyle());
  });

  test('the presence of foreground style should not throw', () {
    final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle());
    builder.pushStyle(TextStyle(
      foreground: Paint()..color = const Color(0xFFABCDEF),
    ));
    builder.addText('hi');

    expect(() => builder.build(), returnsNormally);
  });
}
