// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    if (input.config.buildAssetTypes.contains('data_assets/data')) {
      final assets = <String>['id1.txt']; // @assets
      for (final id in assets) {
        output.assets.data.add(
          DataAsset(
            package: input.packageName,
            name: 'data/$id',
            file: input.packageRoot.resolve('data/$id'),
          ),
        );
      }
    }
  });
}
