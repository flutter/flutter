// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// This class downloads assets over the network.
///
/// The assets are resolved relative to [assetsDir] inside the directory
/// containing the currently executing JS script.
class AssetManager {
  static const String _defaultAssetsDir = 'assets';

  /// The directory containing the assets.
  final String assetsDir;

  const AssetManager({this.assetsDir = _defaultAssetsDir});

  String? get _baseUrl {
    return html.window.document
        .querySelectorAll('meta')
        .whereType<html.MetaElement?>()
        .firstWhere((dynamic e) => e.name == 'assetBase', orElse: () => null)
        ?.content;
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
    return Uri.encodeFull((_baseUrl ?? '') + '$assetsDir/$asset');
  }

  Future<ByteData> load(String asset) async {
    final String url = getAssetUrl(asset);
    try {
      final html.HttpRequest request =
          await html.HttpRequest.request(url, responseType: 'arraybuffer');

      final ByteBuffer response = request.response;
      return response.asByteData();
    } on html.ProgressEvent catch (e) {
      final html.EventTarget? target = e.target;
      if (target is html.HttpRequest) {
        if (target.status == 404 && asset == 'AssetManifest.json') {
          html.window.console
              .warn('Asset manifest does not exist at `$url` – ignoring.');
          return Uint8List.fromList(utf8.encode('{}')).buffer.asByteData();
        }
        throw AssetManagerException(url, target.status!);
      }

      html.window.console.warn('Caught ProgressEvent with target: $target');
      rethrow;
    }
  }
}

class AssetManagerException implements Exception {
  final String url;
  final int httpStatus;

  AssetManagerException(this.url, this.httpStatus);

  @override
  String toString() => 'Failed to load asset at "$url" ($httpStatus)';
}

/// An asset manager that gives fake empty responses for assets.
class WebOnlyMockAssetManager implements AssetManager {
  String defaultAssetsDir = '';
  String defaultAssetManifest = '{}';
  String defaultFontManifest = '[]';

  @override
  String get assetsDir => defaultAssetsDir;

  @override
  String get _baseUrl => '';

  @override
  String getAssetUrl(String asset) => '$asset';

  @override
  Future<ByteData> load(String asset) {
    if (asset == getAssetUrl('AssetManifest.json')) {
      return Future<ByteData>.value(
          _toByteData(utf8.encode(defaultAssetManifest)));
    }
    if (asset == getAssetUrl('FontManifest.json')) {
      return Future<ByteData>.value(
          _toByteData(utf8.encode(defaultFontManifest)));
    }
    throw AssetManagerException(asset, 404);
  }

  ByteData _toByteData(List<int> bytes) {
    final ByteData byteData = ByteData(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      byteData.setUint8(i, bytes[i]);
    }
    return byteData;
  }
}
