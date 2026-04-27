// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class MockFallbackFontRegistry implements FallbackFontRegistry {
  final Map<String, Uint8List> loadedFonts = <String, Uint8List>{};
  final List<String> updatedFamilies = <String>[];
  bool failNextLoad = false;

  @override
  Future<bool> loadFallbackFont(String familyName, Uint8List bytes) async {
    if (failNextLoad) {
      failNextLoad = false;
      return false;
    }
    loadedFonts[familyName] = bytes;
    return true;
  }

  @override
  void updateFallbackFontFamilies(List<String> families) {
    updatedFamilies.clear();
    updatedFamilies.addAll(families);
  }
}

void testMain() {
  group('FallbackFontService', () {
    late MockFallbackFontRegistry mockRegistry;
    late FontFallbackManager fontFallbackManager;

    setUp(() async {
      await renderer.initialize();
      mockRegistry = MockFallbackFontRegistry();
      fontFallbackManager = FontFallbackManager(mockRegistry);

      // Inject our mock manager and registry into the renderer.
      renderer.fontCollection.fontFallbackManager = fontFallbackManager;
      renderer.fontCollection.fallbackFontRegistry = mockRegistry;

      FallbackFontService.instance.debugReset();

      debugOverrideJsConfiguration(JsFlutterConfiguration(debugSkipFontRetryDelay: true));
    });

    tearDown(() async {
      await FallbackFontService.instance.waitForIdle();
      debugOverrideJsConfiguration(null);
    });

    test('successfully downloads and registers a font', () async {
      // Code point 0x4E00 is CJK Unified Ideograph, usually covered by Noto Sans SC/TC/JP/KR.
      FallbackFontService.instance.addMissingCodePoints(<int>[0x4E00]);
      await FallbackFontService.instance.waitForIdle();

      // Check if some font was loaded.
      expect(mockRegistry.loadedFonts.isNotEmpty, isTrue);
      expect(mockRegistry.updatedFamilies.isNotEmpty, isTrue);
    });

    test('retries on failure and eventually marks as permanently unavailable', () async {
      debugOverrideJsConfiguration(
        JsFlutterConfiguration(
          debugSkipFontRetryDelay: true,
          fontFallbackBaseUrl: 'http://invalid-url-that-fails.com/',
        ),
      );

      // Arabic code point
      FallbackFontService.instance.addMissingCodePoints(<int>[0x0627]);
      await FallbackFontService.instance.waitForIdle();

      // Since it failed, no fonts should be registered.
      expect(mockRegistry.loadedFonts, isEmpty);
    });

    test('re-evaluates code points when a font fails', () async {
      String? failedFontUrl;
      mockHttpFetchResponseFactory = (String url) async {
        // Fail the very first font that the service decides to download.
        if (failedFontUrl == null) {
          failedFontUrl = url;
          return MockHttpFetchResponse(
            url: url,
            status: 404, // Permanent failure
          );
        }
        // Return a successful response for the subsequent attempts (alternatives).
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: Uint8List(0).buffer),
        );
      };

      FallbackFontService.instance.addMissingCodePoints(<int>[0x4E00]);
      await FallbackFontService.instance.waitForIdle();

      expect(failedFontUrl, isNotNull);

      // The service should have tried another font that covers 0x4E00.
      final List<String> loadedFamilies = mockRegistry.loadedFonts.keys.toList();
      expect(loadedFamilies, isNotEmpty);

      // Verify that the loaded font also covers 0x4E00 (is a CJK font).
      final bool coveredByAlternative = loadedFamilies.any(
        (family) =>
            family.startsWith('Noto Sans SC') ||
            family.startsWith('Noto Sans TC') ||
            family.startsWith('Noto Sans HK') ||
            family.startsWith('Noto Sans JP') ||
            family.startsWith('Noto Sans KR'),
      );

      expect(
        coveredByAlternative,
        isTrue,
        reason: 'Should have loaded an alternative font for 0x4E00',
      );
    });

    test('treats 403 as permanent failure and tries alternative', () async {
      String? failedFontUrl;
      mockHttpFetchResponseFactory = (String url) async {
        if (failedFontUrl == null) {
          failedFontUrl = url;
          return MockHttpFetchResponse(url: url, status: 403);
        }
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: Uint8List(0).buffer),
        );
      };

      FallbackFontService.instance.addMissingCodePoints(<int>[0x4E00]);
      await FallbackFontService.instance.waitForIdle();

      expect(failedFontUrl, isNotNull);
      expect(mockRegistry.loadedFonts.isNotEmpty, isTrue);
    });

    test('treats 500 as transient and retries', () async {
      var attemptsForFirstFont = 0;
      String? firstFontUrl;

      mockHttpFetchResponseFactory = (String url) async {
        if (firstFontUrl == null || firstFontUrl == url) {
          firstFontUrl = url;
          attemptsForFirstFont++;
          if (attemptsForFirstFont < 3) {
            return MockHttpFetchResponse(url: url, status: 500);
          }
        }
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: Uint8List(0).buffer),
        );
      };

      FallbackFontService.instance.addMissingCodePoints(<int>[0x4E00]);
      await FallbackFontService.instance.waitForIdle();

      expect(attemptsForFirstFont, greaterThan(1));
      expect(
        mockRegistry.loadedFonts.keys,
        contains(mockRegistry.loadedFonts.keys.firstWhere((k) => true)),
      );
    });

    test('treats font registration failure as permanent', () async {
      mockHttpFetchResponseFactory = (String url) async {
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: Uint8List(0).buffer),
        );
      };

      // Mock the registry to fail the first time, but succeed afterwards.
      mockRegistry.failNextLoad = true;

      FallbackFontService.instance.addMissingCodePoints(<int>[0x4E00]);
      await FallbackFontService.instance.waitForIdle();

      // The first font failed to register, so it should have tried an alternative.
      expect(mockRegistry.loadedFonts.isNotEmpty, isTrue);
    });

    test('correctly resolves URLs with and without trailing slashes in base URL', () async {
      final requestedUrls = <String>[];
      mockHttpFetchResponseFactory = (String url) async {
        requestedUrls.add(url);
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: Uint8List(0).buffer),
        );
      };

      // Test with trailing slash
      debugOverrideJsConfiguration(
        JsFlutterConfiguration(
          debugSkipFontRetryDelay: true,
          fontFallbackBaseUrl: 'https://example.com/fonts/',
        ),
      );
      FallbackFontService.instance.addMissingCodePoints(<int>[0x0627]);
      await FallbackFontService.instance.waitForIdle();
      expect(requestedUrls.last, startsWith('https://example.com/fonts/'));

      // Test without trailing slash.
      // NOTE: Uri.resolve('a/b').resolve('c') results in 'a/c' if 'a/b' is not recognized as a directory.
      // But usually base URLs for fonts are intended to be directories.
      // If the user provides 'https://example.com/fonts', Uri.resolve will replace 'fonts' with the font path
      // unless 'fonts' ends with a slash.
      debugOverrideJsConfiguration(
        JsFlutterConfiguration(
          debugSkipFontRetryDelay: true,
          fontFallbackBaseUrl: 'https://example.com/fonts',
        ),
      );
      // Reset so it tries to download again.
      FallbackFontService.instance.debugReset();
      FallbackFontService.instance.addMissingCodePoints(<int>[0x0627]);
      await FallbackFontService.instance.waitForIdle();
      // 'https://example.com/fonts' resolved with 'noto...' becomes 'https://example.com/noto...'
      expect(requestedUrls.last, startsWith('https://example.com/'));
      expect(requestedUrls.last, isNot(contains('fonts')));
    });

    test('global kill switch disables service after enough failures with no success', () async {
      var callCount = 0;
      mockHttpFetchResponseFactory = (String url) async {
        callCount++;
        return MockHttpFetchResponse(url: url, status: 404);
      };

      // We need enough missing codepoints to trigger at least 10 unique font requests.
      // 0x4E00 (CJK), 0x0627 (Arabic), 0x05D0 (Hebrew), 0x0905 (Devanagari),
      // 0x03B1 (Greek), 0x0410 (Cyrillic), 0x0E01 (Thai), 0x1200 (Ethiopic),
      // 0x10A0 (Georgian), 0x0531 (Armenian), 0x13A0 (Cherokee)
      final missing = <int>[
        0x4E00,
        0x0627,
        0x05D0,
        0x0905,
        0x03B1,
        0x0410,
        0x0E01,
        0x1200,
        0x10A0,
        0x0531,
        0x13A0,
      ];

      FallbackFontService.instance.addMissingCodePoints(missing);
      await FallbackFontService.instance.waitForIdle();

      // It should have stopped once it hit the threshold.
      // Since downloads are in parallel, it might have started a few more
      // than exactly 10, but it should definitely be in that ballpark.
      expect(callCount, greaterThanOrEqualTo(10));
      expect(callCount, lessThan(20));

      // Subsequent requests should fail immediately.
      callCount = 0;
      FallbackFontService.instance.addMissingCodePoints(<int>[0x1100]); // Hangul Jamo
      await FallbackFontService.instance.waitForIdle();
      expect(callCount, 0);
    });

    test('per-component cap stops attempts after 5 failures for a single component', () async {
      var callCount = 0;
      mockHttpFetchResponseFactory = (String url) async {
        callCount++;
        return MockHttpFetchResponse(url: url, status: 404);
      };

      // CJK Unified Ideograph (0x4E00) is covered by many fonts (SC, TC, HK, JP, KR, etc).
      FallbackFontService.instance.addMissingCodePoints(<int>[0x4E00]);
      await FallbackFontService.instance.waitForIdle();

      // It should have stopped after trying 5 fonts for this component.
      expect(callCount, 5);

      // The service should NOT be broken yet (global limit is 10).
      callCount = 0;
      FallbackFontService.instance.addMissingCodePoints(<int>[0x0627]); // Arabic
      await FallbackFontService.instance.waitForIdle();
      expect(callCount, greaterThan(0));
    });
  });
}
