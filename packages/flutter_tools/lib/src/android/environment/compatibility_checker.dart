// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/logger.dart';
import '../../base/os.dart';
import '../../base/platform.dart';
import '../java.dart';
import 'candidate_locator.dart';

/// Checks compatibility between a candidate Java installation and an Android SDK.
class AndroidCompatibilityChecker {
  AndroidCompatibilityChecker({
    required this.fileSystem,
    required this.processManager,
    required this.platform,
    required this.operatingSystemUtils,
    required this.logger,
  });

  final FileSystem fileSystem;
  final ProcessManager processManager;
  final Platform platform;
  final OperatingSystemUtils operatingSystemUtils;
  final Logger logger;

  /// Returns true if [javaCandidate] is capable of running the tools in [sdkDir].
  ///
  /// This executes `sdkmanager --version` with the given Java runtime to ensure
  /// that JVM class version incompatibilities (such as `UnsupportedClassVersionError`
  /// when running older SDK command-line tools under newer JDKs) are detected.
  bool isCompatiblePair(JavaHomeCandidate javaCandidate, Directory? sdkDir) {
    String? javaBin;
    if (javaCandidate.path != null) {
      javaBin = fileSystem.path.join(javaCandidate.path!, 'bin', 'java');
    } else {
      javaBin = operatingSystemUtils.which('java')?.path;
    }

    if (javaBin == null || !processManager.canRun(javaBin)) {
      logger.printTrace(
        'Java candidate ${javaCandidate.path ?? "PATH"} missing or not runnable java binary ($javaBin).',
      );
      return false;
    }

    if (sdkDir == null) {
      // If no SDK is provided, compatibility succeeds if Java is executable.
      return true;
    }

    // Check for sdkmanager in cmdline-tools
    String? sdkmanagerPath;
    final Directory cmdlineToolsDir = sdkDir.childDirectory('cmdline-tools');
    if (cmdlineToolsDir.existsSync()) {
      final subdirs = <String>['latest'];
      try {
        subdirs.addAll(
          cmdlineToolsDir
              .listSync()
              .whereType<Directory>()
              .map((Directory d) => d.basename)
              .where((String name) => name != 'latest'),
        );
      } on Exception {
        // ignore errors reading directory
      }

      final execName = platform.isWindows ? 'sdkmanager.bat' : 'sdkmanager';
      for (final subdir in subdirs) {
        final File candidate = cmdlineToolsDir
            .childDirectory(subdir)
            .childDirectory('bin')
            .childFile(execName);
        if (candidate.existsSync()) {
          sdkmanagerPath = candidate.path;
          break;
        }
      }
    }

    if (sdkmanagerPath == null) {
      // If sdkmanager is not present, skip compatibility check.
      return true;
    }

    final String? javaHome = javaCandidate.path;
    final String pathDir = fileSystem.path.dirname(javaBin);
    final pathEnv = '$pathDir:${platform.environment['PATH'] ?? ""}';

    final ProcessResult result = processManager.runSync(
      <String>[sdkmanagerPath, '--version'],
      environment: <String, String>{
        if (javaHome != null) Java.javaHomeEnvironmentVariable: javaHome,
        'PATH': pathEnv,
      },
    );

    if (result.exitCode != 0) {
      logger.printTrace(
        'Skipping Java candidate ${javaCandidate.path ?? "PATH"} (${javaCandidate.source.name}): '
        'incompatible with sdkmanager at $sdkmanagerPath.\n'
        'Exit code: ${result.exitCode}. Stderr: ${result.stderr}',
      );
      return false;
    }

    return true;
  }
}
