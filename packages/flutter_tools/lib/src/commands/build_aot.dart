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
  BuildAotCommand() {
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
      ..addFlag('build-shared-library',
        negatable: false,
        defaultsTo: false,
        help: 'Compile to a *.so file (requires NDK when building for Android).'
      )
      ..addMultiOption('ios-arch',
        splitCommas: true,
        defaultsTo: defaultIOSArchs.map<String>(getNameForIOSArch),
        allowed: IOSArch.values.map<String>(getNameForIOSArch),
        help: 'iOS architectures to build.',
      )
      ..addMultiOption(FlutterOptions.kExtraFrontEndOptions,
        splitCommas: true,
        hide: true,
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      );
  }

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<FlutterCommandResult> runCommand() async {
    await super.runCommand();

    final String targetPlatform = argResults['target-platform'];
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null)
      throwToolExit('Unknown platform: $targetPlatform');

    final BuildMode buildMode = getBuildMode();

    Status status;
    if (!argResults['quiet']) {
      final String typeName = artifacts.getEngineType(platform, buildMode);
      status = logger.startProgress(
        'Building AOT snapshot in ${getModeName(getBuildMode())} mode ($typeName)...',
        expectSlowOperation: true,
      );
    }
    final String outputPath = argResults['output-dir'] ?? getAotBuildDirectory();
    try {
      String mainPath = findMainDartFile(targetFile);
      final AOTSnapshotter snapshotter = AOTSnapshotter();

      // Compile to kernel.
      mainPath = await snapshotter.compileKernel(
        platform: platform,
        buildMode: buildMode,
        mainPath: mainPath,
        packagesPath: PackageMap.globalPackagesPath,
        trackWidgetCreation: false,
        outputPath: outputPath,
        extraFrontEndOptions: argResults[FlutterOptions.kExtraFrontEndOptions],
      );
      if (mainPath == null) {
        throwToolExit('Compiler terminated unexpectedly.');
        return null;
      }

      // Build AOT snapshot.
      if (platform == TargetPlatform.ios) {
        // Determine which iOS architectures to build for.
        final Iterable<IOSArch> buildArchs = argResults['ios-arch'].map<IOSArch>(getIOSArchForName);
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
            buildSharedLibrary: false,
            extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
          ).then<int>((int buildExitCode) {
            return buildExitCode;
          });
        });

        // Merge arch-specific App.frameworks into a multi-arch App.framework.
        if ((await Future.wait<int>(exitCodes.values)).every((int buildExitCode) => buildExitCode == 0)) {
          final Iterable<String> dylibs = iosBuilds.values.map<String>((String outputDir) => fs.path.join(outputDir, 'App.framework', 'App'));
          fs.directory(fs.path.join(outputPath, 'App.framework'))..createSync();
          await runCheckedAsync(<String>['lipo']
            ..addAll(dylibs)
            ..addAll(<String>['-create', '-output', fs.path.join(outputPath, 'App.framework', 'App')]),
          );
        } else {
          status?.cancel();
          exitCodes.forEach((IOSArch iosArch, Future<int> exitCodeFuture) async {
            final int buildExitCode = await exitCodeFuture;
            printError('Snapshotting ($iosArch) exited with non-zero exit code: $buildExitCode');
          });
        }
      } else {
        // Android AOT snapshot.
        final int snapshotExitCode = await snapshotter.build(
          platform: platform,
          buildMode: buildMode,
          mainPath: mainPath,
          packagesPath: PackageMap.globalPackagesPath,
          outputPath: outputPath,
          buildSharedLibrary: argResults['build-shared-library'],
          extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
        );
        if (snapshotExitCode != 0) {
          status?.cancel();
          throwToolExit('Snapshotting exited with non-zero exit code: $snapshotExitCode');
        }
      }
    } on String catch (error) {
      // Catch the String exceptions thrown from the `runCheckedSync` methods below.
      status?.cancel();
      printError(error);
      return null;
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
    return null;
  }
}
