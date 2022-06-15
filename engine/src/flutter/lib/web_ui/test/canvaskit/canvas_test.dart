// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome || safari || firefox')

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';

import '../engine/canvas_test.dart';
import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

// Run the same semantics tests in CanvasKit mode because as of today we do not
// yet share platform view logic with the HTML renderer, which affects
// semantics.
Future<void> testMain() async {
  group('CanvasKit semantics', () {
    setUpCanvasKitTest();

    runCanvasTests(deviceClipRoundsOut: true);
    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
