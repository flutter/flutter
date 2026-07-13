// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

@JS('eval')
external JSAny? _eval(JSString code);

@JS('window._capturedDeferredModulesLoader')
external JSAny? get _capturedDeferredModulesLoader;

@JS('window._capturedDeferredModulesLoader')
external set _capturedDeferredModulesLoader(JSAny? value);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<JSObject> createEntrypointLoader() async {
  final promise = _eval('import("/flutter_js/src/entrypoint_loader.js")'.toJS) as JSPromise?;
  final module = await promise!.toDart as JSObject?;
  final JSFunction constructor = module!.getProperty<JSFunction>('FlutterEntrypointLoader'.toJS);
  return constructor.callAsConstructor<JSObject>();
}

String createFakeRuntimeModuleCode() {
  return '''
export function compileStreaming(promise) {
  return Promise.resolve({
    instantiate: async (imports, options) => {
      globalThis._capturedDeferredModulesLoader =
          options.loadDeferredModules;
      return {
        invokeMain: async () => {}
      };
    }
  });
}
''';
}

JSString createFakeRuntimeUrl() {
  final String code = createFakeRuntimeModuleCode();
  return _eval(
        'URL.createObjectURL(new Blob([${jsonEncode(code)}], {type: "application/javascript"}))'
            .toJS,
      )!
      as JSString;
}

JSObject createDummyWasmBuild() {
  return <String, Object>{
    'compileTarget': 'dart2wasm',
    'mainWasmPath': 'data:application/wasm,',
    'jsSupportRuntimePath': createFakeRuntimeUrl().toDart,
  }.jsify()! as JSObject;
}

void testMain() {
  group('Deferred loading helper', () {
    setUp(() {
      _capturedDeferredModulesLoader = null;
    });

    test('config options configure Wasm deferred loader in FlutterEntrypointLoader', () async {
      final JSObject entrypointLoader = await createEntrypointLoader();
      final JSFunction dummyModulesLoader = (() {}).toJS;

      final config = JSObject();
      config.setProperty('wasmDeferredModulesLoader'.toJS, dummyModulesLoader);

      final JSObject dummyBuild = createDummyWasmBuild();

      final JSPromise promise = entrypointLoader.callMethodVarArgs<JSPromise>('load'.toJS, <JSAny?>[
        dummyBuild,
        JSObject(),
        config,
      ]);
      await promise.toDart;

      expect(_capturedDeferredModulesLoader, equals(dummyModulesLoader));
    });

    test('Wasm entrypoint load passes explicit deferred modules loader to instantiate', () async {
      final JSObject entrypointLoader = await createEntrypointLoader();
      final JSFunction dummyModulesLoader = (() {}).toJS;

      final JSObject dummyBuild = createDummyWasmBuild();

      final JSPromise promise = entrypointLoader.callMethodVarArgs<JSPromise>(
        '_loadWasmEntrypoint'.toJS,
        <JSAny?>[dummyBuild, JSObject(), ''.toJS, (() {}).toJS, dummyModulesLoader],
      );
      await promise.toDart;

      expect(_capturedDeferredModulesLoader, equals(dummyModulesLoader));
    });

    test('Wasm entrypoint load provides default fallback loader when unconfigured', () async {
      final JSObject entrypointLoader = await createEntrypointLoader();

      final JSObject dummyBuild = createDummyWasmBuild();

      final JSPromise promise = entrypointLoader.callMethod<JSPromise>(
        '_loadWasmEntrypoint'.toJS,
        dummyBuild,
        JSObject(),
        ''.toJS,
        (() {}).toJS,
      );
      await promise.toDart;

      expect(_capturedDeferredModulesLoader, isNotNull);
      expect(_capturedDeferredModulesLoader!.isA<JSFunction>(), isTrue);
    });
  });
}
