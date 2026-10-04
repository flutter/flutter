// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;
import 'package:skia_gold_client/skia_gold_client.dart';

/// Monotonically increasing counter to ensure unique temporary file names for
/// concurrent downloads within the same process.
int _tempFileCounter = 0;

/// How to compare pixels within the image.
enum PixelComparison {
  /// Allows minor blur and anti-aliasing differences by comparing a 3x3 grid
  /// surrounding the pixel rather than direct 1:1 comparison.
  fuzzy,

  /// Compares one pixel at a time.
  precise,
}

/// The result of comparing two images pixel by pixel.
class PixelComparisonResult {
  /// Creates a [PixelComparisonResult] with detailed comparison metrics.
  const PixelComparisonResult({
    required this.isMatch,
    required this.differentPixelCount,
    required this.differentPixelRate,
    this.diffImage,
    this.errorMessage,
  });

  /// Whether the pixel difference is within acceptable tolerance.
  final bool isMatch;

  /// The number of pixels that differed between images.
  final int differentPixelCount;

  /// The fraction of differing pixels relative to total image pixels.
  final double differentPixelRate;

  /// The visual difference image highlighting mismatched pixels.
  final Image? diffImage;

  /// Diagnostic error message if comparison failed unexpectedly.
  final String? errorMessage;
}

/// Compares [actual] and [expected] images pixel by pixel.
PixelComparisonResult comparePixels(
  Image actual,
  Image expected, {
  PixelComparison pixelComparison = PixelComparison.fuzzy,
  double maxDifferentPixelsRate = 0.01,
  int pixelColorDeltaPerChannel = 1,
}) {
  if (actual.width != expected.width || actual.height != expected.height) {
    final int maxWidth = math.max(actual.width, expected.width);
    final int maxHeight = math.max(actual.height, expected.height);
    final diffImage = Image(width: maxWidth, height: maxHeight);
    final highlightColor = ColorRgba8(255, 0, 127, 255);
    for (var y = 0; y < maxHeight; y++) {
      for (var x = 0; x < maxWidth; x++) {
        diffImage.setPixel(x, y, highlightColor);
      }
    }
    return PixelComparisonResult(
      isMatch: false,
      differentPixelCount: maxWidth * maxHeight,
      differentPixelRate: 1.0,
      diffImage: diffImage,
      errorMessage:
          'Dimension mismatch: actual is ${actual.width}x${actual.height}, expected is ${expected.width}x${expected.height}',
    );
  }

  final int pixelDeltaThreshold = pixelColorDeltaPerChannel * 3;
  final diffImage = Image.from(actual);
  final highlightColor = ColorRgba8(255, 0, 127, 255);
  var diffCount = 0;

  int colorDelta(Pixel p1, Pixel p2) {
    return (p1.r - p2.r).abs().toInt() +
        (p1.g - p2.g).abs().toInt() +
        (p1.b - p2.b).abs().toInt() +
        (p1.a - p2.a).abs().toInt();
  }

  Pixel? actualPixel;
  Pixel? expectedPixel;

  for (var y = 0; y < actual.height; y++) {
    for (var x = 0; x < actual.width; x++) {
      actualPixel = actual.getPixel(x, y, actualPixel);

      if (pixelComparison == PixelComparison.precise) {
        expectedPixel = expected.getPixel(x, y, expectedPixel);
        if (colorDelta(actualPixel, expectedPixel) > pixelDeltaThreshold) {
          diffCount += 1;
          diffImage.setPixel(x, y, highlightColor);
        }
      } else {
        // Fuzzy 3x3 neighborhood matching.
        // Check the exact pixel first to short-circuit the 3x3 search in the common case.
        expectedPixel = expected.getPixel(x, y, expectedPixel);
        bool matched = colorDelta(actualPixel, expectedPixel) <= pixelDeltaThreshold;

        if (!matched) {
          final int minX = math.max(0, x - 1);
          final int maxX = math.min(expected.width - 1, x + 1);
          final int minY = math.max(0, y - 1);
          final int maxY = math.min(expected.height - 1, y + 1);

          for (var ny = minY; ny <= maxY; ny++) {
            for (var nx = minX; nx <= maxX; nx++) {
              if (nx == x && ny == y) {
                continue;
              }
              expectedPixel = expected.getPixel(nx, ny, expectedPixel);
              if (colorDelta(actualPixel, expectedPixel) <= pixelDeltaThreshold) {
                matched = true;
                break;
              }
            }
            if (matched) {
              break;
            }
          }
        }

        if (!matched) {
          diffCount += 1;
          diffImage.setPixel(x, y, highlightColor);
        }
      }
    }
  }

  final int totalPixels = actual.width * actual.height;
  final double diffRate = totalPixels == 0 ? 0.0 : diffCount / totalPixels;
  final bool isMatch = diffRate <= maxDifferentPixelsRate;

  return PixelComparisonResult(
    isMatch: isMatch,
    differentPixelCount: diffCount,
    differentPixelRate: diffRate,
    diffImage: isMatch ? null : diffImage,
  );
}

