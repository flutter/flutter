// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../build_info.dart';
import '../project.dart';

/// The builder in the current context.
AndroidBuilder? get androidBuilder {
  return context.get<AndroidBuilder>();
}

abstract class AndroidBuilder {
  const AndroidBuilder();
  /// Builds an AAR artifact.
  Future<void> buildAar({
    required final FlutterProject project,
    required final Set<AndroidBuildInfo> androidBuildInfo,
    required final String target,
    final String? outputDirectoryPath,
    required final String buildNumber,
  });

  /// Builds an APK artifact.
  Future<void> buildApk({
    required final FlutterProject project,
    required final AndroidBuildInfo androidBuildInfo,
    required final String target,
    final bool configOnly = false,
  });

  /// Builds an App Bundle artifact.
  Future<void> buildAab({
    required final FlutterProject project,
    required final AndroidBuildInfo androidBuildInfo,
    required final String target,
    final bool validateDeferredComponents = true,
    final bool deferredComponentsEnabled = false,
    final bool configOnly = false,
  });
}
