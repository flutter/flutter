// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/io.dart';

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

mixin FlutterAdapter  {
  Map<String, Uri> get orgDartlangSdkMappings;
  String get flutterSdkRoot;
  FileSystem get fileSystem;

  void configureOrgDartlangSdkMappings() {
    /// When a user navigates into 'dart:xxx' sources in their editor (via the
    /// analysis server) they will land in flutter_sdk/bin/cache/pkg/sky_engine.
    ///
    /// The running VM knows nothing about these paths and will resolve these
    /// libraries to 'org-dartlang-sdk://' URIs. We need to map between these
    /// to ensure that if a user puts a breakpoint inside sky_engine the VM can
    /// apply it to the correct place and once hit, we can navigate the user
    /// back to the correct file on their disk.
    ///
    /// The mapping is handled by the base adapter but we need to override the
    /// paths to match the layout used by Flutter.
    ///
    /// In future this might become unnecessary if
    /// https://github.com/dart-lang/sdk/issues/48435 is implemented. Until
    /// then, providing these mappings improves the debugging experience.

    // Clear original Dart SDK mappings because they're not valid here.
    orgDartlangSdkMappings.clear();

    // 'dart:ui' maps to /flutter/lib/ui
    final String flutterRoot = fileSystem.path.join(flutterSdkRoot, 'bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui');
    orgDartlangSdkMappings[flutterRoot] = Uri.parse('org-dartlang-sdk:///flutter/lib/ui');

    // The rest of the Dart SDK maps to /third_party/dart/sdk
    final String dartRoot = fileSystem.path.join(flutterSdkRoot, 'bin', 'cache', 'pkg', 'sky_engine');
    orgDartlangSdkMappings[dartRoot] = Uri.parse('org-dartlang-sdk:///third_party/dart/sdk');
  }
}
