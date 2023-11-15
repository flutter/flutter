// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('services are initalized separately from UI', () async {
    final JsFlutterConfiguration? config = await bootstrapAndExtractConfig();
    expect(scheduleFrameCallback, isNull);
    expect(windowFlutterCanvasKit, isNull);

    expect(findGlassPane(), isNull);
    expect(RawKeyboard.instance, isNull);
    expect(KeyboardBinding.instance, isNull);
    expect(PointerBinding.instance, isNull);

    // After initializing services the UI should remain intact.
    await initializeEngineServices(jsConfiguration: config);
    expect(scheduleFrameCallback, isNotNull);
    expect(windowFlutterCanvasKit, isNotNull);

    expect(findGlassPane(), isNull);
    expect(RawKeyboard.instance, isNull);
    expect(KeyboardBinding.instance, isNull);
    expect(PointerBinding.instance, isNull);

    // Now UI should be taken over by Flutter.
    await initializeEngineUi();
    expect(findGlassPane(), isNotNull);
    expect(RawKeyboard.instance, isNotNull);
    expect(KeyboardBinding.instance, isNotNull);
    expect(PointerBinding.instance, isNotNull);
  });
}

DomElement? findGlassPane() {
  return domDocument.querySelector('flt-glass-pane');
}

Future<JsFlutterConfiguration?> bootstrapAndExtractConfig() {
  // Since this test is explicitly checking each part of the bootstrapping process,
  // we can't use the standard bootstrapper here. However, we do need the flutter
  // configuration object that is passed into flutter.js to actually initialize the
  // engine with, so here we do a little no-op bootstrap that just retrieves the
  // configuration that is passed into the `initializeEngine` callback.
  final Completer<JsFlutterConfiguration?> configCompleter = Completer<JsFlutterConfiguration?>();
  final AppBootstrap bootstrap = AppBootstrap(
    initializeEngine: ([JsFlutterConfiguration? config]) async => configCompleter.complete(config),
    runApp: () {}
  );
  final FlutterLoader? loader = flutter?.loader;
  if (loader == null || loader.isAutoStart) {
    // TODO(jacksongardner): Unit tests under dart2wasm still use the old way which
    // doesn't invoke flutter.js directly, so we autostart here. Once dart2wasm tests
    // work with flutter.js, we can remove this code path.
    bootstrap.autoStart();
  } else {
    loader.didCreateEngineInitializer(bootstrap.prepareEngineInitializer());
  }

  return configCompleter.future;
}
