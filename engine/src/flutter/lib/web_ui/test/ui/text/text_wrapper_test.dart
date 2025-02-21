// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../../../lib/src/engine/web_paragraph/paragraph.dart';
import '../../canvaskit/common.dart';
import '../../common/test_initialization.dart';
import '../utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);
  /*
  test('Text wrapper, 10 lines, 3 trailing whitespaces on each line except the one that has a cluster break', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    //builder.addText('World domination is such an   ugly phrase - I prefer to call it   world optimisation.   ');
    builder.addText('World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: 250));
  });
  test('Text wrapper, 4 lines, 3 trailing whitespaces on each line', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('World domination is   such an ugly phrase   - I prefer to call it   world optimisation.   ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: 500));
  });
  test('Text wrapper, 1 lines, 5 whitespaces and nothing else', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('     ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: double.infinity));
  });
  test('Text wrapper, 3 lines, one very long word', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('abcdefghijklmnopqrstuvwxyz');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: 250));
  });
  */
  test('Text wrapper, leading spaces', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('   abcdefghijklmnopqrstuvwxyz');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(ParagraphConstraints(width: 250));
  });
}
