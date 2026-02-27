// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('initializeEngineServices', () {
    test('does not mock module loaders', () async {
      // Initialize CanvasKit...
      await bootstrapAndRunApp();

      // window.exports and window.module should be undefined!
      expect(domWindow.has('exports'), isFalse, reason: '`window.exports` should not be defined.');
      expect(domWindow.has('module'), isFalse, reason: '`window.module` should not be defined.');
    });
  });
}
