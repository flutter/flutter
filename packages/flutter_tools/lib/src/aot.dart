// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'build_system/build_system.dart';
import 'build_system/targets/common.dart';
import 'build_system/targets/icon_tree_shaker.dart';
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
    @required BuildInfo buildInfo,
    @required String mainDartFile,
    bool bitcode = kBitcodeEnabledDefault,
    bool quiet = true,
    Iterable<DarwinArch> iosBuildArchs = defaultIOSArchs,
    bool reportTimings = false,
  }) async {
    if (platform == null) {
      throwToolExit('No AOT build platform specified');
    }
    Target target;
    bool expectSo = false;
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      case TargetPlatform.android_x86:
        throwToolExit('$platform is not supported in AOT.');
        break;
      case TargetPlatform.fuchsia_x64:
        throwToolExit(
          "To build release for fuchsia, use 'flutter build fuchsia --release'"
        );
        break;
      case TargetPlatform.ios:
        target = buildInfo.isRelease
          ? const AotAssemblyRelease()
          : const AotAssemblyProfile();
        break;
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
        expectSo = true;
        target = buildInfo.isRelease
          ? const AotElfRelease(TargetPlatform.android_arm)
          : const AotElfProfile(TargetPlatform.android_arm);
    }

    Status status;
    if (!quiet) {
      final String typeName = globals.artifacts.getEngineType(platform, buildInfo.mode);
      status = globals.logger.startProgress(
        'Building AOT snapshot in ${getFriendlyModeName(buildInfo.mode)} mode ($typeName)...',
        timeout: timeoutConfiguration.slowOperation,
      );
    }

    final Environment environment = Environment(
      projectDir: globals.fs.currentDirectory,
      outputDir: globals.fs.directory(outputPath),
      buildDir: FlutterProject.current().dartTool.childDirectory('flutter_build'),
      cacheDir: null,
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      engineVersion: globals.artifacts.isLocalEngine
        ? null
        : globals.flutterVersion.engineRevision,
      defines: <String, String>{
        kTargetFile: mainDartFile ?? globals.fs.path.join('lib', 'main.dart'),
        kBuildMode: getNameForBuildMode(buildInfo.mode),
        kTargetPlatform: getNameForTargetPlatform(platform),
        kIconTreeShakerFlag: buildInfo.treeShakeIcons.toString(),
        kDartDefines: buildInfo.dartDefines.join(','),
        kBitcodeFlag: bitcode.toString(),
        if (buildInfo?.extraGenSnapshotOptions?.isNotEmpty ?? false)
          kExtraGenSnapshotOptions: buildInfo.extraGenSnapshotOptions.join(','),
        if (buildInfo?.extraFrontEndOptions?.isNotEmpty ?? false)
          kExtraFrontEndOptions: buildInfo.extraFrontEndOptions.join(','),
        if (platform == TargetPlatform.ios)
          kIosArchs: iosBuildArchs.map(getNameForDarwinArch).join(' ')
      },
      artifacts: globals.artifacts,
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
    );
    final BuildResult result = await globals.buildSystem.build(target, environment);
    status?.stop();

    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        globals.printError(measurement.exception.toString());
      }
      throwToolExit('The aot build failed.');
    }

    // This print output is used by the dart team for build benchmarks.
    if (reportTimings) {
      final PerformanceMeasurement kernel = result.performance['kernel_snapshot'];
      PerformanceMeasurement aot;
      if (expectSo) {
        aot = result.performance.values.firstWhere(
          (PerformanceMeasurement measurement) => measurement.analyicsName == 'android_aot');
      } else {
        aot = result.performance.values.firstWhere(
          (PerformanceMeasurement measurement) => measurement.analyicsName == 'ios_aot');
      }
      globals.printStatus('frontend(CompileTime): ${kernel.elapsedMilliseconds} ms.');
      globals.printStatus('snapshot(CompileTime): ${aot.elapsedMilliseconds} ms.');
    }

    if (expectSo) {
      environment.buildDir.childFile('app.so')
        .copySync(globals.fs.path.join(outputPath, 'app.so'));
    } else {
      globals.fs.directory(globals.fs.path.join(outputPath, 'App.framework'))
        .createSync(recursive: true);
      environment.buildDir.childDirectory('App.framework').childFile('App')
        .copySync(globals.fs.path.join(outputPath, 'App.framework', 'App'));
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
