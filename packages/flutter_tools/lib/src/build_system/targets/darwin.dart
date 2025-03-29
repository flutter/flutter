// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../flutter_plugins.dart';
import '../../globals.dart' as globals;
import '../../project.dart';
import '../build_system.dart';
import '../exceptions.dart';

/// A target that checks that dev dependencies are enabled on debug/profile
/// builds and disabled on release builds.
///
/// The Flutter tool enables/disables dev dependencies using the build mode.
/// These can get out of sync if the user switches the build mode in Xcode.
///
/// Implementers should override [CheckDevDependencies.inputs] to add a [Source]
/// that changes when dev dependencies status changes.
abstract class CheckDevDependencies extends Target {
  const CheckDevDependencies();

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[
    const Source.pattern(
      '{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/darwin.dart',
    ),
    Source.fromProject((FlutterProject project) => project.flutterPluginsDependenciesFile),
  ];

  @override
  List<Source> get outputs => const <Source>[];

  // The command that turns on dev dependencies.
  // Displayed in the error message if dev dependencies are off in a debug build.
  @visibleForOverriding
  String get debugBuildCommand;

  // The command that turns on dev dependencies.
  // Displayed in the error message if dev dependencies are off in a profile build.
  @visibleForOverriding
  String get profileBuildCommand;

  // The command that turns off dev dependencies.
  // Displayed in the error message if dev dependencies are off in a release build.
  @visibleForOverriding
  String get releaseBuildCommand;

  // Check that dev dependencies are enabled on debug or profile builds and
  // disabled on release builds.
  //
  // The Flutter tool enables/disables dev dependencies using the build mode.
  // These can get out of sync if the user switches the build mode in Xcode.
  @override
  Future<void> build(Environment environment) async {
    final String? buildModeEnvironment = environment.defines[kBuildMode];
    if (buildModeEnvironment == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(buildModeEnvironment);
    final String? devDependenciesEnabledString = environment.defines[kDevDependenciesEnabled];
    if (devDependenciesEnabledString == null) {
      throw MissingDefineException(kDevDependenciesEnabled, name);
    }

    final bool? devDependenciesEnabled = bool.tryParse(
      environment.defines[kDevDependenciesEnabled] ?? '',
    );
    if (devDependenciesEnabled == null) {
      throw Exception(
        'Unexpected $kDevDependenciesEnabled define value: "$devDependenciesEnabledString"',
      );
    }

    if (devDependenciesEnabled && buildMode.isRelease) {
      // Supress this error if the project has no dev dependencies.
      if (!_hasDevDependencies(environment)) {
        environment.logger.printTrace(
          'Ignoring dev dependencies error as the project has no dev dependencies',
        );
        return;
      }

      _printXcodeError(
        'Release builds should not have Dart dev dependencies enabled\n'
        '\n'
        'This error happens if:\n'
        '\n'
        '1. Your pubspec.yaml has dev dependencies\n'
        '2. Your last Flutter CLI action turned on dev dependencies\n'
        '3. You do a release build in Xcode\n'
        '\n'
        'You can turn off Dart dev dependencies by running this in your Flutter project:\n'
        '\n'
        '  $releaseBuildCommand\n'
        '\n',
      );
      throwToolExit('Dev dependencies enabled in release build');
    } else if (!devDependenciesEnabled && !buildMode.isRelease) {
      // Supress this error if the project has no dev dependencies.
      if (!_hasDevDependencies(environment)) {
        environment.logger.printTrace(
          'Ignoring dev dependencies error as the project has no dev dependencies',
        );
        return;
      }

      final bool profile = buildMode == BuildMode.profile;
      _printXcodeError(
        '${profile ? 'Profile' : 'Debug'} builds require Dart dev dependencies\n'
        '\n'
        'This error happens if:\n'
        '\n'
        '1. Your pubspec.yaml has dev dependencies\n'
        '2. Your last Flutter CLI action turned off dev dependencies\n'
        '3. You do a debug or profile build in Xcode\n'
        '\n'
        'You can turn on Dart dev dependencies by running this in your Flutter project:\n'
        '\n'
        '  ${profile ? profileBuildCommand : debugBuildCommand}\n'
        '\n',
      );
      throwToolExit('Dev dependencies disabled in ${profile ? 'profile' : 'debug'} build');
    }
  }

  // Check if the iOS project has Dart dev dependencies. On error, assumes true.
  bool _hasDevDependencies(Environment environment) {
    // If the app has no plugins, the .flutter-plugins-dependencies file isn't generated.
    final FlutterProject project = FlutterProject.fromDirectory(environment.projectDir);
    final File pluginsFile = project.flutterPluginsDependenciesFile;
    if (!pluginsFile.existsSync()) {
      return false;
    }

    try {
      return flutterPluginsListHasDevDependencies(pluginsFile);
    } on Exception catch (e) {
      environment.logger.printWarning('Unable to parse .flutter-plugins-dependencies file:\n$e');
      return true;
    }
  }

  void _printXcodeError(String message) {
    globals.stdio.stderrWrite('error: $message');
  }
}
