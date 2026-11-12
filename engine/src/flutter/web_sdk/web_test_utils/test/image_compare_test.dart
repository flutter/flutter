// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;
import 'package:skia_gold_client/skia_gold_client.dart';
import 'package:test/test.dart';
import 'package:web_test_utils/image_compare.dart';

class FakeSkiaGoldClient implements SkiaGoldClient {
  FakeSkiaGoldClient({
    this.expectationToReturn,
    this.imageBytesToReturn,
    this.dimensions,
    this.prefix = 'engine.',
  });

  String? expectationToReturn;
  Uint8List? imageBytesToReturn;

  @override
  final String prefix;

  @override
  final Map<String, String>? dimensions;

  int getExpectationCalls = 0;
  int getImageBytesCalls = 0;

  @override
  Future<String?> getExpectationForTest(String testName) async {
    getExpectationCalls += 1;
    return expectationToReturn;
  }

  @override
  Future<Uint8List> getImageBytes(String digest) async {
    getImageBytesCalls += 1;
    if (imageBytesToReturn != null) {
      return imageBytesToReturn!;
    }
    throw const SocketException('Failed to fetch image');
  }

  @override
  String getTraceID(String testName) {
    return 'trace_$testName';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Image _createSolidImage(int width, int height, ColorRgba8 color) {
  final image = Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixel(x, y, color);
    }
  }
  return image;
}

Directory _createTempTestDir() {
  final Directory tempDir = Directory.systemTemp.createTempSync('flutter_image_compare_test.');
  addTearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  return tempDir;
}

