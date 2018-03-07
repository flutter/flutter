// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AssetImage from package', () {
    const AssetImage image = const AssetImage(
      'assets/image.png',
      package: 'test_package',
    );
    expect(image.keyName, 'packages/test_package/assets/image.png');
  });

  test('ExactAssetImage from package', () {
    const ExactAssetImage image = const ExactAssetImage(
      'assets/image.png',
      scale: 1.5,
      package: 'test_package',
    );
    expect(image.keyName, 'packages/test_package/assets/image.png');
  });

  test('Image.asset from package', () {
    final Image imageWidget = new Image.asset(
      'assets/image.png',
      package: 'test_package',
    );
    assert(imageWidget.image is AssetImage);
    final AssetImage assetImage = imageWidget.image;
    expect(assetImage.keyName, 'packages/test_package/assets/image.png');
  });

  test('Image.asset from package', () {
    final Image imageWidget = new Image.asset(
      'assets/image.png',
      scale: 1.5,
      package: 'test_package',
    );
    assert(imageWidget.image is ExactAssetImage);
    final ExactAssetImage assetImage = imageWidget.image;
    expect(assetImage.keyName, 'packages/test_package/assets/image.png');
  });
}
