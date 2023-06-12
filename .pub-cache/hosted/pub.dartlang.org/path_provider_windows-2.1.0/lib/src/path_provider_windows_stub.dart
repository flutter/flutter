// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A stub implementation to satisfy compilation of multi-platform packages that
/// depend on path_provider_windows. This should never actually be created.
///
/// Notably, because path_provider needs to manually register
/// path_provider_windows, anything with a transitive dependency on
/// path_provider will also depend on path_provider_windows, not just at the
/// pubspec level but the code level.
class PathProviderWindows extends PathProviderPlatform {
  /// Errors on attempted instantiation of the stub. It exists only to satisfy
  /// compile-time dependencies, and should never actually be created.
  PathProviderWindows() : assert(false);

  /// Registers the Windows implementation.
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderWindows();
  }

  /// Stub; see comment on VersionInfoQuerier.
  VersionInfoQuerier versionInfoQuerier = VersionInfoQuerier();

  /// Match PathProviderWindows so that the analyzer won't report invalid
  /// overrides if tests provide fake PathProviderWindows implementations.
  Future<String> getPath(String folderID) async => '';
}

/// Stub to satisfy the analyzer, which doesn't seem to handle conditional
/// exports correctly.
class VersionInfoQuerier {}
