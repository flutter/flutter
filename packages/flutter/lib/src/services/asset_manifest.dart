// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'asset_bundle.dart';
import 'message_codecs.dart';

const String _kAssetManifestFilename = 'AssetManifest.bin';

/// Contains details about available assets and their variants.
/// See [Asset variants](https://docs.flutter.dev/development/ui/assets-and-images#asset-variants)
/// to learn about asset variants and how to declare them.
abstract class AssetManifest {
  /// Loads asset manifest data from an [AssetBundle] object and creates an
  /// [AssetManifest] object from that data.
  static Future<AssetManifest> loadFromAssetBundle(AssetBundle bundle) {
    return bundle.loadStructuredBinaryData(_kAssetManifestFilename, _AssetManifestBin.fromStandardMessageCodecMessage);
  }

  /// Lists the keys of all known assets, not including asset variants.
  ///
  /// The logical key maps to the path of an asset specified in the pubspec.yaml
  /// file at build time.
  ///
  /// See [Specifying assets](https://docs.flutter.dev/development/ui/assets-and-images#specifying-assets)
  /// and [Loading assets](https://docs.flutter.dev/development/ui/assets-and-images#loading-assets) for more
  /// information.
  List<String> listAssets();

  /// Gets available variants of an asset.
  List<AssetVariant> getAssetVariants(String key);
}

// Parses the binary asset manifest into a data structure that's easier to work
// with.
//
// The binary asset manifest is a map of asset keys to a list of objects
// representing the asset's variants.
//
// The entries with each variant object are:
//  - "asset": the location of this variant to load it from.
//  - "dpr": The device-pixel-ratio that the asset is best-suited for.
//
// New fields could be added to this object schema to support new asset variation
// features, such as themes, locale/region support, reading directions, and so on.
class _AssetManifestBin implements AssetManifest {
  _AssetManifestBin(Map<Object?, Object?> standardMessageData): _data = standardMessageData;

  factory _AssetManifestBin.fromStandardMessageCodecMessage(ByteData message) {
    final dynamic data = const StandardMessageCodec().decodeMessage(message);
    return _AssetManifestBin(data as Map<Object?, Object?>);
  }

  final Map<Object?, Object?> _data;
  final Map<String, List<AssetVariant>> _typeCastedData = <String, List<AssetVariant>>{};

  @override
  List<AssetVariant> getAssetVariants(String key) {
    // We lazily delay typecasting to prevent a performance hiccup when parsing
    // large asset manifests.
    if (!_typeCastedData.containsKey(key)) {
      _typeCastedData[key] = ((_data[key] ?? <Object?>[]) as Iterable<Object?>)
        .cast<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> data) => AssetVariant(
            key: data['asset']! as String,
            targetDevicePixelRatio: data['dpr']! as double,
        ))
        .toList();

      _data.remove(key);
    }
    return List<AssetVariant>.of(_typeCastedData[key]!);
  }

  @override
  List<String> listAssets() {
    return <String>[..._data.keys.cast<String>(), ..._typeCastedData.keys];
  }
}

/// Contains information about an asset that is a variant of another asset.
@immutable
class AssetVariant {
  /// Creates an object containing information about an asset variant.
  const AssetVariant({
    required this.key,
    required this.targetDevicePixelRatio,
  });

  /// The device pixel ratio that this asset is most ideal for. This is determined
  /// by the name of the parent folder of the asset file. For example, if the
  /// parent folder is named "3.0x", the target device pixel ratio of that
  /// asset will be interpreted as 3.
  ///
  /// This will be null if the parent folder name is not a ratio value followed
  /// by an "x".
  ///
  /// See [Declaring resolution-aware image assets](https://docs.flutter.dev/development/ui/assets-and-images#resolution-aware)
  /// for more information.
  final double? targetDevicePixelRatio;

  /// The asset's key, which is the path to the asset specified in the pubspec.yaml
  /// file at build time.
  final String key;
}
