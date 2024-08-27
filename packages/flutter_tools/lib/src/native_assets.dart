// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/platform.dart';
import 'build_info.dart';
import 'project.dart';

/// An interface to enable overriding native assets build logic in other
/// build systems.
abstract class TestCompilerNativeAssetsBuilder {
  Future<Uri?> build(BuildInfo buildInfo);

  /// Returns the current PATH environment variable with the native assets build
  /// directory prepended.
  ///
  /// By setting the PATH environment variable for the flutter tester to the
  /// return value of this function, DLLs in the native assets build directory can
  /// be found by the dynamic linker. This is necessary to support native asset
  /// libraries that dynamically link to other libraries.
  String windowsPathWithBuildDirectory(FlutterProject project, Platform platform);
}
