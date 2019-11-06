// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/commands/screenshot.dart';
import 'package:matcher/matcher.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  final Matcher expectToolError = throwsA(const TypeMatcher<ToolExit>());

  setUpAll(() {});

  group('Validate screenshot options', () {
    setUp(() async {});

    testUsingContext('rasterizer and skia screenshots do not require a device', () async {
      ScreenshotCommand.validateOptions('rasterizer', null, 'dummy_observatory_uri');
      ScreenshotCommand.validateOptions('skia', null, 'dummy_observatory_uri');
    });

    testUsingContext('rasterizer and skia screenshots require observatory uri', () async {
      expect(() => ScreenshotCommand.validateOptions('rasterizer', null, null), expectToolError);
      expect(() => ScreenshotCommand.validateOptions('skia', null, null), expectToolError);
    });

    testUsingContext('device screenshots require device', () async {
      expect(() => ScreenshotCommand.validateOptions('device', null, null), expectToolError);
    });
  });
}
