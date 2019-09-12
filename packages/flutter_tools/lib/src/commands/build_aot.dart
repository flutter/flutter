// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/build.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../ios/plist_parser.dart';
import '../macos/xcode.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildAotCommand extends BuildSubCommand with TargetPlatformBasedDevelopmentArtifacts {
  BuildAotCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios'],
      )
      ..addFlag('quiet', defaultsTo: false)
      ..addFlag('report-timings',
        negatable: false,
        defaultsTo: false,
        help: 'Report timing information about build steps in machine readable form,',
      )
      ..addMultiOption('ios-arch',
        splitCommas: true,
        defaultsTo: defaultIOSArchs.map<String>(getNameForDarwinArch),
        allowed: DarwinArch.values.map<String>(getNameForDarwinArch),
        help: 'iOS architectures to build.',
      )
      ..addMultiOption(FlutterOptions.kExtraFrontEndOptions,
        splitCommas: true,
        hide: true,
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('bitcode',
        defaultsTo: false,
        help: 'Build the AOT bundle with bitcode. Requires a compatible bitcode engine.',
        hide: true,
      );
    // --track-widget-creation is exposed as a flag here to deal with build
    // invalidation issues, but it is ignored -- there are no plans to support
    // it for AOT mode.
    usesTrackWidgetCreation(hasEffect: false, verboseHelp: verboseHelp);
  }

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = argResults['target-platform'];
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null)
      throwToolExit('Unknown platform: $targetPlatform');

    final bool bitcode = argResults['bitcode'];
    final BuildMode buildMode = getBuildMode();

    if (bitcode) {
      if (platform != TargetPlatform.ios) {
        throwToolExit('Bitcode is only supported on iOS (TargetPlatform is $targetPlatform).');
      }
      await validateBitcode(buildMode, platform);
    }

    Status status;
    if (!argResults['quiet']) {
      final String typeName = artifacts.getEngineType(platform, buildMode);
      status = logger.startProgress(
        'Building AOT snapshot in ${getFriendlyModeName(getBuildMode())} mode ($typeName)...',
        timeout: timeoutConfiguration.slowOperation,
      );
    }
    final String outputPath = argResults['output-dir'] ?? getAotBuildDirectory();
    final bool reportTimings = argResults['report-timings'];
    try {
      String mainPath = findMainDartFile(targetFile);
      final AOTSnapshotter snapshotter = AOTSnapshotter(reportTimings: reportTimings);

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
        final Iterable<DarwinArch> buildArchs = argResults['ios-arch'].map<DarwinArch>(getIOSArchForName);
        final Map<DarwinArch, String> iosBuilds = <DarwinArch, String>{};
        for (DarwinArch arch in buildArchs)
          iosBuilds[arch] = fs.path.join(outputPath, getNameForDarwinArch(arch));

        // Generate AOT snapshot and compile to arch-specific App.framework.
        final Map<DarwinArch, Future<int>> exitCodes = <DarwinArch, Future<int>>{};
        iosBuilds.forEach((DarwinArch iosArch, String outputPath) {
          exitCodes[iosArch] = snapshotter.build(
            platform: platform,
            darwinArch: iosArch,
            buildMode: buildMode,
            mainPath: mainPath,
            packagesPath: PackageMap.globalPackagesPath,
            outputPath: outputPath,
            extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
            bitcode: bitcode,
          ).then<int>((int buildExitCode) {
            return buildExitCode;
          });
        });

        // Merge arch-specific App.frameworks into a multi-arch App.framework.
        if ((await Future.wait<int>(exitCodes.values)).every((int buildExitCode) => buildExitCode == 0)) {
          final Iterable<String> dylibs = iosBuilds.values.map<String>(
              (String outputDir) => fs.path.join(outputDir, 'App.framework', 'App'));
          fs.directory(fs.path.join(outputPath, 'App.framework'))..createSync();
          await processUtils.run(
            <String>[
              'lipo',
              ...dylibs,
              '-create',
              '-output', fs.path.join(outputPath, 'App.framework', 'App'),
            ],
            throwOnError: true,
          );
        } else {
          status?.cancel();
          exitCodes.forEach((DarwinArch iosArch, Future<int> exitCodeFuture) async {
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
          extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
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
      printError(error.toString());
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

Future<void> validateBitcode(BuildMode buildMode, TargetPlatform targetPlatform) async {
  final Artifacts artifacts = Artifacts.instance;
  final String flutterFrameworkPath = artifacts.getArtifactPath(
    Artifact.flutterFramework,
    mode: buildMode,
    platform: targetPlatform,
  );
  if (!fs.isDirectorySync(flutterFrameworkPath)) {
    throwToolExit('Flutter.framework not found at $flutterFrameworkPath');
  }
  final Xcode xcode = context.get<Xcode>();

  final RunResult clangResult = await xcode.clang(<String>['--version']);
  final String clangVersion = clangResult.stdout.split('\n').first;
  final String engineClangVersion = PlistParser.instance.getValueFromFile(
    fs.path.join(flutterFrameworkPath, 'Info.plist'),
    'ClangVersion',
  );
  final Version engineClangSemVer = _parseVersionFromClang(engineClangVersion);
  final Version clangSemVer = _parseVersionFromClang(clangVersion);
  if (engineClangSemVer > clangSemVer) {
    throwToolExit(
      'The Flutter.framework at $flutterFrameworkPath was built '
      'with "${engineClangVersion ?? 'unknown'}", but the current version '
      'of clang is "$clangVersion". This will result in failures when trying to'
      'archive an IPA. To resolve this issue, update your version of Xcode to '
      'at least $engineClangSemVer.',
    );
  }
}

Version _parseVersionFromClang(String clangVersion) {
  final RegExp pattern = RegExp(r'Apple (LLVM|clang) version (\d+\.\d+\.\d+) ');
  void _invalid() {
    throwToolExit('Unable to parse Clang version from "$clangVersion". '
                  'Expected a string like "Apple (LLVM|clang) #.#.# (clang-####.#.##.#)".');
  }

  if (clangVersion == null || clangVersion.isEmpty) {
    _invalid();
  }
  final RegExpMatch match = pattern.firstMatch(clangVersion);
  if (match == null || match.groupCount != 2) {
    _invalid();
  }
  final Version version = Version.parse(match.group(2));
  if (version == null) {
    _invalid();
  }
  return version;
}
