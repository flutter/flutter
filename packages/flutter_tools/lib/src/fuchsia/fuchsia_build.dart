// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../asset.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../convert.dart';
import '../devfs.dart';
import '../globals.dart' as globals;
import '../project.dart';

import 'fuchsia_pm.dart';
import 'fuchsia_sdk.dart';

Future<void> _timedBuildStep(String name, Future<void> Function() action) async {
  final Stopwatch sw = Stopwatch()..start();
  await action();
  globals.printTrace('$name: ${sw.elapsedMilliseconds} ms.');
  globals.flutterUsage.sendTiming('build', name, Duration(milliseconds: sw.elapsedMilliseconds));
}

Future<void> _validateCmxFile(FuchsiaProject fuchsiaProject) async {
  final String appName = fuchsiaProject.project.manifest.appName;
  final String cmxPath = globals.fs.path.join(fuchsiaProject.meta.path, '$appName.cmx');
  final File cmxFile = globals.fs.file(cmxPath);
  if (!await cmxFile.exists()) {
    throwToolExit('The Fuchsia build requires a .cmx file at $cmxPath for the app: $appName.');
  }
}

// Building a Fuchsia package has a few steps:
// 1. Do the custom kernel compile using the kernel compiler from the Fuchsia
//    SDK. This produces .dilp files (among others) and a manifest file.
// 2. Create a manifest file for assets.
// 3. Using these manifests, use the Fuchsia SDK 'pm' tool to create the
//    Fuchsia package.
Future<void> buildFuchsia({
  @required FuchsiaProject fuchsiaProject,
  @required TargetPlatform targetPlatform,
  @required String target, // E.g., lib/main.dart
  BuildInfo buildInfo = BuildInfo.debug,
  String runnerPackageSource = FuchsiaPackageServer.toolHost,
}) async {
  await _validateCmxFile(fuchsiaProject);
  final Directory outDir = globals.fs.directory(getFuchsiaBuildDirectory());
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  await _timedBuildStep('fuchsia-kernel-compile',
    () => fuchsiaSdk.fuchsiaKernelCompiler.build(
      fuchsiaProject: fuchsiaProject, target: target, buildInfo: buildInfo));

  if (buildInfo.usesAot) {
    await _timedBuildStep('fuchsia-gen-snapshot',
      () => _genSnapshot(fuchsiaProject, target, buildInfo, targetPlatform));
  }

  await _timedBuildStep('fuchsia-build-assets',
    () => _buildAssets(fuchsiaProject, target, buildInfo));
  await _timedBuildStep('fuchsia-build-package',
    () => _buildPackage(fuchsiaProject, target, buildInfo, runnerPackageSource));
}

Future<void> _genSnapshot(
  FuchsiaProject fuchsiaProject,
  String target, // lib/main.dart
  BuildInfo buildInfo,
  TargetPlatform targetPlatform,
) async {
  final String outDir = getFuchsiaBuildDirectory();
  final String appName = fuchsiaProject.project.manifest.appName;
  final String dilPath = globals.fs.path.join(outDir, '$appName.dil');

  final String elf = globals.fs.path.join(outDir, 'elf.aotsnapshot');

  final String genSnapshot = globals.artifacts.getArtifactPath(
    Artifact.genSnapshot,
    platform: targetPlatform,
    mode: buildInfo.mode,
  );

  final List<String> command = <String>[
    genSnapshot,
    '--no-causal-async-stacks',
    '--lazy-async-stacks',
    '--deterministic',
    '--snapshot_kind=app-aot-elf',
    '--elf=$elf',
    if (buildInfo.isDebug) '--enable-asserts',
    dilPath,
  ];
  int result;
  final Status status = globals.logger.startProgress(
    'Compiling Fuchsia application to native code...',
    timeout: null,
  );
  try {
    result = await processUtils.stream(command, trace: true);
  } finally {
    status.cancel();
  }
  if (result != 0) {
    throwToolExit('Build process failed');
  }
}

