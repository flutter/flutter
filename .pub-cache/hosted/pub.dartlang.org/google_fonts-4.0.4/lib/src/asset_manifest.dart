// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:flutter/foundation.dart';
// TODO(andrewkolos): remove this after flutter adds its own AssetManifest API
// (see https://github.com/flutter/flutter/pull/119277) which will replace the
// one defined here.
// ignore: undefined_hidden_name
import 'package:flutter/services.dart' hide AssetManifest;

/// A class to obtain and memoize the app's asset manifest.
///
/// Used to check whether a font is provided as an asset.
class AssetManifest {
  AssetManifest({this.enableCache = true});

  static Future<Map<String, List<String>>?>? _jsonFuture;

  /// Whether the rootBundle should cache AssetManifest.json.
  ///
  /// Enabled by default. Should only be disabled during tests.
  final bool enableCache;

  Future<Map<String, List<String>>?>? json() {
    _jsonFuture ??= _loadAssetManifestJson();
    return _jsonFuture;
  }

  Future<Map<String, List<String>>?> _loadAssetManifestJson() async {
    try {
      final jsonString = await rootBundle.loadString(
        'AssetManifest.json',
        cache: enableCache,
      );
      return _manifestParser(jsonString);
    } catch (e) {
      rootBundle.evict('AssetManifest.json');
      rethrow;
    }
  }

  static Future<Map<String, List<String>>?> _manifestParser(String? jsonData) {
    if (jsonData == null) {
      return SynchronousFuture(null);
    }
    final parsedJson = convert.json.decode(jsonData) as Map<String, dynamic>;
    final parsedManifest = <String, List<String>>{
      for (final entry in parsedJson.entries)
        entry.key: (entry.value as List<dynamic>).cast<String>(),
    };
    return SynchronousFuture(parsedManifest);
  }

  @visibleForTesting
  static void reset() => _jsonFuture = null;
}
