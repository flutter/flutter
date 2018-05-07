// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/build.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
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
      ..addMultiOption('ios-arch',
        splitCommas: true,
        defaultsTo: defaultIOSArchs.map(getNameForIOSArch),
        allowed: IOSArch.values.map(getNameForIOSArch),
        help: 'iOS architectures to build',
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

    final BuildMode buildMode = getBuildMode();

    Status status;
    if (!argResults['quiet']) {
      final String typeName = artifacts.getEngineType(platform, buildMode);
      status = logger.startProgress('Building AOT snapshot in ${getModeName(getBuildMode())} mode ($typeName)...',
          expectSlowOperation: true);
    }
    final String outputPath = argResults['output-dir'] ?? getAotBuildDirectory();
    try {
      final bool previewDart2 = argResults['preview-dart-2'];
      String mainPath = findMainDartFile(targetFile);
      final AOTSnapshotter snapshotter = new AOTSnapshotter();

      // Compile to kernel, if Dart 2.
      if (previewDart2) {
        mainPath = await snapshotter.compileKernel(
          platform: platform,
          buildMode: buildMode,
          mainPath: mainPath,
          outputPath: outputPath,
          extraFrontEndOptions: argResults[FlutterOptions.kExtraFrontEndOptions],
        );
        if (mainPath == null) {
          printError('Compiler terminated unexpectedly.');
          return;
        }
      }

      // Build AOT snapshot.
      if (platform == TargetPlatform.ios) {
        // Determine which iOS architectures to build for.
        final Iterable<IOSArch> buildArchs = argResults['ios-arch'].map(getIOSArchForName);
        final Map<IOSArch, String> iosBuilds = <IOSArch, String>{};
        for (IOSArch arch in buildArchs)
          iosBuilds[arch] = fs.path.join(outputPath, getNameForIOSArch(arch));

        // Generate AOT snapshot and compile to arch-specific App.framework.
        final Map<IOSArch, Future<int>> exitCodes = <IOSArch, Future<int>>{};
        iosBuilds.forEach((IOSArch iosArch, String outputPath) {
          exitCodes[iosArch] = snapshotter.build(
            platform: platform,
            iosArch: iosArch,
            buildMode: buildMode,
            mainPath: mainPath,
            packagesPath: PackageMap.globalPackagesPath,
            outputPath: outputPath,
            previewDart2: previewDart2,
            preferSharedLibrary: false,
            extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
          ).then((int buildExitCode) {
            if (buildExitCode != 0)
              printError('Snapshotting ($iosArch) exited with non-zero exit code: $buildExitCode');
            return buildExitCode;
          });
        });

        // Merge arch-specific App.frameworks into a multi-arch App.framework.
        if ((await Future.wait(exitCodes.values)).every((int buildExitCode) => buildExitCode == 0)) {
          final Iterable<String> dylibs = iosBuilds.values.map((String outputDir) => fs.path.join(outputDir, 'App.framework', 'App'));
          fs.directory(fs.path.join(outputPath, 'App.framework'))..createSync();
          await runCheckedAsync(<String>['lipo']
            ..addAll(dylibs)
            ..addAll(<String>['-create', '-output', fs.path.join(outputPath, 'App.framework', 'App')]),
          );
        }
      } else {
        // Android AOT snapshot.
        final int snapshotExitCode = await snapshotter.build(
          platform: platform,
          buildMode: buildMode,
          mainPath: mainPath,
          packagesPath: PackageMap.globalPackagesPath,
          outputPath: outputPath,
          previewDart2: previewDart2,
          preferSharedLibrary: argResults['prefer-shared-library'],
          extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
        );
        if (snapshotExitCode != 0) {
          printError('Snapshotting exited with non-zero exit code: $snapshotExitCode');
        }
      }
    } on String catch (error) {
      // Catch the String exceptions thrown from the `runCheckedSync` methods below.
      printError(error);
    }
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
