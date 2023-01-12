import 'dart:convert';

import 'package:flutter/services.dart';

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
  _AssetManifestBin(Map<String, Object?> manifestData): _data = manifestData;

  factory _AssetManifestBin.fromStandardMessageCodecMessage(ByteData message) {
    final Object? data = const StandardMessageCodec().decodeMessage(message);
    final Map<String, Object> typeCastedData = (data! as Map<Object?, Object?>).cast<String, Object>();
    return _AssetManifestBin(typeCastedData);
  }

  final Map<String, Object?> _data;
  final Map<String, Iterable<AssetVariant>> _typeCastedData = <String, Iterable<AssetVariant>>{};

  @override
  Iterable<AssetVariant> getAssetVariants(String key) {
    // We lazily delay typecasting to prevent a performance hiccup when parsing
    // large asset manifests.
    if (!_typeCastedData.containsKey(key)) {
      _typeCastedData[key] = ((_data[key] ?? <Object?>[]) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map((Map<String, Object?> data) => AssetVariant(
            key: data['asset']! as String,
            targetDevicePixelRatio: data['dpr']! as double,
        ));

      _data.remove(key);
    }
    return _typeCastedData[key]!;
  }

  @override
  Iterable<String> listAssets() {
    return <String>[..._data.keys, ..._typeCastedData.keys];
  }
}

/// Contains information about an asset that is a variant of another asset.
class AssetVariant {
  /// Creates an object containing information about an asset variant.
  AssetVariant({
    required this.key,
    required this.targetDevicePixelRatio,
  });

  /// The device pixel ratio that the asset is most ideal for, if any.
  final double targetDevicePixelRatio;

  /// The asset's key. This can also be thought of as the logical name of an asset,
  /// and it typically resembles a file location.
  final String key;
}
