// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

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

    setUp(() {
      fakePlatform = FakePlatform()..environment = <String, String>{};
      mockStdio = MockStdio();
      mockHttpClient = MockHttpClient();
      mockHttpClientRequest = MockHttpClientRequest();
      mockHttpHeaders = MockHttpHeaders();
      botDetector = BotDetector(
        platform: fakePlatform,
        httpClientFactory: () => mockHttpClient,
      );
    });

    group('isRunningOnBot', () {
      testWithoutContext('returns false unconditionally if BOT=false is set', () async {
        fakePlatform.environment['BOT'] = 'false';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false unconditionally if FLUTTER_HOST is set', () async {
        fakePlatform.environment['FLUTTER_HOST'] = 'foo';
        fakePlatform.environment['TRAVIS'] = 'true';
        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns false with and without a terminal attached', () async {
        when(mockHttpClient.getUrl(any)).thenAnswer((_) {
          throw const SocketException('HTTP connection timed out');
        });
        mockStdio.stdout.hasTerminal = true;
        expect(await botDetector.isRunningOnBot, isFalse);
        mockStdio.stdout.hasTerminal = false;
        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('can test analytics outputs on bots when outputting to a file', () async {
        fakePlatform.environment['TRAVIS'] = 'true';
        fakePlatform.environment['FLUTTER_ANALYTICS_LOG_FILE'] = '/some/file';
        expect(await botDetector.isRunningOnBot, isFalse);
      });

      testWithoutContext('returns true when azure metadata is reachable', () async {
        when(mockHttpClient.getUrl(any)).thenAnswer((_) {
          return Future<HttpClientRequest>.value(mockHttpClientRequest);
        });
        when(mockHttpClientRequest.headers).thenReturn(mockHttpHeaders);
        expect(await botDetector.isRunningOnBot, isTrue);
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
