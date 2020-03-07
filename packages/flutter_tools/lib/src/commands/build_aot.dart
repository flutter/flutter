// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../aot.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../ios/bitcode.dart';
import '../resident_runner.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

/// Builds AOT snapshots into platform specific library containers.
class BuildAotCommand extends BuildSubCommand with TargetPlatformBasedDevelopmentArtifacts {
  BuildAotCommand({bool verboseHelp = false, this.aotBuilder}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    usesDartDefineOption();
    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios', 'android-x64'],
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
        defaultsTo: kBitcodeEnabledDefault,
        help: 'Build the AOT bundle with bitcode. Requires a compatible bitcode engine.',
        hide: true,
      );
    // --track-widget-creation is exposed as a flag here to deal with build
    // invalidation issues, but it is ignored -- there are no plans to support
    // it for AOT mode.
    usesTrackWidgetCreation(hasEffect: false, verboseHelp: verboseHelp);
  }

  AotBuilder aotBuilder;

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = stringArg('target-platform');
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    final String outputPath = stringArg('output-dir') ?? getAotBuildDirectory();
    final BuildInfo buildInfo = getBuildInfo();
    if (platform == null) {
      throwToolExit('Unknown platform: $targetPlatform');
    }

    aotBuilder ??= AotBuilder();

    await aotBuilder.build(
      platform: platform,
      outputPath: outputPath,
      buildInfo: buildInfo,
      mainDartFile: findMainDartFile(targetFile),
      bitcode: boolArg('bitcode'),
      quiet: boolArg('quiet'),
      reportTimings: boolArg('report-timings'),
      iosBuildArchs: stringsArg('ios-arch').map<DarwinArch>(getIOSArchForName),
    );
    return FlutterCommandResult.success();
  }
}
