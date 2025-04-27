// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('initializeEngineServices', () {
    test('stores user configuration', () async {
      final JsFlutterConfiguration config = JsFlutterConfiguration();
      config
        // `canvasKitBaseUrl` is required for the test to actually run.
        ..['canvasKitBaseUrl'] = '/canvaskit/'.toJS
        // A property under test, that we'll try to read later.
        ..['nonce'] = 'some_nonce'.toJS
        // A non-existing property to verify our js-interop doesn't crash.
        ..['nonexistentProperty'] = 32.0.toJS;

      // Remove window.flutterConfiguration (if it's there)
      config['flutterConfiguration'] = null;

      // TODO(web): Replace the above nullification by the following assertion
      // when wasm and JS tests initialize their config the same way:
      // assert(js_util.getProperty<Object?>(domWindow, 'flutterConfiguration') == null);

      await initializeEngineServices(jsConfiguration: config);

      expect(configuration.nonce, 'some_nonce');
    });
  });
}
