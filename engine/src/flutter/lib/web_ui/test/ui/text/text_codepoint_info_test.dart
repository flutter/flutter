// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

import '../../../lib/src/engine/web_paragraph/paragraph.dart';
import '../../../lib/src/engine/web_paragraph/layout.dart';
import '../../../lib/src/engine/web_paragraph/code_unit_flags.dart';
import '../../canvaskit/common.dart';
import '../../common/test_initialization.dart';
import '../utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('Extract unicode info', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('World domination is such an ugly phrase - \nI prefer to call it world optimisation.');
    final WebParagraph paragraph = builder.build();
    TextLayout layout = TextLayout(paragraph);
    layout.extractUnicodeInfo();

    int i = 0;
    for (final CodeUnitFlags flags in layout.codeUnitFlags) {
      print('${i}: ${flags.toString()}');
      i += 1;
    }
  });
}
