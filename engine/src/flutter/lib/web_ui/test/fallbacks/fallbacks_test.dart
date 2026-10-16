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

@JS('_flutter.supportsDart2Wasm')
external JSAny? get _flutterSupportsDart2Wasm;

@JS('_flutter.supportsDart2Wasm')
external set _flutterSupportsDart2Wasm(JSAny? value);

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

  test('loader rejects dart2wasm on Firefox < 147 before checking Wasm capabilities', () async {
    final String originalUserAgent = domWindow.navigator.userAgent;
    final JSAny? originalBuildConfig = _flutterBuildConfig;
    final JSAny? originalSupportsDart2Wasm = _flutterSupportsDart2Wasm;
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

      final JSAny? optInOptions = <String, Object?>{
        'config': <String, Object?>{
          'wasmAllowList': <String, bool>{'gecko': true},
        },
      }.jsify();

      // 1. Firefox 146 (< 147) must be rejected before evaluating Wasm capabilities,
      // even when _flutter.supportsDart2Wasm and WebAssembly.validate are true.
      objectConstructor.defineProperty(
        domWindow.navigator,
        'userAgent',
        DomPropertyDataDescriptor(
          value: 'Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0',
          configurable: true,
        ),
      );
      _flutterSupportsDart2Wasm = true.toJS;
      var validateCalls = 0;
      _wasmValidate = (() {
        validateCalls++;
        return true;
      }).toJS;

      await expectLater(
        _flutterLoaderLoad(optInOptions).toDart,
        throwsA(
          predicate<Object>(
            (Object e) => e.toString().contains('FlutterLoader could not find a build compatible'),
          ),
        ),
      );
      expect(validateCalls, 0);

      // 2. Firefox 147 (>= 147) passes the version gate and proceeds to evaluate
      // Wasm capabilities.
      objectConstructor.defineProperty(
        domWindow.navigator,
        'userAgent',
        DomPropertyDataDescriptor(
          value: 'Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0',
          configurable: true,
        ),
      );
      _flutterSupportsDart2Wasm = null;
      validateCalls = 0;
      _wasmValidate = (() {
        validateCalls++;
        return false;
      }).toJS;

      await expectLater(
        _flutterLoaderLoad(optInOptions).toDart,
        throwsA(
          predicate<Object>(
            (Object e) => e.toString().contains('FlutterLoader could not find a build compatible'),
          ),
        ),
      );
      expect(validateCalls, greaterThan(0));
    } finally {
      objectConstructor.defineProperty(
        domWindow.navigator,
        'userAgent',
        DomPropertyDataDescriptor(value: originalUserAgent, configurable: true),
      );
      _flutterSupportsDart2Wasm = originalSupportsDart2Wasm;
      _wasmValidate = originalValidate;
      _flutterBuildConfig = originalBuildConfig;
    }
  }, skip: ui_web.browser.browserEngine != ui_web.BrowserEngine.firefox);

  test('loader strictly honors wasmAllowList and WasmGC capability for dart2wasm builds', () async {
    final JSAny? originalBuildConfig = _flutterBuildConfig;
    final JSAny? originalSupportsDart2Wasm = _flutterSupportsDart2Wasm;
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

      // 2. When _flutter.supportsDart2Wasm is false (e.g. from main.dart.support.js),
      // explicit opt-in via wasmAllowList must reject the dart2wasm build even if
      // defaultSupportsDart2Wasm() would pass.
      _flutterSupportsDart2Wasm = false.toJS;
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

      // 3. When _flutter.supportsDart2Wasm is unset and WebAssembly.validate fails,
      // explicit opt-in via wasmAllowList must still reject the dart2wasm build.
      _flutterSupportsDart2Wasm = null;
      _wasmValidate = (() => false).toJS;

      await expectLater(
        _flutterLoaderLoad(optInOptions).toDart,
        throwsA(
          predicate<Object>(
            (Object e) => e.toString().contains('FlutterLoader could not find a build compatible'),
          ),
        ),
      );
    } finally {
      _flutterSupportsDart2Wasm = originalSupportsDart2Wasm;
      _wasmValidate = originalValidate;
      _flutterBuildConfig = originalBuildConfig;
    }
  });
}
