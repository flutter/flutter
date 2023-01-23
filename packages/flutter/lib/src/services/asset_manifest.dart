// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/widgets/framework.dart';

import 'asset_bundle.dart';
import 'message_codecs.dart';

const String _kAssetManifestFilename = 'AssetManifest.bin';

/// Contains details about available assets.
abstract class AssetManifest {
  /// Loads asset manifest data from an [AssetBundle] object and creates an
  /// [AssetManifest] object from that data.
  static Future<AssetManifest> loadFromAssetBundle(AssetBundle bundle) {
    return bundle.loadStructuredBinaryData(_kAssetManifestFilename, _AssetManifestBin.fromStandardMessageCodecMessage);
  }

  /// Loads asset manifest data from the root bundle and creates an
  /// [AssetManifest] from that data.
  static Future<AssetManifest> loadFromRootBundle() {
    return loadFromAssetBundle(rootBundle);
  }

  /// Lists the keys of all known assets, not including asset variants.
  Iterable<String> listAssets() {
    throw UnimplementedError();
  }

  /// Gets available variants of an asset.
  Iterable<AssetVariant> getAssetVariants(String key) {
    throw UnimplementedError();
  }
}

/// Parses the binary asset manifest into a data structure that's easier to work with.
///
/// The asset manifest is a map of asset files to a list of objects containing
/// information about variants of that asset.
///
/// The entries with each variant object are:
///  - "asset": the location of this variant to load it from.
///  - "dpr": The device-pixel-ratio that the asset is best-suited for.
///
/// New fields could be added to this object schema to support new asset variation
/// features, such as themes, locale/region support, reading directions, and so on.
class _AssetManifestBin implements AssetManifest {
  _AssetManifestBin(Map<Object?, Object?> standardMessageData): _data = standardMessageData;

  factory _AssetManifestBin.fromStandardMessageCodecMessage(ByteData message) {
    final dynamic data = const StandardMessageCodec().decodeMessage(message);
    return _AssetManifestBin(data as Map<Object?, Object?>);
  }

  final Map<Object?, Object?> _data;
  final Map<String, Iterable<AssetVariant>> _typeCastedData = <String, Iterable<AssetVariant>>{};

  @override
  Iterable<AssetVariant> getAssetVariants(String key) {
    // We lazily delay typecasting to prevent a performance hiccup when parsing
    // large asset manifests.
    if (!_typeCastedData.containsKey(key)) {
      _typeCastedData[key] = ((_data[key] ?? <Object?>[]) as List<Object?>)
        .cast<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> data) => AssetVariant(
            key: data['asset']! as String,
            targetDevicePixelRatio: data['dpr']! as double,
        ));

      _data.remove(key);
    }
    return _typeCastedData[key]!;
  }

  @override
  Iterable<String> listAssets() {
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

  /// The device pixel ratio that the asset is most ideal for, if any.
  final double? targetDevicePixelRatio;

  /// The asset's key. This can also be thought of as the logical name of an asset,
  /// and it typically resembles a file location.
  final String key;
}
