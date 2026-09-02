// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('initializeAssetManager sets ui_web.assetManager', () {
    final customManager = ui_web.AssetManager(assetsDir: 'custom_assets');
    ui_web.initializeAssetManager(customManager);
    expect(ui_web.assetManager, customManager);
  });

  test('bootstrapEngineServices and bootstrapEngineUi initialize engine in steps', () async {
    // Reset the engine
    engine.debugResetEngineInitializationState();

    expect(engine.initializationState, engine.DebugEngineInitializationState.uninitialized);

    final engineConfiguration = JSObject()..setProperty('multiViewEnabled'.toJS, true.toJS);

    await ui_web.bootstrapEngineServices(jsConfiguration: engineConfiguration);

    expect(engine.initializationState, engine.DebugEngineInitializationState.initializedServices);
    expect(engine.configuration.multiViewEnabled, isTrue);

    await ui_web.bootstrapEngineUi();

    expect(engine.initializationState, engine.DebugEngineInitializationState.initialized);
  }, skip: ui_web.browser.isFirefox);
}
