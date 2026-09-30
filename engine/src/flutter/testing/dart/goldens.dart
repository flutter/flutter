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
    final ByteData goldenData = (await golden.toByteData())!;
    final ByteData testImageData = (await testImage.toByteData())!;

    // Fast path: Exact 32-bit pixel comparison.
    if (maxColorDelta == 0 && maxDifferentPixelsRate == 0.0) {
      final int totalPixels = golden.width * golden.height;
      for (var i = 0; i < totalPixels; i++) {
        if (goldenData.getUint32(i * 4) != testImageData.getUint32(i * 4)) {
          return false;
        }
      }
      return true;
    }

    var differentPixels = 0;
    final int totalPixels = golden.width * golden.height;

    for (var y = 0; y < golden.height; y++) {
      for (var x = 0; x < golden.width; x++) {
        final int offset = (x + y * golden.width) * 4;
        final int rDiff = (goldenData.getUint8(offset) - testImageData.getUint8(offset)).abs();
        final int gDiff = (goldenData.getUint8(offset + 1) - testImageData.getUint8(offset + 1))
            .abs();
        final int bDiff = (goldenData.getUint8(offset + 2) - testImageData.getUint8(offset + 2))
            .abs();
        final int aDiff = (goldenData.getUint8(offset + 3) - testImageData.getUint8(offset + 3))
            .abs();

        if (rDiff > maxColorDelta ||
            gDiff > maxColorDelta ||
            bDiff > maxColorDelta ||
            aDiff > maxColorDelta) {
          differentPixels++;
          if (maxDifferentPixelsRate == 0.0) {
            return false;
          }
        }
      }
    }
    return (differentPixels / totalPixels) <= maxDifferentPixelsRate;
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
