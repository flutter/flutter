// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAssetBundle extends CachingAssetBundle {
  TestAssetBundle(this._assetBundleMap);

  final Map<dynamic, dynamic> _assetBundleMap;

  Map<String, int> loadCallCount = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(_assetBundleMap)!;
    }

    loadCallCount[key] = loadCallCount[key] ?? 0 + 1;
    if (key == 'one') {
      return ByteData(1)
        ..setInt8(0, 49);
    }
    throw FlutterError('key not found');
  }

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) async {
    final ByteData data = await load(key);
    return ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());
  }
}

class BundleWithoutAssetManifestBin extends CachingAssetBundle {
  BundleWithoutAssetManifestBin(this._legacyAssetBundleMap);

  final Map<dynamic, List<String>> _legacyAssetBundleMap;

  Map<String, int> loadCallCount = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    ByteData testByteData(double scale) => ByteData(8)..setFloat64(0, scale);

    if (key == 'AssetManifest.bin') {
      throw FlutterError('AssetManifest.bin was not found.');
    }
    if (key == 'AssetManifest.json') {
      return ByteData.view(Uint8List.fromList(const Utf8Encoder().convert(json.encode(_legacyAssetBundleMap))).buffer);
    }
    switch (key) {
      case 'assets/image.png':
        return testByteData(1.0); // see "...with a main asset and a 1.0x asset"
      case 'assets/2.0x/image.png':
        return testByteData(1.5);
    }

    throw FlutterError('Unexpected key: $key');
  }

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) async {
    final ByteData data = await load(key);
    return ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());
  }
}

void main() {

  // TODO(andrewkolos): Once google3 is migrated away from using AssetManifest.json,
  // remove all references to it. See https://github.com/flutter/flutter/issues/114913.
  test('AssetBundle falls back to using AssetManifest.json if AssetManifest.bin cannot be found.', () async {
    const String assetPath = 'assets/image.png';
    final Map<dynamic, List<String>> assetBundleMap = <dynamic, List<String>>{};
    assetBundleMap[assetPath] = <String>[];
    final AssetImage assetImage = AssetImage(assetPath, bundle: BundleWithoutAssetManifestBin(assetBundleMap));
    final AssetBundleImageKey key = await assetImage.obtainKey(ImageConfiguration.empty);
    expect(key.name, assetPath);
    expect(key.scale, 1.0);
  });

  test('When using AssetManifest.json, on a high DPR device, a high dpr variant is selected.', () async {
    const String assetPath = 'assets/image.png';
    const String asset2xPath = 'assets/2.0x/image.png';
    final Map<dynamic, List<String>> assetBundleMap = <dynamic, List<String>>{};
    assetBundleMap[assetPath] = <String>[asset2xPath];
    final AssetImage assetImage = AssetImage(assetPath, bundle: BundleWithoutAssetManifestBin(assetBundleMap));
    final AssetBundleImageKey key = await assetImage.obtainKey(const ImageConfiguration(devicePixelRatio: 2.0));
    expect(key.name, asset2xPath);
    expect(key.scale, 2.0);
  });

  group('1.0 scale device tests', () {
    void buildAndTestWithOneAsset(String mainAssetPath) {
      final Map<dynamic, List<Map<dynamic, dynamic>>> assetBundleMap = <dynamic, List<Map<dynamic, dynamic>>>{};

      assetBundleMap[mainAssetPath] = <Map<dynamic,dynamic>>[];

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
      buildAndTestWithOneAsset('assets/normalFolder/normalFile.png');
    });

    test('When asset path and key are the same string even though it could be took as a 3.0x variant', () async {
      buildAndTestWithOneAsset('assets/parentFolder/3.0x/normalFile.png');
    });

    test('When asset path contains variant identifier as part of parent folder name scale is 1.0', () {
      buildAndTestWithOneAsset('assets/parentFolder/__3.0x__/leafFolder/normalFile.png');
    });

    test('When asset path contains variant identifier as part of leaf folder name scale is 1.0', () {
      buildAndTestWithOneAsset('assets/parentFolder/__3.0x_leaf_folder_/normalFile.png');
    });

    test('When asset path contains variant identifier as part of parent folder name scale is 1.0', () {
      buildAndTestWithOneAsset('assets/parentFolder/__3.0x__/leafFolder/normalFile.png');
    });

    test('When asset path contains variant identifier in parent folder scale is 1.0', () {
      buildAndTestWithOneAsset('assets/parentFolder/3.0x/leafFolder/normalFile.png');
    });
  });


  group('High-res device behavior tests', () {
    test('When asset is not main variant check scale is not 1.0', () {
      const String mainAssetPath = 'assets/normalFolder/normalFile.png';
      const String variantPath = 'assets/normalFolder/3.0x/normalFile.png';

      final Map<dynamic, List<Map<dynamic, dynamic>>> assetBundleMap = <dynamic, List<Map<dynamic, dynamic>>>{};

      final Map<dynamic, dynamic> mainAssetVariantManifestEntry = <dynamic, dynamic>{};
      mainAssetVariantManifestEntry['asset'] = variantPath;
      mainAssetVariantManifestEntry['dpr'] = 3.0;
      assetBundleMap[mainAssetPath] = <Map<dynamic, dynamic>>[mainAssetVariantManifestEntry];

      final TestAssetBundle testAssetBundle = TestAssetBundle(assetBundleMap);

      final AssetImage assetImage = AssetImage(
        mainAssetPath,
        bundle: testAssetBundle,
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
        expect(bundleKey.name, variantPath);
        expect(bundleKey.scale, 3.0);
      }));
    });

    test('When high-res device and high-res asset not present in bundle then return main variant', () {
      const String mainAssetPath = 'assets/normalFolder/normalFile.png';

      final Map<dynamic, List<Map<dynamic, dynamic>>> assetBundleMap = <dynamic, List<Map<dynamic, dynamic>>>{};

      assetBundleMap[mainAssetPath] = <Map<dynamic, dynamic>>[];

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

    void buildBundleAndTestVariantLogic(
      double deviceRatio,
      double chosenAssetRatio,
      String expectedAssetPath,
    ) {
      final Map<dynamic, List<Map<dynamic, dynamic>>> assetBundleMap = <dynamic, List<Map<dynamic, dynamic>>>{};

      final Map<dynamic, dynamic> mainAssetVariantManifestEntry = <dynamic, dynamic>{};
      mainAssetVariantManifestEntry['asset'] = variantPath;
      mainAssetVariantManifestEntry['dpr'] = 3.0;
      assetBundleMap[mainAssetPath] = <Map<dynamic, dynamic>>[mainAssetVariantManifestEntry];

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
      buildBundleAndTestVariantLogic(1.0, 1.0, mainAssetPath);
    });

    test('Obvious case 3.0 - we have exact asset', () {
      buildBundleAndTestVariantLogic(3.0, 3.0, variantPath);
    });

    test('Typical case 2.0', () {
      buildBundleAndTestVariantLogic(2.0, 1.0, mainAssetPath);
    });

    test('Borderline case 2.01', () {
      buildBundleAndTestVariantLogic(2.01, 3.0, variantPath);
    });
    test('Borderline case 2.9', () {
      buildBundleAndTestVariantLogic(2.9, 3.0, variantPath);
    });

    test('Typical case 4.0', () {
      buildBundleAndTestVariantLogic(4.0, 3.0, variantPath);
    });
  });

}
