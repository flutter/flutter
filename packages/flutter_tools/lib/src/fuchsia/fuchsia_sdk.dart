// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/file_system.dart';

/// The fuchsia SDK.
FuchsiaSdk get fuchsiaSdk => context[FuchsiaSdk];

/// The fuchsia SDK.
class FuchsiaSdk {
  FuchsiaSdk(this.location);

  factory FuchsiaSdk.locateFuchsiaSdk() {
    // TODO?
    // It's either in a third_party directory or else it doesn't exist.
    final Directory location = fs.directory('third_party/unsupported_toolchains/fuchsia/sdk');
    return FuchsiaSdk(location);
  }

  /// The location of the fuchsia SDK.
  final Directory location;

  /// The path to the netls tool.
  ///
  /// This is used to discover fuchsia devices.
  String get netlsPath {
    return '${location.path}/tools/netls';
  }
}