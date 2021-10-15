// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle(this._assetBundleMap);

  final Map<String, List<String>> _assetBundleMap;

  Map<String, int> loadCallCount = <String, int>{};

  String get _assetBundleContents {
    return json.encode(_assetBundleMap);
  }

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.json')
      return ByteData.view(Uint8List.fromList(const Utf8Encoder().convert(_assetBundleContents)).buffer);

    loadCallCount[key] = loadCallCount[key] ?? 0 + 1;
    if (key == 'one')
      return ByteData(1)
        ..setInt8(0, 49);
    throw FlutterError('key not found');
  }
}

void main() {
  group('1.0 scale device tests', () {
    void _buildAndTestWithOneAsset(String mainAssetPath) {
      final Map<String, List<String>> assetBundleMap = <String, List<String>>{};

      assetBundleMap[mainAssetPath] = <String>[];

      final AssetImage assetImage = AssetImage(
        mainAssetPath,
        bundle: TestAssetBundle(assetBundleMap),
      );
      const ImageConfiguration configuration = ImageConfiguration.empty;

      assetImage.obtainKey(configuration)
        .then(expectAsync1((AssetBundleImageKey bundleKey) {
          expect(bundleKey.name, mainAssetPath);
          expect(bundleKey.scale, 1.0);
        }));
    }

    test('When asset is main variant check scale is 1.0', () {
      _buildAndTestWithOneAsset('assets/normalFolder/normalFile.png');
    });

    test('When asset path and key are the same string even though it could be took as a 3.0x variant', () async {
      _buildAndTestWithOneAsset('assets/parentFolder/3.0x/normalFile.png');
    });

    test('When asset path contains variant identifier as part of parent folder name scale is 1.0', () {
      _buildAndTestWithOneAsset('assets/parentFolder/__3.0x__/leafFolder/normalFile.png');
    });

    test('When asset path contains variant identifier as part of leaf folder name scale is 1.0', () {
      _buildAndTestWithOneAsset('assets/parentFolder/__3.0x_leaf_folder_/normalFile.png');
    });

    test('When asset path contains variant identifier as part of parent folder name scale is 1.0', () {
      _buildAndTestWithOneAsset('assets/parentFolder/__3.0x__/leafFolder/normalFile.png');
    });

    test('When asset path contains variant identifier in parent folder scale is 1.0', () {
      _buildAndTestWithOneAsset('assets/parentFolder/3.0x/leafFolder/normalFile.png');
    });
  });


  group('High-res device behavior tests', () {
    test('When asset is not main variant check scale is not 1.0', () {
      const String mainAssetPath = 'assets/normalFolder/normalFile.png';
      const String variantPath = 'assets/normalFolder/3.0x/normalFile.png';

      final Map<String, List<String>> assetBundleMap =
      <String, List<String>>{};

      assetBundleMap[mainAssetPath] = <String>[mainAssetPath, variantPath];

      final TestAssetBundle testAssetBundle = TestAssetBundle(assetBundleMap);

      final AssetImage assetImage = AssetImage(
        mainAssetPath,
        bundle: testAssetBundle,
      );

      // we have the exact match for this scale, let's use it
      assetImage.obtainKey(ImageConfiguration.empty)
        .then(expectAsync1((AssetBundleImageKey bundleKey) {
          expect(bundleKey.name, mainAssetPath);
          expect(bundleKey.scale, 1.0);
        }));

      // we also have the exact match for this scale, let's use it
      assetImage.obtainKey(ImageConfiguration(
        bundle: testAssetBundle,
        devicePixelRatio: 3.0,
      )).then(expectAsync1((AssetBundleImageKey bundleKey) {
        expect(bundleKey.name, variantPath);
        expect(bundleKey.scale, 3.0);
      }));
    });

    test('When high-res device and high-res asset not present in bundle then  return main variant', () {
      const String mainAssetPath = 'assets/normalFolder/normalFile.png';

      final Map<String, List<String>> assetBundleMap =
      <String, List<String>>{};

      assetBundleMap[mainAssetPath] = <String>[mainAssetPath];

      final TestAssetBundle testAssetBundle = TestAssetBundle(assetBundleMap);

      final AssetImage assetImage = AssetImage(
        mainAssetPath,
        bundle: TestAssetBundle(assetBundleMap),
      );


      assetImage.obtainKey(ImageConfiguration.empty)
        .then(expectAsync1((AssetBundleImageKey bundleKey) {
          expect(bundleKey.name, mainAssetPath);
          expect(bundleKey.scale, 1.0);
        }));

      assetImage.obtainKey(ImageConfiguration(
        bundle: testAssetBundle,
        devicePixelRatio: 3.0,
      )).then(expectAsync1((AssetBundleImageKey bundleKey) {
        expect(bundleKey.name, mainAssetPath);
        expect(bundleKey.scale, 1.0);
      }));
    });
  });

  group('Regression - When assets available are 1.0 and 3.0 check devices with a range of scales', () {
    const String mainAssetPath = 'assets/normalFolder/normalFile.png';
    const String variantPath = 'assets/normalFolder/3.0x/normalFile.png';


    void _buildBundleAndTestVariantLogic(
      double deviceRatio,
      double chosenAssetRatio,
      String expectedAssetPath,
    ) {
      final Map<String, List<String>> assetBundleMap =
      <String, List<String>>{};

      assetBundleMap[mainAssetPath] = <String>[mainAssetPath, variantPath];

      final TestAssetBundle testAssetBundle = TestAssetBundle(assetBundleMap);

      final AssetImage assetImage = AssetImage(
        mainAssetPath,
        bundle: testAssetBundle,
      );

      // we have 1.0 and 3.0, asking for 1.5 should give
      assetImage.obtainKey(ImageConfiguration(
        bundle: testAssetBundle,
        devicePixelRatio: deviceRatio,
      )).then(expectAsync1((AssetBundleImageKey bundleKey) {
        expect(bundleKey.name, expectedAssetPath);
        expect(bundleKey.scale, chosenAssetRatio);
      }));
    }

    test('Obvious case 1.0 - we have exact asset', () {
      _buildBundleAndTestVariantLogic(1.0, 1.0, mainAssetPath);
    });

    test('Obvious case 3.0 - we have exact asset', () {
      _buildBundleAndTestVariantLogic(3.0, 3.0, variantPath);
    });

    test('Typical case 2.0', () {
      _buildBundleAndTestVariantLogic(2.0, 1.0, mainAssetPath);
    });

    test('Borderline case 2.01', () {
      _buildBundleAndTestVariantLogic(2.01, 3.0, variantPath);
    });
    test('Borderline case 2.9', () {
      _buildBundleAndTestVariantLogic(2.9, 3.0, variantPath);
    });

    test('Typical case 4.0', () {
      _buildBundleAndTestVariantLogic(4.0, 3.0, variantPath);
    });
  });

}
