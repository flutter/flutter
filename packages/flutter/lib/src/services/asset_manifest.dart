import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String _kLegacyAssetManifestFilename = 'AssetManifest.json';
const String _kAssetManifestFilename = 'AssetManifest.bin';

/// Contains details about available assets.
abstract class AssetManifest {
  /// Loads asset manifest data from an [AssetBundle] object and creates an
  /// [AssetManifest] object from that data.
  static Future<AssetManifest> loadFromAssetBundle(AssetBundle bundle) {
    // TODO(andrewkolos): Once google3 and google-fonts-flutter are migrated
    // away from using AssetManifest.json, remove all references to it.
    // See https://github.com/flutter/flutter/issues/114913.
    Future<AssetManifest> loadJsonAssetManifest(AssetBundle bundle) =>
      bundle.loadStructuredData(_kLegacyAssetManifestFilename,
        (String data) => SynchronousFuture<AssetManifest>(_LegacyAssetManifest.fromJsonString(data)));

    Future<AssetManifest>? result;
    // Since AssetBundle load calls can be synchronous (e.g. in the case of tests),
    // it is not sufficient to only use catchError/onError or the onError parameter
    // of Future.then--we also have to use a synchronous try/catch. Once google3
    // tooling starts producing AssetManifest.bin, this block can be removed.
    try {
      result = bundle.loadStructuredBinaryData(_kAssetManifestFilename, _AssetManifestBin.fromStandardMessageCodecMessage);
    } catch (error) {
      result = loadJsonAssetManifest(bundle);
    }

    // To understand why we use this no-op `then` instead of `catchError`/`onError`,
    // see https://github.com/flutter/flutter/issues/115601
    return result.then((AssetManifest manifest) => manifest,
      onError: (Object? error, StackTrace? stack) => loadJsonAssetManifest(bundle));
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
/// information about variants of that asset. This only applies to image
/// assets--other types of assets will have empty variant lists.
///
/// The entries of each variant object are:
///  - "asset": the location of this variant to load it from.
///  - "dpr": The device-pixel-ratio that the asset is best-suited for.
///
/// New fields could be added to this object schema to support new asset variation
/// features, such as themes, locale/region support, reading directions, and so on.

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
  _AssetManifestBin(Map<String, Object?> standardMessageData): _data = standardMessageData;

  factory _AssetManifestBin.fromStandardMessageCodecMessage(ByteData message) {
    final Object? data = const StandardMessageCodec().decodeMessage(message);
    return _AssetManifestBin(data! as Map<String, Object?>);
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

class _LegacyAssetManifest implements AssetManifest {

  _LegacyAssetManifest({
    required Map<String, Iterable<AssetVariant>> manifest,
  }) : _manifest = manifest;

  factory _LegacyAssetManifest.fromJsonString(String jsonString) {
    List<AssetVariant> adaptLegacyVariantList(String mainAsset, List<String> variants) {

    double parseScale(String mainAsset, String variant) {
      // The legacy asset manifest includes the main asset within its variant list.
      if (mainAsset == variant) {
        return _naturalResolution;
      }

      final Uri assetUri = Uri.parse(variant);
      String directoryPath = '';
      if (assetUri.pathSegments.length > 1) {
        directoryPath = assetUri.pathSegments[assetUri.pathSegments.length - 2];
      }

      final Match? match = _extractRatioRegExp.firstMatch(directoryPath);
      if (match != null && match.groupCount > 0) {
        return double.parse(match.group(1)!);
      }

      return _naturalResolution; // i.e. default to 1.0x
    }

    return variants
      .map((String variant) =>
        AssetVariant(key: variant, targetDevicePixelRatio: parseScale(mainAsset, variant)))
      .toList();
    }

    if (jsonString == null) {
      return _LegacyAssetManifest(manifest: <String, List<AssetVariant>>{});
    }
    final Map<String, Object?> parsedJson = json.decode(jsonString) as Map<String, dynamic>;
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest = <String, List<String>> {
      for (final String key in keys) key: List<String>.from(parsedJson[key]! as List<dynamic>),
    };
    final Map<String, List<AssetVariant>> manifestWithParsedVariants =
      parsedManifest.map((String asset, List<String> variants) =>
        MapEntry<String, List<AssetVariant>>(asset, adaptLegacyVariantList(asset, variants)));

    return _LegacyAssetManifest(manifest: manifestWithParsedVariants);
  }
  // We assume the main asset is designed for a device pixel ratio of 1.0
  static const double _naturalResolution = 1.0;

  final Map<String, Iterable<AssetVariant>> _manifest;

  static final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

  @override
  Iterable<AssetVariant> getAssetVariants(String key) {
    return _manifest[key] ?? <AssetVariant>[];
  }

  @override
  Iterable<String> listAssets() {
    return _manifest.keys;
  }
}

/// Contains information about an asset that is a variant of another asset.
class AssetVariant {
  /// Creates an object containing information about an asset variant.
  AssetVariant({
    required this.key,
    required this.targetDevicePixelRatio,
  });

  /// The device pixel ratio that the images are intended for.
  final double targetDevicePixelRatio;

  /// The asset's key. This can also be thought of as the logical name of an asset.
  final String key;
}
