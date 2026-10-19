// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';

void main() {
  group('BotDetector', () {
    late FakePlatform fakePlatform;
    late BotDetector botDetector;

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      botDetector = BotDetector(platform: fakePlatform);
    });

    group('isRunningOnBot', () {
      testWithoutContext('returns false unconditionally if BOT=false or BOT=0 is set', () {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(botDetector.isRunningOnBot, isFalse);

        fakePlatform.environment['BOT'] = 'False';
        expect(botDetector.isRunningOnBot, isFalse);

        fakePlatform.environment['BOT'] = '0';
        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false when BOT or CI is false, 0, or empty', () {
        for (final value in <String>['false', 'False', 'FALSE', '0', ' 0 ', '', '   ']) {
          fakePlatform.environment
            ..clear()
            ..['BOT'] = value;
          expect(botDetector.isRunningOnBot, isFalse, reason: 'BOT=$value');

          fakePlatform.environment
            ..clear()
            ..['CI'] = value;
          expect(botDetector.isRunningOnBot, isFalse, reason: 'CI=$value');
        }
      });

      testWithoutContext('returns true when BOT or CI is true or 1', () {
        for (final value in <String>['true', 'True', 'TRUE', '1', ' 1 ']) {
          fakePlatform.environment
            ..clear()
            ..['BOT'] = value;
          expect(botDetector.isRunningOnBot, isTrue, reason: 'BOT=$value');

          fakePlatform.environment
            ..clear()
            ..['CI'] = value;
          expect(botDetector.isRunningOnBot, isTrue, reason: 'CI=$value');
        }
      });

      testWithoutContext('does not cache BOT environment variable', () {
        fakePlatform.environment['BOT'] = 'true';
        expect(botDetector.isRunningOnBot, isTrue);

        fakePlatform.environment['BOT'] = 'false';
        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false unconditionally if FLUTTER_HOST is set', () {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';

        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('can test analytics outputs on bots when outputting to a file', () {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';

        expect(botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns true when running on borg', () {
        fakePlatform.environment['BORG_ALLOC_DIR'] = 'true';

        expect(botDetector.isRunningOnBot, isTrue);
      });

      testWithoutContext('returns true when running on Azure (AZURE_HTTP_USER_AGENT is set)', () {
        fakePlatform.environment['AZURE_HTTP_USER_AGENT'] = 'VSTS_...';

        expect(botDetector.isRunningOnBot, isTrue);
      });

      testWithoutContext('returns true when running on Azure DevOps (TF_BUILD is set)', () {
        fakePlatform.environment['TF_BUILD'] = 'True';

        expect(botDetector.isRunningOnBot, isTrue);
      });
    });
  });
}
