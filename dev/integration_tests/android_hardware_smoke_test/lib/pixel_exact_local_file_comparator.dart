// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android_driver_extensions/native_driver.dart' show GoldenFileComparator;

/// We use a raw pixel-exact comparator on-device because comparing compressed PNG files byte-for-byte
/// is flaky. Android's native zlib compressor (libpng) and Dart's pure-Dart 'image' encoder use
/// different metadata, chunk orderings, and zlib compression levels for identical images.
class PixelExactLocalFileComparator extends GoldenFileComparator {
  const PixelExactLocalFileComparator();

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenFile = io.File(golden.toFilePath());
    if (!goldenFile.existsSync()) {
      throw StateError('Golden file not found: ${goldenFile.path}');
    }
    final Uint8List goldenBytes = await goldenFile.readAsBytes();

    // Decode both images to raw pixels
    final ui.Image image1 = await _decodePng(imageBytes);
    final ui.Image image2 = await _decodePng(goldenBytes);

    if (image1.width != image2.width || image1.height != image2.height) {
      image1.dispose();
      image2.dispose();
      return false;
    }

    final ByteData? bytes1 = await image1.toByteData();
    final ByteData? bytes2 = await image2.toByteData();
    image1.dispose();
    image2.dispose();

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
