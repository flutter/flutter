// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cmake_project.dart';

/// Generate an install manifest that is required for CMAKE on UWP projects.
Future<void> createManifest({
  @required Logger logger,
  @required FileSystem fileSystem,
  @required Platform platform,
  @required WindowsUwpProject project,
  @required BuildInfo buildInfo,
  @required Directory buildDirectory,
}) async {
  final List<File> outputs = <File>[];
  final AssetBundle assetBundle = AssetBundleFactory.defaultInstance(
    logger: logger,
    fileSystem: fileSystem,
    platform: platform,
    splitDeferredAssets: false,
  ).createBundle();
  final int resultCode = await assetBundle.build(
    packagesPath: buildInfo.packagesPath,
    assetDirPath: buildDirectory.childDirectory('flutter_assets').path,
  );
  if (resultCode != 0) {
    throwToolExit('Failed to build assets.');
  }

  if (buildInfo.mode.isPrecompiled) {
    outputs.add(buildDirectory.childFile('app.so'));
  } else {
    outputs.add(buildDirectory.parent.childDirectory('flutter_assets').childFile('kernel_blob.bin'));
  }
  for (final String key in assetBundle.entries.keys) {
    outputs.add(buildDirectory.parent.childDirectory('flutter_assets').childFile(key));
  }
  outputs.add(project.ephemeralDirectory.childFile('flutter_windows_winuwp.dll'));
  outputs.add(project.ephemeralDirectory.childFile('flutter_windows_winuwp.dll.pdb'));
  outputs.add(project.ephemeralDirectory.childFile('icudtl.dat'));
  project.ephemeralDirectory.childFile('install_manifest')
    ..createSync(recursive: true)
    ..writeAsStringSync(outputs.map((File file) => file.absolute.uri.path.substring(1)).join('\n'));
}
