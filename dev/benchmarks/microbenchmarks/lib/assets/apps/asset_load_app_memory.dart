// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/asset_manifest.dart';

/// An [AssetBundle] that loads resources using platform messages.
class ManifestPlatformAssetBundle extends CachingAssetBundle {
  ManifestPlatformAssetBundle(this._assetManifest, this._fontManifest);

  static const String _kAssetManifestKey = 'AssetManifest.json';
  static const String _kFontManifestKey = 'FontManfiest.json';

  final Object _assetManifest;
  final Object _fontManifest;


  @override
  Future<ByteData> load(String key) async {
    final Uint8List encoded = utf8.encoder.convert(Uri(path: Uri.encodeFull(key)).path);
    final ByteData asset =
    await defaultBinaryMessenger.send('flutter/assets', encoded.buffer.asByteData());
    if (asset == null)
      throw FlutterError('Unable to load asset: $key');
    return asset;
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value)) async {
    if (key == _kAssetManifestKey) {
      return _assetManifest;
    } else if (key == _kFontManifestKey) {
      return _fontManifest;
    } else {
      return super.loadStructuredData(key, parser);
    }
  }
}

final AssetBundle bundle = ManifestPlatformAssetBundle(assetManifest, fontManifest);

Future<void> obtainKey() async {
  final AssetImage assetImage = AssetImage('packages/shrine_images/10-0.jpg', bundle: bundle, package: null);
  return assetImage.obtainKey(ImageConfiguration.empty);
}
