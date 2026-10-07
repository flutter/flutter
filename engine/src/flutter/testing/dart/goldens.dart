// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:skia_gold_client/skia_gold_client.dart';

import 'impeller_enabled.dart';

const String _kSkiaGoldWorkDirectoryKey = 'kSkiaGoldWorkDirectory';

/// A helper for doing image comparison (golden) tests.
///
/// Contains utilities for comparing two images in memory that are expected to
/// be identical, or for adding images to Skia gold for comparison.
class ImageComparer {
  ImageComparer._({required SkiaGoldClient client}) : _client = client;

  // Avoid talking to Skia gold for the force-multithreading variants.
  static bool get _useSkiaGold => !Platform.executableArguments.contains('--force-multithreading');

  /// Creates an image comparer and authorizes.
  static Future<ImageComparer> create({bool verbose = false}) async {
    const workDirectoryPath = String.fromEnvironment(_kSkiaGoldWorkDirectoryKey);
    if (workDirectoryPath.isEmpty) {
      throw UnsupportedError('Using ImageComparer requries defining kSkiaGoldWorkDirectoryKey.');
    }

    final workDirectory = Directory(
      impellerEnabled ? '${workDirectoryPath}_iplr_$impellerBackend' : workDirectoryPath,
    )..createSync();
    final dimensions = <String, String>{
      'impeller_enabled': impellerEnabled.toString(),
      'impeller_backend': impellerBackend ?? 'none',
    };
    final SkiaGoldClient client = SkiaGoldClient.isAvailable() && _useSkiaGold
        ? SkiaGoldClient(workDirectory, dimensions: dimensions, verbose: verbose)
        : _FakeSkiaGoldClient(workDirectory, dimensions, verbose: verbose);

    await client.auth();
    return ImageComparer._(client: client);
  }

  final SkiaGoldClient _client;

  /// Adds an [Image] to Skia Gold for comparison.
  ///
  /// The [fileName] must be unique.
  Future<void> addGoldenImage(Image image, String fileName) async {
    final ByteData data = (await image.toByteData(format: ImageByteFormat.png))!;

    final file = File(path.join(_client.workDirectory.path, fileName))
      ..writeAsBytesSync(data.buffer.asUint8List());
    await _client.addImg(fileName, file, screenshotSize: image.width * image.height).catchError((
      dynamic error,
    ) {
      print('Skia gold comparison failed: $error');
      throw Exception('Failed comparison: $fileName');
    });
  }

  /// Compares two images pixel by pixel.
  ///
  /// If [maxColorDelta] is greater than 0, per-channel differences less than or
  /// equal to [maxColorDelta] are considered identical.
  ///
  /// If [maxDifferentPixelsRate] is greater than 0.0, the comparison passes if
  /// the ratio of different pixels to total pixels does not exceed this value.
  Future<bool> fuzzyCompareImages(
    Image golden,
    Image testImage, {
    int maxColorDelta = 0,
    double maxDifferentPixelsRate = 0.0,
  }) async {
    if (golden.width != testImage.width || golden.height != testImage.height) {
      return false;
    }
    final ByteData? goldenData = await golden.toByteData();
    final ByteData? testImageData = await testImage.toByteData();
    if (goldenData == null || testImageData == null) {
      return false;
    }

    final int totalPixels = golden.width * golden.height;

    // When no tolerance thresholds are specified, compare full 32-bit RGBA pixel
    // values directly in a single pass with early exit on first mismatch.
    if (maxColorDelta == 0 && maxDifferentPixelsRate == 0.0) {
      final Uint32List goldenUint32 = goldenData.buffer.asUint32List(
        goldenData.offsetInBytes,
        totalPixels,
      );
      final Uint32List testUint32 = testImageData.buffer.asUint32List(
        testImageData.offsetInBytes,
        totalPixels,
      );
      for (var i = 0; i < totalPixels; i++) {
        if (goldenUint32[i] != testUint32[i]) {
          return false;
        }
      }
      return true;
    }

    // When tolerance thresholds are configured, inspect each pixel's color
    // channels and count those exceeding [maxColorDelta] to determine whether
    // the proportion of different pixels is within [maxDifferentPixelsRate].
    var differentPixels = 0;
    var maxObservedDelta = 0;

    final Uint8List goldenBytes = goldenData.buffer.asUint8List(
      goldenData.offsetInBytes,
      totalPixels * 4,
    );
    final Uint8List testBytes = testImageData.buffer.asUint8List(
      testImageData.offsetInBytes,
      totalPixels * 4,
    );

    for (var i = 0; i < totalPixels; i++) {
      final int pixelDelta = _maxChannelDelta(goldenBytes, testBytes, i * 4);
      if (pixelDelta > maxObservedDelta) {
        maxObservedDelta = pixelDelta;
      }
      if (pixelDelta > maxColorDelta) {
        differentPixels++;
      }
    }

    final double diffRate = differentPixels / totalPixels;
    if (diffRate > maxDifferentPixelsRate) {
      print(
        'fuzzyCompareImages failed: '
        'maxObservedDelta=$maxObservedDelta (threshold=$maxColorDelta), '
        'differentPixels=$differentPixels/$totalPixels '
        '(${(diffRate * 100).toStringAsFixed(3)}%, maxAllowed=${(maxDifferentPixelsRate * 100).toStringAsFixed(3)}%)',
      );
      return false;
    }
    return true;
  }

  static int _maxChannelDelta(Uint8List a, Uint8List b, int offset) {
    var maxDelta = (a[offset] - b[offset]).abs();
    for (var c = 1; c < 4; c++) {
      final int diff = (a[offset + c] - b[offset + c]).abs();
      if (diff > maxDelta) {
        maxDelta = diff;
      }
    }
    return maxDelta;
  }
}

// TODO(dnfield): add local comparison against baseline,
// https://github.com/flutter/flutter/issues/136831
class _FakeSkiaGoldClient implements SkiaGoldClient {
  _FakeSkiaGoldClient(this.workDirectory, this.dimensions, {this.verbose = false});

  @override
  final Directory workDirectory;

  @override
  final Map<String, String> dimensions;

  @override
  final bool verbose;

  @override
  Future<void> auth() async {}

  @override
  Future<void> addImg(
    String testName,
    File goldenFile, {
    double differentPixelsRate = 0.01,
    int pixelColorDelta = 0,
    required int screenshotSize,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString().split('"')[1]);
  }
}
