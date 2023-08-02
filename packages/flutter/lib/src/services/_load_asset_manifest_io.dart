// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'asset_bundle.dart';
import 'asset_manifest.dart';

/// Loads the contents of the asset manifest generated at build time.
Future<AssetManifest> loadAssetManifest(AssetBundle bundle) async {
  return AssetManifest.fromByteData(await bundle.load('AssetManifest.bin'));
}
