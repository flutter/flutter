// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';


void main(List<String> args) async {
  await build(args, (BuildConfig config, BuildOutput output) async {
    final String packageName = config.packageName;
    final CBuilder cbuilder = CBuilder.library(
      name: packageName,
      assetName: 'some_asset_name_that_is_not_used',
      sources: <String>[
        'src/$packageName.c',
      ],
      dartBuildFiles: <String>['hook/build.dart'],
    );
    final BuildOutput outputCatcher = BuildOutput();
    await cbuilder.run(
      buildConfig: config,
      buildOutput: outputCatcher,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((LogRecord record) => print(record.message)),
    );
    output.addDependencies(outputCatcher.dependencies);
    // Send the asset to hook/link.dart.
    output.addAsset(
      outputCatcher.assets.single,
      linkInPackage: 'link_hook',
    );
  });
}
