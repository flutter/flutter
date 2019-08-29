// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_builder.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

class BuildAarCommand extends BuildSubCommand {
  BuildAarCommand({bool verboseHelp = false}) {
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesFlavorOption();
    usesPubOption();
    argParser
      ..addMultiOption('target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the project is compiled.',
      )
      ..addOption('output-dir',
        help: 'The absolute path to the directory where the repository is generated.'
              'By default, this is \'<current-directory>android/build\'. ',
      );
  }

  @override
  final String name = 'aar';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usage = <CustomDimensions, String>{};
    final FlutterProject futterProject = _getProject();
    if (futterProject == null) {
      return usage;
    }
    if (futterProject.manifest.isModule) {
      usage[CustomDimensions.commandBuildAarProjectType] = 'module';
    } else if (futterProject.manifest.isPlugin) {
      usage[CustomDimensions.commandBuildAarProjectType] = 'plugin';
    } else {
      usage[CustomDimensions.commandBuildAarProjectType] = 'app';
    }
    usage[CustomDimensions.commandBuildAarTargetPlatform] =
        (argResults['target-platform'] as List<String>).join(',');
    return usage;
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
    DevelopmentArtifact.android,
  };

  @override
  final String description = 'Build a repository containing an AAR and a POM file.\n\n'
      'The POM file is used to include the dependencies that the AAR was compiled against.\n\n'
      'To learn more about how to use these artifacts, see '
      'https://docs.gradle.org/current/userguide/repository_types.html#sub:maven_local';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = getBuildInfo();
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(buildInfo,
        targetArchs: argResults['target-platform'].map<AndroidArch>(getAndroidArchForName));

    await androidBuilder.buildAar(
      project: _getProject(),
      target: '', // Not needed because this command only builds Android's code.
      androidBuildInfo: androidBuildInfo,
      outputDir: argResults['output-dir'],
    );
    return null;
  }

  /// Returns the [FlutterProject] which is determinated from the remaining command-line
  /// argument if any or the current working directory.
  FlutterProject _getProject() {
    if (argResults.rest.isEmpty) {
      return FlutterProject.current();
    }
    return FlutterProject.fromPath(findProjectRoot(argResults.rest.first));
  }
}
