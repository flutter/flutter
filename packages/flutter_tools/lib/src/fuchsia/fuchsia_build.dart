// Copyright 2019 The Chromium Authors. All rights reserved.
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
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';

import 'fuchsia_pm.dart';
import 'fuchsia_sdk.dart';

Future<void> _timedBuildStep(String name, Future<void> Function() action) async {
  final Stopwatch sw = Stopwatch()..start();
  await action();
  printTrace('$name: ${sw.elapsedMilliseconds} ms.');
  flutterUsage.sendTiming('build', name, Duration(milliseconds: sw.elapsedMilliseconds));
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
  final Directory outDir = fs.directory(getFuchsiaBuildDirectory());
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
  final String dilPath = fs.path.join(outDir, '$appName.dil');

  final String vmSnapshotData = fs.path.join(outDir, 'vm_data.aotsnapshot');
  final String vmSnapshotInstructions = fs.path.join(outDir, 'vm_instructions.aotsnapshot');
  final String snapshotData = fs.path.join(outDir, 'data.aotsnapshot');
  final String snapshotInstructions = fs.path.join(outDir, 'instructions.aotsnapshot');

  final String genSnapshot = artifacts.getArtifactPath(
    Artifact.genSnapshot,
    platform: targetPlatform,
    mode: buildInfo.mode,
  );

  final List<String> command = <String>[
    genSnapshot,
    '--no_causal_async_stacks',
    '--deterministic',
    '--snapshot_kind=app-aot-blobs',
    '--vm_snapshot_data=$vmSnapshotData',
    '--vm_snapshot_instructions=$vmSnapshotInstructions',
    '--isolate_snapshot_data=$snapshotData',
    '--isolate_snapshot_instructions=$snapshotInstructions',
    if (buildInfo.isDebug) '--enable-asserts',
    dilPath,
  ];
  int result;
  final Status status = logger.startProgress(
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
  final String pkgDir = fs.path.join(outDir, 'pkg');
  final String appName = fuchsiaProject.project.manifest.appName;
  final String pkgassets = fs.path.join(outDir, '${appName}_pkgassets');
  final String packageManifest = fs.path.join(pkgDir, 'package_manifest');
  final String devKeyPath = fs.path.join(pkgDir, 'development.key');

  final Directory pkg = fs.directory(pkgDir);
  if (!pkg.existsSync()) {
    pkg.createSync(recursive: true);
  }

  final File srcCmx =
      fs.file(fs.path.join(fuchsiaProject.meta.path, '$appName.cmx'));
  final File dstCmx = fs.file(fs.path.join(outDir, '$appName.cmx'));
  _rewriteCmx(buildInfo.mode, runnerPackageSource, srcCmx, dstCmx);

  final File manifestFile = fs.file(packageManifest);

  if (buildInfo.usesAot) {
    final String vmSnapshotData = fs.path.join(outDir, 'vm_data.aotsnapshot');
    final String vmSnapshotInstructions = fs.path.join(outDir, 'vm_instructions.aotsnapshot');
    final String snapshotData = fs.path.join(outDir, 'data.aotsnapshot');
    final String snapshotInstructions = fs.path.join(outDir, 'instructions.aotsnapshot');
    manifestFile.writeAsStringSync(
      'data/$appName/vm_snapshot_data.bin=$vmSnapshotData\n');
    manifestFile.writeAsStringSync(
      'data/$appName/vm_snapshot_instructions.bin=$vmSnapshotInstructions\n',
      mode: FileMode.append);
    manifestFile.writeAsStringSync(
      'data/$appName/isolate_snapshot_data.bin=$snapshotData\n',
      mode: FileMode.append);
    manifestFile.writeAsStringSync(
      'data/$appName/isolate_snapshot_instructions.bin=$snapshotInstructions\n',
      mode: FileMode.append);
  } else {
    final String dilpmanifest = fs.path.join(outDir, '$appName.dilpmanifest');
    manifestFile.writeAsStringSync(fs.file(dilpmanifest).readAsStringSync());
  }

  manifestFile.writeAsStringSync(fs.file(pkgassets).readAsStringSync(),
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
