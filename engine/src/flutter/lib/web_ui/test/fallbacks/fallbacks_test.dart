// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

@JS()
external bool get crossOriginIsolated;

@JS('_flutter.loader.load')
external JSPromise<JSAny?> _flutterLoaderLoad(JSAny? options);

@JS('_flutter.buildConfig')
external JSAny? get _flutterBuildConfig;

@JS('_flutter.buildConfig')
external set _flutterBuildConfig(JSAny? value);

@JS('WebAssembly.validate')
external JSFunction get _wasmValidate;

@JS('WebAssembly.validate')
external set _wasmValidate(JSFunction value);

Future<void> testMain() async {
  setUpUnitTests(setUpTestViewDimensions: false);

  test('bootstrapper selects correct builds', () {
    if (ui_web.browser.browserEngine == ui_web.BrowserEngine.blink) {
      expect(isWasm, isTrue);
      expect(isSkwasm, isTrue);
      final bool shouldBeMultiThreaded =
          crossOriginIsolated && !configuration.forceSingleThreadedSkwasm;
      expect(isMultiThreaded, shouldBeMultiThreaded);
    } else {
      expect(isWasm, isFalse);
      expect(isCanvasKit, isTrue);
    }
  });

  test('loader strictly honors wasmAllowList and WasmGC capability for dart2wasm builds', () async {
    final JSAny? originalBuildConfig = _flutterBuildConfig;
    final JSFunction originalValidate = _wasmValidate;
    try {
      _flutterBuildConfig = <String, Object?>{
        'builds': <Map<String, Object?>>[
          <String, Object?>{
            'compileTarget': 'dart2wasm',
            'renderer': 'canvaskit',
            'mainWasmPath': 'main.dart.wasm',
            'jsSupportRuntimePath': 'main.dart.mjs',
          },
        ],
      }.jsify();

      // 1. When wasmAllowList disables the browser engine, dart2wasm/canvaskit
      // must be rejected even if the browser supports WasmGC.
      final JSAny? optOutOptions = <String, Object?>{
        'config': <String, Object?>{
          'wasmAllowList': <String, bool>{
            'gecko': false,
            'webkit': false,
            'blink': false,
            'unknown': false,
          },
        },
      }.jsify();

      await expectLater(
        _flutterLoaderLoad(optOutOptions).toDart,
        throwsA(
          predicate<Object>(
            (Object e) => e.toString().contains('FlutterLoader could not find a build compatible'),
          ),
        ),
      );

      // 2. When WasmGC capability validation fails, explicit opt-in via
      // wasmAllowList must still reject the dart2wasm build.
      _wasmValidate = (() => false).toJS;
      final JSAny? optInOptions = <String, Object?>{
        'config': <String, Object?>{
          'wasmAllowList': <String, bool>{
            'gecko': true,
            'webkit': true,
            'blink': true,
            'unknown': true,
          },
        },
      }.jsify();

      await expectLater(
        _flutterLoaderLoad(optInOptions).toDart,
        throwsA(
          predicate<Object>(
            (Object e) => e.toString().contains('FlutterLoader could not find a build compatible'),
          ),
        ),
      );
    } finally {
      _wasmValidate = originalValidate;
      _flutterBuildConfig = originalBuildConfig;
    }
  });
}
