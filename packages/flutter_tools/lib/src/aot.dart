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
import 'build_system/build_system.dart';
import 'build_system/targets/dart.dart';
import 'build_system/targets/ios.dart';
import 'cache.dart';
import 'dart/package_map.dart';
import 'globals.dart' as globals;
import 'ios/bitcode.dart';
import 'project.dart';

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

    if (_canUseAssemble(platform)
        && extraGenSnapshotOptions?.isEmpty != false
        && extraFrontEndOptions?.isEmpty != false) {
      await _buildWithAssemble(
        targetFile: mainDartFile,
        outputDir: outputPath,
        targetPlatform: platform,
        buildMode: buildMode,
        quiet: quiet,
        iosArchs: iosBuildArchs ?? defaultIOSArchs,
        bitcode: bitcode ?? kBitcodeEnabledDefault,
      );
      return;
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

  bool _canUseAssemble(TargetPlatform targetPlatform) {
    switch (targetPlatform) {
      case TargetPlatform.ios:
        return true;
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x86:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.android_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      default:
        return false;
    }
  }

  Future<void> _buildWithAssemble({
    TargetPlatform targetPlatform,
    BuildMode buildMode,
    String targetFile,
    String outputDir,
    bool quiet,
    Iterable<DarwinArch> iosArchs,
    bool bitcode,
  }) async {
    Status status;
    if (!quiet) {
      final String typeName = globals.artifacts.getEngineType(targetPlatform, buildMode);
      status = globals.logger.startProgress(
        'Building AOT snapshot in ${getFriendlyModeName(buildMode)} mode ($typeName)...',
        timeout: timeoutConfiguration.slowOperation,
      );
    }
    final FlutterProject flutterProject = FlutterProject.current();
    final Target target = buildMode == BuildMode.profile
      ? const AotAssemblyProfile()
      : const AotAssemblyRelease();

    final BuildResult result = await buildSystem.build(target, Environment(
      projectDir: flutterProject.directory,
      cacheDir: globals.cache.getRoot(),
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      outputDir: globals.fs.directory(outputDir),
      buildDir: flutterProject.directory
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build'),
      defines: <String, String>{
        kBuildMode: getNameForBuildMode(buildMode),
        kTargetPlatform: getNameForTargetPlatform(targetPlatform),
        kTargetFile: targetFile,
        kIosArchs: iosArchs.map(getNameForDarwinArch).join(','),
        kBitcodeFlag: bitcode.toString()
      }
    ));
    status?.stop();
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        globals.printError('Target ${measurement.target} failed: ${measurement.exception}',
          stackTrace: measurement.fatal
            ? measurement.stackTrace
            : null,
        );
      }
      throwToolExit('Failed to build aot.');
    }
    final String builtMessage = 'Built to $outputDir${globals.fs.path.separator}.';
    if (quiet) {
      globals.printTrace(builtMessage);
    } else {
      globals.printStatus(builtMessage);
    }
  }
}
