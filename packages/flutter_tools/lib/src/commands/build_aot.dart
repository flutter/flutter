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
  BuildAotCommand({this.aotBuilder}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    usesDartDefineOption();
    usesExtraFrontendOptions();
    argParser
      ..addOption('output-dir', defaultsTo: getAotBuildDirectory())
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64', 'ios', 'android-x64'],
      )
      ..addFlag('quiet', defaultsTo: false)
      ..addMultiOption('ios-arch',
        splitCommas: true,
        defaultsTo: defaultIOSArchs.map<String>(getNameForDarwinArch),
        allowed: DarwinArch.values.map<String>(getNameForDarwinArch),
        help: 'iOS architectures to build.',
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('bitcode',
        defaultsTo: kBitcodeEnabledDefault,
        help: 'Build the AOT bundle with bitcode. Requires a compatible bitcode engine.',
        hide: true,
      )
      ..addFlag('report-timings', hide: true);
  }

  AotBuilder aotBuilder;

  @override
  final String name = 'aot';

  // TODO(jonahwilliams): remove after https://github.com/flutter/flutter/issues/49562 is resolved.
  @override
  bool get deprecated => true;

  @override
  final String description = "(deprecated) Build an ahead-of-time compiled snapshot of your app's Dart code.";

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
      iosBuildArchs: stringsArg('ios-arch').map<DarwinArch>(getIOSArchForName),
      reportTimings: boolArg('report-timings'),
    );
    return FlutterCommandResult.success();
  }
}
