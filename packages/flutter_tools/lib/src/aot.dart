// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/build.dart';
import 'base/common.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'build_info.dart';
import 'dart/package_map.dart';
import 'globals.dart' as globals;
import 'ios/bitcode.dart';

/// Builds AOT snapshots given a platform, build mode and a path to a Dart
/// library.
class AotBuilder {
  Future<void> build({
    @required TargetPlatform platform,
    @required String outputPath,
    @required BuildMode buildMode,
    @required String mainDartFile,
    bool bitcode = kBitcodeEnabledDefault,
    bool quiet = true,
    bool reportTimings = false,
    Iterable<DarwinArch> iosBuildArchs = defaultIOSArchs,
    List<String> extraFrontEndOptions,
    List<String> extraGenSnapshotOptions,
    @required List<String> dartDefines,
    @required bool treeShakeIcons,
  }) async {
    if (platform == null) {
      throwToolExit('No AOT build platform specified');
    }

    if (bitcode) {
      if (platform != TargetPlatform.ios) {
        throwToolExit('Bitcode is only supported on iOS (TargetPlatform is $platform).');
      }
      await validateBitcode(buildMode, platform);
    }

    Status status;
    if (!quiet) {
      final String typeName = globals.artifacts.getEngineType(platform, buildMode);
      status = globals.logger.startProgress(
        'Building AOT snapshot in ${getFriendlyModeName(buildMode)} mode ($typeName)...',
        timeout: timeoutConfiguration.slowOperation,
      );
    }
    try {
      final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: reportTimings);

      // Compile to kernel.
      final String kernelOut = await snapshotter.compileKernel(
        platform: platform,
        buildMode: buildMode,
        mainPath: mainDartFile,
        packagesPath: PackageMap.globalPackagesPath,
        trackWidgetCreation: false,
        outputPath: outputPath,
        extraFrontEndOptions: extraFrontEndOptions,
        dartDefines: dartDefines,
      );
      if (kernelOut == null) {
        throwToolExit('Compiler terminated unexpectedly.');
        return;
      }

      // Build AOT snapshot.
      if (platform == TargetPlatform.ios) {
        // Determine which iOS architectures to build for.
        final Map<DarwinArch, String> iosBuilds = <DarwinArch, String>{};
        for (final DarwinArch arch in iosBuildArchs) {
          iosBuilds[arch] = globals.fs.path.join(outputPath, getNameForDarwinArch(arch));
        }

        // Generate AOT snapshot and compile to arch-specific App.framework.
        final Map<DarwinArch, Future<int>> exitCodes = <DarwinArch, Future<int>>{};
        iosBuilds.forEach((DarwinArch iosArch, String outputPath) {
          exitCodes[iosArch] = snapshotter.build(
            platform: platform,
            darwinArch: iosArch,
            buildMode: buildMode,
            mainPath: kernelOut,
            packagesPath: PackageMap.globalPackagesPath,
            outputPath: outputPath,
            extraGenSnapshotOptions: extraGenSnapshotOptions,
            bitcode: bitcode,
            quiet: quiet,
            splitDebugInfo: null,
            dartObfuscation: false,
          ).then<int>((int buildExitCode) {
            return buildExitCode;
          });
        });

        // Merge arch-specific App.frameworks into a multi-arch App.framework.
        if ((await Future.wait<int>(exitCodes.values)).every((int buildExitCode) => buildExitCode == 0)) {
          final Iterable<String> dylibs = iosBuilds.values.map<String>(
              (String outputDir) => globals.fs.path.join(outputDir, 'App.framework', 'App'));
          globals.fs.directory(globals.fs.path.join(outputPath, 'App.framework'))..createSync();
          await processUtils.run(
            <String>[
              'lipo',
              ...dylibs,
              '-create',
              '-output', globals.fs.path.join(outputPath, 'App.framework', 'App'),
            ],
            throwOnError: true,
          );
        } else {
          status?.cancel();
          exitCodes.forEach((DarwinArch iosArch, Future<int> exitCodeFuture) async {
            final int buildExitCode = await exitCodeFuture;
            globals.printError('Snapshotting ($iosArch) exited with non-zero exit code: $buildExitCode');
          });
        }
      } else {
        // Android AOT snapshot.
        final int snapshotExitCode = await snapshotter.build(
          platform: platform,
          buildMode: buildMode,
          mainPath: kernelOut,
          packagesPath: PackageMap.globalPackagesPath,
          outputPath: outputPath,
          extraGenSnapshotOptions: extraGenSnapshotOptions,
          bitcode: false,
          splitDebugInfo: null,
          dartObfuscation: false,
        );
        if (snapshotExitCode != 0) {
          status?.cancel();
          throwToolExit('Snapshotting exited with non-zero exit code: $snapshotExitCode');
        }
      }
    } on ProcessException catch (error) {
      // Catch the String exceptions thrown from the `runSync` methods below.
      status?.cancel();
      globals.printError(error.toString());
      return;
    }
    status?.stop();

    if (outputPath == null) {
      throwToolExit(null);
    }

    final String builtMessage = 'Built to $outputPath${globals.fs.path.separator}.';
    if (quiet) {
      globals.printTrace(builtMessage);
    } else {
      globals.printStatus(builtMessage);
    }
    return;
  }
}
