// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../asset.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../devfs.dart';
import '../project.dart';

import 'fuchsia_pm.dart';
import 'fuchsia_sdk.dart';

// Building a Fuchsia package has a few steps:
// 1. Do the custom kernel compile using the kernel compiler from the Fuchsia
//    SDK. This produces .dilp files (among others) and a manifest file.
// 2. Create a manifest file for assets.
// 3. Using these manifests, use the Fuchsia SDK 'pm' tool to create the
//    Fuchsia package.
Future<void> buildFuchsia(
    {@required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug}) async {
  final Directory outDir = fs.directory(getFuchsiaBuildDirectory());
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await fuchsiaSdk.fuchsiaKernelCompiler.build(
      fuchsiaProject: fuchsiaProject, target: target, buildInfo: buildInfo);
  await _buildAssets(fuchsiaProject, target, buildInfo);
  await _buildPackage(fuchsiaProject, target, buildInfo);
}

Future<void> _buildAssets(
    FuchsiaProject fuchsiaProject,
    String target, // lib/main.dart
    BuildInfo buildInfo) async {
  final String assetDir = getAssetBuildDirectory();
  final AssetBundle assets = await buildAssets(
    manifestPath: fuchsiaProject.project.pubspecFile.path,
    packagesPath: fuchsiaProject.project.packagesFile.path,
    assetDirPath: assetDir,
    includeDefaultFonts: false,
  );

  final Map<String, DevFSContent> assetEntries =
      Map<String, DevFSContent>.from(assets.entries);
  await writeBundle(fs.directory(assetDir), assetEntries);

  final String appName = fuchsiaProject.project.manifest.appName;
  final String outDir = getFuchsiaBuildDirectory();
  final String assetManifest = fs.path.join(outDir, '${appName}_pkgassets');

  final File destFile = fs.file(assetManifest);
  await destFile.create(recursive: true);
  final IOSink outFile = destFile.openWrite();

  for (String path in assets.entries.keys) {
    outFile.write('data/$appName/$path=$assetDir/$path\n');
  }
  await outFile.flush();
  await outFile.close();
}

// TODO(zra): Allow supplying a signing key.
Future<void> _buildPackage(
    FuchsiaProject fuchsiaProject,
    String target, // lib/main.dart
    BuildInfo buildInfo) async {
  final String outDir = getFuchsiaBuildDirectory();
  final String pkgDir = fs.path.join(outDir, 'pkg');
  final String appName = fuchsiaProject.project.manifest.appName;
  final String dilpmanifest = fs.path.join(outDir, '$appName.dilpmanifest');
  final String pkgassets = fs.path.join(outDir, '${appName}_pkgassets');
  final String packageManifest = fs.path.join(pkgDir, 'package_manifest');
  final String devKeyPath = fs.path.join(pkgDir, 'development.key');

  final Directory pkg = fs.directory(pkgDir);
  if (!pkg.existsSync()) {
    pkg.createSync(recursive: true);
  }

  // Concatenate dilpmanifest and pkgassets into package_manifest.
  final File manifestFile = fs.file(packageManifest);
  manifestFile.writeAsStringSync(fs.file(dilpmanifest).readAsStringSync());
  manifestFile.writeAsStringSync(fs.file(pkgassets).readAsStringSync(),
      mode: FileMode.append);
  manifestFile.writeAsStringSync(
      'meta/$appName.cmx=${fuchsiaProject.meta.path}/$appName.cmx\n',
      mode: FileMode.append);
  manifestFile.writeAsStringSync('meta/package=$pkgDir/meta/package\n',
      mode: FileMode.append);

  final FuchsiaPM fuchsiaPM = fuchsiaSdk.fuchsiaPM;
  if (!await fuchsiaPM.init(pkgDir, appName)) {
    return;
  }
  if (!await fuchsiaPM.genkey(pkgDir, devKeyPath)) {
    return;
  }
  if (!await fuchsiaPM.build(pkgDir, devKeyPath, packageManifest)) {
    return;
  }
  if (!await fuchsiaPM.archive(pkgDir, devKeyPath, packageManifest)) {
    return;
  }
}
