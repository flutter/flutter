// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux [BuildService] implementation.
final class LinuxBuildService extends BuildService {
  /// Target name for the prototype Linux build target.
  static const String customLinuxBuildTargetName = 'custom-linux-build';

  /// Target platform for the prototype Linux build target.
  static const String linuxX64TargetPlatform = 'linux-x64';

  @override
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    return const <ExtensionBuildTarget>[
      ExtensionBuildTarget(
        description: 'A custom Linux build target from prototype extension.',
        name: customLinuxBuildTargetName,
        targetPlatform: linuxX64TargetPlatform,
      ),
    ];
  }

  @override
  Future<ExtensionBuildResult> build({
    required String buildMode,
    required String mainPath,
    required String projectRoot,
    required String targetName,
  }) async {
    if (targetName == customLinuxBuildTargetName) {
      return const ExtensionBuildResult(success: true);
    }
    return ExtensionBuildResult(success: false, errorMessage: 'Unknown build target: $targetName');
  }
}
