// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';
import 'package:web_engine_tester/golden_tester.dart';

Future<void> takeScreenshot(
  EngineCanvas canvas,
  Rect region,
  String fileName, {
  bool write = false,
  double? maxDiffRatePercent,
}) async {
  final html.Element sceneElement = html.Element.tag('flt-scene');
  try {
    sceneElement.append(canvas.rootElement);
    html.document.body!.append(sceneElement);
    await matchGoldenFile(
      '$fileName.png',
      region: region,
      maxDiffRatePercent: maxDiffRatePercent,
      write: write,
    );
  } finally {
    // The page is reused across tests, so remove the element after taking the
    // Scuba screenshot.
    sceneElement.remove();
  }
}
