// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
/*
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/rendering.dart';
import '../../common/test_initialization.dart';
//import '../paragraph/helper.dart';
*/

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import '../../../lib/src/engine/web_paragraph/paragraph.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true);

  group('$WebParagraph.layout', () {
    test('print text clusters', () {
      final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Ahem', fontSize: 10);

      final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
      builder.addText('Lorem ipsum');
      final WebParagraph paragraph = builder.build();
      paragraph.layout(constrain(double.infinity));
    });
  });
}

