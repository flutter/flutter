// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';

import '../frame_timings_common.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('frame timings', () {
    setUpCanvasKitTest();

    test('collects frame timings', () async {
      await runFrameTimingsTest();
    });
  }, skip: isIosSafari); // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
}
