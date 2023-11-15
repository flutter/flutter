// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/initialization.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'fake_asset_manager.dart';

void setUpUnitTests({
  bool emulateTesterEnvironment = true,
  bool setUpTestViewDimensions = true,
}) {
  late final FakeAssetScope debugFontsScope;
  setUpAll(() async {
    // The implicit view is needed for `debugEmulateFlutterTesterEnvironment`,
    // `flutterViewEmbedder`, and `debugPhysicalSizeOverride`.
    engine.ensureImplicitViewInitialized();

    if (emulateTesterEnvironment) {
      ui_web.debugEmulateFlutterTesterEnvironment = true;
    }

    debugFontsScope = configureDebugFontsAssetScope(fakeAssetManager);
    debugOnlyAssetManager = fakeAssetManager;
    await bootstrapAndRunApp();
    engine.renderer.fontCollection.fontFallbackManager?.downloadQueue.fallbackFontUrlPrefixOverride = 'assets/fallback_fonts/';

    if (setUpTestViewDimensions) {
      // Force-initialize FlutterViewEmbedder so it doesn't overwrite test pixel ratio.
      engine.ensureFlutterViewEmbedderInitialized();

      // The following parameters are hard-coded in Flutter's test embedder. Since
      // we don't have an embedder yet this is the lowest-most layer we can put
      // this stuff in.
      const double devicePixelRatio = 3.0;
      engine.EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(devicePixelRatio);
      engine.EnginePlatformDispatcher.instance.implicitView!.debugPhysicalSizeOverride =
          const ui.Size(800 * devicePixelRatio, 600 * devicePixelRatio);
      engine.scheduleFrameCallback = () {};
    }
  });

  tearDownAll(() async {
    fakeAssetManager.popAssetScope(debugFontsScope);
  });
}

Future<void> bootstrapAndRunApp() async {
  final Completer<void> completer = Completer<void>();
  await ui_web.bootstrapEngine(runApp: () => completer.complete());
  await completer.future;
}
