// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// This class downloads assets over the network.
///
/// The assets are resolved relative to [assetsDir].
class AssetManager {
  static const String _defaultAssetsDir = 'assets';

  /// The directory containing the assets.
  final String assetsDir;

  const AssetManager({this.assetsDir = _defaultAssetsDir});

  String getAssetUrl(String asset) {
    var assetUri = Uri.parse(asset);

    String url;

    if (assetUri.hasScheme) {
      url = asset;
    } else {
      url = '$assetsDir/$asset';
    }

    return url;
  }

  Future<ByteData> load(String asset) async {
    var url = getAssetUrl(asset);
    try {
      var request =
          await html.HttpRequest.request(url, responseType: 'arraybuffer');

      return (request.response as ByteBuffer).asByteData();
    } on html.ProgressEvent catch (e) {
      final target = e.target;
      if (target is html.HttpRequest) {
        if (target.status == 404 && asset == 'AssetManifest.json') {
          html.window.console
              .warn('Asset manifest does not exist at `$url` – ignoring.');
          return Uint8List.fromList(utf8.encode('{}')).buffer.asByteData();
        }
        throw AssetManagerException(url, target.status);
      }

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
