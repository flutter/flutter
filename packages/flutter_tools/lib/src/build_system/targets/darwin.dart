// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../artifacts.dart';
import '../../base/io.dart';
import '../../build_info.dart';
import '../../darwin/darwin.dart';
import '../../globals.dart' as globals show stdio;
import '../../project.dart';
import '../build_system.dart';

abstract class UnpackDarwin extends Target {
  const UnpackDarwin();

  @visibleForOverriding
  FlutterDarwinPlatform get darwinPlatform;

  @override
  Future<bool> canSkip(Environment environment) async {
    final String? buildScript = environment.defines[kXcodeBuildScript];
    final FlutterProject flutterProject = FlutterProject.fromDirectory(environment.projectDir);
    final XcodeBasedProject xcodeProject = darwinPlatform.xcodeProject(flutterProject);
    if (buildScript == kXcodeBuildScriptValueBuild &&
        xcodeProject.usesSwiftPackageManager &&
        xcodeProject.flutterFrameworkSwiftPackageDirectory.existsSync()) {
      // Skip copying the Flutter framework during the build Run Script if Swift Package Manager
      // is being used and the FlutterFramework swift package exists. Swift Package Manager now
      // handles the Flutter framework.
      return true;
    }
    return false;
  }

  /// Copies the [framework] artifact using `rsync` to the [Environment.outputDir].
  /// Throws an error if copy fails.
  @protected
  Future<void> copyFramework(
    Environment environment, {
    EnvironmentType? environmentType,
    TargetPlatform? targetPlatform,
    required Artifact framework,
    required BuildMode buildMode,
  }) async {
    final String basePath = environment.artifacts.getArtifactPath(
      framework,
      platform: targetPlatform,
      mode: buildMode,
      environmentType: environmentType,
    );

    final ProcessResult result = await environment.processManager.run(<String>[
      'rsync',
      '-av',
      '--delete',
      '--filter',
      '- .DS_Store/',
      '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
      basePath,
      environment.outputDir.path,
    ]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}',
      );
    }
  }

  /// Verifies and destructively thins the framework binary found at [frameworkBinaryPath]
  /// to include only the architectures specified in [archs].
  ///
  /// [archs] should be a space separated list passed from Xcode containing one or
  /// more architectures (e.g. "x86_64 arm64", "arm64", "x86_64").
  ///
  /// Throws an error if the binary does not contain the [archs] or fails to thin.
  @protected
  Future<void> thinFramework(
    Environment environment,
    String frameworkBinaryPath,
    String archs,
  ) async {
    final List<String> archList = archs.split(' ').toList();
    final ProcessResult infoResult = await environment.processManager.run(<String>[
      'lipo',
      '-info',
      frameworkBinaryPath,
    ]);
    final lipoInfo = infoResult.stdout as String;

    final ProcessResult verifyResult = await environment.processManager.run(<String>[
      'lipo',
      frameworkBinaryPath,
      '-verify_arch',
      ...archList,
    ]);

    if (verifyResult.exitCode != 0) {
      throw Exception(
        'Binary $frameworkBinaryPath does not contain architectures "$archs".\n'
        '\n'
        'lipo -info:\n'
        '$lipoInfo',
      );
    }

    // Skip thinning for non-fat executables.
    if (lipoInfo.startsWith('Non-fat file:')) {
      environment.logger.printTrace('Skipping lipo for non-fat file $frameworkBinaryPath');
      return;
    }

    // Thin in-place.
    final ProcessResult extractResult = await environment.processManager.run(<String>[
      'lipo',
      '-output',
      frameworkBinaryPath,
      for (final String arch in archList) ...<String>['-extract', arch],
      frameworkBinaryPath,
    ]);

    if (extractResult.exitCode != 0) {
      throw Exception(
        'Failed to extract architectures "$archs" for $frameworkBinaryPath.\n'
        '\n'
        'stderr:\n'
        '${extractResult.stderr}\n\n'
        'lipo -info:\n'
        '$lipoInfo',
      );
    }
  }
}

/// Log warning message to the Xcode build logs. Log will show as yellow with an icon.
///
/// If the issue occurs in a specific file, include the [filePath] as an absolute path.
/// If the issue occurs at a specific line in the file, include the [lineNumber] as well.
/// The [filePath] and [lineNumber] are optional.
void printXcodeWarning(String warning, {String? filePath, int? lineNumber}) {
  _printXcodeLog(XcodeLogType.warning, warning, filePath: filePath, lineNumber: lineNumber);
}

/// Log error message to the Xcode build logs. Log will show as red with an icon and may cause the build to fail.
///
/// If the issue occurs in a specific file, include the [filePath] as an absolute path.
/// If the issue occurs at a specific line in the file, include the [lineNumber] as well.
/// The [filePath] and [lineNumber] are optional.
void printXcodeError(String error, {String? filePath, int? lineNumber}) {
  _printXcodeLog(XcodeLogType.error, error, filePath: filePath, lineNumber: lineNumber);
}

/// Log note message to the Xcode build logs. Log will show with no special color or icon.
///
/// If the issue occurs in a specific file, include the [filePath] as an absolute path.
/// If the issue occurs at a specific line in the file, include the [lineNumber] as well.
/// The [filePath] and [lineNumber] are optional.
void printXcodeNote(String note, {String? filePath, int? lineNumber}) {
  _printXcodeLog(XcodeLogType.note, note, filePath: filePath, lineNumber: lineNumber);
}

/// Log [message] to the Xcode build logs.
///
/// If [logType] is [XcodeLogType.error], log will show as red with an icon and may cause the build to fail.
/// If [logType] is [XcodeLogType.warning], log will show as yellow with an icon.
/// If [logType] is [XcodeLogType.note], log will show with no special color or icon.
///
///
/// If the issue occurs in a specific file, include the [filePath] as an absolute path.
/// If the issue occurs at a specific line in the file, include the [lineNumber] as well.
/// The [filePath] and [lineNumber] are optional.
///
/// See Apple's documentation:
/// https://developer.apple.com/documentation/xcode/running-custom-scripts-during-a-build#Log-errors-and-warnings-from-your-script
void _printXcodeLog(XcodeLogType logType, String message, {String? filePath, int? lineNumber}) {
  var linePath = '';
  if (filePath != null) {
    linePath = '$filePath:';

    // A line number is meaningless without a filePath, so only set if filePath is also provided.
    if (lineNumber != null) {
      linePath = '$linePath$lineNumber:';
    }
  }
  if (linePath.isNotEmpty) {
    linePath = '$linePath ';
  }

  // Must be printed to stderr to be streamed to the Flutter tool in xcode_backend.dart.
  globals.stdio.stderrWrite('$linePath${logType.name}: $message\n');
}

enum XcodeLogType { error, warning, note }
