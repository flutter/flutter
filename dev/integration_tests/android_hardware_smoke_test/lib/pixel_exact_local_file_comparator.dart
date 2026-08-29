// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android_driver_extensions/native_driver.dart' show GoldenFileComparator;
import 'package:flutter/services.dart' show ByteData, rootBundle;

/// A raw pixel-exact comparator used on-device during **Instrumented Mode** test runs.
///
/// This is required because comparing compressed PNG files byte-for-byte on the device is flaky.
/// Android's native screencap compressor (libpng) and Dart's pure-Dart 'image' encoder use
/// different metadata, chunk orderings, and zlib compression levels for identical pixel grids.
///
/// During **Host-Driven Mode** (using `flutter drive`), golden comparisons are resolved on the
/// host computer using the host-side comparator instead.
class PixelExactLocalFileComparator extends GoldenFileComparator {
  const PixelExactLocalFileComparator();

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final Uint8List goldenBytes = await _loadGoldenBytes(golden);

    // Decode both images to raw pixels
    final ui.Image image1 = await _decodePng(imageBytes);
    final ui.Image image2 = await _decodePng(goldenBytes);

    return _comparePixels(image1, image2);
  }

  Future<Uint8List> _loadGoldenBytes(Uri golden) async {
    if (golden.scheme == 'asset') {
      final rawPath = '${golden.host}${golden.path}';
      final String assetKey = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
      try {
        final ByteData byteData = await rootBundle.load(assetKey);
        return byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      } catch (e) {
        throw StateError('Failed to load golden asset "$assetKey" from package assets: $e');
      }
    }

    final goldenFile = io.File(golden.toFilePath());
    if (!goldenFile.existsSync()) {
      throw StateError('Golden file not found: ${goldenFile.path}');
    }
    return goldenFile.readAsBytes();
  }

  Future<bool> _comparePixels(ui.Image image1, ui.Image image2) async {
    try {
      if (image1.width != image2.width || image1.height != image2.height) {
        return false;
      }

      final ByteData? bytes1 = await image1.toByteData();
      final ByteData? bytes2 = await image2.toByteData();

      if (bytes1 == null || bytes2 == null) {
        return false;
      }

      if (bytes1.lengthInBytes != bytes2.lengthInBytes) {
        return false;
      }

      final Uint8List list1 = bytes1.buffer.asUint8List();
      final Uint8List list2 = bytes2.buffer.asUint8List();

      for (var i = 0; i < list1.length; i++) {
        if (list1[i] != list2[i]) {
          return false;
        }
      }

      return true;
    } finally {
      image1.dispose();
      image2.dispose();
    }
  }

  Future<ui.Image> _decodePng(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    codec.dispose();
    return fi.image;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final goldenFile = io.File(golden.toFilePath());
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes);
  }
}