sealed class _GoldenLookupResult {}

class _GoldenFound extends _GoldenLookupResult {
  _GoldenFound(this.image);
  final Image image;
}

class _GoldenNotFound extends _GoldenLookupResult {
  _GoldenNotFound({this.message});
  final String? message;
}

class _GoldenError extends _GoldenLookupResult {
  _GoldenError(this.errorMessage);
  final String errorMessage;
}

/// Compares a screenshot taken through a test with its golden.
///
/// Used by Flutter Web Engine unit tests and the integration tests.
///
/// Returns the results of the tests as `String`. When a test passes, the result
/// is simply `OK`, however when it fails it contains a detailed explanation
/// on which files are compared, their absolute locations and diagnostic info.
Future<String> compareImage(
  Image screenshot,
  bool doUpdateScreenshotGoldens,
  String filename,
  Directory suiteGoldenDirectory,
  SkiaGoldClient? skiaClient, {
  required bool isCanvaskitTest,
  required bool verbose,
  PixelComparison pixelComparison = PixelComparison.fuzzy,
  double? maxDiffRate,
  int? pixelColorDeltaPerChannel,
  bool isOffline = false,
  bool refreshGoldens = false,
  Directory? cacheDirectory,
}) async {
  if (skiaClient == null) {
    return 'OK';
  }

  final String sanitizedFilename = p.basename(filename);
  final String screenshotPath = p.join(suiteGoldenDirectory.path, sanitizedFilename);
  final screenshotFile = File(screenshotPath);
  await screenshotFile.create(recursive: true);
  await screenshotFile.writeAsBytes(encodePng(screenshot), flush: true);

  final double defaultMaxDiffRate;
  final int defaultPixelColorDelta;
  if (isCanvaskitTest) {
    defaultMaxDiffRate = 0.1;
    defaultPixelColorDelta = 7;
  } else if (skiaClient.dimensions != null && skiaClient.dimensions!['Browser'] == 'ios-safari') {
    defaultMaxDiffRate = 0.15;
    defaultPixelColorDelta = 16;
  } else {
    defaultMaxDiffRate = 0.1;
    defaultPixelColorDelta = 1;
  }

  final double effectiveMaxDiffRate = maxDiffRate ?? defaultMaxDiffRate;
  final int effectivePixelColorDelta = pixelColorDeltaPerChannel ?? defaultPixelColorDelta;

  if (SkiaGoldClient.isLuciEnv()) {
    final int screenshotSize = screenshot.width * screenshot.height;

    await skiaClient.addImg(
      sanitizedFilename,
      screenshotFile,
      screenshotSize: screenshotSize,
      differentPixelsRate: effectiveMaxDiffRate,
      pixelColorDelta: effectivePixelColorDelta * 3,
    );
    return 'OK';
  }

  final Directory cacheDir =
      cacheDirectory ??
      Directory(p.join(Directory.current.path, '.dart_tool', 'web_goldens_cache'));

  final String testName = p.basenameWithoutExtension(sanitizedFilename);
  final normalizedTestName = '${skiaClient.prefix}$testName';

  final _GoldenLookupResult lookupResult = await _getGolden(
    sanitizedFilename,
    normalizedTestName,
    skiaClient,
    screenshotPath: screenshotPath,
    isOffline: isOffline,
    refreshGoldens: refreshGoldens,
    cacheDir: cacheDir,
  );

  final Image golden;
  switch (lookupResult) {
    case _GoldenFound(:final Image image):
      golden = image;
    case _GoldenNotFound(:final String? message):
      if (message != null) {
        stdout.writeln(message);
      }
      return 'OK';
    case _GoldenError(:final String errorMessage):
      return errorMessage;
  }

  if (doUpdateScreenshotGoldens) {
    return 'OK';
  }

  final PixelComparisonResult comparison = comparePixels(
    screenshot,
    golden,
    pixelComparison: pixelComparison,
    maxDifferentPixelsRate: effectiveMaxDiffRate,
    pixelColorDeltaPerChannel: effectivePixelColorDelta,
  );

  if (comparison.isMatch) {
    return 'OK';
  }

  final failureDir = Directory(p.join(cacheDir.path, 'failures', normalizedTestName));
  await failureDir.create(recursive: true);
  final actualFile = File(p.join(failureDir.path, 'actual.png'));
  final expectedFile = File(p.join(failureDir.path, 'expected.png'));
  await actualFile.writeAsBytes(encodePng(screenshot), flush: true);
  await expectedFile.writeAsBytes(encodePng(golden), flush: true);

  File? diffFile;
  if (comparison.diffImage != null) {
    diffFile = File(p.join(failureDir.path, 'diff.png'));
    await diffFile.writeAsBytes(encodePng(comparison.diffImage!), flush: true);
  }

  final buffer = StringBuffer()
    ..writeln('Golden comparison failed for test: $sanitizedFilename')
    ..writeln('- Reason: ${comparison.errorMessage ?? 'Pixel mismatch (${pixelComparison.name})'}')
    ..writeln(
      '- Different pixels: ${comparison.differentPixelCount} (${(comparison.differentPixelRate * 100).toStringAsFixed(2)}% > max tolerance ${(effectiveMaxDiffRate * 100).toStringAsFixed(2)}%)',
    )
    ..writeln('- Max color delta per channel: $effectivePixelColorDelta')
    ..writeln('- Expected: ${Uri.file(expectedFile.path)}')
    ..writeln('- Actual:   ${Uri.file(actualFile.path)}')
    ..writeln('- Diff:     ${diffFile != null ? Uri.file(diffFile.path) : 'N/A'}');

  return buffer.toString();
}

