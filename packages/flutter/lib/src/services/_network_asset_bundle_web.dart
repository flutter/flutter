// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'asset_bundle.dart' as asset_bundle;

/// The `dart:html` implementation of [asset_bundle.NetworkAssetBundle].
///
/// This class is unsupported and will throw if used.
class NetworkAssetBundle extends asset_bundle.AssetBundle implements asset_bundle.NetworkAssetBundle {
  /// Creates an network asset bundle that resolves asset keys as URLs relative
  /// to the given base URL.
  ///
  /// Always throws an [UnsupportedError].
  NetworkAssetBundle(this._baseUrl) {
    throw UnsupportedError('NetworkAssetBundle is not suppored on the web');
  }

  final Uri _baseUrl;

  @override
  Future<ByteData> load(String key) async {
    throw UnsupportedError('NetworkAssetBundle is not suppored on the web.');
  }

  /// Retrieve a string from the asset bundle, parse it with the given function,
  /// and return the function's result.
  ///
  /// The result is not cached. The parser is run each time the resource is
  /// fetched.
  @override
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value)) async {
    assert(key != null);
    assert(parser != null);
    return parser(await loadString(key));
  }

  @override
  String toString() => '${describeIdentity(this)}($_baseUrl)';
}
