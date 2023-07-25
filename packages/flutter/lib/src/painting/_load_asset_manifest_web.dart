// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@JS('window')
external _DomWindow get _domWindow;

@JS()
@staticInterop
class _DomWindow {}

extension _DomWindowExtension on _DomWindow {
  @JS('_flutter_assetManifestBytes')
  external List<int>? get _assetManifestAsByteList;
}

Future<AssetManifest>? _precachedAssetManifest;

/// Loads the contents of the asset manifest generated at build time.
///
// For most web apps, the generated entry point code includes code that writes
// the asset manifest's contents to a JS property on the global window object.
// This implementation reads that property.
Future<AssetManifest> loadAssetManifest(AssetBundle bundle) {
  if (_precachedAssetManifest != null) {
    return _precachedAssetManifest!;
  }
  final List<int>? assetManifestAsByteList = _domWindow._assetManifestAsByteList;
  if (assetManifestAsByteList != null) {
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
