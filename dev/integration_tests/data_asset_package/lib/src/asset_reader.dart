// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show rootBundle;

Future<String> loadAssetContent() async {
  try {
    return await rootBundle.loadString('packages/data_asset_package/data/id1.txt');
  } catch (e) {
    return 'Dependency asset not found: $e';
  }
}
