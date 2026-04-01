// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print
import 'package:flutter/services.dart' show rootBundle;

// Only run the code once for each version.
String lastVersion = '';

class AssetData {
  const AssetData(this.version, this.found, this.notFound);
  final String version;
  final Map<String, String> found;
  final List<String> notFound;
}

Future<AssetData?> dumpAssets() async {
  const String version = 'version1'; // @version
  if (lastVersion == version) {
    return null;
  }
  lastVersion = version;

  final found = <String, String>{};
  final notFound = <String>[];
  final List<String> assets = <String>[
    'packages/data_asset_app/data/id1.txt'
  ]; // @assets
  for (final String assetId in assets) {
    try {
      found[assetId] = await rootBundle.loadString(assetId);
    } catch (e) {
      print('EXCEPTION $e');
      notFound.add(assetId);
    }
  }
  print('VERSION: $version');
  for (final MapEntry(:key, :value) in found.entries) {
    print('FOUND "$key": "$value".');
  }
  for (final id in notFound) {
    print('NOT-FOUND "$id".');
  }
  return AssetData(version, found, notFound);
}
// @forced_rerun
