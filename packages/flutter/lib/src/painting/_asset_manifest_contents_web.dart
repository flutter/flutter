// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<AssetManifest>? _precachedAssetManifest;
final List<int>? _assetManifestContents =
  js.context['_flutter_assetManifestAsByteList'] as List<int>?;

/// Loads the contents of the asset manifest generated at build time.
///
// For most web apps, the generated entry point code includes code that writes
// the asset manifest's contents to a JS global as a base64-encoded string.
// This implementation reads that global.
Future<AssetManifest> loadAssetManifest(AssetBundle bundle) {
  if (_precachedAssetManifest != null) {
    return _precachedAssetManifest!;
  }

  if (_assetManifestContents != null) {
    final List<int> assetManifestAsByteList = _assetManifestContents!;
    final ByteData assetManifestByteData = ByteData.view(
      Uint8List.fromList(assetManifestAsByteList)
      .buffer
    );

    return _precachedAssetManifest = SynchronousFuture<AssetManifest>(
      AssetManifest.fromByteData(assetManifestByteData)
    );
  }

  return AssetManifest.loadFromAssetBundle(bundle);
}
