// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';

import '../../src/common.dart';
import '../../src/fake_http_client.dart';
import '../../src/fakes.dart';

final Uri azureUrl = Uri.parse('http://169.254.169.254/metadata/instance');

void main() {
  group('BotDetector', () {
    late FakePlatform fakePlatform;
    late FakeStdio fakeStdio;
    late PersistentToolState persistentToolState;

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      fakeStdio = FakeStdio();
      persistentToolState = PersistentToolState.test(
        directory: MemoryFileSystem.test().currentDirectory,
        logger: BufferLogger.test(),
      );
    });

    group('isRunningOnBot', () {
      testWithoutContext('returns false unconditionally if BOT=false is set', () async {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';

        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isNull);
      });

      testWithoutContext('does not cache BOT environment variable', () async {
        fakePlatform.environment['BOT'] = 'true';

        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(persistentToolState.isRunningOnBot, isNull);

        fakePlatform.environment['BOT'] = 'false';

        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isNull);
      });

      testWithoutContext('returns false unconditionally if FLUTTER_HOST is set', () async {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';

        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isNull);
      });

      testWithoutContext('returns false with and without a terminal attached', () async {
        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[
            FakeRequest(
              azureUrl,
              responseError: const SocketException('HTTP connection timed out'),
            ),
          ]),
          persistentToolState: persistentToolState,
        );

        fakeStdio.stdout.hasTerminal = true;
        expect(await botDetector.isRunningOnBot, isFalse);
        fakeStdio.stdout.hasTerminal = false;
        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isFalse);
      });

      testWithoutContext('can test analytics outputs on bots when outputting to a file', () async {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';

        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isNull);
      });

      testWithoutContext('returns true when azure metadata is reachable', () async {
        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(persistentToolState.isRunningOnBot, isTrue);
      });

      testWithoutContext('caches azure bot detection results across instances', () async {
        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(
          await BotDetector(
            platform: fakePlatform,
            httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[]),
            persistentToolState: persistentToolState,
          ).isRunningOnBot,
          isTrue,
        );
      });

      testWithoutContext('returns true when running on borg', () async {
        fakePlatform.environment['BORG_ALLOC_DIR'] = 'true';

        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.any(),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(persistentToolState.isRunningOnBot, isNull);
      });

      testWithoutContext('returns true when running on Azure DevOps (TF_BUILD is set)', () async {
        fakePlatform.environment['TF_BUILD'] = 'True';

        final botDetector = BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[]),
          persistentToolState: persistentToolState,
        );

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(persistentToolState.isRunningOnBot, isNull);
      });

      testWithoutContext(
        'overrides cached false when CI environment variable is set at runtime without mutating cache',
        () async {
          // Simulate an image bake where isRunningOnBot evaluated to false and cached to disk:
          persistentToolState.setIsRunningOnBot(false);
          expect(persistentToolState.isRunningOnBot, isFalse);

          fakePlatform.environment['GITHUB_ACTIONS'] = 'true';

          final botDetector = BotDetector(
            platform: fakePlatform,
            httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[]),
            persistentToolState: persistentToolState,
          );

          expect(await botDetector.isRunningOnBot, isTrue);
          expect(persistentToolState.isRunningOnBot, isFalse);
        },
      );

      testWithoutContext(
        'running with CI=true does not poison persistentToolState for subsequent runs',
        () async {
          persistentToolState.setIsRunningOnBot(false);
          expect(persistentToolState.isRunningOnBot, isFalse);

          // Invocation 1: Ran in a subshell or test runner with CI=true
          fakePlatform.environment['CI'] = 'true';
          final botDetector1 = BotDetector(
            platform: fakePlatform,
            httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[]),
            persistentToolState: persistentToolState,
          );
          expect(await botDetector1.isRunningOnBot, isTrue);
          expect(persistentToolState.isRunningOnBot, isFalse);

          // Invocation 2: Normal interactive terminal run (no CI variable)
          fakePlatform.environment.clear();
          final botDetector2 = BotDetector(
            platform: fakePlatform,
            httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[]),
            persistentToolState: persistentToolState,
          );
          expect(await botDetector2.isRunningOnBot, isFalse);
        },
      );

      testWithoutContext(
        'returns cached false when no bot environment variables are set',
        () async {
          persistentToolState.setIsRunningOnBot(false);
          expect(persistentToolState.isRunningOnBot, isFalse);

          final botDetector = BotDetector(
            platform: fakePlatform,
            httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[]),
            persistentToolState: persistentToolState,
          );

          expect(await botDetector.isRunningOnBot, isFalse);
          expect(persistentToolState.isRunningOnBot, isFalse);
        },
      );
    });
  });

  group('AzureDetector', () {
    testWithoutContext('isRunningOnAzure returns false when connection times out', () async {
      final azureDetector = AzureDetector(
        httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[
          FakeRequest(azureUrl, responseError: const SocketException('HTTP connection timed out')),
        ]),
      );

      expect(await azureDetector.isRunningOnAzure, isFalse);
    });

    testWithoutContext('isRunningOnAzure returns false when OsError is thrown', () async {
      final azureDetector = AzureDetector(
        httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[
          FakeRequest(azureUrl, responseError: const OSError('Connection Refused', 111)),
        ]),
      );

      expect(await azureDetector.isRunningOnAzure, isFalse);
    });

    testWithoutContext('isRunningOnAzure returns true when azure metadata is reachable', () async {
      final azureDetector = AzureDetector(
        httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[FakeRequest(azureUrl)]),
      );

      expect(await azureDetector.isRunningOnAzure, isTrue);
    });
    testWithoutContext(
      'isRunningOnAzure returns false when an unexpected exception is thrown',
      () async {
        final azureDetector = AzureDetector(
          httpClientFactory: () => FakeHttpClient.list(<FakeRequest>[
            FakeRequest(
              azureUrl,
              responseError: ArgumentError('No host specified in URI http:///e2gerror.php'),
            ),
          ]),
        );
        expect(await azureDetector.isRunningOnAzure, isFalse);
      },
    );
  });
}
