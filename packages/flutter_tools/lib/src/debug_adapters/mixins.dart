// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/io.dart';

/// A mixin providing some utility functions for locating/working with
/// package_config.json files.
///
/// Adapted from package:dds/src/dap/adapters/mixins.dart to use Flutter's
/// dart:io wrappers.
mixin PackageConfigUtils {
  abstract FileSystem fileSystem;

  /// Find the `package_config.json` file for the program being launched.
  File? findPackageConfigFile(String possibleRoot) {
    // TODO(dantup): Remove this once
    //   https://github.com/dart-lang/sdk/issues/45530 is done as it will not be
    //   necessary.
    File? packageConfig;
    while (true) {
      packageConfig = fileSystem.file(
        fileSystem.path.join(possibleRoot, '.dart_tool', 'package_config.json'),
      );

      // If this packageconfig exists, use it.
      if (packageConfig.existsSync()) {
        break;
      }

      final String parent = fileSystem.path.dirname(possibleRoot);

      // If we can't go up anymore, the search failed.
      if (parent == possibleRoot) {
        packageConfig = null;
        break;
      }

      possibleRoot = parent;
    }

    return packageConfig;
  }
}

/// A mixin for tracking additional PIDs that can be shut down at the end of a debug session.
///
/// Adapted from package:dds/src/dap/adapters/mixins.dart to use Flutter's
/// dart:io wrappers.
mixin PidTracker {
  /// Process IDs to terminate during shutdown.
  ///
  /// This may be populated with pids from the VM Service to ensure we clean up
  /// properly where signals may not be passed through the shell to the
  /// underlying VM process.
  /// https://github.com/Dart-Code/Dart-Code/issues/907
  final Set<int> pidsToTerminate = <int>{};

  /// Terminates all processes with the PIDs registered in [pidsToTerminate].
  void terminatePids(ProcessSignal signal) {
    pidsToTerminate.forEach(signal.send);
  }
}
