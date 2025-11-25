// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      final config = JsFlutterConfiguration(canvasKitBaseUrl: '/canvaskit/', nonce: 'some_nonce');

      assert(domWindow['flutterConfiguration'] == null);

      await initializeEngineServices(jsConfiguration: config);

      expect(configuration.nonce, 'some_nonce');
    });
  });
}
