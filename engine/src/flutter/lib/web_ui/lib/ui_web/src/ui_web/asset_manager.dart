// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';

/// Provides the [AssetManager] used by the Flutter Engine.
AssetManager get assetManager => engineAssetManager;

/// This class downloads assets over the network.
///
/// Assets are resolved relative to [assetsDir] inside the absolute base
/// specified by [assetBase] (optional).
///
/// By default, URLs are relative to the `<base>` of the current website.
class AssetManager {
  /// Initializes [AssetManager] with paths.
  AssetManager({this.assetsDir = _defaultAssetsDir, String? assetBase})
    : assert(
        assetBase == null || assetBase.endsWith('/'),
        '`assetBase` must end with a `/` character.',
      ),
      _assetBase = assetBase;

  static const String _defaultAssetsDir = 'assets';

  /// Static lookup table mapping logical asset keys to their content-hashed
  /// relative paths when `--web-content-hash` is enabled.
  ///
  /// Stored statically so that both [engineAssetManager] and any standalone
  /// [AssetManager] instances created by plugins or embedders resolve
  /// content-hashed paths once loaded during engine initialization.
  static Map<String, String> _contentHashedAssetMap = const <String, String>{};

  /// Updates the content-hash lookup table from the decoded `AssetManifest.bin.json`.
  ///
  /// Called by the web engine during `initializeEngineServices()` when
  /// `_flutter.buildConfig` specifies a content-hashed `assetManifest`.
  void setAssetMap(Map<String, String> assetMap) {
    if (assetMap.isEmpty) {
      _contentHashedAssetMap = const <String, String>{};
      return;
    }
    final normalized = <String, String>{};
    for (final MapEntry<String, String> entry in assetMap.entries) {
      final String key = entry.key;
      final String value = entry.value;
      normalized[key] = value;
      normalized[Uri.encodeFull(key)] = value;
      normalized[Uri(path: Uri.encodeFull(key)).path] = value;
      try {
        final String decoded = Uri.decodeFull(key);
        normalized[decoded] = value;
        normalized[Uri.encodeFull(decoded)] = value;
        normalized[Uri(path: Uri.encodeFull(decoded)).path] = value;
      } on ArgumentError {
        // Ignore malformed percent-encoding in keys.
      }
    }
    _contentHashedAssetMap = normalized;
  }

  /// The directory containing the assets.
  final String assetsDir;

  /// The absolute base URL for assets.
  String? _assetBase;

  // Cache a value for `_assetBase` so we don't hit the DOM multiple times.
  String get _baseUrl => _assetBase ??= _deprecatedAssetBase ?? '';

  // Retrieves the `assetBase` value from the DOM.
  //
  // This warns the user and points them to the new initializeEngine style.
  String? get _deprecatedAssetBase {
    final meta = domWindow.document.querySelector('meta[name=assetBase]') as DomHTMLMetaElement?;

    final String? fallbackBaseUrl = meta?.content;

    if (fallbackBaseUrl != null) {
      // Warn users that they're using a deprecated configuration style...
      domWindow.console.warn(
        'The `assetBase` meta tag is now deprecated.\n'
        'Use engineInitializer.initializeEngine(config) instead.\n'
        'See: https://docs.flutter.dev/development/platform-integration/web/initialization',
      );
    }
    return fallbackBaseUrl;
  }

  /// Returns the URL to load the asset from, given the asset key.
  ///
  /// We URL-encode the asset URL in order to correctly issue the right
  /// HTTP request to the server.
  ///
  /// For example, if you have an asset in the file "assets/hello world.png",
  /// two things will happen. When the app is built, the asset will be copied
  /// to an asset directory with the file name URL-encoded. So our asset will
  /// be copied to something like "assets/hello%20world.png". To account for
  /// the assets being copied over with a URL-encoded name, the Flutter
  /// framework URL-encodes the asset key  so when it sends a request to the
  /// engine to load "assets/hello world.png", it actually sends a request to
  /// load "assets/hello%20world.png". However, on the web, if we try to load
  /// "assets/hello%20world.png", the request will be URL-decoded, we will
  /// request "assets/hello world.png", and the request will 404. Therefore, we
  /// must URL-encode the asset key *again* so when it is decoded, it is
  /// requesting the once-URL-encoded asset key.
  String getAssetUrl(String asset) {
    if (Uri.parse(asset).hasScheme) {
      return Uri.encodeFull(asset);
    }
    final String resolvedAsset = _contentHashedAssetMap[asset] ?? asset;
    return Uri.encodeFull('$_baseUrl$assetsDir/$resolvedAsset');
  }

  /// Loads an asset and returns the server response.
  Future<Object> loadAsset(String asset) {
    return httpFetch(getAssetUrl(asset));
  }

  /// Loads an asset using an [XMLHttpRequest] and returns data as [ByteData].
  Future<ByteData> load(String asset) async {
    final String url = getAssetUrl(asset);
    final HttpFetchResponse response = await httpFetch(url);

    if (response.status == 404 && asset == 'AssetManifest.json') {
      printWarning('Asset manifest does not exist at `$url` - ignoring.');
      return ByteData.sublistView(utf8.encode('{}'));
    }

    return (await response.payload.asByteBuffer()).asByteData();
  }
}
