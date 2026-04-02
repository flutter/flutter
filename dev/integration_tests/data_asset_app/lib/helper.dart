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

Future<AssetData?> loadAppAssets() async {
  const version = 'version1'; // @version
  if (lastVersion == version) {
    return null;
  }
  lastVersion = version;

  final found = <String, String>{};
  final notFound = <String>[];
  final assets = <String>['packages/data_asset_app/data/id1.txt']; // @assets
  for (final assetId in assets) {
    try {
      found[assetId] = await rootBundle.loadString(assetId);
    } catch (e) {
      print('EXCEPTION $e');
      notFound.add(assetId);
    }
  }

  return AssetData(version, found, notFound);
}
