// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Image;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  final ui.Image smallImage = createTestImage(width: 10, height: 20);
  final ui.Image middleImage = createTestImage(width: 20, height: 100);
  final ui.Image bigImage = createTestImage(width: 100, height: 200);

  test('ImageInfo sizeBytes', () {
    ImageInfo imageInfo = ImageInfo(image: smallImage);
    expect(imageInfo.sizeBytes, equals(800));

    imageInfo = ImageInfo(image: middleImage);
    expect(imageInfo.sizeBytes, equals(8000));

    imageInfo = ImageInfo(image: bigImage);
    expect(imageInfo.sizeBytes, equals(80000));
  });
}
