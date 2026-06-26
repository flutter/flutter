// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';

@JS('_flutterTestConfig')
external JSObject get flutterTestConfig;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('loads the expected Skwasm artifact for this suite', () {
    final List<String> loadedResourceNames = getLoadedResourceNames();
    final String? expectedFileStem = getExpectedSkwasmFileStem();

    if (expectedFileStem == null) {
      expect(
        loadedResourceNames.any(isSkwasmArtifact),
        isTrue,
        reason: 'The Skwasm test suite should load a Skwasm-family artifact.',
      );
    } else {
      expect(
        loadedResourceNames,
        contains(endsWith('/canvaskit/$expectedFileStem.js')),
        reason: 'The Skwasm test suite should load the expected JS artifact.',
      );
      expect(
        loadedResourceNames,
        contains(endsWith('/canvaskit/$expectedFileStem.wasm')),
        reason: 'The Skwasm test suite should load the expected Wasm artifact.',
      );
      for (final fileStem in <String>['skwasm', 'skwasm_heavy', 'wimp']) {
        if (fileStem == expectedFileStem) {
          continue;
        }
        expect(
          loadedResourceNames.any((String name) => name.contains('/canvaskit/$fileStem.')),
          isFalse,
          reason: 'The Skwasm test suite should not silently load $fileStem.',
        );
      }
    }
    expect(
      loadedResourceNames.any((String name) => name.contains('/canvaskit/canvaskit.')),
      isFalse,
      reason: 'The Skwasm suite should not silently fall back to CanvasKit.',
    );
  });
}

List<String> getLoadedResourceNames() {
  final JSArray<JSAny?> entries = domWindow.performance.callMethod<JSArray<JSAny?>>(
    'getEntriesByType'.toJS,
    'resource'.toJS,
  );
  return entries.toDart.map((JSAny? entry) {
    return (entry! as JSObject).getProperty<JSString>('name'.toJS).toDart;
  }).toList();
}

String? getExpectedSkwasmFileStem() {
  final bool enableWimp = flutterTestConfig.getProperty<JSBoolean>('enableWimp'.toJS).toDart;
  if (enableWimp) {
    return 'wimp';
  }
  final String? skwasmVariant = flutterTestConfig
      .getProperty<JSString?>('skwasmVariant'.toJS)
      ?.toDart;
  return switch (skwasmVariant) {
    'normal' => 'skwasm',
    'heavy' => 'skwasm_heavy',
    _ => null,
  };
}

bool isSkwasmArtifact(String name) {
  return name.contains('/canvaskit/skwasm.') ||
      name.contains('/canvaskit/skwasm_heavy.') ||
      name.contains('/canvaskit/wimp.');
}