Future<void> _buildAssets(
  FuchsiaProject fuchsiaProject,
  String target, // lib/main.dart
  BuildInfo buildInfo,
) async {
  final String assetDir = getAssetBuildDirectory();
  final AssetBundle assets = await buildAssets(
    manifestPath: fuchsiaProject.project.pubspecFile.path,
    packagesPath: fuchsiaProject.project.packagesFile.path,
    assetDirPath: assetDir,
    includeDefaultFonts: false,
  );

  final Map<String, DevFSContent> assetEntries =
      Map<String, DevFSContent>.of(assets.entries);
  await writeBundle(globals.fs.directory(assetDir), assetEntries);

  final String appName = fuchsiaProject.project.manifest.appName;
  final String outDir = getFuchsiaBuildDirectory();
  final String assetManifest = globals.fs.path.join(outDir, '${appName}_pkgassets');

  final File destFile = globals.fs.file(assetManifest);
  await destFile.create(recursive: true);
  final IOSink outFile = destFile.openWrite();

  for (final String path in assets.entries.keys) {
    outFile.write('data/$appName/$path=$assetDir/$path\n');
  }
  await outFile.flush();
  await outFile.close();
}

void _rewriteCmx(BuildMode mode, String runnerPackageSource, File src, File dst) {
  final Map<String, dynamic> cmx = castStringKeyedMap(json.decode(src.readAsStringSync()));
  // If the app author has already specified the runner in the cmx file, then
  // do not override it with something else.
  if (cmx.containsKey('runner')) {
    dst.writeAsStringSync(json.encode(cmx));
    return;
  }
  String runner;
  switch (mode) {
    case BuildMode.debug:
      runner = 'flutter_jit_runner';
      break;
    case BuildMode.profile:
      runner = 'flutter_aot_runner';
      break;
    case BuildMode.jitRelease:
      runner = 'flutter_jit_product_runner';
      break;
    case BuildMode.release:
      runner = 'flutter_aot_product_runner';
      break;
    default:
      throwToolExit('Fuchsia does not support build mode "$mode"');
      break;
  }
  cmx['runner'] = 'fuchsia-pkg://$runnerPackageSource/$runner#meta/$runner.cmx';
  dst.writeAsStringSync(json.encode(cmx));
}

// TODO(zra): Allow supplying a signing key.
Future<void> _buildPackage(
  FuchsiaProject fuchsiaProject,
  String target, // lib/main.dart
  BuildInfo buildInfo,
  String runnerPackageSource,
) async {
  final String outDir = getFuchsiaBuildDirectory();
  final String pkgDir = globals.fs.path.join(outDir, 'pkg');
  final String appName = fuchsiaProject.project.manifest.appName;
  final String pkgassets = globals.fs.path.join(outDir, '${appName}_pkgassets');
  final String packageManifest = globals.fs.path.join(pkgDir, 'package_manifest');
  final String devKeyPath = globals.fs.path.join(pkgDir, 'development.key');

  final Directory pkg = globals.fs.directory(pkgDir);
  if (!pkg.existsSync()) {
    pkg.createSync(recursive: true);
  }

  final File srcCmx =
      globals.fs.file(globals.fs.path.join(fuchsiaProject.meta.path, '$appName.cmx'));
  final File dstCmx = globals.fs.file(globals.fs.path.join(outDir, '$appName.cmx'));
  _rewriteCmx(buildInfo.mode, runnerPackageSource, srcCmx, dstCmx);

  final File manifestFile = globals.fs.file(packageManifest);

  if (buildInfo.usesAot) {
    final String elf = globals.fs.path.join(outDir, 'elf.aotsnapshot');
    manifestFile.writeAsStringSync(
      'data/$appName/app_aot_snapshot.so=$elf\n');
  } else {
    final String dilpmanifest = globals.fs.path.join(outDir, '$appName.dilpmanifest');
    manifestFile.writeAsStringSync(globals.fs.file(dilpmanifest).readAsStringSync());
  }

  manifestFile.writeAsStringSync(globals.fs.file(pkgassets).readAsStringSync(),
      mode: FileMode.append);
  manifestFile.writeAsStringSync('meta/$appName.cmx=${dstCmx.path}\n',
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
