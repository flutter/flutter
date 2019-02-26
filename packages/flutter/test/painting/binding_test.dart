// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';

import 'image_data.dart';
import 'painting_utils.dart';

void main() {
  final PaintingBindingSpy binding = PaintingBindingSpy();

  test('decodedCacheRatio', () async {
    // final PaintingBinding binding = PaintingBinding.instance;
    // Has default value.
    expect(binding.decodedCacheRatioCap, isNot(null)); // ignore: deprecated_member_use_from_same_package

    // Can be set.
    binding.decodedCacheRatioCap = 1.0; // ignore: deprecated_member_use_from_same_package
    expect(binding.decodedCacheRatioCap, 1.0); // ignore: deprecated_member_use_from_same_package
  });

  test('instantiateImageCodec used for loading images', () async {
    expect(binding.instantiateImageCodecCalledCount, 0);

    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    memoryImage.load(memoryImage);
    expect(binding.instantiateImageCodecCalledCount, 1);
  });
}
