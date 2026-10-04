// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/project_migrator.dart';
import '../ios/xcodeproj.dart';
import '../xcode_project.dart';

// Xcode 14.3 changed the readlink symlink behavior to be relative from the script working directory, instead of the
// relative path of the symlink. The -f flag returns the original "--canonicalize" behavior the CocoaPods script relies on.
// This has been fixed upstream in CocoaPods, but migrate a copy of their workaround so users don't need to update.
//
// See https://github.com/flutter/flutter/issues/123890#issuecomment-1494825976.
class CocoaPodsScriptReadlink extends ProjectMigrator {
  CocoaPodsScriptReadlink(
    XcodeBasedProject project,
    XcodeProjectInterpreter xcodeProjectInterpreter,
    super.logger,
  ) : _podRunnerFrameworksScript = project.podRunnerFrameworksScript,
      _xcodeProjectInterpreter = xcodeProjectInterpreter;

  final File _podRunnerFrameworksScript;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;

  @override
  Future<void> migrate() async {
    if (!_podRunnerFrameworksScript.existsSync()) {
      logger.printTrace(
        'CocoaPods Pods-Runner-frameworks.sh script not found, skipping "readlink -f" workaround.',
      );
      return;
    }

    // If Xcode not installed, skip this migration.
    if (!_xcodeProjectInterpreter.isInstalled) {
      logger.printTrace('Xcode is not installed, skipping "readlink -f" workaround.');
      return;
    }

    processFileLines(_podRunnerFrameworksScript);
  }

  @override
  String? migrateLine(String line) {
    const originalReadLinkLine = r'source="$(readlink "${source}")"';
    const replacementReadLinkLine = r'source="$(readlink -f "${source}")"';

    return line.replaceAll(originalReadLinkLine, replacementReadLinkLine);
  }
}
