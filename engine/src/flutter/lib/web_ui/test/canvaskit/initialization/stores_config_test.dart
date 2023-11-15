// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js_util.dart' as js_util;
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
      js_util.setProperty(config, 'canvasKitMaximumSurfaces', 32.0);
      js_util.setProperty(config, 'canvasKitBaseUrl', '/canvaskit/');
      js_util.setProperty(domWindow, 'flutterConfiguration', null);
      await initializeEngineServices(jsConfiguration: config);

      expect(configuration.canvasKitMaximumSurfaces, 32);
    });
  });
}
