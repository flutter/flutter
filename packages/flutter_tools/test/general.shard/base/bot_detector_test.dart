// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';

void main() {
  group('BotDetector', () {
    FakePlatform fakePlatform;
    MockStdio mockStdio;
    MockHttpClient mockHttpClient;
    MockHttpClientRequest mockHttpClientRequest;
    MockHttpHeaders mockHttpHeaders;
    BotDetector botDetector;
    PersistentToolState persistentToolState;

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      mockStdio = MockStdio();
      mockHttpClient = MockHttpClient();
      mockHttpClientRequest = MockHttpClientRequest();
      mockHttpHeaders = MockHttpHeaders();
      persistentToolState = PersistentToolState.test(
        directory: MemoryFileSystem.test().currentDirectory,
        logger: BufferLogger.test(),
      );
      botDetector = BotDetector(
        platform: fakePlatform,
        httpClientFactory: () => mockHttpClient,
        persistentToolState: persistentToolState,
      );
    });

    group('isRunningOnBot', () {
      testWithoutContext('returns false unconditionally if BOT=false is set', () async {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';

        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false unconditionally if FLUTTER_HOST is set', () async {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';

        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false with and without a terminal attached', () async {
        when(mockHttpClient.getUrl(any)).thenAnswer((_) {
          throw const SocketException('HTTP connection timed out');
        });
        mockStdio.stdout.hasTerminal = true;
        expect(await botDetector.isRunningOnBot, isFalse);
        mockStdio.stdout.hasTerminal = false;
        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isFalse);
      });

      testWithoutContext('can test analytics outputs on bots when outputting to a file', () async {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';
        expect(await botDetector.isRunningOnBot, isFalse);
        expect(persistentToolState.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns true when azure metadata is reachable', () async {
        when(mockHttpClient.getUrl(any)).thenAnswer((_) {
          return Future<HttpClientRequest>.value(mockHttpClientRequest);
        });
        when(mockHttpClientRequest.headers).thenReturn(mockHttpHeaders);

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(persistentToolState.isRunningOnBot, isTrue);
      });

      testWithoutContext('caches azure bot detection results across instances', () async {
        when(mockHttpClient.getUrl(any)).thenAnswer((_) {
          return Future<HttpClientRequest>.value(mockHttpClientRequest);
        });
        when(mockHttpClientRequest.headers).thenReturn(mockHttpHeaders);

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(await BotDetector(
          platform: fakePlatform,
          httpClientFactory: () => mockHttpClient,
          persistentToolState: persistentToolState,
        ).isRunningOnBot, isTrue);
        verify(mockHttpClient.getUrl(any)).called(1);
      });

      testWithoutContext('returns true when running on borg', () async {
        fakePlatform.environment['BORG_ALLOC_DIR'] = 'true';

        expect(await botDetector.isRunningOnBot, isTrue);
        expect(persistentToolState.isRunningOnBot, isTrue);
      });
    });
  });

  group('AzureDetector', () {
    AzureDetector azureDetector;
    MockHttpClient mockHttpClient;
    MockHttpClientRequest mockHttpClientRequest;
    MockHttpHeaders mockHttpHeaders;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockHttpClientRequest = MockHttpClientRequest();
      mockHttpHeaders = MockHttpHeaders();
      azureDetector = AzureDetector(
        httpClientFactory: () => mockHttpClient,
      );
    });

    testWithoutContext('isRunningOnAzure returns false when connection times out', () async {
      when(mockHttpClient.getUrl(any)).thenAnswer((_) {
        throw const SocketException('HTTP connection timed out');
      });

      expect(await azureDetector.isRunningOnAzure, isFalse);
    });

    testWithoutContext('isRunningOnAzure returns false when the http request times out', () {
      FakeAsync().run((FakeAsync time) async {
        when(mockHttpClient.getUrl(any)).thenAnswer((_) {
          final Completer<HttpClientRequest> completer = Completer<HttpClientRequest>();
          return completer.future;  // Never completed to test timeout behavior.
        });
        final Future<bool> onBot = azureDetector.isRunningOnAzure;
        time.elapse(const Duration(seconds: 2));

        expect(await onBot, isFalse);
      });
    });

    testWithoutContext('isRunningOnAzure returns false when OsError is thrown', () async {
      when(mockHttpClient.getUrl(any)).thenAnswer((_) {
        throw const OSError('Connection Refused', 111);
      });

      expect(await azureDetector.isRunningOnAzure, isFalse);
    });

    testWithoutContext('isRunningOnAzure returns true when azure metadata is reachable', () async {
      when(mockHttpClient.getUrl(any)).thenAnswer((_) {
        return Future<HttpClientRequest>.value(mockHttpClientRequest);
      });
      when(mockHttpClientRequest.headers).thenReturn(mockHttpHeaders);

      expect(await azureDetector.isRunningOnAzure, isTrue);
    });
  });
}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
