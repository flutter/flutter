// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  group('BotDetector', () {
    late FakePlatform fakePlatform;
    late FakeStdio fakeStdio;

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      fakeStdio = FakeStdio();
    });

    group('isRunningOnBot', () {
      testWithoutContext('returns false unconditionally if BOT=false is set', () async {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';

        final botDetector = BotDetector(platform: fakePlatform);

        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false when CI is set to false, 0, or empty string', () async {
        final botDetector = BotDetector(platform: fakePlatform);

        fakePlatform.environment['CI'] = 'false';
        expect(await botDetector.isRunningOnBot, isFalse);

        fakePlatform.environment['CI'] = '0';
        expect(await botDetector.isRunningOnBot, isFalse);

        fakePlatform.environment['CI'] = '';
        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext(
        'returns true when CI is set to true, 1, or another non-empty truthy value',
        () async {
          final botDetector = BotDetector(platform: fakePlatform);

          fakePlatform.environment['CI'] = 'true';
          expect(await botDetector.isRunningOnBot, isTrue);

          fakePlatform.environment['CI'] = '1';
          expect(await botDetector.isRunningOnBot, isTrue);

          fakePlatform.environment['CI'] = 'any_ci_value';
          expect(await botDetector.isRunningOnBot, isTrue);
        },
      );

      testWithoutContext('returns false unconditionally if FLUTTER_HOST is set', () async {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';

        final botDetector = BotDetector(platform: fakePlatform);

        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false with and without a terminal attached', () async {
        final botDetector = BotDetector(platform: fakePlatform);

        fakeStdio.stdout.hasTerminal = true;
        expect(await botDetector.isRunningOnBot, isFalse);
        fakeStdio.stdout.hasTerminal = false;
        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('can test analytics outputs on bots when outputting to a file', () async {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';

        final botDetector = BotDetector(platform: fakePlatform);

        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns true when running on borg', () async {
        fakePlatform.environment['BORG_ALLOC_DIR'] = 'true';

        final botDetector = BotDetector(platform: fakePlatform);

        expect(await botDetector.isRunningOnBot, isTrue);
      });

      testWithoutContext('returns true when running on Azure DevOps (TF_BUILD is set)', () async {
        fakePlatform.environment['TF_BUILD'] = 'True';

        final botDetector = BotDetector(platform: fakePlatform);

        expect(await botDetector.isRunningOnBot, isTrue);
      });

      testWithoutContext('returns false when no bot environment variables are set', () async {
        final botDetector = BotDetector(platform: fakePlatform);

        expect(await botDetector.isRunningOnBot, isFalse);
      });
    });
  });
}
