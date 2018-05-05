// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void _assert(double expectedScale, double actualScale, String assetKey) {
    assert(expectedScale == actualScale,
        'Expected $expectedScale and got $actualScale for asset key $assetKey');
  }

  test('When asset is main variant check scale is 1.0', () {
    const String mainAssetPath = 'assets/normalFolder/normalFile.png';

    _assert(1.0, const AssetImage(mainAssetPath).parseScale(mainAssetPath),
        mainAssetPath);
  });

  test(
      'When asset path and key are the same string even though it could be took as a 3.0x variant',
          () {
        const String mainAssetPath = 'assets/parentFolder/3.0x/normalFile.png';

        _assert(1.0, const AssetImage(mainAssetPath).parseScale(mainAssetPath),
            mainAssetPath);
      });

  test('When asset is not main variant check scale is not 1.0', () {
    const String mainAssetPath = 'assets/normalFolder/normalFile.png';
    const String variantPath = 'assets/normalFolder/3.0x/normalFile.png';

    _assert(3.0, const AssetImage(mainAssetPath).parseScale(variantPath),
        variantPath);
  });

  test(
      'When asset path contains variant identifier as part of parent folder name scale is 1.0',
          () {
        const String mainAssetPath =
            'assets/parentFolder/__3.0x__/leafFolder/normalFile.png';

        _assert(1.0, const AssetImage(mainAssetPath).parseScale(mainAssetPath),
            mainAssetPath);
      });


  test(
      'When asset path contains variant identifier as part of leaf folder name scale is 1.0',
          () {
        const String mainAssetPath =
            'assets/parentFolder/__3.0x_leaf_folder_/normalFile.png';

        _assert(1.0, const AssetImage(mainAssetPath).parseScale(mainAssetPath),
            mainAssetPath);
      });


  test(
      'When asset path contains variant identifier as part of parent folder name scale is 1.0',
          () {
        const String mainAssetPath =
            'assets/parentFolder/__3.0x__/leafFolder/normalFile.png';

        _assert(1.0, const AssetImage(mainAssetPath).parseScale(mainAssetPath),
            mainAssetPath);
      });

  test(
      'When asset path contains variant identifier in parent folder scale is 1.0',
      () {
    const String mainAssetPath =
        'assets/parentFolder/3.0x/leafFolder/normalFile.png';

    _assert(1.0, const AssetImage(mainAssetPath).parseScale(mainAssetPath),
        mainAssetPath);
  });

}
