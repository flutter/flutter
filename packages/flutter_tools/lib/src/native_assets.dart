// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'asset.dart';
import 'build_info.dart';
import 'context/tool_context.dart';
import 'project.dart';

typedef TestCompilerNativeAssetsBuildResult = ({
  Uri? nativeAssetsManifest,
  FlutterHookResult? flutterHookResult,
});

/// An interface to enable overriding native assets build logic in other
/// build systems.
abstract class TestCompilerNativeAssetsBuilder {
  Future<Uri?> build(BuildInfo buildInfo, {required ToolContext toolContext});

  Future<TestCompilerNativeAssetsBuildResult> buildWithHookResult(
    BuildInfo buildInfo, {
    required ToolContext toolContext,
  }) async => (
    nativeAssetsManifest: await build(buildInfo, toolContext: toolContext),
    flutterHookResult: null,
  );

  /// Returns the Windows native assets build directory.
  ///
  /// By prepending the PATH environment variable for the flutter tester with the
  /// return value of this function, DLLs in the native assets build directory can
  /// be found by the dynamic linker. This is necessary to support native asset
  /// libraries that dynamically link to other libraries.
  String windowsBuildDirectory(FlutterProject project, {required ToolContext toolContext});
}
