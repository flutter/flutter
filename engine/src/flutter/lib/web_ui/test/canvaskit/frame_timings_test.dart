// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';
import '../frame_timings_common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('frame timings', () {
    setUpAll(() async {
      await ui.webOnlyInitializePlatform();
    });

    test('Using CanvasKit', () {
      expect(useCanvasKit, true);
    });

    test('collects frame timings', () async {
      await runFrameTimingsTest();
    });
  }, skip: isIosSafari); // TODO: https://github.com/flutter/flutter/issues/60040
}
