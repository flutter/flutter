// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux [BuildService] implementation.
final class LinuxBuildService extends BuildService {
  /// Target name for the prototype Linux build target.
  static const String customLinuxBuildTargetName = 'custom-linux-build';

  static String? _getCmakeBinaryName(Uri projectDirUri) {
    final cmakeFile = File.fromUri(projectDirUri.resolve('linux/CMakeLists.txt'));
    if (!cmakeFile.existsSync()) {
      return null;
    }
    final nameSetPattern = RegExp(r'^\s*set\(BINARY_NAME\s*"(.*)"\s*\)\s*$');
    for (final String line in cmakeFile.readAsLinesSync()) {
      final RegExpMatch? match = nameSetPattern.firstMatch(line);
      if (match != null) {
        final String name = match.group(1)!.trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    }
    return null;
  }

  @override
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return const <ExtensionBuildTarget>[
      ExtensionBuildTarget(
        description: 'A custom Linux build target from prototype extension.',
        name: customLinuxBuildTargetName,
      ),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    if (targetName == customLinuxBuildTargetName) {
      final Uri projectDirUri = Directory.fromUri(projectRoot).uri;
      final String? appName = _getCmakeBinaryName(projectDirUri);
      if (appName == null) {
        return const ExtensionBuildResult(
          success: false,
          errorMessage: 'Could not find BINARY_NAME in linux/CMakeLists.txt.',
        );
      }

      // TODO(bkonyi): Invoke the Linux build pipeline instead of resolving the expected bundle path.
      final executableFile = File.fromUri(
        projectDirUri.resolve('build/linux/x64/${buildMode.cliName}/bundle/$appName'),
      );
      return ExtensionBuildResult(success: true, executableUri: executableFile.absolute.uri);
    }
    return ExtensionBuildResult(success: false, errorMessage: 'Unknown build target: $targetName');
  }
}
