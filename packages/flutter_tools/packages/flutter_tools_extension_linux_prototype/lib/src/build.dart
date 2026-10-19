// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:yaml/yaml.dart';

/// Prototype Linux [BuildService] implementation.
final class LinuxBuildService extends BuildService {
  /// Target name for the prototype Linux build target.
  static const String customLinuxBuildTargetName = 'custom-linux-build';
  static const String _defaultAppName = 'app';
  static const String _pubspecNameKey = 'name';

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
      String appName = _defaultAppName;
      final pubspecFile = File.fromUri(projectDirUri.resolve('pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        try {
          final Object? parsed = loadYaml(pubspecFile.readAsStringSync());
          if (parsed case {_pubspecNameKey: final String name} when name.trim().isNotEmpty) {
            appName = name.trim();
          }
        } on YamlException {
          // Fall back to default app name if pubspec.yaml is malformed.
        }
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
