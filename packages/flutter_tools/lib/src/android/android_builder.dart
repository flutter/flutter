// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/context.dart';
import '../build_info.dart';
import '../project.dart';

/// The builder in the current context.
AndroidBuilder get androidBuilder {
  return context.get<AndroidBuilder>();
}

abstract class AndroidBuilder {
  const AndroidBuilder();
  /// Builds an AAR artifact.
  Future<void> buildAar({
    @required FlutterProject project,
    @required Set<AndroidBuildInfo> androidBuildInfo,
    @required String target,
    @required String outputDirectoryPath,
    @required String buildNumber,
  });

  /// Builds an APK artifact.
  Future<void> buildApk({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  });

  /// Builds an App Bundle artifact.
  Future<void> buildAab({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    bool validateDeferredComponents = true,
    bool deferredComponentsEnabled = false,
  });
}
