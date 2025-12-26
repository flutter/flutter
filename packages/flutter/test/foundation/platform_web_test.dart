// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('chrome')
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    // Remove the `debugOperatingSystemOverride`.
    ui_web.browser.debugOperatingSystemOverride = null;
  });

  group('defaultTargetPlatform', () {
    testWidgets('returns what ui_web says', (WidgetTester _) async {
      // Set the OS reported by web_ui to anything that is not linux.
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.iOs;

      expect(defaultTargetPlatform, TargetPlatform.iOS);
    });

    testWidgets('defaults `unknown` to android', (WidgetTester _) async {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.unknown;

      expect(defaultTargetPlatform, TargetPlatform.android);
    });
  });
}
