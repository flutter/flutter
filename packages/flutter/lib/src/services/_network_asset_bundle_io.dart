// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'asset_bundle.dart' as asset_bundle;

/// The `dart:io` implementation of [asset_bundle.NetworkAssetBundle].
class NetworkAssetBundle extends asset_bundle.AssetBundle implements asset_bundle.NetworkAssetBundle {
  /// Creates an network asset bundle that resolves asset keys as URLs relative
  /// to the given base URL.
  NetworkAssetBundle(Uri baseUrl)
    : _baseUrl = baseUrl,
      _httpClient = HttpClient();

  final Uri _baseUrl;
  final HttpClient _httpClient;

  Uri _urlFromKey(String key) => _baseUrl.resolve(key);

  @override
  Future<ByteData> load(String key) async {
    final HttpClientRequest request = await _httpClient.getUrl(_urlFromKey(key));
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok)
      throw FlutterError(
        'Unable to load asset: $key\n'
        'HTTP status code: ${response.statusCode}'
      );
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    return bytes.buffer.asByteData();
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

  // TODO(ianh): Once the underlying network logic learns about caching, we
  // should implement evict().

  @override
  String toString() => '${describeIdentity(this)}($_baseUrl)';
}
