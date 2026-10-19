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
      final projectDir = Directory.fromUri(projectRoot);
      String appName = _defaultAppName;
      final pubspecFile = File('${projectDir.path}/pubspec.yaml');
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

      final executableFile = File(
        '${projectDir.path}/build/linux/x64/${buildMode.cliName}/bundle/$appName',
      );
      return ExtensionBuildResult(success: true, executablePath: executableFile.absolute.path);
    }
    return ExtensionBuildResult(success: false, errorMessage: 'Unknown build target: $targetName');
  }
}
