// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';

void main() {
  group('BotDetector', () {
    FakePlatform fakePlatform;
    MockStdio mockStdio;
    BotDetector botDetector;

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      mockStdio = MockStdio();
      botDetector = BotDetector(platform: fakePlatform);
    });

    group('isRunningOnBot', () {
      testWithoutContext('returns false unconditionally if BOT=false is set', () async {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false unconditionally if FLUTTER_HOST is set', () async {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false with and without a terminal attached', () async {
        mockStdio.stdout.hasTerminal = true;
        expect(botDetector.isRunningOnBot, isFalse);
        mockStdio.stdout.hasTerminal = false;
        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('can test analytics outputs on bots when outputting to a file', () async {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';
        expect(botDetector.isRunningOnBot, isFalse);
      });
    });
  });
}
