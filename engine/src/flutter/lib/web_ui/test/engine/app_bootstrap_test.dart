// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  int callOrder = 1;
  int initCalled = 0;
  int runCalled = 0;

  setUp(() {
    callOrder = 1;
    initCalled = 0;
    runCalled = 0;
  });

  Future<void> mockInit([JsFlutterConfiguration? configuration]) async {
    debugOverrideJsConfiguration(configuration);
    addTearDown(() => debugOverrideJsConfiguration(null));
    initCalled = callOrder++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  Future<void> mockRunApp() async {
    runCalled = callOrder++;
  }

  test('autoStart() immediately calls init and run', () async {
    final AppBootstrap bootstrap = AppBootstrap(initializeEngine: mockInit, runApp: mockRunApp);

    await bootstrap.autoStart();

    expect(initCalled, 1, reason: 'initEngine should be called first.');
    expect(runCalled, 2, reason: 'runApp should be called after init.');
  });

  test('engineInitializer autoStart() does the same as Dart autoStart()', () async {
    final AppBootstrap bootstrap = AppBootstrap(initializeEngine: mockInit, runApp: mockRunApp);

    final FlutterEngineInitializer engineInitializer = bootstrap.prepareEngineInitializer();

    expect(engineInitializer, isNotNull);

    final JSObject maybeApp = await engineInitializer
        .callMethod<JSPromise<JSObject>>('autoStart'.toJS)
        .toDart;

    expect(maybeApp, isA<FlutterApp>());
    expect(initCalled, 1, reason: 'initEngine should be called first.');
    expect(runCalled, 2, reason: 'runApp should be called after init.');
  });

  test('engineInitializer initEngine() calls init and returns an appRunner', () async {
    final AppBootstrap bootstrap = AppBootstrap(initializeEngine: mockInit, runApp: mockRunApp);

    final FlutterEngineInitializer engineInitializer = bootstrap.prepareEngineInitializer();

    final JSObject maybeAppInitializer = await engineInitializer
        .callMethod<JSPromise<JSObject>>('initializeEngine'.toJS)
        .toDart;

    expect(maybeAppInitializer, isA<FlutterAppRunner>());
    expect(initCalled, 1, reason: 'initEngine should have been called.');
    expect(runCalled, 0, reason: 'runApp should not have been called.');
  });

  test('appRunner runApp() calls run and returns a FlutterApp', () async {
    final AppBootstrap bootstrap = AppBootstrap(initializeEngine: mockInit, runApp: mockRunApp);

    final FlutterEngineInitializer engineInitializer = bootstrap.prepareEngineInitializer();

    final JSObject appInitializer = await engineInitializer
        .callMethod<JSPromise<JSObject>>('initializeEngine'.toJS)
        .toDart;
    expect(appInitializer, isA<FlutterAppRunner>());
    final JSObject maybeApp = await appInitializer
        .callMethod<JSPromise<JSObject>>('runApp'.toJS)
        .toDart;
    expect(maybeApp, isA<FlutterApp>());
    expect(initCalled, 1, reason: 'initEngine should have been called.');
    expect(runCalled, 2, reason: 'runApp should have been called.');
  });

  group('FlutterApp', () {
    test('has addView/removeView methods', () async {
      final AppBootstrap bootstrap = AppBootstrap(initializeEngine: mockInit, runApp: mockRunApp);

      final FlutterEngineInitializer engineInitializer = bootstrap.prepareEngineInitializer();

      final JSObject appInitializer = await engineInitializer
          .callMethod<JSPromise<JSObject>>('initializeEngine'.toJS)
          .toDart;
      final FlutterApp maybeApp = await appInitializer
          .callMethod<JSPromise<FlutterApp>>('runApp'.toJS)
          .toDart;

      expect(maybeApp['addView'].isA<JSFunction>(), isTrue);
      expect(maybeApp['removeView'].isA<JSFunction>(), isTrue);
    });
    test('addView/removeView respectively adds/removes view', () async {
      final AppBootstrap bootstrap = AppBootstrap(initializeEngine: mockInit, runApp: mockRunApp);

      final FlutterEngineInitializer engineInitializer = bootstrap.prepareEngineInitializer();

      final JSObject appInitializer = await engineInitializer
          .callMethod<JSPromise<JSObject>>(
            'initializeEngine'.toJS,
            <String, Object?>{'multiViewEnabled': true}.jsify(),
          )
          .toDart;
      final JSObject maybeApp = await appInitializer
          .callMethod<JSPromise<JSObject>>('runApp'.toJS)
          .toDart;
      final int viewId = maybeApp
          .callMethod<JSNumber>(
            'addView'.toJS,
            <String, Object?>{'hostElement': createDomElement('div')}.jsify(),
          )
          .toDartInt;
      expect(bootstrap.viewManager[viewId], isNotNull);

      maybeApp.callMethod('removeView'.toJS, viewId.toJS);
      expect(bootstrap.viewManager[viewId], isNull);
    });
  });
}
