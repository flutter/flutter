// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/build.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildAotCommand extends BuildSubCommand {
  BuildAotCommand({bool verboseHelp: false}) {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios']
      )
      ..addFlag('quiet', defaultsTo: false)
      ..addFlag('preview-dart-2',
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Preview Dart 2.0 functionality.',
      )
      ..addMultiOption(FlutterOptions.kExtraFrontEndOptions,
        splitCommas: true,
        hide: true,
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('prefer-shared-library',
        negatable: false,
        help: 'Whether to prefer compiling to a *.so file (android only).');
  }

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<Null> runCommand() async {
    await super.runCommand();
    final String targetPlatform = argResults['target-platform'];
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null)
      throwToolExit('Unknown platform: $targetPlatform');

    final String typeName = artifacts.getEngineType(platform, getBuildMode());
    Status status;
    if (!argResults['quiet']) {
      status = logger.startProgress('Building AOT snapshot in ${getModeName(getBuildMode())} mode ($typeName)...',
          expectSlowOperation: true);
    }
    final String outputPath = await buildAotSnapshot(
      findMainDartFile(targetFile),
      platform,
      getBuildMode(),
      outputPath: argResults['output-dir'],
      previewDart2: argResults['preview-dart-2'],
      extraFrontEndOptions: argResults[FlutterOptions.kExtraFrontEndOptions],
      extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
      preferSharedLibrary: argResults['prefer-shared-library'],
    );
    status?.stop();

    if (outputPath == null)
      throwToolExit(null);

    final String builtMessage = 'Built to $outputPath${fs.path.separator}.';
    if (argResults['quiet']) {
      printTrace(builtMessage);
    } else {
      printStatus(builtMessage);
    }
  }
}

/// Build an AOT snapshot. Return null (and log to `printError`) if the method
/// fails.
Future<String> buildAotSnapshot(
  String mainPath,
  TargetPlatform platform,
  BuildMode buildMode, {
  String outputPath,
  bool previewDart2: false,
  List<String> extraFrontEndOptions,
  List<String> extraGenSnapshotOptions,
  bool preferSharedLibrary: false,
}) async {
  outputPath ??= getAotBuildDirectory();
  try {
    final Snapshotter snapshotter = new Snapshotter();
    final int snapshotExitCode = await snapshotter.buildAotSnapshot(
      platform: platform,
      buildMode: buildMode,
      mainPath: mainPath,
      depfilePath: 'depFilePathGoesHere',
      packagesPath: PackageMap.globalPackagesPath,
      outputPath: outputPath,
      previewDart2: previewDart2,
      preferSharedLibrary: preferSharedLibrary,
      extraFrontEndOptions: extraFrontEndOptions,
      extraGenSnapshotOptions: extraGenSnapshotOptions,
    );
    if (snapshotExitCode != 0) {
      printError('Snapshotting exited with non-zero exit code: $snapshotExitCode');
      return null;
    }
    return outputPath;
  } on String catch (error) {
    // Catch the String exceptions thrown from the `runCheckedSync` methods below.
    printError(error);
    return null;
  }
}
