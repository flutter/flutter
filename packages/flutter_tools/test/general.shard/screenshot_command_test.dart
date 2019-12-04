// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/screenshot.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Validate screenshot options', () {
    testUsingContext('rasterizer and skia screenshots do not require a device', () async {
      ScreenshotCommand.validateOptions('rasterizer', null, 'dummy_observatory_uri');
      ScreenshotCommand.validateOptions('skia', null, 'dummy_observatory_uri');
    });

    testUsingContext('rasterizer and skia screenshots require observatory uri', () async {
      expect(() => ScreenshotCommand.validateOptions('rasterizer', null, null), throwsToolExit());
      expect(() => ScreenshotCommand.validateOptions('skia', null, null), throwsToolExit());
    });

    testUsingContext('device screenshots require device', () async {
      expect(() => ScreenshotCommand.validateOptions('device', null, null), throwsToolExit());
    });
  });
}
