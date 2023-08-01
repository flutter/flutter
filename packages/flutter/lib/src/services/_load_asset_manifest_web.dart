// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'asset_bundle.dart';
import 'asset_manifest.dart';

@JS('_flutter_assetManifestBytes')
@staticInterop
external List<int>? _assetManifestAsByteList;

AssetManifest? _precachedAssetManifest;

/// Loads the contents of the asset manifest generated at build time.
///
// For most web apps, the generated entry point code includes code that writes
// the asset manifest's contents to a JS property on the global window object.
// This implementation reads that property.
Future<AssetManifest> loadAssetManifest(AssetBundle bundle) async {
  // Refuse to work without an inline bundle
  assert(_precachedAssetManifest != null || (_assetManifestAsByteList != null && _assetManifestAsByteList!.isNotEmpty));

  if (_precachedAssetManifest == null) {
    final List<int>? assetManifestAsByteList = _assetManifestAsByteList;
    if (assetManifestAsByteList != null) {
      final ByteData assetManifestByteData =
        Uint8List.fromList(assetManifestAsByteList)
        .buffer
        .asByteData();

      _assetManifestAsByteList = null; // Clean-up the manifest on window.

      _precachedAssetManifest = AssetManifest.fromByteData(assetManifestByteData);
    }
  }

  return _precachedAssetManifest!;
}
