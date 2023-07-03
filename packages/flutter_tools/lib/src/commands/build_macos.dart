// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../ios/mac.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macOS desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand({
    required super.logger,
    required bool verboseHelp,
  }) : super(verboseHelp: verboseHelp) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
    usesFlavorOption();
    argParser
      .addFlag('config-only',
        help: 'Update the project configuration without performing a build. '
          'This can be used in CI/CD process that create an archive to avoid '
          'performing duplicate work.'
    );
  }

  @override
  final String name = 'macos';

  @override
  bool get hidden => !featureFlags.isMacOSEnabled || !globals.platform.isMacOS;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
  };

  @override
  String get description => 'Build a macOS desktop application.';

  @override
  bool get supported => globals.platform.isMacOS;

  bool get configOnly => boolArg('config-only');

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!featureFlags.isMacOSEnabled) {
      throwToolExit('"build macos" is not currently supported. To enable, run "flutter config --enable-macos-desktop".');
    }
    if (!supported) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }
    displayNullSafetyMode(buildInfo);
    final XcodeBuildResult result = await buildMacOS(
      flutterProject: flutterProject,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      verboseLogging: globals.logger.isVerbose,
      configOnly: configOnly,
    );

    if (result.output == null) {
      return FlutterCommandResult.fail();
    }

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result, globals.flutterUsage, globals.logger);
      throwToolExit('Encountered error while building for device.');
    }

    if (buildInfo.codeSizeDirectory != null) {
      final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
        fileSystem: globals.fs,
        logger: globals.logger,
        appFilenamePattern: 'App',
        flutterUsage: globals.flutterUsage,
      );
      final String arch = DarwinArch.x86_64.name;
      final File aotSnapshot = globals.fs.directory(buildInfo.codeSizeDirectory)
        .childFile('snapshot.$arch.json');
      final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
        .childFile('trace.$arch.json');

      // This analysis is only supported for release builds.
      // Attempt to guess the correct .app by picking the first one.
      final Directory candidateDirectory = globals.fs.directory(
        globals.fs.path.join(getMacOSBuildDirectory(), 'Build', 'Products', 'Release'),
      );
      final Directory appDirectory = candidateDirectory.listSync()
        .whereType<Directory>()
        .firstWhere((Directory directory) {
        return globals.fs.path.extension(directory.path) == '.app';
      });
      final Map<String, Object?> output = await sizeAnalyzer.analyzeAotSnapshot(
        aotSnapshot: aotSnapshot,
        precompilerTrace: precompilerTrace,
        outputDirectory: appDirectory,
        type: 'macos',
        excludePath: 'Versions', // Avoid double counting caused by symlinks
      );
      final File outputFile = globals.fsUtils.getUniqueFile(
        globals.fs
          .directory(globals.fsUtils.homeDirPath)
          .childDirectory('.flutter-devtools'), 'macos-code-size-analysis', 'json',
      )..writeAsStringSync(jsonEncode(output));
      // This message is used as a sentinel in analyze_apk_size_test.dart
      globals.printStatus(
        'A summary of your macOS bundle analysis can be found at: ${outputFile.path}',
      );

      // DevTools expects a file path relative to the .flutter-devtools/ dir.
      final String relativeAppSizePath = outputFile.path.split('.flutter-devtools/').last.trim();
      globals.printStatus(
        '\nTo analyze your app size in Dart DevTools, run the following command:\n'
        'dart devtools --appSizeBase=$relativeAppSizePath'
      );
    }

    final Directory outputDirectory = globals.fs.directory(result.output);
    final int? directorySize = globals.os.getDirectorySize(outputDirectory);
    final String appSize = (directorySize == null)
        ? '' // Don't display the size when building a debug variant.
        : ' (${getSizeAsMB(directorySize)})';

    globals.printStatus(
      '${globals.terminal.successMark} '
      'Built ${globals.fs.path.relative(outputDirectory.path)}$appSize',
      color: TerminalColor.green,
    );

    return FlutterCommandResult.success();
  }
}