void main() {
  group('comparePixels', () {
    final white = ColorRgba8(255, 255, 255, 255);
    final black = ColorRgba8(0, 0, 0, 255);
    final red = ColorRgba8(255, 0, 0, 255);

    test('exact match returns isMatch true', () {
      final Image img1 = _createSolidImage(10, 10, white);
      final Image img2 = _createSolidImage(10, 10, white);

      final PixelComparisonResult result = comparePixels(
        img1,
        img2,
        pixelComparison: PixelComparison.precise,
      );

      expect(result.isMatch, isTrue);
      expect(result.differentPixelCount, 0);
      expect(result.differentPixelRate, 0.0);
    });

    test('precise match detects pixel difference above tolerance', () {
      final Image img1 = _createSolidImage(10, 10, white);
      final Image img2 = _createSolidImage(10, 10, white);
      img2.setPixel(5, 5, black);

      final PixelComparisonResult result = comparePixels(
        img1,
        img2,
        pixelComparison: PixelComparison.precise,
        maxDifferentPixelsRate: 0.0,
      );

      expect(result.isMatch, isFalse);
      expect(result.differentPixelCount, 1);
      expect(result.differentPixelRate, closeTo(0.01, 0.001));
      expect(result.diffImage, isNotNull);

      // Check that the diff pixel is highlighted with #FF007F (255, 0, 127, 255).
      final Pixel diffPixel = result.diffImage!.getPixel(5, 5);
      expect(diffPixel.r, 255);
      expect(diffPixel.g, 0);
      expect(diffPixel.b, 127);
    });

    test('fuzzy match allows 1-pixel shift in 3x3 neighborhood', () {
      final Image actual = _createSolidImage(10, 10, white);
      final Image expected = _createSolidImage(10, 10, white);

      // Put red pixel at (5, 5) in actual, but at (5, 6) in expected.
      actual.setPixel(5, 5, red);
      expected.setPixel(5, 6, red);

      final PixelComparisonResult result = comparePixels(
        actual,
        expected,
        maxDifferentPixelsRate: 0.0,
      );

      expect(result.isMatch, isTrue);
      expect(result.differentPixelCount, 0);
    });

    test('fuzzy match fails when pixel has no matching neighbor in 3x3 grid', () {
      final Image actual = _createSolidImage(10, 10, white);
      final Image expected = _createSolidImage(10, 10, white);

      actual.setPixel(5, 5, red); // Red not present in expected 3x3 grid (which is all white)

      final PixelComparisonResult result = comparePixels(
        actual,
        expected,
        maxDifferentPixelsRate: 0.0,
      );

      expect(result.isMatch, isFalse);
      expect(result.differentPixelCount, 1);
    });

    test('dimension mismatch returns isMatch false and dimension error', () {
      final Image img1 = _createSolidImage(10, 10, white);
      final Image img2 = _createSolidImage(10, 12, white);

      final PixelComparisonResult result = comparePixels(
        img1,
        img2,
        pixelComparison: PixelComparison.precise,
      );

      expect(result.isMatch, isFalse);
      expect(result.errorMessage, contains('Dimension mismatch'));
      expect(result.errorMessage, contains('10x10'));
      expect(result.errorMessage, contains('10x12'));
    });
  });

  group('compareImage with caching and local golden', () {
    final white = ColorRgba8(255, 255, 255, 255);
    final black = ColorRgba8(0, 0, 0, 255);

    test('new golden returns OK when Skia Gold returns no positive expectation', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, white);
      final client = FakeSkiaGoldClient();

      final String result = await compareImage(
        screenshot,
        false,
        'new_test.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        cacheDirectory: tempDir,
      );

      expect(result, 'OK');
      expect(client.getExpectationCalls, 1);
    });

    test('matching baseline returns OK and caches baseline on disk', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, white);
      final Uint8List goldenBytes = encodePng(_createSolidImage(10, 10, white));
      final client = FakeSkiaGoldClient(
        expectationToReturn: 'digest123456',
        imageBytesToReturn: goldenBytes,
      );

      final String result = await compareImage(
        screenshot,
        false,
        'match_test.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        cacheDirectory: tempDir,
      );

      expect(result, 'OK');
      expect(client.getExpectationCalls, 1);
      expect(client.getImageBytesCalls, 1);

      // Verify cached file exists on disk.
      final cachedFile = File(p.join(tempDir.path, 'baselines', 'digest123456.png'));
      expect(cachedFile.existsSync(), isTrue);

      // Second run should use cached file without calling getImageBytes again.
      final String result2 = await compareImage(
        screenshot,
        false,
        'match_test.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        cacheDirectory: tempDir,
      );
      expect(result2, 'OK');
      expect(client.getImageBytesCalls, 1); // Still 1
    });

    test('mismatching baseline fails and produces failure artifacts', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, black);
      final Uint8List goldenBytes = encodePng(_createSolidImage(10, 10, white));
      final client = FakeSkiaGoldClient(
        expectationToReturn: 'digest_mismatch',
        imageBytesToReturn: goldenBytes,
      );

      final String result = await compareImage(
        screenshot,
        false,
        'mismatch_test.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        pixelComparison: PixelComparison.precise,
        maxDiffRate: 0.0,
        cacheDirectory: tempDir,
      );

      expect(result, isNot('OK'));
      expect(result, contains('Golden comparison failed for test: mismatch_test.png'));
      expect(result, contains('Different pixels: 100'));

      // Check failure artifacts.
      final failureDir = Directory(p.join(tempDir.path, 'failures', 'engine.mismatch_test'));
      expect(File(p.join(failureDir.path, 'actual.png')).existsSync(), isTrue);
      expect(File(p.join(failureDir.path, 'expected.png')).existsSync(), isTrue);
      expect(File(p.join(failureDir.path, 'diff.png')).existsSync(), isTrue);
    });

    test('offline mode uses disk cache if available', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, white);
      final Uint8List goldenBytes = encodePng(_createSolidImage(10, 10, white));
      final client = FakeSkiaGoldClient(expectationToReturn: 'digest_offline');

      // Prepopulate cache with trace ID digest and image.
      final String traceID = client.getTraceID('engine.offline_cached');
      final digestFile = File(p.join(tempDir.path, 'baselines', '$traceID.digest'));
      await digestFile.create(recursive: true);
      await digestFile.writeAsString('digest_offline', flush: true);

      final baselineFile = File(p.join(tempDir.path, 'baselines', 'digest_offline.png'));
      await baselineFile.create(recursive: true);
      await baselineFile.writeAsBytes(goldenBytes, flush: true);

      final String result = await compareImage(
        screenshot,
        false,
        'offline_cached.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        isOffline: true,
        cacheDirectory: tempDir,
      );

      expect(result, 'OK');
      expect(client.getImageBytesCalls, 0);
    });

    test('offline mode returns OK with warning when baseline is not cached', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, white);
      final client = FakeSkiaGoldClient(expectationToReturn: 'digest_not_cached');

      final String result = await compareImage(
        screenshot,
        false,
        'offline_uncached.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        isOffline: true,
        cacheDirectory: tempDir,
      );

      expect(result, 'OK');
    });

    test('non-offline mode fails clearly when Skia Gold is unreachable', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, white);
      final client = FakeSkiaGoldClient(
        expectationToReturn: 'digest_unreachable',
        // imageBytesToReturn is null, so it throws SocketException
      );

      final String result = await compareImage(
        screenshot,
        false,
        'unreachable.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        cacheDirectory: tempDir,
      );

      expect(result, contains('Could not reach Skia Gold to fetch baseline'));
    });

    test('refreshGoldens forces re-downloading golden even when cached', () async {
      final Directory tempDir = _createTempTestDir();
      final suiteGoldenDir = Directory(p.join(tempDir.path, 'suite_goldens'))
        ..createSync(recursive: true);
      final Image screenshot = _createSolidImage(10, 10, white);
      final Uint8List goldenBytes = encodePng(_createSolidImage(10, 10, white));
      final client = FakeSkiaGoldClient(
        expectationToReturn: 'digest_refreshed',
        imageBytesToReturn: goldenBytes,
      );

      // Run 1: downloads and caches.
      await compareImage(
        screenshot,
        false,
        'refresh_test.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        cacheDirectory: tempDir,
      );
      expect(client.getImageBytesCalls, 1);

      // Run 2 with refreshGoldens: true re-downloads.
      await compareImage(
        screenshot,
        false,
        'refresh_test.png',
        suiteGoldenDir,
        client,
        isCanvaskitTest: true,
        verbose: false,
        refreshGoldens: true,
        cacheDirectory: tempDir,
      );
      expect(client.getImageBytesCalls, 2);
    });
  });
}
