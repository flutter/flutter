// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

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
        // If the file is modified, the hook needs to be rerun. (Technically, we
        // don't need to rerun because we'd output the exact same thing. But the
        // hook could be doing other things based on the input file.)
        output.dependencies.add(input.packageRoot.resolve('data/$id'));
      }

      // Generate a data asset in the hook.
      // It is better to generate to outputDirectoryShared, but users might do
      // this instead and then delete the file manually.
      final Uri generatedUri = input.packageRoot.resolve('data/generated.txt');
      final file = File(generatedUri.toFilePath());
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync('generated content');
      output.assets.data.add(
        DataAsset(
          package: input.packageName,
          name: 'data/generated.txt',
          file: generatedUri,
        ),
      );
    }
  });
}
