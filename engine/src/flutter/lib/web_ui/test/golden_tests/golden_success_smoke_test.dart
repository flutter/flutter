// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';
import 'package:web_engine_tester/golden_tester.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  debugEmulateFlutterTesterEnvironment = true;
  await webOnlyInitializePlatform(assetManager: WebOnlyMockAssetManager());

  test('screenshot test reports success', () async {
    html.document.body.style.fontFamily = 'Roboto';
    html.document.body.innerHtml = 'Hello world!';
    await matchGoldenFile('__local__/smoke_test.png', region: Rect.fromLTWH(0, 0, 320, 200));
  });
}
