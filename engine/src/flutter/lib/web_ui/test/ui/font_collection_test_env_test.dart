// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_test_fonts/web_test_fonts.dart';

import '../common/fake_asset_manager.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
    setUpTestViewDimensions: false,
    testEnvironment: const ui_web.TestEnvironment(forceTestFonts: true),
  );

  test('FlutterTest is registered before the asset fonts', () {
    final collection = renderer.fontCollection as EngineFontCollection;
    final List<String> families = collection.debugRegisteredFonts
        .map((RegisteredFont font) => font.family)
        .toList();
    expect(families, <String>[
      EmbeddedTestFont.flutterTest.fontFamily,
      robotoFontFamily,
      ahemFontFamily,
      robotoVariableFontFamily,
    ]);
  });
}
