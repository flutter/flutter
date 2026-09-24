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

  test(
    'loader strictly honors WasmGC capability when explicitly opted in on unsupported browsers',
    () async {
      // If the browser does NOT natively support dart2wasm (like Gecko in CI/today),
      // and the user opts in via `wasmAllowList`, it should STILL throw an error
      // because it respects the capability probe.
      if (!isWasm) {
        final JSAny? loadOptions = <String, Object?>{
          'config': <String, Object?>{
            'wasmAllowList': <String, bool>{
              'gecko': true,
              'webkit': true,
              'blink': true,
              'unknown': true,
            },
          },
        }.jsify();

        try {
          await _flutterLoaderLoad(loadOptions).toDart;
          fail('Expected flutter.loader.load() to throw because of WasmGC unsupported fallback.');
        } catch (e) {
          // The error should mention FlutterLoader could not find a build compatible,
          // which proves the dart2wasm build was skipped due to !supportsDart2Wasm.
          expect(e.toString(), contains('FlutterLoader could not find a build compatible'));
        }
      }
    },
  );
}
