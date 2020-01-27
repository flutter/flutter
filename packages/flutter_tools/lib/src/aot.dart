// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/targets/dart.dart';
import 'build_system/targets/ios.dart';
import 'cache.dart';
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
    throwToolExit('"flutter build aot" does not support configuration: $platform/$buildMode.');
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
