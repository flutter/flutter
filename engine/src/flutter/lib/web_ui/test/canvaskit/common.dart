// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/rendering.dart';
import '../common/test_initialization.dart';

export '../common/rendering.dart' show renderScene;

/// Common test setup for all CanvasKit unit-tests.
void setUpCanvasKitTest({
  bool withImplicitView = false,
  ui_web.TestEnvironment testEnvironment = const ui_web.TestEnvironment.production(),
}) {
  setUpUnitTests(
    withImplicitView: withImplicitView,
    setUpTestViewDimensions: false,
    testEnvironment: testEnvironment,
  );

  setUp(
    () => debugOverrideJsConfiguration(
      <String, Object?>{'fontFallbackBaseUrl': 'assets/fallback_fonts/'}.jsify()
          as JsFlutterConfiguration?,
    ),
  );
}

/// Checks that a [picture] matches the [goldenFile].
///
/// The picture is drawn onto the UI at [ui.Offset.zero] with no additional
/// layers.
Future<void> matchPictureGolden(
  String goldenFile,
  CkPicture picture, {
  required ui.Rect region,
}) async {
  final sb = LayerSceneBuilder();
  sb.pushOffset(0, 0);
  sb.addPicture(ui.Offset.zero, picture);
  await renderScene(sb.build());
  await matchGoldenFile(goldenFile, region: region);
}
