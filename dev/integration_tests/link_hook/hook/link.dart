// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_cli/code_assets.dart';

void main(List<String> args) async {
  await link(args, (LinkInput input, LinkOutputBuilder output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }
    final CodeAsset asset = input.assets.code.single;
    final String packageName = input.packageName;
    output.assets.code.add(
      CodeAsset(
        package: packageName,
        // Change the asset id to something that is used.
        name: '${packageName}_bindings_generated.dart',
        linkMode: asset.linkMode,
        os: input.config.code.targetOS,
        architecture: input.config.code.targetArchitecture,
        file: asset.file,
      ),
    );
  });
}