Future<_GoldenLookupResult> _getGolden(
  String sanitizedFilename,
  String normalizedTestName,
  SkiaGoldClient skiaClient, {
  required String screenshotPath,
  required bool isOffline,
  required bool refreshGoldens,
  required Directory cacheDir,
}) async {
  final baselinesDir = Directory(p.join(cacheDir.path, 'baselines'));
  final String traceID = skiaClient.getTraceID(normalizedTestName);
  final digestFile = File(p.join(baselinesDir.path, '$traceID.digest'));

  if (isOffline) {
    if (digestFile.existsSync()) {
      final String digest = (await digestFile.readAsString()).trim();
      final imageFile = File(p.join(baselinesDir.path, '$digest.png'));
      if (imageFile.existsSync()) {
        final Image? decoded = decodePng(await imageFile.readAsBytes());
        if (decoded != null) {
          return _GoldenFound(decoded);
        }
      }
    }
    return _GoldenNotFound(message: '[OFFLINE] No local baseline found for $sanitizedFilename');
  }

  String? digest;
  try {
    digest = await skiaClient.getExpectationForTest(normalizedTestName);
  } catch (error) {
    return _GoldenError(
      'Could not reach Skia Gold to fetch baseline for $sanitizedFilename. '
      'Check your network connection or pass --offline to use cached goldens. (Error: $error)',
    );
  }

  if (digest == null || digest.isEmpty) {
    return _GoldenNotFound(
      message:
          '[NEW GOLDEN] $sanitizedFilename recorded locally at ${Uri.file(screenshotPath)} (no Skia Gold baseline yet)',
    );
  }

  await baselinesDir.create(recursive: true);
  await digestFile.writeAsString(digest, flush: true);

  final imageFile = File(p.join(baselinesDir.path, '$digest.png'));
  if (imageFile.existsSync() && !refreshGoldens) {
    final Image? decoded = decodePng(await imageFile.readAsBytes());
    if (decoded != null) {
      return _GoldenFound(decoded);
    }
  }

  Uint8List bytes;
  try {
    bytes = await skiaClient.getImageBytes(digest);
  } catch (error) {
    return _GoldenError(
      'Could not reach Skia Gold to fetch baseline image for $sanitizedFilename (digest: $digest). '
      'Check your network connection or pass --offline to use cached goldens. (Error: $error)',
    );
  }

  // Write to a unique temporary file and atomically rename to avoid corrupted
  // baseline files or intra-process file collisions when multiple tests download
  // the same baseline simultaneously.
  final tempFile = File(
    p.join(baselinesDir.path, '$digest.png.tmp.${pid}_${_tempFileCounter += 1}'),
  );
  await tempFile.writeAsBytes(bytes, flush: true);
  if (imageFile.existsSync()) {
    try {
      imageFile.deleteSync();
    } on FileSystemException {
      // Ignored if deleted concurrently.
    }
  }
  try {
    await tempFile.rename(imageFile.path);
  } on FileSystemException {
    if (imageFile.existsSync()) {
      try {
        tempFile.deleteSync();
      } catch (_) {}
    } else {
      rethrow;
    }
  }

  final Image? decoded = decodePng(bytes);
  if (decoded == null) {
    return _GoldenError('Failed to decode downloaded PNG baseline for $sanitizedFilename.');
  }

  return _GoldenFound(decoded);
}
