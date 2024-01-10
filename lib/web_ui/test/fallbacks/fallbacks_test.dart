// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(
    setUpTestViewDimensions: false,
  );

  test('bootstrapper selects correct builds', () {
    if (browserEngine == BrowserEngine.blink) {
      expect(isWasm, isTrue);
      expect(isSkwasm, isTrue);
    } else {
      expect(isWasm, isFalse);
      expect(isCanvasKit, isTrue);
    }
  });
}
