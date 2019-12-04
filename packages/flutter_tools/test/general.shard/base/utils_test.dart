// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('BotDetector', () {
    FakePlatform fakePlatform;
    MockStdio mockStdio;
    BotDetector botDetector;

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      mockStdio = MockStdio();
      botDetector = const BotDetector();
    });

    group('isRunningOnBot', () {
      testUsingContext('returns false unconditionally if BOT=false is set', () async {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(botDetector.isRunningOnBot, isFalse);
      }, overrides: <Type, Generator>{
        Stdio: () => mockStdio,
        Platform: () => fakePlatform,
      });

      testUsingContext('returns false unconditionally if FLUTTER_HOST is set', () async {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(botDetector.isRunningOnBot, isFalse);
      }, overrides: <Type, Generator>{
        Stdio: () => mockStdio,
        Platform: () => fakePlatform,
      });

      testUsingContext('returns false with and without a terminal attached', () async {
        mockStdio.stdout.hasTerminal = true;
        expect(botDetector.isRunningOnBot, isFalse);
        mockStdio.stdout.hasTerminal = false;
        expect(botDetector.isRunningOnBot, isFalse);
      }, overrides: <Type, Generator>{
        Stdio: () => mockStdio,
        Platform: () => fakePlatform,
      });

      testUsingContext('can test analytics outputs on bots when outputting to a file', () async {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';
        expect(botDetector.isRunningOnBot, isFalse);
      }, overrides: <Type, Generator>{
        Stdio: () => mockStdio,
        Platform: () => fakePlatform,
      });
    });
  });
}
